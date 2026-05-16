// =====================================================
// FormAnalysisView.swift
// หน้า Form Analysis — Real-time pose tracking
// Now saves CDFormAnalysisResult to CoreData on stop
// =====================================================

import SwiftUI
import PhotosUI
import AVKit
import CoreData
import Vision

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

private enum FocusJoint: CaseIterable, Hashable {
    case nose
    case torso
    case leftShoulder
    case rightShoulder
    case leftElbow
    case rightElbow
    case leftWrist
    case rightWrist

    var position: CGPoint {
        switch self {
        case .nose: return CGPoint(x: 0.50, y: 0.12)
        case .torso: return CGPoint(x: 0.50, y: 0.46)
        case .leftShoulder: return CGPoint(x: 0.38, y: 0.30)
        case .rightShoulder: return CGPoint(x: 0.62, y: 0.30)
        case .leftElbow: return CGPoint(x: 0.40, y: 0.60)
        case .rightElbow: return CGPoint(x: 0.60, y: 0.60)
        case .leftWrist: return CGPoint(x: 0.40, y: 0.78)
        case .rightWrist: return CGPoint(x: 0.60, y: 0.78)
        }
    }

    var visionJoint: VNHumanBodyPoseObservation.JointName? {
        switch self {
        case .nose: return .nose
        case .torso: return nil
        case .leftShoulder: return .leftShoulder
        case .rightShoulder: return .rightShoulder
        case .leftElbow: return .leftElbow
        case .rightElbow: return .rightElbow
        case .leftWrist: return .leftWrist
        case .rightWrist: return .rightWrist
        }
    }
}

private struct ExerciseFocusProfile {
    let exerciseName: String
    let bodyFocus: String
    let frameHint: String
    let trackingCue: String
    let checklist: [ChecklistItem]
    let highlightedJoints: Set<FocusJoint>

    var highlightedVisionJoints: Set<VNHumanBodyPoseObservation.JointName> {
        Set(highlightedJoints.compactMap(\.visionJoint))
    }

