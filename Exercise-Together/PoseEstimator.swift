import Foundation
import AVFoundation
import Vision
import Combine

class PoseEstimator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, ObservableObject {
    private typealias JointName = VNHumanBodyPoseObservation.JointName

    let sequenceHandler = VNSequenceRequestHandler()
    @Published var bodyParts = [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]()
    @Published var currentExercise: String = ""
    @Published var isGoodForm = true
    @Published var isFrameValid = true
    @Published var isProperlyFramed = true
    @Published var exerciseCount = 0

    private var countAble = true
    private let requiredJointConfidence: Float = 0.6
    private let requiredHipConfidence: Float = 0.5
    private let disabledLowerBodyExercises: Set<String> = [
        "Squats",
        "Lunges",
        "Jumping Jacks",
        "Leg Lifts",
        "Knee Extensions"
    ]

    let caloriesPerPushUp: Double = 0.29
    let caloriesPerSitUp: Double = 0.15
    let caloriesPerBurpee: Double = 0.5
    let caloriesPerPlankToPushUp: Double = 0.35
    let caloriesPerHighKnee: Double = 0.24
    let caloriesPerRussianTwist: Double = 0.25
    let caloriesPerLegRaise: Double = 0.2

    var caloriesBurned: Double = 0.0

    var wasInStartPosition = false
    var subscriptions = Set<AnyCancellable>()

    override init() {
        super.init()
        $bodyParts
            .dropFirst()
            .sink { [weak self] bodyParts in self?.analyzeCurrentExercise(bodyParts: bodyParts) }
            .store(in: &subscriptions)
    }

