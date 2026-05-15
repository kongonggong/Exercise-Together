// =====================================================
// CompareView.swift
// หน้า Compare — เปรียบเทียบ Expert vs นักกีฬา
// =====================================================

import SwiftUI
import PhotosUI
import AVKit

class PlayerState: NSObject, ObservableObject {
    @Published var player: AVPlayer?
    @Published var isPlaying: Bool = false
    private var timeObserverToken: Any?
    
    override init() {
        super.init()
    }
    
    func setPlayer(_ newPlayer: AVPlayer?) {
        self.player = newPlayer
        setupTimeObserver()
    }
    
    private func setupTimeObserver() {
        timeObserverToken = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
    
    func play() {
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seekForward(_ seconds: Double = 10.0) {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: seconds, preferredTimescale: 1))
        player.seek(to: newTime)
    }
    
    func seekBackward(_ seconds: Double = 10.0) {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: seconds, preferredTimescale: 1))
        let safeTime = max(newTime.seconds, 0)
        player.seek(to: CMTime(seconds: safeTime, preferredTimescale: 1))
    }
    
    deinit {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }
    }
}

struct CompareView: View {
    private let initialReferenceVideoName: String?
    private let referenceTitle: String

    // State
    @State private var formAccuracy: Int = 0
    @State private var syncOffset: Double = 0.0     // milliseconds
    @State private var angleDeviation: Double = 0.0  // degrees
    @State private var isPlaying: Bool = false
    @State private var expertProgress: Double = 0.0
    @State private var userProgress: Double = 0.0
    @State private var issues: [CompareIssue] = []
    @State private var isAnalyzing: Bool = false
    @State private var analysisTask: Task<Void, Never>?
    
    // Video picker states
    @State private var userVideoSelection: PhotosPickerItem?
    @State private var expertVideoURL: URL?
    @State private var userVideoURL: URL?
    @State private var showUserPicker: Bool = false
    @State private var showCorrectionPlan: Bool = false
    
    // Settings
    @State private var showSettings: Bool = false

    init(
        referenceVideoName: String? = "biceps-curl",
        referenceTitle: String = "Biceps Curl"
    ) {
        self.initialReferenceVideoName = referenceVideoName
        self.referenceTitle = referenceTitle
    }

    private var correctionPlanScore: Double {
        formAccuracy > 0 ? Double(formAccuracy) / 100.0 : 0.70
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color.surface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        Color.clear.frame(height: 104)

                        // ── Page Header ───────────────────────
                        ComparePageHeader(referenceTitle: referenceTitle)
                            .padding(.horizontal, 24)

                        // ── Dual Video Players ────────────────
                        DualVideoSection(
                            isPlaying: $isPlaying,
                            expertProgress: $expertProgress,
                            userProgress: $userProgress,
                            userVideoSelection: $userVideoSelection,
                            expertVideoURL: $expertVideoURL,
                            userVideoURL: $userVideoURL,
                            showUserPicker: $showUserPicker,
                            initialReferenceVideoName: initialReferenceVideoName
                        )

                        // ── Sync Stats Row ────────────────────
                        SyncStatsRow(
                            formAccuracy: formAccuracy,
                            syncOffset: syncOffset,
                            angleDeviation: angleDeviation
                        )
                        .padding(.horizontal, 24)

                        // ── Issues Breakdown ──────────────────
                        IssuesSection(issues: issues, isAnalyzing: isAnalyzing)
                            .padding(.horizontal, 24)

                        // ── CTA ───────────────────────────────
                        PrimaryButton(title: "Generate Correction Plan") {
                            showCorrectionPlan = true
                        }
                        .padding(.horizontal, 24)

                        Color.clear.frame(height: 132)
                    }
                }

                TopAppBar(trailingIcon: "gearshape") {
                    showSettings = true
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showCorrectionPlan) {
                DrillPlanView(
                    exerciseName: referenceTitle,
                    formScore: correctionPlanScore,
                    issueCount: max(issues.count, 1)
                )
            }
        }
        .onChange(of: expertVideoURL) { _, _ in
            runAccuracyAnalysisIfPossible()
        }
        .onChange(of: userVideoURL) { _, _ in
            runAccuracyAnalysisIfPossible()
        }
        .onDisappear {
            analysisTask?.cancel()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    private func runAccuracyAnalysisIfPossible() {
        guard let expertVideoURL, let userVideoURL else {
            formAccuracy = 0
            syncOffset = 0
            angleDeviation = 0
            issues = []
            return
        }

        analysisTask?.cancel()
        isAnalyzing = true

        analysisTask = Task {
            let result = await CompareAccuracyAnalyzer.analyze(
                referenceURL: expertVideoURL,
                userURL: userVideoURL
            )

            guard !Task.isCancelled else { return }

            await MainActor.run {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    formAccuracy = result.accuracy
                    syncOffset = result.syncOffsetMilliseconds
                    angleDeviation = result.angleDeviation
                    issues = result.issues
                    isAnalyzing = false
                }
            }
        }
    }
}