    static func profile(for exercise: String) -> ExerciseFocusProfile {
        switch exercise {
        case "Arm Curls":
            return ExerciseFocusProfile(
                exerciseName: exercise,
                bodyFocus: "Right biceps and elbow path",
                frameHint: "Keep your working shoulder, elbow, wrist, and waist visible",
                trackingCue: "TRACKING CURL PATH",
                checklist: [
                    ChecklistItem(title: "Right Arm Fully Visible", status: .pending),
                    ChecklistItem(title: "Elbow Stays Under Shoulder", status: .optimal),
                    ChecklistItem(title: "Wrist Tracks Toward Shoulder", status: .pending),
                    ChecklistItem(title: "Waist Remains In Frame", status: .optimal)
                ],
                highlightedJoints: [.rightShoulder, .rightElbow, .rightWrist, .torso]
            )
        case "Shoulder Press":
            return ExerciseFocusProfile(
                exerciseName: exercise,
                bodyFocus: "Pressing shoulder and elbow lockout",
                frameHint: "Keep your pressing arm, shoulder line, and waist in frame",
                trackingCue: "TRACKING PRESS LINE",
                checklist: [
                    ChecklistItem(title: "Pressing Arm Visible", status: .pending),
                    ChecklistItem(title: "Shoulder Starts Stable", status: .optimal),
                    ChecklistItem(title: "Elbow Extends Overhead", status: .pending),
                    ChecklistItem(title: "Waist Remains In Frame", status: .optimal)
                ],
                highlightedJoints: [.leftShoulder, .leftElbow, .leftWrist, .torso]
            )
        case "Lateral Raises":
            return ExerciseFocusProfile(
                exerciseName: exercise,
                bodyFocus: "Both shoulders and wrist height",
                frameHint: "Center both shoulders, elbows, wrists, and waist",
                trackingCue: "TRACKING SIDE RAISE",
                checklist: [
                    ChecklistItem(title: "Both Shoulders Visible", status: .optimal),
                    ChecklistItem(title: "Both Wrists Visible", status: .pending),
                    ChecklistItem(title: "Arms Rise Evenly", status: .pending),
                    ChecklistItem(title: "Waist Remains In Frame", status: .optimal)
                ],
                highlightedJoints: [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist, .torso]
            )
        case "Front Raises":
            return ExerciseFocusProfile(
                exerciseName: exercise,
                bodyFocus: "Both arms and shoulder angle",
                frameHint: "Keep both shoulders, elbows, wrists, and waist visible",
                trackingCue: "TRACKING FRONT RAISE",
                checklist: [
                    ChecklistItem(title: "Both Arms Fully Visible", status: .pending),
                    ChecklistItem(title: "Shoulders Stay Level", status: .optimal),
                    ChecklistItem(title: "Elbows Stay Soft", status: .pending),
                    ChecklistItem(title: "Waist Remains In Frame", status: .optimal)
                ],
                highlightedJoints: [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist, .torso]
            )
        case "Arm Extensions":
            return ExerciseFocusProfile(
                exerciseName: exercise,
                bodyFocus: "Right triceps and elbow extension",
                frameHint: "Keep your working shoulder, elbow, wrist, and waist visible",
                trackingCue: "TRACKING ELBOW EXTENSION",
                checklist: [
                    ChecklistItem(title: "Right Arm Fully Visible", status: .pending),
                    ChecklistItem(title: "Upper Arm Stays Stable", status: .optimal),
                    ChecklistItem(title: "Elbow Reaches Extension", status: .pending),
                    ChecklistItem(title: "Waist Remains In Frame", status: .optimal)
                ],
                highlightedJoints: [.rightShoulder, .rightElbow, .rightWrist, .torso]
            )
        case "Upright Rows":
            return ExerciseFocusProfile(
                exerciseName: exercise,
                bodyFocus: "Both elbows rising above shoulders",
                frameHint: "Keep shoulders, elbows, and waist centered",
                trackingCue: "TRACKING ELBOW HEIGHT",
                checklist: [
                    ChecklistItem(title: "Both Shoulders Visible", status: .optimal),
                    ChecklistItem(title: "Both Elbows Visible", status: .pending),
                    ChecklistItem(title: "Elbows Rise Evenly", status: .pending),
                    ChecklistItem(title: "Waist Remains In Frame", status: .optimal)
                ],
                highlightedJoints: [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .torso]
            )
        default:
            return ExerciseFocusProfile(
                exerciseName: defaultSupportedExercise,
                bodyFocus: "Chest, shoulders, elbows, and wrists",
                frameHint: "Position your body from head to waist within the frame",
                trackingCue: "TRACKING PUSH-UP FORM",
                checklist: [
                    ChecklistItem(title: "Head-to-Waist Framing", status: .pending),
                    ChecklistItem(title: "Both Shoulders Visible", status: .optimal),
                    ChecklistItem(title: "Both Elbows Visible", status: .pending),
                    ChecklistItem(title: "Both Wrists Visible", status: .optimal)
                ],
                highlightedJoints: [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist, .torso]
            )
        }
    }
}

private struct LibraryExerciseProfile {
    let name: String
    let category: String
    let primaryMuscle: String
    let level: String
    let imageName: String

    static func profile(for exercise: String) -> LibraryExerciseProfile {
        switch exercise {
        case "Arm Curls":
            return LibraryExerciseProfile(
                name: "Biceps Curl",
                category: "Isolations",
                primaryMuscle: "Biceps",
                level: "Beginner",
                imageName: "biceps-curl"
            )
        case "Shoulder Press":
            return LibraryExerciseProfile(
                name: "Shoulder Press",
                category: "Isolations",
                primaryMuscle: "Shoulders",
                level: "Intermediate",
                imageName: "shoulder-press"
            )
        case "Lateral Raises":
            return LibraryExerciseProfile(
                name: "Lateral Raise",
                category: "Isolations",
                primaryMuscle: "Shoulders",
                level: "Beginner",
                imageName: "lateral-raise"
            )
        case "Front Raises":
            return LibraryExerciseProfile(
                name: "Front Raise",
                category: "Isolations",
                primaryMuscle: "Shoulders",
                level: "Beginner",
                imageName: "front-raise"
            )
        case "Arm Extensions":
            return LibraryExerciseProfile(
                name: "Triceps Extension",
                category: "Isolations",
                primaryMuscle: "Triceps",
                level: "Intermediate",
                imageName: "triceps-extension"
            )
        case "Upright Rows":
            return LibraryExerciseProfile(
                name: "Upright Rows",
                category: "Compounds",
                primaryMuscle: "Back",
                level: "Intermediate",
                imageName: "incline-row"
            )
        default:
            return LibraryExerciseProfile(
                name: "Push-Ups",
                category: "Compounds",
                primaryMuscle: "Chest",
                level: "Beginner",
                imageName: "push-ups"
            )
        }
    }
}

