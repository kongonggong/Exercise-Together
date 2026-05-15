// =====================================================
// DashboardView.swift
// หน้าหลัก — ภาพรวม Performance ประจำวัน
// Wired to CDWorkoutSession + CDFormAnalysisResult CoreData
// =====================================================

import SwiftUI
import CoreData

struct DashboardView: View {

    // MARK: - Core Data

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDWorkoutSession.date, ascending: false)],
        animation: .default
    )
    private var sessions: FetchedResults<CDWorkoutSession>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDFormAnalysisResult.date, ascending: false)],
        animation: .default
    )
    private var analysisResults: FetchedResults<CDFormAnalysisResult>
    
    // Settings
    @State private var showSettings: Bool = false

    // MARK: - Computed Stats

    private var latestFormScore: Double {
        analysisResults.first?.formScore ?? 0.0
    }

    private var averageFormScore: Double {
        guard !analysisResults.isEmpty else { return 0 }
        let sum = analysisResults.prefix(10).reduce(0.0) { $0 + $1.formScore }
        return sum / Double(min(analysisResults.count, 10))
    }

    private var totalCaloriesBurned: Double {
        analysisResults.prefix(7).reduce(0.0) { $0 + $1.caloriesBurned }
    }

    private var totalRepsThisWeek: Int32 {
        analysisResults.prefix(7).reduce(0) { $0 + $1.totalReps }
    }

    private var performanceScore: Int {
        guard !analysisResults.isEmpty else { return 0 }
        let recent = analysisResults.prefix(5)
        let avgOverall = recent.reduce(0.0) { $0 + $1.overallScore } / Double(recent.count)
        return min(100, max(0, Int(avgOverall)))
    }

    private var weeklyChange: Double {
        guard analysisResults.count >= 2 else { return 0 }
        let recent = analysisResults[0].overallScore
        let previous = analysisResults[1].overallScore
        guard previous > 0 else { return 0 }
        return ((recent - previous) / previous) * 100
    }

    private var powerOutput: Double {
        guard !analysisResults.isEmpty else { return 0 }
        let avg = analysisResults.prefix(5).reduce(0.0) { $0 + $1.overallScore } / Double(min(analysisResults.count, 5))
        return min(1.0, avg / 100)
    }

    private var recoveryRate: Double {
        guard analysisResults.count >= 2 else { return 0 }
        let avg = analysisResults.prefix(5).reduce(0.0) { $0 + (1.0 - $1.powerLeakScore) } / Double(min(analysisResults.count, 5))
        return min(1.0, max(0, avg))
    }

    private var metrics: [PerformanceMetric] {
        [
            PerformanceMetric(label: "Power Output", value: powerOutput, color: .primary),
            PerformanceMetric(label: "Recovery Rate", value: recoveryRate, color: .tertiary),
        ]
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            Color.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Color.clear.frame(height: 64)

                    // ── 1. Hero Banner ───────────────────
                    HeroBannerSection(sessionCount: sessions.count)

                    // ── 2. Weekly Snapshot ───────────────
                    WeeklySnapshotRow(
                        calories: totalCaloriesBurned,
                        reps: totalRepsThisWeek,
                        sessions: sessions.count
                    )

                    // ── 3. Bento Grid ────────────────────
                    BentoGridSection(
                        score: performanceScore,
                        weeklyChange: weeklyChange,
                        metrics: metrics,
                        formAccuracy: latestFormScore
                    )

                    // ── 4. Recent Sessions ───────────────
                    RecentSessionsSection(sessions: Array(sessions.prefix(5)))

                    Color.clear.frame(height: 32)
                }
                .padding(.horizontal, 24)
            }

            TopAppBar(trailingIcon: "gearshape") {
                showSettings = true
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear { seedSessionsIfNeeded() }
    }
}

// MARK: - Seeder (fallback sample data)

extension DashboardView {

    func seedSessionsIfNeeded() {
        guard sessions.isEmpty else { return }

        let sampleData: [(String, String, Int32, Int32)] = [
            ("Heavy Leg Day",   "figure.strengthtraining.traditional", 72, 12450),
            ("Upper Body Push", "figure.arms.open",                    58,  9800),
            ("Olympic Pulls",   "figure.gymnastics",                   90, 15200),
        ]

        let calendar = Calendar.current
        for (index, (name, icon, duration, volume)) in sampleData.enumerated() {
            let session = CDWorkoutSession(context: viewContext)
            session.id       = UUID()
            session.name     = name
            session.icon     = icon
            session.duration = duration
            session.volumeLbs = volume
            session.date     = calendar.date(byAdding: .day, value: -index * 2, to: Date())
        }

        do { try viewContext.save() } catch { print(error.localizedDescription) }
    }
}

// MARK: - Hero Banner