// MARK: - Page Header

private struct ComparePageHeader: View {
    let referenceTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Video Comparison")
                .font(.system(size: 28, weight: .black))
                .tracking(-0.5)
                .foregroundColor(.onSurface)

            MetadataLabel(text: "\(referenceTitle) reference vs your upload", color: .outline)
        }
    }
}

// MARK: - Dual Video Section

private struct DualVideoSection: View {
    @Binding var isPlaying: Bool
    @Binding var expertProgress: Double
    @Binding var userProgress: Double
    @Binding var userVideoSelection: PhotosPickerItem?
    @Binding var expertVideoURL: URL?
    @Binding var userVideoURL: URL?
    @Binding var showUserPicker: Bool
    let initialReferenceVideoName: String?
    
    @State private var expertPlayer: AVPlayer?
    @State private var userPlayer: AVPlayer?
    @State private var currentPlayerTimestamp: Double = 0

    var body: some View {
        VStack(spacing: 18) {
            HStack(spacing: 8) {
                // ── Expert Video (ซ้าย) ─────────────────────
                VideoPanel(
                    label: "Expert Reference",
                    sublabel: "Reference",
                    progress: $expertProgress,
                    badgeColor: .primary,
                    isExpert: true,
                    videoURL: $expertVideoURL,
                    videoSelection: .constant(nil),
                    showPicker: .constant(false),
                    player: $expertPlayer,
                    allowsUpload: false,
                    emptyMessage: "Reference unavailable"
                )

                // ── User Video (ขวา) ────────────────────────
                VideoPanel(
                    label: "User Recording",
                    sublabel: "Your Session",
                    progress: $userProgress,
                    badgeColor: .tertiary,
                    isExpert: false,
                    videoURL: $userVideoURL,
                    videoSelection: $userVideoSelection,
                    showPicker: $showUserPicker,
                    player: $userPlayer,
                    allowsUpload: true,
                    emptyMessage: "Tap to upload video"
                )
                .onTapGesture {
                    showUserPicker = true
                }
            }

            SharedPlaybackControls(
                isPlaying: $isPlaying,
                expertPlayer: $expertPlayer,
                userPlayer: $userPlayer
            )
        }
        .padding(.horizontal, 16)
        .photosPicker(
            isPresented: $showUserPicker,
            selection: $userVideoSelection,
            matching: .videos
        )
        .onChange(of: userVideoSelection) { _, newValue in
            Task {
                if let videoFile = try? await newValue?.loadTransferable(type: VideoTransferable.self) {
                    userVideoURL = videoFile.url
                    userPlayer = AVPlayer(url: videoFile.url)
                }
            }
        }
        .onAppear {
            loadBundledExpertReferenceIfNeeded()
        }
    }

    private func loadBundledExpertReferenceIfNeeded() {
        if expertVideoURL == nil,
           let initialReferenceVideoName,
           let url = ReferenceVideoLibrary.url(for: initialReferenceVideoName) {
            expertVideoURL = url
            expertPlayer = AVPlayer(url: url)
        }
    }
}

// ── Single Video Panel ─────────────────────────────────