struct FormAnalysisView: View {

    private let initialExercise: String

    // MARK: - Core Data

    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Pose / Video State

    @StateObject private var poseEstimator  = PoseEstimator()
    @StateObject private var videoProcessor = VideoProcessor()
    @StateObject private var recordingManager = CameraRecordingManager()

    @State private var isTracking:     Bool = false
    @State private var trackingStartedAt: Date?
    @State private var selectedExercise: String   = defaultSupportedExercise

    // Video
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var selectedVideoURL:  URL?

    // Summary sheet
    @State private var showSummary:    Bool = false
    @State private var savedResultID:  UUID?
    
    // Settings
    @State private var showSettings: Bool = false

    init(initialExercise: String = defaultSupportedExercise) {
        let normalizedExercise = supportedExercises.contains(initialExercise)
            ? initialExercise : defaultSupportedExercise
        self.initialExercise = normalizedExercise
        _selectedExercise = State(initialValue: normalizedExercise)
    }

    private var focusProfile: ExerciseFocusProfile {
        ExerciseFocusProfile.profile(for: selectedExercise)
    }

    private var hasAnalysisSignal: Bool {
        !poseEstimator.bodyParts.isEmpty && (isTracking || trackingStartedAt != nil || poseEstimator.exerciseCount > 0)
    }

    private var currentOverallScore: Int {
        guard hasAnalysisSignal else { return 0 }
        guard poseEstimator.isFrameValid && poseEstimator.isProperlyFramed else { return 0 }
        return poseEstimator.isGoodForm ? 95 : 60
    }

    private var currentStabilityScore: Int {
        guard hasAnalysisSignal else { return 0 }
        return poseEstimator.isGoodForm ? 90 : 55
    }

    private var currentPowerLeakScore: Int {
        guard hasAnalysisSignal else { return 0 }
        return poseEstimator.isGoodForm ? 8 : 30
    }

    private var currentFormScore: Double {
        Double(currentOverallScore) / 100.0
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.surface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        Color.clear.frame(height: 104)

                        FormAnalysisHeader(
                            isTracking: isTracking,
                            focusProfile: focusProfile,
                            selectedExercise: $selectedExercise,
                            supportedExercises: supportedExercises,
                            selectedVideoItem: $selectedVideoItem
                        )
                        .padding(.horizontal, 24)

                        CameraViewport(
                            isTracking: $isTracking,
                            poseEstimator: poseEstimator,
                            videoProcessor: videoProcessor,
                            recordingManager: recordingManager,
                            selectedVideoURL: selectedVideoURL,
                            focusProfile: focusProfile
                        )
                        .padding(.horizontal, 24)

                        // Track Button
                        Button { toggleTracking() } label: {
                            Text(isTracking ? "STOP TRACKING" : "START TRACKING")
                                .font(.system(size: 18, weight: .black))
                                .tracking(1.5)
                                .foregroundColor(isTracking ? .red : Color(hex: "#002957"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(isTracking ? Color.red.opacity(0.15) : Color(hex: "#00E5FF"))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(isTracking ? Color.red : Color(hex: "#00E5FF"), lineWidth: 2))
                        }
                        .padding(.horizontal, 24)

                        ExecutionChecklist(items: focusProfile.checklist)
                            .padding(.horizontal, 24)

                        ScoreSummaryCard(
                            selectedExercise: selectedExercise,
                            overallScore: currentOverallScore,
                            stabilityScore: currentStabilityScore,
                            powerLeakScore: currentPowerLeakScore
                        )
                        .padding(.horizontal, 24)

                        Color.clear.frame(height: 132)
                    }
                }

                TopAppBar(trailingIcon: "gearshape") {
                    showSettings = true
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { syncInitialExercise() }
            .onChange(of: initialExercise) { _, _ in syncInitialExercise() }
            .onChange(of: selectedExercise) { _, _ in applySelectedExercise() }
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
                    formScore: currentFormScore,
                    caloriesBurned: poseEstimator.caloriesBurned,
                    onReset: {
                        applySelectedExercise()
                        isTracking      = false
                        trackingStartedAt = nil
                        selectedVideoURL  = nil
                        selectedVideoItem = nil
                        recordingManager.saveMessage = nil
                        videoProcessor.stop()
                    }
                )
                .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Helpers

