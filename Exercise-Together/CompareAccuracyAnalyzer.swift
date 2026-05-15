import AVFoundation
import CoreGraphics
import Vision

struct CompareAnalysisResult {
    let accuracy: Int
    let syncOffsetMilliseconds: Double
    let angleDeviation: Double
    let issues: [CompareIssue]
}

enum CompareAccuracyAnalyzer {
    private typealias JointName = VNHumanBodyPoseObservation.JointName

    private static let sampleCount = 18
    private static let minimumComparableFrames = 4
    private static let requiredJointConfidence: VNConfidence = 0.6
    private static let requiredHipConfidence: VNConfidence = 0.5

    static func analyze(referenceURL: URL, userURL: URL) async -> CompareAnalysisResult {
        await Task.detached(priority: .userInitiated) {
            let referenceSamples = await sampleVideo(url: referenceURL)
            let userSamples = await sampleVideo(url: userURL)
            let comparablePairs = zip(referenceSamples, userSamples).compactMap { reference, user -> PoseComparison? in
                guard let reference, let user else { return nil }
                return PoseComparison(reference: reference, user: user)
            }

            guard comparablePairs.count >= minimumComparableFrames else {
                return CompareAnalysisResult(
                    accuracy: 0,
                    syncOffsetMilliseconds: 0,
                    angleDeviation: 0,
                    issues: [
                        CompareIssue(
                            type: .warning,
                            title: "Not enough visible pose data",
                            description: "Keep head, shoulders, elbows, wrists, and waist visible in both videos."
                        )
                    ]
                )
            }

            let averageDeviation = comparablePairs.map(\.deviation).reduce(0, +) / Double(comparablePairs.count)
            let poseCoverage = Double(comparablePairs.count) / Double(sampleCount)
            let rawAccuracy = max(0, min(100, 100 - averageDeviation * 1.45))
            let coveragePenalty = poseCoverage < 0.75 ? (0.75 - poseCoverage) * 35 : 0
            let accuracy = max(0, min(100, Int((rawAccuracy - coveragePenalty).rounded())))
            let syncOffset = await estimateSyncOffset(referenceSamples: referenceSamples, userSamples: userSamples, userURL: userURL)
            let issues = buildIssues(
                accuracy: accuracy,
                averageDeviation: averageDeviation,
                poseCoverage: poseCoverage,
                pairs: comparablePairs
            )

            return CompareAnalysisResult(
                accuracy: accuracy,
                syncOffsetMilliseconds: syncOffset,
                angleDeviation: averageDeviation,
                issues: issues
            )
        }.value
    }

    private static func sampleVideo(url: URL) async -> [PoseSample?] {
        let asset = AVURLAsset(url: url)
        guard let duration = try? await asset.load(.duration) else { return [] }
        let durationSeconds = CMTimeGetSeconds(duration)
        guard durationSeconds.isFinite, durationSeconds > 0 else { return [] }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        generator.maximumSize = CGSize(width: 720, height: 720)

        var samples: [PoseSample?] = []
        for index in 0..<sampleCount {
            let progress = Double(index) / Double(max(sampleCount - 1, 1))
            let seconds = max(0.05, min(durationSeconds - 0.05, durationSeconds * progress))
            let time = CMTime(seconds: seconds, preferredTimescale: 600)

            guard let image = await image(from: generator, at: time) else {
                samples.append(nil)
                continue
            }

            samples.append(poseSample(from: image))
        }
        return samples
    }

    private static func image(from generator: AVAssetImageGenerator, at time: CMTime) async -> CGImage? {
        await withCheckedContinuation { continuation in
            generator.generateCGImageAsynchronously(for: time) { image, _, _ in
                continuation.resume(returning: image)
            }
        }
    }

    private static func poseSample(from image: CGImage) -> PoseSample? {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cgImage: image, orientation: .up)