private struct VideoPanel: View {
    let label: String
    let sublabel: String
    @Binding var progress: Double
    let badgeColor: Color
    let isExpert: Bool
    @Binding var videoURL: URL?
    @Binding var videoSelection: PhotosPickerItem?
    @Binding var showPicker: Bool
    @Binding var player: AVPlayer?
    let allowsUpload: Bool
    let emptyMessage: String

    var body: some View {
        VStack(spacing: 0) {
            // Video Frame
            ZStack(alignment: .bottom) {
                // Video placeholder or player
                if let url = videoURL, let player = player {
                    VideoPlayerView(url: url, player: player)
                        .aspectRatio(9/16, contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(Color.containerLowest)
                        .aspectRatio(9/16, contentMode: .fit)
                        .overlay(
                            // Skeleton silhouette
                            VStack(spacing: 12) {
                                Image(systemName: isExpert ? "figure.strengthtraining.traditional" : "figure.walk")
                                    .font(.system(size: 48, weight: .ultraLight))
                                    .foregroundColor(Color.outline.opacity(0.2))
                                
                                Text(emptyMessage)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color.outline.opacity(0.4))
                            }
                        )
                }

                // Badge overlay
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(label)
                                .font(.system(size: 9, weight: .black))
                                .tracking(1.5)
                                .foregroundColor(.onSurface)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.containerHigh.opacity(0.7))
                                .clipShape(Capsule())


                            Text(sublabel)
                                .font(.system(size: 9, weight: .medium))
                                .tracking(1.2)
                                .foregroundColor(badgeColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .padding(.horizontal, 8)
                        }
                        Spacer()
                    }
                    .padding(10)
                    Spacer()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture {
                if allowsUpload {
                    showPicker = true
                }
            }
        }
    }
}

// ── Shared Playback Controls ───────────────────────────

private struct SharedPlaybackControls: View {
    @Binding var isPlaying: Bool
    @Binding var expertPlayer: AVPlayer?
    @Binding var userPlayer: AVPlayer?

    var body: some View {
        HStack(spacing: 28) {
            Spacer()

            // Rewind 10s
            Button {
                expertPlayer?.seek(to: CMTime(seconds: max(0, (expertPlayer?.currentTime().seconds ?? 0) - 10), preferredTimescale: 1))
                userPlayer?.seek(to: CMTime(seconds: max(0, (userPlayer?.currentTime().seconds ?? 0) - 10), preferredTimescale: 1))
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.onSurface)
            }

            // Play / Pause (main)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPlaying.toggle()
                    if isPlaying {
                        expertPlayer?.play()
                        userPlayer?.play()
                    } else {
                        expertPlayer?.pause()
                        userPlayer?.pause()
                    }
                }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.containerHighest)
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())

            // Forward 10s
            Button {
                if let expertDuration = expertPlayer?.currentItem?.duration.seconds,
                   !expertDuration.isNaN {
                    let currentTime = expertPlayer?.currentTime().seconds ?? 0
                    let newTime = min(currentTime + 10, expertDuration)
                    expertPlayer?.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
                }
                
                if let userDuration = userPlayer?.currentItem?.duration.seconds,
                   !userDuration.isNaN {
                    let currentTime = userPlayer?.currentTime().seconds ?? 0
                    let newTime = min(currentTime + 10, userDuration)
                    userPlayer?.seek(to: CMTime(seconds: newTime, preferredTimescale: 1))
                }
            } label: {
                Image(systemName: "goforward.10")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.onSurface)
            }

            Spacer()
        }
    }
}

// MARK: - Sync Stats Row

private struct SyncStatsRow: View {
    let formAccuracy: Int
    let syncOffset: Double
    let angleDeviation: Double

    var body: some View {
        HStack(spacing: 0) {
            // Form Accuracy — ใหญ่สุด
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(formAccuracy)")
                        .font(.system(size: 48, weight: .black))
                        .tracking(-1.5)
                        .foregroundColor(.onSurface)
                    Text("%")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                }
                MetadataLabel(text: "Form Accuracy", color: .primary)
            }

            Spacer()