    private func applySelectedExercise() {
        let normalized = supportedExercises.contains(selectedExercise)
            ? selectedExercise : defaultSupportedExercise
        if selectedExercise != normalized { selectedExercise = normalized }
        poseEstimator.updateCurrentExercise(to: normalized)
    }

    private func syncInitialExercise() {
        let normalized = supportedExercises.contains(initialExercise)
            ? initialExercise : defaultSupportedExercise
        if selectedExercise != normalized {
            selectedExercise = normalized
        }
        poseEstimator.updateCurrentExercise(to: normalized)
    }

    private func toggleTracking() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if isTracking {
                isTracking = false
                poseEstimator.stopCount()
                if selectedVideoURL != nil {
                    videoProcessor.stop()
                } else {
                    recordingManager.stopRecording()
                }

                // ── Save result to CoreData ──────────────
                saveAnalysisResult()
                trackingStartedAt = nil

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showSummary = true
                }
            } else {
                isTracking = true
                trackingStartedAt = Date()
                poseEstimator.startCount()
                if selectedVideoURL != nil {
                    videoProcessor.play()
                } else {
                    recordingManager.startRecording()
                }
            }
        }
    }

    // MARK: - CoreData Save

    private func saveAnalysisResult() {
        let libraryExercise = savedLibraryExercise(for: selectedExercise)

        let result = CDFormAnalysisResult(context: viewContext)
        result.id              = UUID()
        result.date            = Date()
        result.totalReps       = Int32(poseEstimator.exerciseCount)
        result.caloriesBurned  = poseEstimator.caloriesBurned
        result.formScore       = currentFormScore
        result.overallScore    = Double(currentOverallScore)
        result.stabilityScore  = Double(currentStabilityScore) / 100.0
        result.powerLeakScore  = Double(currentPowerLeakScore) / 100.0
        result.exercise        = libraryExercise

        // Also create a linked WorkoutSession
        let session        = CDWorkoutSession(context: viewContext)
        session.id         = UUID()
        session.name       = libraryExercise.name ?? selectedExercise
        session.date       = Date()
        session.duration   = trackedDurationMinutes
        session.volumeLbs  = 0
        session.icon       = "figure.strengthtraining.traditional"
        result.session     = session

        do {
            try viewContext.save()
            savedResultID = result.id
            print("✅ Saved FormAnalysisResult to CoreData")
        } catch {
            print("❌ CoreData save error: \(error.localizedDescription)")
        }
    }

    private func savedLibraryExercise(for exerciseName: String) -> CDExercise {
        let profile = LibraryExerciseProfile.profile(for: exerciseName)
        let exercise = existingLibraryExercise(named: profile.name)
            ?? CDExercise(context: viewContext)

        if exercise.id == nil {
            exercise.id = UUID()
        }

        exercise.name = profile.name
        exercise.category = profile.category
        exercise.primaryMuscle = profile.primaryMuscle
        exercise.level = profile.level
        exercise.imageName = profile.imageName
        exercise.isSaved = true

        return exercise
    }

    private func existingLibraryExercise(named name: String) -> CDExercise? {
        let request: NSFetchRequest<CDExercise> = CDExercise.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1

        return try? viewContext.fetch(request).first
    }

    private var trackedDurationMinutes: Int32 {
        guard let trackingStartedAt else { return 0 }
        let elapsedMinutes = Date().timeIntervalSince(trackingStartedAt) / 60
        return max(1, Int32(elapsedMinutes.rounded(.up)))
    }
}

// MARK: - Page Header