        do {
            try handler.perform([request])
            guard let observation = request.results?.first,
                  let points = try? observation.recognizedPoints(.all) else {
                return nil
            }
            return PoseSample(points: points)
        } catch {
            return nil
        }
    }

    private static func estimateSyncOffset(
        referenceSamples: [PoseSample?],
        userSamples: [PoseSample?],
        userURL: URL
    ) async -> Double {
        guard let referencePeak = peakIndex(referenceSamples),
              let userPeak = peakIndex(userSamples),
              sampleCount > 1 else {
            return 0
        }

        let asset = AVURLAsset(url: userURL)
        guard let duration = try? await asset.load(.duration) else { return 0 }
        let durationSeconds = CMTimeGetSeconds(duration)
        guard durationSeconds.isFinite, durationSeconds > 0 else { return 0 }

        let stepSeconds = durationSeconds / Double(sampleCount - 1)
        return Double(userPeak - referencePeak) * stepSeconds * 1000
    }

    private static func peakIndex(_ samples: [PoseSample?]) -> Int? {
        let scored = samples.enumerated().compactMap { index, sample -> (index: Int, intensity: Double)? in
            guard let intensity = sample?.movementIntensity else { return nil }
            return (index, intensity)
        }

        return scored.max(by: { $0.intensity < $1.intensity })?.index
    }

    private static func buildIssues(
        accuracy: Int,
        averageDeviation: Double,
        poseCoverage: Double,
        pairs: [PoseComparison]
    ) -> [CompareIssue] {
        var issues: [CompareIssue] = []

        if poseCoverage < 0.75 {
            issues.append(
                CompareIssue(
                    type: .warning,
                    title: "Pose visibility is limited",
                    description: "Only \(Int((poseCoverage * 100).rounded()))% of sampled frames had enough upper-body joints visible."
                )
            )
        }

        if averageDeviation <= 12 {
            issues.append(
                CompareIssue(
                    type: .passed,
                    title: "Reference match is strong",
                    description: "Your upper-body angles stay close to the reference movement."
                )
            )
        } else {
            issues.append(
                CompareIssue(
                    type: .warning,
                    title: "Upper-body timing or angle differs",
                    description: "Average angle deviation is \(String(format: "%.1f", averageDeviation)) degrees from the reference."
                )
            )
        }

        let averageElbowDifference = pairs.map(\.elbowDeviation).reduce(0, +) / Double(pairs.count)
        if averageElbowDifference > 18 {
            issues.append(
                CompareIssue(
                    type: .warning,
                    title: "Elbow path needs attention",
                    description: "Keep the elbow path closer to the reference through the rep."
                )
            )
        }

        let averageWristDifference = pairs.map(\.wristHeightDeviation).reduce(0, +) / Double(pairs.count)
        if averageWristDifference > 14 {
            issues.append(
                CompareIssue(
                    type: .warning,
                    title: "Wrist height differs",
                    description: "Match the wrist height and range of motion shown in the expert reference."
                )
            )
        }

        if accuracy >= 80 {
            issues.append(
                CompareIssue(
                    type: .passed,
                    title: "Ready for a clean rep",
                    description: "The uploaded video is close enough to use for form comparison."
                )
            )
        }

        return issues
    }

    private struct PoseSample {
        let leftElbowAngle: Double?
        let rightElbowAngle: Double?
        let leftWristHeight: Double?
        let rightWristHeight: Double?
        let leftElbowHeight: Double?
        let rightElbowHeight: Double?
        let movementIntensity: Double?

        init?(points: [JointName: VNRecognizedPoint]) {
            let leftHipConfidence = points[.leftHip]?.confidence ?? 0
            let rightHipConfidence = points[.rightHip]?.confidence ?? 0
            guard leftHipConfidence >= requiredHipConfidence || rightHipConfidence >= requiredHipConfidence else {
                return nil
            }

            let leftShoulder = PoseSample.validPoint(.leftShoulder, points: points)
            let rightShoulder = PoseSample.validPoint(.rightShoulder, points: points)
            let leftElbow = PoseSample.validPoint(.leftElbow, points: points)
            let rightElbow = PoseSample.validPoint(.rightElbow, points: points)
            let leftWrist = PoseSample.validPoint(.leftWrist, points: points)
            let rightWrist = PoseSample.validPoint(.rightWrist, points: points)

            guard leftShoulder != nil || rightShoulder != nil else { return nil }

            let shoulderScale = max(
                distance(leftShoulder, rightShoulder),
                0.12
            )

            leftElbowAngle = angle(shoulder: leftShoulder, elbow: leftElbow, wrist: leftWrist)
            rightElbowAngle = angle(shoulder: rightShoulder, elbow: rightElbow, wrist: rightWrist)
            leftWristHeight = normalizedHeight(point: leftWrist, shoulder: leftShoulder, scale: shoulderScale)
            rightWristHeight = normalizedHeight(point: rightWrist, shoulder: rightShoulder, scale: shoulderScale)
            leftElbowHeight = normalizedHeight(point: leftElbow, shoulder: leftShoulder, scale: shoulderScale)
            rightElbowHeight = normalizedHeight(point: rightElbow, shoulder: rightShoulder, scale: shoulderScale)

            let motionValues = [leftWristHeight, rightWristHeight, leftElbowHeight, rightElbowHeight].compactMap { $0 }
            movementIntensity = motionValues.isEmpty ? nil : motionValues.map(abs).reduce(0, +) / Double(motionValues.count)

            let hasComparisonSignal = [
                leftElbowAngle,
                rightElbowAngle,
                leftWristHeight,
                rightWristHeight,
                leftElbowHeight,
                rightElbowHeight
            ].contains { $0 != nil }

            guard hasComparisonSignal else { return nil }
        }

        private static func validPoint(
            _ joint: JointName,
            points: [JointName: VNRecognizedPoint]
        ) -> CGPoint? {
            guard let point = points[joint], point.confidence >= requiredJointConfidence else {
                return nil
            }
            return point.location
        }
    }

    private struct PoseComparison {
        let deviation: Double
        let elbowDeviation: Double
        let wristHeightDeviation: Double

        init?(reference: PoseSample, user: PoseSample) {
            var weightedDifferences: [(difference: Double, weight: Double)] = []

            PoseComparison.appendAngleDifference(reference.leftElbowAngle, user.leftElbowAngle, weight: 1.2, to: &weightedDifferences)
            PoseComparison.appendAngleDifference(reference.rightElbowAngle, user.rightElbowAngle, weight: 1.2, to: &weightedDifferences)
            PoseComparison.appendHeightDifference(reference.leftWristHeight, user.leftWristHeight, weight: 1.0, to: &weightedDifferences)
            PoseComparison.appendHeightDifference(reference.rightWristHeight, user.rightWristHeight, weight: 1.0, to: &weightedDifferences)
            PoseComparison.appendHeightDifference(reference.leftElbowHeight, user.leftElbowHeight, weight: 0.8, to: &weightedDifferences)
            PoseComparison.appendHeightDifference(reference.rightElbowHeight, user.rightElbowHeight, weight: 0.8, to: &weightedDifferences)

            guard !weightedDifferences.isEmpty else { return nil }

            let totalWeight = weightedDifferences.map(\.weight).reduce(0, +)
            deviation = weightedDifferences.map { $0.difference * $0.weight }.reduce(0, +) / totalWeight

            let elbowValues = [
                PoseComparison.angleDifference(reference.leftElbowAngle, user.leftElbowAngle),
                PoseComparison.angleDifference(reference.rightElbowAngle, user.rightElbowAngle)
            ].compactMap { $0 }
            elbowDeviation = elbowValues.isEmpty ? 0 : elbowValues.reduce(0, +) / Double(elbowValues.count)

            let wristValues = [
                PoseComparison.heightDifference(reference.leftWristHeight, user.leftWristHeight),
                PoseComparison.heightDifference(reference.rightWristHeight, user.rightWristHeight)
            ].compactMap { $0 }
            wristHeightDeviation = wristValues.isEmpty ? 0 : wristValues.reduce(0, +) / Double(wristValues.count)
        }

        private static func appendAngleDifference(
            _ reference: Double?,
            _ user: Double?,
            weight: Double,
            to values: inout [(difference: Double, weight: Double)]
        ) {
            guard let difference = angleDifference(reference, user) else { return }
            values.append((difference, weight))
        }

        private static func appendHeightDifference(
            _ reference: Double?,
            _ user: Double?,
            weight: Double,
            to values: inout [(difference: Double, weight: Double)]
        ) {
            guard let difference = heightDifference(reference, user) else { return }
            values.append((difference, weight))
        }

        private static func angleDifference(_ reference: Double?, _ user: Double?) -> Double? {
            guard let reference, let user else { return nil }
            return abs(reference - user)
        }

        private static func heightDifference(_ reference: Double?, _ user: Double?) -> Double? {
            guard let reference, let user else { return nil }
            return min(abs(reference - user) * 55, 55)
        }
    }

    private static func normalizedHeight(point: CGPoint?, shoulder: CGPoint?, scale: Double) -> Double? {
        guard let point, let shoulder, scale > 0 else { return nil }
        return Double(point.y - shoulder.y) / scale
    }

    private static func angle(shoulder: CGPoint?, elbow: CGPoint?, wrist: CGPoint?) -> Double? {
        guard let shoulder, let elbow, let wrist else { return nil }

        let a = distance(shoulder, elbow)
        let b = distance(elbow, wrist)
        let c = distance(shoulder, wrist)
        guard a > 0, b > 0 else { return nil }

        let rawCosine = (pow(a, 2) + pow(b, 2) - pow(c, 2)) / (2 * a * b)
        let cosine = min(max(rawCosine, -1), 1)
        return acos(cosine) * 180 / .pi
    }

    private static func distance(_ first: CGPoint?, _ second: CGPoint?) -> Double {
        guard let first, let second else { return 0 }
        return hypot(Double(second.x - first.x), Double(second.y - first.y))
    }
}
