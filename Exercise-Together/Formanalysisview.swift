// =====================================================
// FormAnalysisView.swift
// หน้า Form Analysis — วิเคราะห์ฟอร์มแบบ Real-time
// =====================================================

import SwiftUI
import PhotosUI
import AVKit

private let supportedExercises = [
    "Push-Ups",
    "Arm Curls",
    "Shoulder Press",
    "Lateral Raises",
    "Front Raises",
    "Arm Extensions",
    "Upright Rows"
]

private let defaultSupportedExercise = "Push-Ups"

private let upperBodyChecklist = [
    ChecklistItem(title: "Head-to-Waist Framing", status: .pending),
    ChecklistItem(title: "Shoulder Alignment", status: .optimal),
    ChecklistItem(title: "Elbow Tracking", status: .pending),
    ChecklistItem(title: "Wrist Visibility", status: .optimal)
]

struct FormAnalysisView: View {
    // State
    @StateObject private var poseEstimator = PoseEstimator()
    @StateObject private var videoProcessor = VideoProcessor()
    
    @State private var overallScore: Int = 84
    @State private var stabilityScore: Int = 78
    @State private var powerLeakScore: Int = 12
    @State private var isTracking: Bool = false
    @State private var checklist: [ChecklistItem] = upperBodyChecklist
    @State private var selectedExercise: String = defaultSupportedExercise
    
    // Video Processing State
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var selectedVideoURL: URL?
    
    // Summary State
    @State private var showSummary: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {
                    Color.clear.frame(height: 64)

                    // ── Page Header ───────────────────────
                    FormAnalysisHeader(
                        isTracking: isTracking,
                        selectedExercise: $selectedExercise,
                        supportedExercises: supportedExercises,
                        selectedVideoItem: $selectedVideoItem
                    )
                        .padding(.horizontal, 24)

                    // ── Live Camera or Video Viewport ─────
                    CameraViewport(
                        isTracking: $isTracking,
                        poseEstimator: poseEstimator,
                        videoProcessor: videoProcessor,
                        selectedVideoURL: selectedVideoURL
                    )
                    .padding(.horizontal, 24)
                    
                    // ── Oversized Track Button ────────────
                    Button(action: {
                        toggleTracking()
                    }) {
                        Text(isTracking ? "STOP TRACKING" : "START TRACKING")
                            .font(.system(size: 18, weight: .black))
                            .tracking(1.5)
                            .foregroundColor(isTracking ? .red : Color(hex: "#002957"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(isTracking ? Color.red.opacity(0.15) : Color(hex: "#00E5FF"))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(isTracking ? Color.red : Color(hex: "#00E5FF"), lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, 24)

                    // ── Execution Checklist ───────────────
                    ExecutionChecklist(items: checklist)
                        .padding(.horizontal, 24)

                    // ── Score Summary Card ────────────────
                    ScoreSummaryCard(
                        overallScore: poseEstimator.isGoodForm ? overallScore : max(0, overallScore - 20),
                        stabilityScore: stabilityScore,
                        powerLeakScore: powerLeakScore
                    )
                    .padding(.horizontal, 24)

                    Color.clear.frame(height: 32)
                }
            }
            .onAppear {
                applySelectedExercise()
            }
            .onChange(of: selectedExercise) { _, _ in
                applySelectedExercise()
            }
            .onChange(of: selectedVideoItem) { _, newItem in
                Task {
                    if let videoFile = try? await newItem?.loadTransferable(type: VideoTransferable.self) {
                        DispatchQueue.main.async {
                            self.selectedVideoURL = videoFile.url
                            self.videoProcessor.loadVideo(url: videoFile.url, poseEstimator: self.poseEstimator)
                            self.isTracking = false
                            self.applySelectedExercise()
                        }
                    }
                }
            }
            .sheet(isPresented: $showSummary) {
                PostWorkoutSummaryView(
                    totalReps: poseEstimator.exerciseCount,
                    formScore: poseEstimator.isGoodForm ? 0.95 : 0.60,
                    caloriesBurned: poseEstimator.caloriesBurned,
                    onReset: {
                        applySelectedExercise()
                        isTracking = false
                        selectedVideoURL = nil
                        selectedVideoItem = nil
                        videoProcessor.stop()
                    }
                )
                .presentationDetents([.medium])
            }

            TopAppBar()
        }
    }

    private func applySelectedExercise() {
        let normalizedExercise = supportedExercises.contains(selectedExercise)
            ? selectedExercise
            : defaultSupportedExercise

        if selectedExercise != normalizedExercise {
            selectedExercise = normalizedExercise
        }

        poseEstimator.updateCurrentExercise(to: normalizedExercise)
    }
    
    private func toggleTracking() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if isTracking {
                // STOP recording
                isTracking = false
                poseEstimator.stopCount()
                if selectedVideoURL != nil { videoProcessor.stop() }
                
                // Show summary
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showSummary = true
                }
            } else {
                // START recording
                isTracking = true
                poseEstimator.startCount()
                if selectedVideoURL != nil {
                    videoProcessor.play()
                }
            }
        }
    }
}

// MARK: - Page Header

private struct FormAnalysisHeader: View {
    let isTracking: Bool
    @Binding var selectedExercise: String
    let supportedExercises: [String]
    @Binding var selectedVideoItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("Form Analysis")
                    .font(.system(size: 36, weight: .black))
                    .tracking(-1)
                    .foregroundColor(.onSurface)

                Spacer()

