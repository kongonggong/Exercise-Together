// =====================================================
// DashboardView.swift
// หน้าหลัก — ภาพรวม Performance ประจำวัน
// =====================================================

import SwiftUI

struct DashboardView: View {
    // ViewModel / State
    @State private var performanceScore: Int = 88
    @State private var weeklyChange: Double = 4.2
    @State private var formAccuracy: Double = 0.70
    @State private var sessions: [WorkoutSession] = WorkoutSession.samples

    private let metrics: [PerformanceMetric] = [
        PerformanceMetric(label: "Power Output",  value: 0.92, color: .primary),
        PerformanceMetric(label: "Recovery Rate", value: 0.76, color: .tertiary),
    ]

    var body: some View {
        ZStack(alignment: .top) {
            // ── Background ───────────────────────────────
            Color.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Space สำหรับ Top Bar
                    Color.clear.frame(height: 64)

                    // ── 1. Hero Banner: Ready to Lift? ───
                    HeroBannerSection()

                    // ── 2. Bento Grid: Stats + Form ──────
                    BentoGridSection(
                        score: performanceScore,
                        weeklyChange: weeklyChange,
                        metrics: metrics,
                        formAccuracy: formAccuracy
                    )

                    // ── 3. Recent Sessions ────────────────
                    RecentSessionsSection(sessions: sessions)

                    // Bottom padding
                    Color.clear.frame(height: 32)
                }
                .padding(.horizontal, 24)
            }

            // ── Sticky Top App Bar ────────────────────────
            TopAppBar()
        }
    }
}

// MARK: - Hero Banner Section

private struct HeroBannerSection: View {
    var body: some View {
        ZStack(alignment: .leading) {
            // Background Image placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.containerLow)
                .frame(minHeight: 280)
                .overlay(
                    // Gradient overlay
                    LinearGradient(
                        colors: [Color.surface, Color.surface.opacity(0.6), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            VStack(alignment: .leading, spacing: 0) {
                MetadataLabel(text: "Recommended Today", color: .primary)
                    .padding(.bottom, 12)

                Text("Ready to\nLift?")
                    .font(PerformanceTextStyle.displayMedium)
                    .tracking(-1)
                    .foregroundColor(.onSurface)
                    .padding(.bottom, 16)

                Text("Your physiological data suggests peak recovery.\nToday is optimized for a High-Intensity Squat Session.")
                    .font(PerformanceTextStyle.bodyMedium)
                    .foregroundColor(.onSurfaceVariant)
                    .lineSpacing(4)
                    .padding(.bottom, 28)

                // CTA Button
                Button {
                    // Navigate to workout start
                } label: {
                    Text("START WORKOUT")
                        .font(PerformanceTextStyle.labelSmall)
                        .tracking(1.5)
                        .foregroundColor(Color(hex: "#002957"))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(LinearGradient.primaryGradient)
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(28)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Bento Grid Section (Performance Score + Form Analysis)

private struct BentoGridSection: View {
    let score: Int
    let weeklyChange: Double
    let metrics: [PerformanceMetric]
    let formAccuracy: Double

    var body: some View {
        // iPhone: Stack แนวตั้ง / iPad: แนวนอน
        HStack(alignment: .top, spacing: 16) {
            // ── Card ซ้าย: Performance Score ─────────
            PerformanceScoreCard(
                score: score,
                weeklyChange: weeklyChange,
                metrics: metrics
            )

            // ── Card ขวา: Form Analysis ───────────────
            FormAnalysisSummaryCard(accuracy: formAccuracy)
        }
    }
}

// ── Performance Score Card ─────────────────────────────

private struct PerformanceScoreCard: View {
    let score: Int
    let weeklyChange: Double
    let metrics: [PerformanceMetric]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Performance Score")
                    .font(PerformanceTextStyle.headlineSmall)
                    .foregroundColor(.onSurface)
                Spacer()
                Image(systemName: "bolt.fill")
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 28)

            // Big Score Number
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text("\(score)")
                    .font(.system(size: 64, weight: .black))
                    .tracking(-2)
                    .foregroundColor(.onSurface)

                VStack(alignment: .leading, spacing: 2) {
                    Text("+\(String(format: "%.1f", weeklyChange))%")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    MetadataLabel(text: "Week over Week")
                }
            }
            .padding(.bottom, 28)

            // Progress Bars
            VStack(spacing: 16) {
                ForEach(metrics, id: \.label) { metric in
                    VStack(spacing: 6) {
                        HStack {
                            MetadataLabel(text: metric.label, color: .onSurfaceVariant)
                            Spacer()
                            MetadataLabel(text: "\(Int(metric.value * 100))%", color: .onSurfaceVariant)
                        }
                        ProgressBlade(value: metric.value, color: metric.color)
                    }
                }
            }
        }
        .padding(24)
        .background(Color.containerLow.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
    }
}

// ── Form Analysis Summary Card ─────────────────────────

private struct FormAnalysisSummaryCard: View {
    let accuracy: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Form Analysis")
                .font(PerformanceTextStyle.headlineSmall)
                .foregroundColor(.onSurface)
                .padding(.bottom, 20)

            Spacer()

            // Progress Ring + Percentage
            ZStack {
                ProgressRing(progress: accuracy, size: 100, ringColor: .tertiary)
                Text("\(Int(accuracy * 100))%")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.onSurface)
            }
            .frame(maxWidth: .infinity)

            Spacer()

            Text("Squat depth is inconsistent. Focus on hip mobility in your warm-up.")
                .font(PerformanceTextStyle.bodyMedium)
                .foregroundColor(.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)

            Divider()
                .background(Color.outlineVariant.opacity(0.2))
                .padding(.bottom, 12)

            // View Drills CTA
            Button {
                // Navigate to drills
            } label: {
                MetadataLabel(text: "View Detailed Drills", color: .primary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 280)
        .background(Color.containerLow)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Recent Sessions Section

private struct RecentSessionsSection: View {
    let sessions: [WorkoutSession]

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Recent Sessions")
                    .font(PerformanceTextStyle.headlineSmall)
                    .foregroundColor(.onSurface)
                Spacer()
                Button {
                    // Navigate to all sessions
                } label: {
                    MetadataLabel(text: "View All", color: .outline)
                }
            }

            // Session List
            VStack(spacing: 8) {
                ForEach(sessions) { session in
                    SessionRow(session: session)
                }
            }
        }
    }
}

// ── Session Row ────────────────────────────────────────

private struct SessionRow: View {
    let session: WorkoutSession

    var body: some View {
        HStack(spacing: 16) {
            // Icon Box
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.containerHigh)
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: session.icon)
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.primary)
                )

            // Name + Metadata
            VStack(alignment: .leading, spacing: 4) {
                Text(session.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.onSurface)
                MetadataLabel(text: "\(session.dayTime) • \(session.duration) MIN")
            }

            Spacer()

            // Volume
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.volumeLbs.formatted())")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.onSurface)
                MetadataLabel(text: "LBS Volume")
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.outline)
        }
        .padding(16)
        .background(Color.containerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
}