private struct HeroBannerSection: View {
    let sessionCount: Int

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.containerLow)
                .frame(minHeight: 280)
                .overlay(
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

                Text("Your physiological data suggests peak recovery.\nToday is optimized for a High-Intensity Session.")
                    .font(PerformanceTextStyle.bodyMedium)
                    .foregroundColor(.onSurfaceVariant)
                    .lineSpacing(4)
                    .padding(.bottom, 28)

                Button { } label: {
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

// MARK: - Weekly Snapshot Row

private struct WeeklySnapshotRow: View {
    let calories: Double
    let reps: Int32
    let sessions: Int

    var body: some View {
        HStack(spacing: 12) {
            SnapshotTile(
                icon: "flame.fill",
                value: String(format: "%.0f", calories),
                unit: "kcal",
                label: "This Week",
                color: .tertiary
            )
            SnapshotTile(
                icon: "repeat",
                value: "\(reps)",
                unit: "reps",
                label: "Total Reps",
                color: .primary
            )
            SnapshotTile(
                icon: "calendar.badge.checkmark",
                value: "\(sessions)",
                unit: "sessions",
                label: "Logged",
                color: .primary
            )
        }
    }
}

private struct SnapshotTile: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(color)

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.onSurface)
                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.onSurfaceVariant)
            }

            MetadataLabel(text: label, color: .outline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.containerLow)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Bento Grid Section

private struct BentoGridSection: View {
    let score: Int
    let weeklyChange: Double
    let metrics: [PerformanceMetric]
    let formAccuracy: Double

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            PerformanceScoreCard(
                score: score,
                weeklyChange: weeklyChange,
                metrics: metrics
            )
            FormAnalysisSummaryCard(accuracy: formAccuracy)
        }
    }
}

// ── Performance Score Card ─────────────────────────────

private struct PerformanceScoreCard: View {
    let score: Int
    let weeklyChange: Double
    let metrics: [PerformanceMetric]

    private var changePrefix: String { weeklyChange >= 0 ? "+" : "" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Performance Score")
                    .font(PerformanceTextStyle.headlineSmall)
                    .foregroundColor(.onSurface)
                Spacer()
                Image(systemName: "bolt.fill")
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 28)

            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text(score > 0 ? "\(score)" : "--")
                    .font(.system(size: 64, weight: .black))
                    .tracking(-2)
                    .foregroundColor(.onSurface)

                VStack(alignment: .leading, spacing: 2) {
                    Text(score > 0 ? "\(changePrefix)\(String(format: "%.1f", weeklyChange))%" : "--")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(weeklyChange >= 0 ? .primary : .tertiary)
                    MetadataLabel(text: "Week over Week")
                }
            }
            .padding(.bottom, 28)

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

            ZStack {
                ProgressRing(progress: accuracy, size: 100, ringColor: .tertiary)
                Text(accuracy > 0 ? "\(Int(accuracy * 100))%" : "--")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.onSurface)
            }
            .frame(maxWidth: .infinity)

            Spacer()

            Text(accuracy > 0.8
                 ? "Great form! Keep up the momentum."
                 : accuracy > 0 ? "Squat depth is inconsistent. Focus on hip mobility."
                 : "No sessions yet. Start tracking to see your score.")
                .font(PerformanceTextStyle.bodyMedium)
                .foregroundColor(.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.vertical, 16)

            Divider()
                .background(Color.outlineVariant.opacity(0.2))
                .padding(.bottom, 12)

            Button { } label: {
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
    let sessions: [CDWorkoutSession]

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Sessions")
                    .font(PerformanceTextStyle.headlineSmall)
                    .foregroundColor(.onSurface)
                Spacer()
                NavigationLink(destination: WorkoutHistoryView()) {
                    MetadataLabel(text: "View All", color: .outline)
                }
            }

            if sessions.isEmpty {
                EmptySessionsState()
            } else {
                VStack(spacing: 8) {
                    ForEach(sessions, id: \.id) { session in
                        CDSessionRow(session: session)
                    }
                }
            }
        }
    }
}

private struct EmptySessionsState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundColor(.outline)
            Text("No sessions yet")
                .font(PerformanceTextStyle.bodyLarge)
                .foregroundColor(.onSurfaceVariant)
            MetadataLabel(text: "Start tracking to see history", color: .outline)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.containerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// ── CDSession Row ──────────────────────────────────────

private struct CDSessionRow: View {
    let session: CDWorkoutSession

    private var formattedDate: String {
        guard let date = session.date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE • hh:mm a"
        return formatter.string(from: date).uppercased()
    }

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.containerHigh)
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: session.icon ?? "figure.walk")
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(.primary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(session.name ?? "Workout")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.onSurface)
                MetadataLabel(text: "\(formattedDate) • \(session.duration) MIN")
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.volumeLbs.formatted())")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.onSurface)
                MetadataLabel(text: "LBS")
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
    NavigationStack {
        DashboardView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
