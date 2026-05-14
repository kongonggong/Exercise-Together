//
//  WorkoutHistoryView.swift
//  Exercise-Together
//
//  Destination for Dashboard "View All" button.
//  Reads all CDWorkoutSession records from CoreData.
//  Place in: Views/Dashboard/
//

import SwiftUI
import CoreData

struct WorkoutHistoryView: View {

    // MARK: - Environment

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - CoreData

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \CDWorkoutSession.date, ascending: false)
        ],
        animation: .default
    )
    private var sessions: FetchedResults<CDWorkoutSession>

    // MARK: - State

    @State private var searchText = ""
    @State private var selectedSession: CDWorkoutSession? = nil

    // MARK: - Filtered

    private var filtered: [CDWorkoutSession] {
        guard !searchText.isEmpty else { return Array(sessions) }
        return sessions.filter {
            ($0.name ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Grouped by month

    private var grouped: [(String, [CDWorkoutSession])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        var result: [(String, [CDWorkoutSession])] = []
        var seen: [String: Int] = [:]

        for session in filtered {
            let key = session.date.map { formatter.string(from: $0) } ?? "Unknown"
            if let idx = seen[key] {
                result[idx].1.append(session)
            } else {
                seen[key] = result.count
                result.append((key, [session]))
            }
        }
        return result
    }

    // MARK: - Stats

    private var totalVolume: Int {
        sessions.reduce(0) { $0 + Int($1.volumeLbs) }
    }

    private var totalMinutes: Int {
        sessions.reduce(0) { $0 + Int($1.duration) }
    }

    // MARK: - Body

    var body: some View {

        ZStack(alignment: .top) {

            Color.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {

                VStack(alignment: .leading, spacing: 0) {

                    Color.clear.frame(height: 64)

                    // ── Header ─────────────────────────
                    headerSection
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    // ── Summary Strip ──────────────────
                    summaryStrip
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    // ── Search ─────────────────────────
                    searchBar
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    // ── Session List ───────────────────
                    if filtered.isEmpty {
                        emptyState
                            .padding(.top, 60)
                    } else {
                        sessionList
                            .padding(.top, 24)
                    }

                    Color.clear.frame(height: 40)
                }
            }

            // Top Bar with back button
            historyTopBar
        }
    }
}

// =====================================================
// MARK: - Sections
// =====================================================

extension WorkoutHistoryView {

    // MARK: Top Bar

    private var historyTopBar: some View {

        HStack {

            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.outline)
                    .frame(width: 40, height: 40)
                    .background(Color.containerLow)
                    .clipShape(Circle())
            }

            Spacer()

            HStack(spacing: 10) {
                Circle()
                    .fill(Color.containerHighest)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.primary)
                    )
                Text("PERFORMANCE LAB")
                    .font(.system(size: 15, weight: .black))
                    .tracking(1)
                    .foregroundColor(.primary)
            }

            Spacer()

            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 24)
        .frame(height: 64)
        .background(
            Color.surface.opacity(0.8)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }

    // MARK: Header

    private var headerSection: some View {

        VStack(alignment: .leading, spacing: 6) {

            Text("History")
                .font(.system(size: 56, weight: .black))
                .tracking(-2)
                .foregroundColor(.onSurface)

            MetadataLabel(
                text: "\(sessions.count) sessions logged",
                color: .outline
            )
            .tracking(2.4)
        }
    }

    // MARK: Summary Strip

    private var summaryStrip: some View {

        HStack(spacing: 10) {

            SummaryChip(
                icon: "calendar",
                label: "Sessions",
                value: "\(sessions.count)"
            )

            SummaryChip(
                icon: "clock",
                label: "Total Time",
                value: "\(totalMinutes / 60)h \(totalMinutes % 60)m"
            )

            SummaryChip(
                icon: "scalemass",
                label: "Volume",
                value: "\((totalVolume / 1000))k lbs"
            )
        }
    }

    // MARK: Search Bar

    private var searchBar: some View {

        HStack(spacing: 12) {

            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(.outline)

            TextField("Search sessions...", text: $searchText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.onSurface)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.containerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Session List (grouped)

    private var sessionList: some View {

        VStack(alignment: .leading, spacing: 28) {

            ForEach(grouped, id: \.0) { month, monthSessions in

                VStack(alignment: .leading, spacing: 12) {

                    MetadataLabel(text: month, color: .outline)
                        .tracking(2)
                        .padding(.horizontal, 24)

                    VStack(spacing: 8) {
                        ForEach(monthSessions) { session in
                            HistorySessionRow(session: session)
                                .padding(.horizontal, 24)
                        }
                    }
                }
            }
        }
    }

    // MARK: Empty State

    private var emptyState: some View {

        VStack(spacing: 16) {

            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundColor(.outline)

            Text("No sessions found")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.onSurfaceVariant)

            MetadataLabel(
                text: "Complete a workout to build your history",
                color: .outline
            )
        }
        .frame(maxWidth: .infinity)
    }
}

// =====================================================
// MARK: - Summary Chip
// =====================================================

private struct SummaryChip: View {

    let icon: String
    let label: String
    let value: String

    var body: some View {

        VStack(alignment: .leading, spacing: 6) {

            Image(systemName: icon)
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.primary)

            Text(value)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.onSurface)

            MetadataLabel(text: label, color: .outline)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.containerLow)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// =====================================================
// MARK: - History Session Row
// =====================================================

private struct HistorySessionRow: View {

    let session: CDWorkoutSession

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM • h:mm a"
        return f
    }()

    var body: some View {

        HStack(spacing: 14) {

            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.containerHigh)
                    .frame(width: 50, height: 50)

                Image(systemName: session.icon ?? "figure.strengthtraining.traditional")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.primary)
            }

            // Name + date
            VStack(alignment: .leading, spacing: 4) {

                Text(session.name ?? "Workout")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.onSurface)

                let dateStr = session.date.map {
                    HistorySessionRow.dateFormatter.string(from: $0)
                } ?? "–"

                MetadataLabel(text: dateStr, color: .outline)
            }

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 4) {

                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text("\(session.volumeLbs.formatted())")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.onSurface)
                    Text("lbs")
                        .font(.system(size: 10))
                        .foregroundColor(.outline)
                }

                MetadataLabel(text: "\(session.duration) min", color: .outline)
            }
        }
        .padding(14)
        .background(Color.containerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
        )
    }
}

// =====================================================
// MARK: - Preview
// =====================================================

#Preview {
    WorkoutHistoryView()
        .environment(
            \.managedObjectContext,
             PersistenceController.preview.container.viewContext
        )
        .preferredColorScheme(.dark)
}