            // Sync Offset
            VStack(alignment: .trailing, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%.2f", syncOffset))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.onSurface)
                    Text("ms")
                        .font(.system(size: 11))
                        .foregroundColor(.onSurfaceVariant)
                }
                MetadataLabel(text: "Sync Offset")
            }

            Color.outlineVariant.opacity(0.3)
                .frame(width: 1, height: 40)
                .padding(.horizontal, 20)

            // Angle Deviation
            VStack(alignment: .trailing, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", angleDeviation))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.tertiary)
                    Text("°")
                        .font(.system(size: 11))
                        .foregroundColor(.onSurfaceVariant)
                }
                MetadataLabel(text: "Angle Dev.")
            }
        }
        .padding(20)
        .background(Color.containerLow)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Issues Section

private struct IssuesSection: View {
    let issues: [CompareIssue]
    let isAnalyzing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MetadataLabel(text: "Movement Analysis", color: .outline)
                .tracking(2)

            VStack(spacing: 12) {
                if isAnalyzing {
                    Text("Calculating upper-body accuracy...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.onSurfaceVariant)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.containerLow)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if issues.isEmpty {
                    Text("Upload your video to calculate movement accuracy.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.onSurfaceVariant)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color.containerLow)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    ForEach(issues) { issue in
                        IssueRow(issue: issue)
                    }
                }
            }
        }
    }
}

private struct IssueRow: View {
    let issue: CompareIssue

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon
            Image(systemName: issue.icon)
                .font(.system(size: 18, weight: .light))
                .foregroundColor(issue.iconColor)
                .frame(width: 24, height: 24)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.onSurface)
                Text(issue.description)
                    .font(.system(size: 12))
                    .foregroundColor(.onSurfaceVariant)
                    .lineSpacing(3)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.containerLow)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    CompareView()
        .preferredColorScheme(.dark)
}

// MARK: - Video Player View

struct VideoPlayerView: View {
    let url: URL
    let player: AVPlayer

    @State private var thumbnail: UIImage?
    @State private var isReadyToDisplay = false
    @State private var failureMessage: String?

    private let statusTimer = Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.black

            PlayerLayerView(player: player)

            if let thumbnail, !isReadyToDisplay {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
            }

            if let failureMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 28, weight: .light))
                    Text(failureMessage)
                        .font(.system(size: 12, weight: .medium))
                        .multilineTextAlignment(.center)
                }
                .foregroundColor(.white)
                .padding(16)
            }
        }
        .clipped()
        .task(id: url) {
            loadThumbnail()
        }
        .onAppear {
            player.automaticallyWaitsToMinimizeStalling = false
            refreshPlayerStatus()
        }
        .onReceive(statusTimer) { _ in
            refreshPlayerStatus()
        }
    }

    private func refreshPlayerStatus() {
        guard let item = player.currentItem else { return }

        switch item.status {
        case .readyToPlay:
            isReadyToDisplay = true
            failureMessage = nil
        case .failed:
            isReadyToDisplay = false
            failureMessage = item.error?.localizedDescription ?? "Video could not be loaded."
        case .unknown:
            if player.timeControlStatus == .playing {
                isReadyToDisplay = true
            }
            break
        @unknown default:
            break
        }
    }

    private func loadThumbnail() {
        let thumbnailURL = url

        let asset = AVURLAsset(url: thumbnailURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 900, height: 900)

        generator.generateCGImageAsynchronously(
            for: CMTime(seconds: 0.1, preferredTimescale: 600)
        ) { cgImage, _, error in
            if let cgImage {
                let image = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
                    thumbnail = image
                }
            } else if error != nil {
                DispatchQueue.main.async {
                    if failureMessage == nil {
                        failureMessage = "Video preview is loading."
                    }
                }
            }
        }
    }
}

private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerLayerContainerView {
        let view = PlayerLayerContainerView()
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ uiView: PlayerLayerContainerView, context: Context) {
        uiView.playerLayer.player = player
    }
}

private final class PlayerLayerContainerView: UIView {
    override static var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        playerLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .black
        playerLayer.videoGravity = .resizeAspect
    }
}
