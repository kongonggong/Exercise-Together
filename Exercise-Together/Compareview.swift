// =====================================================
// CompareView.swift
// หน้า Compare — เปรียบเทียบ Expert vs นักกีฬา
// =====================================================

import SwiftUI

struct CompareView: View {
    // State
    @State private var formAccuracy: Int = 84
    @State private var syncOffset: Double = -0.24     // milliseconds
    @State private var angleDeviation: Double = 12.4  // degrees
    @State private var isPlaying: Bool = false
    @State private var expertProgress: Double = 0.38
    @State private var userProgress: Double = 0.38
    @State private var issues: [CompareIssue] = CompareIssue.squatIssues

    var body: some View {
        ZStack(alignment: .top) {
            Color.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Color.clear.frame(height: 64)

                    // ── Page Header ───────────────────────
                    ComparePageHeader()
                        .padding(.horizontal, 24)

                    // ── Dual Video Players ────────────────
                    DualVideoSection(
                        isPlaying: $isPlaying,
                        expertProgress: $expertProgress,
                        userProgress: $userProgress
                    )

                    // ── Sync Stats Row ────────────────────
                    SyncStatsRow(
                        formAccuracy: formAccuracy,
                        syncOffset: syncOffset,
                        angleDeviation: angleDeviation
                    )
                    .padding(.horizontal, 24)

                    // ── Issues Breakdown ──────────────────
                    IssuesSection(issues: issues)
                        .padding(.horizontal, 24)

                    // ── CTA ───────────────────────────────
                    PrimaryButton(title: "Generate Correction Plan") {
                        // Navigate to corrections
                    }
                    .padding(.horizontal, 24)

                    Color.clear.frame(height: 32)
                }
            }

            TopAppBar(trailingIcon: "gearshape")
        }
    }
}

// MARK: - Page Header

private struct ComparePageHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Video Comparison")
                .font(.system(size: 28, weight: .black))
                .tracking(-0.5)
                .foregroundColor(.onSurface)

            MetadataLabel(text: "Expert Reference vs Your Session", color: .outline)
        }
    }
}

// MARK: - Dual Video Section

private struct DualVideoSection: View {
    @Binding var isPlaying: Bool
    @Binding var expertProgress: Double
    @Binding var userProgress: Double

    var body: some View {
        HStack(spacing: 8) {
            // ── Expert Video (ซ้าย) ─────────────────────
            VideoPanel(
                label: "Expert Reference",
                sublabel: "Olympic Level",
                progress: $expertProgress,
                badgeColor: .primary,
                isExpert: true
            )

            // ── User Video (ขวา) ────────────────────────
            VideoPanel(
                label: "User Recording",
                sublabel: "Session #24",
                progress: $userProgress,
                badgeColor: .tertiary,
                isExpert: false
            )
        }
        .padding(.horizontal, 16)

        // Shared Playback Controls
        SharedPlaybackControls(isPlaying: $isPlaying)
            .padding(.horizontal, 24)
    }
}

// ── Single Video Panel ─────────────────────────────────

private struct VideoPanel: View {
    let label: String
    let sublabel: String
    @Binding var progress: Double
    let badgeColor: Color
    let isExpert: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Video Frame
            ZStack(alignment: .bottom) {
                // Video placeholder
                Rectangle()
                    .fill(Color.containerLowest)
                    .aspectRatio(9/16, contentMode: .fit)
                    .overlay(
                        // Skeleton silhouette
                        Image(systemName: isExpert ? "figure.strengthtraining.traditional" : "figure.walk")
                            .font(.system(size: 48, weight: .ultraLight))
                            .foregroundColor(Color.outline.opacity(0.2))
                    )

                // Badge overlay
                VStack {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(label)
                                .font(.system(size: 9, weight: .black))
                                .tracking(1.5)
                                .foregroundColor(.onSurface)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.containerHigh.opacity(0.7))
                                .clipShape(Capsule())

                            Text(sublabel)
                                .font(.system(size: 9, weight: .medium))
                                .tracking(1.2)
                                .foregroundColor(badgeColor)
                                .padding(.horizontal, 8)
                        }
                        Spacer()
                    }
                    .padding(10)
                    Spacer()
                }

                // Progress scrubber
                VStack(spacing: 0) {
                    Slider(value: $progress)
                        .tint(badgeColor)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// ── Shared Playback Controls ───────────────────────────

private struct SharedPlaybackControls: View {
    @Binding var isPlaying: Bool

    var body: some View {
        HStack(spacing: 28) {
            Spacer()

            // Rewind 10s
            Button {
                // Seek backward
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.onSurface)
            }

            // Play / Pause (main)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPlaying.toggle()
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
                // Seek forward
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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MetadataLabel(text: "Movement Analysis", color: .outline)
                .tracking(2)

            VStack(spacing: 12) {
                ForEach(issues) { issue in
                    IssueRow(issue: issue)
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