private struct FormAnalysisHeader: View {
    let isTracking: Bool
    let focusProfile: ExerciseFocusProfile
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
                    MetadataLabel(text: focusProfile.frameHint, color: .outline)
                }

                HStack(spacing: 6) {
                    Image(systemName: "scope")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primary)
                    MetadataLabel(text: "Focus: \(focusProfile.bodyFocus)", color: .primary)
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
    @ObservedObject var recordingManager: CameraRecordingManager
    var selectedVideoURL: URL?
    let focusProfile: ExerciseFocusProfile

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.containerLowest)
                .frame(height: 320)
                .overlay(
                    Group {
                        if selectedVideoURL != nil {
                            VideoPlayer(player: videoProcessor.player)
                                .disabled(true)
                        } else if isTracking {
                            CameraViewWrapper(
                                poseEstimator: poseEstimator,
                                recordingManager: recordingManager
                            )
                        } else {
                            SkeletonOverlay(focusProfile: focusProfile)
                        }
                    }
                )

            if shouldShowDetectedSkeleton {
                UpperBodySkeletonOverlay(
                    bodyParts: poseEstimator.bodyParts,
                    highlightedJoints: focusProfile.highlightedVisionJoints,
                    isMirrored: selectedVideoURL == nil,
                    lineColor: skeletonColor,
                    jointColor: skeletonColor
                )
                .frame(height: 320)
                .padding(6)
            }

            VStack {
                HStack {
                    Spacer()
                    if isTracking {
                        Text(formStatusText)
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

            VStack {
                Spacer()
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "scope")
                            .font(.system(size: 11, weight: .bold))
                        Text(focusProfile.trackingCue)
                            .font(.system(size: 11, weight: .black))
                            .tracking(1.2)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Capsule())
                    .padding(12)

                    Spacer()
                }
            }

            if let saveMessage = recordingManager.saveMessage, selectedVideoURL == nil {
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: recordingManager.isSavingToPhotos ? "arrow.down.circle" : "photo.on.rectangle")
                                .font(.system(size: 11, weight: .bold))
                            Text(saveMessage.uppercased())
                                .font(.system(size: 10, weight: .black))
                                .tracking(1)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Capsule())
                        .padding(12)
                    }
                    Spacer()
                }
            }

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

    private var formStatusText: String {
        if !poseEstimator.isProperlyFramed {
            return "FRAME WAIST UP"
        }
        if !poseEstimator.isFrameValid {
            return "SHOW TARGET JOINTS"
        }
        return poseEstimator.isGoodForm ? "PERFECT FORM" : "ADJUST POSTURE"
    }

    private var shouldShowDetectedSkeleton: Bool {
        (isTracking || selectedVideoURL != nil) && !poseEstimator.bodyParts.isEmpty
    }

    private var skeletonColor: Color {
        guard poseEstimator.isProperlyFramed, poseEstimator.isFrameValid else { return .red }
        return poseEstimator.isGoodForm ? .primary : .tertiary
    }
}

// ── Skeleton Overlay ───────────────────────────────────

private struct SkeletonOverlay: View {
    let focusProfile: ExerciseFocusProfile

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            Path { path in
                path.move(to:    CGPoint(x: w * 0.50, y: h * 0.12))
                path.addLine(to: CGPoint(x: w * 0.50, y: h * 0.46))
                path.move(to:    CGPoint(x: w * 0.50, y: h * 0.46))
                path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.60))
                path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.78))
                path.move(to:    CGPoint(x: w * 0.50, y: h * 0.46))
                path.addLine(to: CGPoint(x: w * 0.60, y: h * 0.60))
                path.addLine(to: CGPoint(x: w * 0.60, y: h * 0.78))
                path.move(to:    CGPoint(x: w * 0.38, y: h * 0.30))
                path.addLine(to: CGPoint(x: w * 0.62, y: h * 0.30))
            }
            .stroke(Color.primary.opacity(0.4), lineWidth: 1.5)

            ForEach(FocusJoint.allCases, id: \.self) { joint in
                let isHighlighted = focusProfile.highlightedJoints.contains(joint)
                Circle()
                    .fill(isHighlighted ? Color.primary : Color.primary.opacity(0.28))
                    .frame(width: isHighlighted ? 11 : 7, height: isHighlighted ? 11 : 7)
                    .overlay(
                        Circle()
                            .stroke(isHighlighted ? Color.white.opacity(0.8) : Color.clear, lineWidth: 1)
                    )
                    .position(x: w * joint.position.x, y: h * joint.position.y)
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
    let selectedExercise: String
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
                    SmallStat(label: "Stability",  value: "\(stabilityScore)%",  color: .onSurface)
                    SmallStat(label: "Power Leak", value: "\(powerLeakScore)%",  color: .tertiary)
                }
            }
            .padding(24)
            .background(Color.containerHighest.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.outlineVariant.opacity(0.15), lineWidth: 1)
            )

            NavigationLink(destination: DrillPlanView(exerciseName: selectedExercise, formScore: Double(overallScore) / 100.0)) {
                Text("GENERATE DRILL PLAN")
                    .font(PerformanceTextStyle.labelSmall)
                    .tracking(1.5)
                    .foregroundColor(Color(hex: "#002957"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
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

// MARK: - Preview

#Preview {
    NavigationStack {
        FormAnalysisView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