    func processFrame(_ sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation = .right) {
        let humanBodyRequest = VNDetectHumanBodyPoseRequest(completionHandler: detectedBodyPose)
        do {
            try sequenceHandler.perform([humanBodyRequest], on: sampleBuffer, orientation: orientation)
        } catch {
            print(error.localizedDescription)
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processFrame(sampleBuffer)
    }


    func detectedBodyPose(request: VNRequest, error: Error?) {
        guard let bodyPoseResults = request.results as? [VNHumanBodyPoseObservation],
              let bodyParts = try? bodyPoseResults.first?.recognizedPoints(.all) else { return }
        DispatchQueue.main.async {
            self.bodyParts = bodyParts
            self.analyzeCurrentExercise(bodyParts: self.bodyParts)
        }
    }

    var exerciseAnalysisMapping: [String: ([VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) -> Void] {
        [
            "Push-Ups": analyzePushUps,
            "Lateral Raises": analyzeLateralRaises,
            "Front Raises": analyzeFrontRaises,
            "Arm Curls": analyzeArmCurls,
            "Shoulder Press":analyzeShoulderPress,
            "Arm Extensions":analyzeArmExtensions,
            "Upright Rows":analyzeUprightRows,
        ]
    }

    func analyzeCurrentExercise(bodyParts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        if disabledLowerBodyExercises.contains(currentExercise) {
            markFrameInvalid(properlyFramed: hasValidHalfBodyFrame(bodyParts: bodyParts))
            print("\(currentExercise) requires lower-body tracking and is disabled in half-body mode")
            return
        }

        if let analysisFunction = exerciseAnalysisMapping[currentExercise] {
            analysisFunction(bodyParts)
        } else if !currentExercise.isEmpty {
            print("Exercise not recognized")
        }
    }


    private func distanceBetween(p1: CGPoint, p2: CGPoint) -> CGFloat {
        return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
    }

    private func calculateAngle(p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGFloat {
        let a = distanceBetween(p1: p1, p2: p2)
        let b = distanceBetween(p1: p2, p2: p3)
        let c = distanceBetween(p1: p1, p2: p3)
        guard a > 0, b > 0 else { return 0 }

        let rawCosine = (pow(a, 2) + pow(b, 2) - pow(c, 2)) / (2 * a * b)
        let cosine = min(max(rawCosine, -1), 1)
        let angle = acos(cosine)
        return angle * (180 / .pi)
    }

    private func hasValidHalfBodyFrame(bodyParts: [JointName: VNRecognizedPoint]) -> Bool {
        let leftHipConfidence = bodyParts[.leftHip]?.confidence ?? 0
        let rightHipConfidence = bodyParts[.rightHip]?.confidence ?? 0

        return leftHipConfidence >= requiredHipConfidence || rightHipConfidence >= requiredHipConfidence
    }

    private func markFrameInvalid(properlyFramed: Bool) {
        isFrameValid = false
        isProperlyFramed = properlyFramed
        isGoodForm = false
    }

    private func markFrameValid() {
        isFrameValid = true
        isProperlyFramed = true
    }

    private func validatedUpperBodyPoints(
        bodyParts: [JointName: VNRecognizedPoint],
        required joints: [JointName]
    ) -> [JointName: VNRecognizedPoint]? {
        guard hasValidHalfBodyFrame(bodyParts: bodyParts) else {
            markFrameInvalid(properlyFramed: false)
            return nil
        }

        var validatedPoints = [JointName: VNRecognizedPoint]()
        for joint in joints {
            guard let point = bodyParts[joint], point.confidence >= requiredJointConfidence else {
                markFrameInvalid(properlyFramed: true)
                return nil
            }
            validatedPoints[joint] = point
        }

        markFrameValid()
        return validatedPoints
    }

    private func validArmPoints(
        bodyParts: [JointName: VNRecognizedPoint],
        shoulder: JointName,
        elbow: JointName,
        wrist: JointName
    ) -> (shoulder: VNRecognizedPoint, elbow: VNRecognizedPoint, wrist: VNRecognizedPoint)? {
        guard let points = validatedUpperBodyPoints(
            bodyParts: bodyParts,
            required: [shoulder, elbow, wrist]
        ),
              let shoulderPoint = points[shoulder],
              let elbowPoint = points[elbow],
              let wristPoint = points[wrist] else {
            return nil
        }

        return (shoulderPoint, elbowPoint, wristPoint)
    }

    private func validArmAngle(
        bodyParts: [JointName: VNRecognizedPoint],
        shoulder: JointName,
        elbow: JointName,
        wrist: JointName
    ) -> CGFloat? {
        guard let armPoints = validArmPoints(
            bodyParts: bodyParts,
            shoulder: shoulder,
            elbow: elbow,
            wrist: wrist
        ) else {
            return nil
        }

        return calculateAngle(
            p1: armPoints.shoulder.location,
            p2: armPoints.elbow.location,
            p3: armPoints.wrist.location
        )
    }



    private func analyzePushUps(bodyParts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        guard let points = validatedUpperBodyPoints(
            bodyParts: bodyParts,
            required: [.rightShoulder, .rightElbow, .rightWrist, .leftShoulder, .leftElbow, .leftWrist]
        ),
              let rightShoulder = points[.rightShoulder],
              let rightElbow = points[.rightElbow],
              let rightWrist = points[.rightWrist],
              let leftShoulder = points[.leftShoulder],
              let leftElbow = points[.leftElbow],
              let leftWrist = points[.leftWrist] else {
            return
        }

        let rightAngle = calculateAngle(p1: rightShoulder.location, p2: rightElbow.location, p3: rightWrist.location)
        let leftAngle = calculateAngle(p1: leftShoulder.location, p2: leftElbow.location, p3: leftWrist.location)

        if (rightAngle < 160 && rightAngle > 20) || (leftAngle < 160 && leftAngle > 20) {
            if !wasInStartPosition {
                wasInStartPosition = true
            }
        } else if (rightAngle >= 160 || leftAngle >= 160), wasInStartPosition {
            exerciseCount += countAble ? 1 : 0
            caloriesBurned += caloriesPerPushUp
            wasInStartPosition = false
        }
        isGoodForm = (CGFloat(20)...CGFloat(180)).contains(rightAngle) || (CGFloat(20)...CGFloat(180)).contains(leftAngle)
    }

    private var wasInCurlPosition = false

    private func analyzeArmCurls(bodyParts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        let caloriesPerArmCurl = 0.5

        guard let angle = validArmAngle(
            bodyParts: bodyParts,
            shoulder: .rightShoulder,
            elbow: .rightElbow,
            wrist: .rightWrist
        ) else {
            return
        }

        if angle > 45 && angle <= 90 && !wasInCurlPosition {
            wasInCurlPosition = true
            wasInStartPosition = false
        }

        if angle > 90 && angle <= 160 && wasInCurlPosition {
            wasInCurlPosition = false
            wasInStartPosition = true

            if countAble {
                exerciseCount += 1
                caloriesBurned += caloriesPerArmCurl
                print("Arm Curl Completed: Count: \(exerciseCount), Calories Burned: \(caloriesBurned)")
            }
        }
        isGoodForm = (CGFloat(45)...CGFloat(160)).contains(angle)
    }


    private var wasFullyExtended = false

    private func analyzeShoulderPress(bodyParts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        let caloriesPerShoulderPress = 0.8

        guard let angle = validArmAngle(
            bodyParts: bodyParts,
            shoulder: .leftShoulder,
            elbow: .leftElbow,
            wrist: .leftWrist
        ) else {
            return
        }

        if angle > 160 && !wasFullyExtended {
            wasFullyExtended = true
        } else if angle <= 90 && wasFullyExtended {
            wasFullyExtended = false

            if countAble {
                exerciseCount += 1
                caloriesBurned += caloriesPerShoulderPress
                print("Shoulder Press Full Cycle Completed: Count: \(exerciseCount), Calories Burned: \(caloriesBurned)")
            }
        }
        isGoodForm = angle > 60
    }




    private var wasFullyContracted = false

    private func analyzeArmExtensions(bodyParts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        let caloriesPerArmExtension = 0.4

        guard let angle = validArmAngle(
            bodyParts: bodyParts,
            shoulder: .rightShoulder,
            elbow: .rightElbow,
            wrist: .rightWrist
        ) else {
            return
        }

        if angle >= 130 && !wasFullyExtended {
            wasFullyExtended = true
            wasFullyContracted = false
        } else if angle < 80 && wasFullyExtended && !wasFullyContracted {
            wasFullyContracted = true
        }

        if wasFullyExtended && wasFullyContracted {
            exerciseCount += countAble ? 1 : 0
            caloriesBurned += caloriesPerArmExtension
            wasFullyExtended = false
            wasFullyContracted = false
            print("Arm Extension Cycle Completed: Angle is \(angle) degrees, Count: \(exerciseCount), Calories Burned: \(caloriesBurned)")
        }
        isGoodForm = (CGFloat(40)...CGFloat(180)).contains(angle)
    }


    private func analyzeLateralRaises(bodyParts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        let caloriesPerLateralRaise = 0.5
        guard let points = validatedUpperBodyPoints(
            bodyParts: bodyParts,
            required: [.leftShoulder, .leftElbow, .leftWrist, .rightShoulder, .rightElbow, .rightWrist]
        ),
              let leftShoulder = points[.leftShoulder],
              let leftWrist = points[.leftWrist],
              let rightShoulder = points[.rightShoulder],
              let rightWrist = points[.rightWrist] else {
            return
        }

        let leftArmRaised = leftWrist.location.y < leftShoulder.location.y
        let rightArmRaised = rightWrist.location.y < rightShoulder.location.y

        if leftArmRaised && rightArmRaised && !wasInStartPosition {
            wasInStartPosition = true
        } else if (!leftArmRaised || !rightArmRaised) && wasInStartPosition {
            exerciseCount += 1
            caloriesBurned += caloriesPerLateralRaise
            wasInStartPosition = false
            print("Lateral Raise Completed: Count: \(exerciseCount), Calories Burned: \(caloriesBurned)")
        }
        isGoodForm = leftArmRaised == rightArmRaised
    }



    private func analyzeFrontRaises(bodyParts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        let caloriesPerFrontRaise = 0.5
        guard let points = validatedUpperBodyPoints(
            bodyParts: bodyParts,
            required: [.leftShoulder, .leftElbow, .leftWrist, .rightShoulder, .rightElbow, .rightWrist]
        ),
              let leftShoulder = points[.leftShoulder],
              let leftElbow = points[.leftElbow],
              let leftWrist = points[.leftWrist],
              let rightShoulder = points[.rightShoulder],
              let rightElbow = points[.rightElbow],
              let rightWrist = points[.rightWrist] else {
            return
        }

        let leftAngle = calculateAngle(p1: leftShoulder.location, p2: leftElbow.location, p3: leftWrist.location)
        let rightAngle = calculateAngle(p1: rightShoulder.location, p2: rightElbow.location, p3: rightWrist.location)

        if (leftAngle > 70 && leftAngle < 110) && (rightAngle > 70 && rightAngle < 110) && !wasInStartPosition {
            wasInStartPosition = true
        } else if ((leftAngle <= 70 || leftAngle >= 110) || (rightAngle <= 70 || rightAngle >= 110)) && wasInStartPosition {
            exerciseCount += 1
            caloriesBurned += caloriesPerFrontRaise
            wasInStartPosition = false
            print("Front Raise Completed: Count: \(exerciseCount), Calories Burned: \(caloriesBurned)")
        }
        isGoodForm = abs(leftAngle - rightAngle) < 25
    }




    private func analyzeUprightRows(bodyParts: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]) {
        let caloriesPerUprightRow = 0.6

        guard let points = validatedUpperBodyPoints(
            bodyParts: bodyParts,
            required: [.leftShoulder, .leftElbow, .rightShoulder, .rightElbow]
        ),
              let leftShoulder = points[.leftShoulder],
              let leftElbow = points[.leftElbow],
              let rightShoulder = points[.rightShoulder],
              let rightElbow = points[.rightElbow] else {
            return
        }

        let leftElbowHigher = leftElbow.location.y < leftShoulder.location.y
        let rightElbowHigher = rightElbow.location.y < rightShoulder.location.y

        if leftElbowHigher && rightElbowHigher && !wasInStartPosition {
            wasInStartPosition = true
        } else if (!leftElbowHigher || !rightElbowHigher) && wasInStartPosition {
            exerciseCount += 1
            caloriesBurned += caloriesPerUprightRow
            wasInStartPosition = false
            print("Upright Row Completed: Count: \(exerciseCount), Calories Burned: \(caloriesBurned)")
        }
        isGoodForm = leftElbowHigher == rightElbowHigher
    }




}
extension PoseEstimator {
    func updateCurrentExercise(to newExercise: String) {
        DispatchQueue.main.async {
            self.currentExercise = newExercise
            self.exerciseCount = 0
            self.wasInStartPosition = false
            self.isGoodForm = true
            self.isFrameValid = true
            self.isProperlyFramed = true
        }
    }

    func stopCount(){
        countAble = false
    }

    func startCount(){
        countAble = true
    }
}