                // Photos Picker
                PhotosPicker(selection: $selectedVideoItem, matching: .videos) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 18))
                        .foregroundColor(.onSurface)
                        .padding(10)
                        .background(Color.containerHigh)
                        .clipShape(Circle())
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 16) {
                    Menu {
                        ForEach(supportedExercises, id: \.self) { exercise in
                            Button {
                                selectedExercise = exercise
                            } label: {
                                if exercise == selectedExercise {
                                    Label(exercise, systemImage: "checkmark")
                                } else {
                                    Text(exercise)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            MetadataLabel(text: selectedExercise, color: .onSurfaceVariant)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.outline)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.containerHigh)
                        .clipShape(Capsule())
                    }

                    HStack(spacing: 6) {
                        Circle()
                            .fill(isTracking ? Color.tertiary : Color.outline)
                            .frame(width: 6, height: 6)
                        MetadataLabel(
                            text: isTracking ? "Live" : "Standby",
                            color: isTracking ? .tertiary : .outline
                        )
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.containerHigh)
                    .clipShape(Capsule())
                }

                HStack(spacing: 6) {
                    Image(systemName: "person.crop.rectangle")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.outline)
                    MetadataLabel(text: "Position your body from head to waist within the frame", color: .outline)
                }
            }
        }
    }
}

// MARK: - Camera Viewport

private struct CameraViewport: View {
    @Binding var isTracking: Bool
    @ObservedObject var poseEstimator: PoseEstimator
    @ObservedObject var videoProcessor: VideoProcessor
    var selectedVideoURL: URL?

    var body: some View {
        ZStack {
            // Camera / Video feed placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.containerLowest)
                .frame(height: 320)
                .overlay(
                    Group {
                        if selectedVideoURL != nil {
                            VideoPlayer(player: videoProcessor.player)
                                .disabled(true) // Just display
                        } else if isTracking {
                            CameraViewWrapper(poseEstimator: poseEstimator)
                        } else {
                            SkeletonOverlay()
                        }
                    }
                )

            // Dynamic Form Feedback overlay (Top Right)
            VStack {
                HStack {
                    Spacer()
                    if isTracking {
                        Text(poseEstimator.isGoodForm ? "PERFECT FORM" : "ADJUST POSTURE")
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(poseEstimator.isGoodForm ? .black : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(poseEstimator.isGoodForm ? Color(hex: "#00E5FF") : .red)
                            .clipShape(Capsule())
                            .padding(12)
                    }
                }
                Spacer()
            }

            // Rep Counter Overlay (Center)
            if isTracking || poseEstimator.exerciseCount > 0 {
                VStack {
                    Spacer()
                    Text("\(poseEstimator.exerciseCount)")
                        .font(.system(size: 80, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 5)
                    Text("REPS")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(2)
                        .shadow(color: .black, radius: 4)
                    Spacer()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// ── Simple skeleton/joint overlay ─────────────────────

private struct SkeletonOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            // Joint positions (% of frame)
            let joints: [(x: CGFloat, y: CGFloat)] = [
                (0.50, 0.12), (0.50, 0.28), (0.38, 0.30),
                (0.62, 0.30), (0.50, 0.46), (0.40, 0.60),
                (0.60, 0.60), (0.40, 0.78), (0.60, 0.78)
            ]

            Path { path in
                path.move(to: CGPoint(x: w * 0.50, y: h * 0.12))
                path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.46))
                path.move(to: CGPoint(x: w * 0.50, y: h * 0.46))
                path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.60))
                path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.78))
                path.move(to: CGPoint(x: w * 0.50, y: h * 0.46))
                path.addLine(to: CGPoint(x: w * 0.60, y: h * 0.60))
                path.addLine(to: CGPoint(x: w * 0.60, y: h * 0.78))
                path.move(to: CGPoint(x: w * 0.38, y: h * 0.30))
                path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.30))
            }
            .stroke(Color.primary.opacity(0.4), lineWidth: 1.5)

            ForEach(joints.indices, id: \.self) { i in
                Circle()
                    .fill(Color.primary.opacity(0.8))
                    .frame(width: 8, height: 8)
                    .position(x: w * joints[i].x, y: h * joints[i].y)
            }
        }
    }
}

// MARK: - Execution Checklist

private struct ExecutionChecklist: View {
    let items: [ChecklistItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            MetadataLabel(text: "Execution Checklist", color: .outline)
                .tracking(2.4)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    ChecklistRow(item: item)
                    if index < items.count - 1 {
                        Color.outlineVariant.opacity(0.15)
                            .frame(height: 1)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color.containerLow)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct ChecklistRow: View {
    let item: ChecklistItem

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: item.status.icon)
                .font(.system(size: 18, weight: .light))
                .foregroundColor(item.status.color)
                .frame(width: 24)

            Text(item.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.onSurface)

            Spacer()

            MetadataLabel(text: item.status.label, color: item.status.color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

// MARK: - Score Summary Card

private struct ScoreSummaryCard: View {
    let overallScore: Int
    let stabilityScore: Int
    let powerLeakScore: Int

    var body: some View {
        VStack(spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(overallScore)")
                            .font(.system(size: 56, weight: .black))
                            .tracking(-2)
                            .foregroundColor(.onSurface)
                        Text("%")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    MetadataLabel(text: "Overall Score")
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 20) {
                    SmallStat(label: "Stability",   value: "\(stabilityScore)%", color: .onSurface)
                    SmallStat(label: "Power Leak",  value: "\(powerLeakScore)%", color: .tertiary)
                }
            }
            .padding(24)
            .background(Color.containerHighest.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.outlineVariant.opacity(0.15), lineWidth: 1)
            )

            PrimaryButton(title: "Generate Drill Plan") {
            }
        }
    }
}

private struct SmallStat: View {
    let label: String
    let value: String
    var color: Color = .onSurface

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            MetadataLabel(text: label, color: .outline)
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(color)
        }
    }
}

#Preview {
    FormAnalysisView()
        .preferredColorScheme(.dark)
}
