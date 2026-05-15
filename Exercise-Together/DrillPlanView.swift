//
//  DrillPlanView.swift
//  Exercise-Together
//
//  Destination for:
//  - FormAnalysisView → "Generate Drill Plan"
//  - CompareView      → "Generate Correction Plan"
//  Place in: Views/
//

import SwiftUI

// =====================================================
// MARK: - Drill Model
// =====================================================

private struct DrillItem: Identifiable {
    let id = UUID()
    let phase: String
    let name: String
    let sets: Int
    let reps: String
    let focus: String
    let icon: String
    let priority: DrillPriority
}

private enum DrillPriority {
    case critical, moderate, maintenance

    var color: Color {
        switch self {
        case .critical:    return Color(hex: "#FF6B6B")
        case .moderate:    return .tertiary
        case .maintenance: return .primary
        }
    }

    var label: String {
        switch self {
        case .critical:    return "Critical"
        case .moderate:    return "Moderate"
        case .maintenance: return "Maintenance"
        }
    }
}

private func drillPlan(for exerciseName: String) -> [DrillItem] {
    switch exerciseName {
    case "Arm Curls":
        return [
            DrillItem(phase: "Activation", name: "Scapular Set", sets: 2, reps: "10", focus: "Set the shoulder before curling so the elbow path stays quiet.", icon: "figure.arms.open", priority: .moderate),
            DrillItem(phase: "Drill", name: "Wall Elbow Curl", sets: 3, reps: "8", focus: "Keep the upper arm close to the wall while the wrist travels toward the shoulder.", icon: "dumbbell", priority: .critical),
            DrillItem(phase: "Drill", name: "Tempo Curl", sets: 3, reps: "6", focus: "Use a slow lower to keep the elbow angle controlled through the full range.", icon: "metronome", priority: .moderate),
            DrillItem(phase: "Mobility", name: "Biceps Wall Stretch", sets: 2, reps: "30 sec", focus: "Open the front of the arm without losing shoulder position.", icon: "figure.cooldown", priority: .maintenance)
        ]
    case "Shoulder Press":
        return [
            DrillItem(phase: "Activation", name: "Wall Slide", sets: 3, reps: "8", focus: "Prime upward shoulder rotation while keeping ribs quiet.", icon: "arrow.up", priority: .critical),
            DrillItem(phase: "Drill", name: "Seated Press Path", sets: 3, reps: "6", focus: "Press along a vertical line with elbow stacked under wrist.", icon: "figure.strengthtraining.traditional", priority: .critical),
            DrillItem(phase: "Drill", name: "Overhead Lockout Hold", sets: 3, reps: "15 sec", focus: "Finish with a stable elbow and shoulder instead of drifting forward.", icon: "pause.circle", priority: .moderate),
            DrillItem(phase: "Mobility", name: "Lat Reach Stretch", sets: 2, reps: "40 sec", focus: "Free overhead range so the press does not arch the torso.", icon: "figure.cooldown", priority: .maintenance)
        ]
    case "Lateral Raises":
        return [
            DrillItem(phase: "Activation", name: "Band Pull-Apart", sets: 3, reps: "12", focus: "Set shoulder blades before raising both arms.", icon: "figure.arms.open", priority: .moderate),
            DrillItem(phase: "Drill", name: "Thumb-Up Lateral Raise", sets: 3, reps: "8", focus: "Raise both wrists evenly while keeping shoulders level.", icon: "arrow.left.and.right", priority: .critical),
            DrillItem(phase: "Drill", name: "Top Range Pause", sets: 3, reps: "5 sec", focus: "Hold the top position without shrugging.", icon: "pause.circle", priority: .moderate),
            DrillItem(phase: "Mobility", name: "Cross-Body Shoulder Stretch", sets: 2, reps: "30 sec", focus: "Reduce shoulder tightness before the next set.", icon: "figure.cooldown", priority: .maintenance)
        ]
    case "Front Raises":
        return [
            DrillItem(phase: "Activation", name: "Scapular Reach", sets: 2, reps: "10", focus: "Prepare the shoulder to move forward without shrugging.", icon: "figure.arms.open", priority: .moderate),
            DrillItem(phase: "Drill", name: "Alternating Front Raise", sets: 3, reps: "8 each", focus: "Track one wrist at a time to shoulder height with a soft elbow.", icon: "arrow.up.forward", priority: .critical),
            DrillItem(phase: "Drill", name: "Wall Front Raise", sets: 3, reps: "6", focus: "Keep the torso still while the arm angle changes.", icon: "rectangle.portrait", priority: .moderate),
            DrillItem(phase: "Mobility", name: "Pec Doorway Stretch", sets: 2, reps: "30 sec", focus: "Open the chest so the shoulders start neutral.", icon: "figure.cooldown", priority: .maintenance)
        ]
    case "Arm Extensions":
        return [
            DrillItem(phase: "Activation", name: "Triceps Isometric Press", sets: 2, reps: "15 sec", focus: "Wake up elbow extension without shoulder movement.", icon: "hand.raised", priority: .moderate),
            DrillItem(phase: "Drill", name: "Pinned-Elbow Extension", sets: 3, reps: "8", focus: "Keep the upper arm stable while the elbow opens and closes.", icon: "dumbbell", priority: .critical),
            DrillItem(phase: "Drill", name: "End-Range Hold", sets: 3, reps: "5 sec", focus: "Pause at full extension so the lockout is visible.", icon: "pause.circle", priority: .moderate),
            DrillItem(phase: "Mobility", name: "Overhead Triceps Stretch", sets: 2, reps: "30 sec", focus: "Restore comfortable elbow flexion for the next set.", icon: "figure.cooldown", priority: .maintenance)
        ]
    case "Upright Rows":
        return [
            DrillItem(phase: "Activation", name: "Scapular Shrug Reset", sets: 2, reps: "10", focus: "Find a controlled shoulder blade position before pulling.", icon: "figure.arms.open", priority: .moderate),
            DrillItem(phase: "Drill", name: "Elbow-Led Row", sets: 3, reps: "8", focus: "Pull with elbows first and keep both sides level.", icon: "arrow.up", priority: .critical),
            DrillItem(phase: "Drill", name: "Mirror Tempo Row", sets: 3, reps: "6", focus: "Move slowly enough to catch uneven elbow height.", icon: "metronome", priority: .moderate),
            DrillItem(phase: "Mobility", name: "Upper Trap Release", sets: 2, reps: "30 sec", focus: "Reduce neck tension before the next row set.", icon: "figure.cooldown", priority: .maintenance)
        ]
    default:
        return [
            DrillItem(phase: "Activation", name: "Scapular Push-Up", sets: 3, reps: "10", focus: "Set the shoulder blades so the upper body tracks cleanly.", icon: "figure.arms.open", priority: .critical),
            DrillItem(phase: "Drill", name: "Incline Push-Up", sets: 4, reps: "8", focus: "Keep shoulders, elbows, wrists, and waist visible while reducing load.", icon: "figure.strengthtraining.traditional", priority: .critical),
            DrillItem(phase: "Drill", name: "Bottom Position Pause", sets: 3, reps: "5 sec", focus: "Pause with elbows bent and wrists under shoulders before pressing up.", icon: "pause.circle", priority: .moderate),
            DrillItem(phase: "Mobility", name: "Pec Doorway Stretch", sets: 2, reps: "30 sec", focus: "Open the chest so shoulders stay aligned during reps.", icon: "figure.cooldown", priority: .maintenance)
        ]
    }
}

// =====================================================
// MARK: - Main View
// =====================================================

struct DrillPlanView: View {

    @Environment(\.dismiss) private var dismiss

    // Plan metadata
    let exerciseName: String
    let formScore: Double
    let issueCount: Int
    @State private var showSavedConfirmation = false

    private var drills: [DrillItem] {
        drillPlan(for: exerciseName)
    }

    // Group drills by phase
    private var phases: [(String, [DrillItem])] {
        var result: [(String, [DrillItem])] = []
        var seen: [String: Int] = [:]
        for drill in drills {
            if let idx = seen[drill.phase] {
                result[idx].1.append(drill)
            } else {
                seen[drill.phase] = result.count
                result.append((drill.phase, [drill]))
            }
        }
        return result
    }

    // ปรับปรุง Initializer ให้รับ Double
    init(
        exerciseName: String = "Push-Ups",
        formScore: Double = 0.70, // รับเป็น 0.0 - 1.0
        issueCount: Int = 2
    ) {
        self.exerciseName = exerciseName
        self.formScore = formScore
        self.issueCount = issueCount
    }

    // MARK: - Body

    var body: some View {

        ZStack(alignment: .top) {

            Color.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {

                VStack(alignment: .leading, spacing: 0) {

                    Color.clear.frame(height: 104)

                    // ── Header ─────────────────────────
                    headerSection
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    // ── Plan Overview Card ─────────────
                    planOverviewCard
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    // ── Drills by Phase ────────────────
                    VStack(alignment: .leading, spacing: 28) {

                        ForEach(phases, id: \.0) { phase, drills in

                            PhaseSection(phase: phase, drills: drills)
                        }
                    }
                    .padding(.top, 28)

                    // ── Save CTA ───────────────────────
                    PrimaryButton(title: "Save to My Plan") {
                        showSavedConfirmation = true
                    }
                        .padding(.horizontal, 24)
                        .padding(.top, 32)

                    Color.clear.frame(height: 132)
                }
            }

            // Top Bar
            drillTopBar
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .alert("Plan saved", isPresented: $showSavedConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your drill plan is ready for the next training session.")
        }
    }
}

// =====================================================
// MARK: - Sections
// =====================================================

extension DrillPlanView {

    // MARK: Top Bar

    private var drillTopBar: some View {

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
        .padding(.top, 48)
        .frame(height: 104, alignment: .top)
        .background(
            Color.surface.opacity(0.8)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }

    // MARK: Header

    private var headerSection: some View {

        VStack(alignment: .leading, spacing: 6) {

            MetadataLabel(text: exerciseName, color: .primary)
                .tracking(2)

            Text("Correction\nDrill Plan")
                .font(.system(size: 48, weight: .black))
                .tracking(-1.5)
                .foregroundColor(.onSurface)
                .lineSpacing(2)

            MetadataLabel(
                text: "\(drills.count) drills · \(issueCount) issues targeted",
                color: .outline
            )
            .tracking(2)
            .padding(.top, 4)
        }
    }

    // MARK: Plan Overview Card

    private var planOverviewCard: some View {

        HStack(spacing: 0) {

            OverviewStat(
                label: "Form Score",
                value: "\(Int(formScore * 100))%", // แปลงจาก 0.7 เป็น 70%
                icon: "checkmark.seal.fill",
                color: scoreColor
            )

            Divider()
                .background(Color.outlineVariant.opacity(0.2))
                .padding(.vertical, 16)

            OverviewStat(
                label: "Issues",
                value: "\(issueCount)",
                icon: "exclamationmark.triangle.fill",
                color: .tertiary
            )

            Divider()
                .background(Color.outlineVariant.opacity(0.2))
                .padding(.vertical, 16)

            OverviewStat(
                label: "Drills",
                value: "\(drills.count)",
                icon: "list.bullet.clipboard.fill",
                color: .primary
            )
        }
        .padding(.vertical, 8)
        .background(Color.containerLow)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var scoreColor: Color {
        let scorePercent = formScore * 100
        if scorePercent >= 85 { return .primary }
        if scorePercent >= 65 { return .tertiary }
        return Color(hex: "#FF6B6B")
    }
}

// =====================================================
// MARK: - Overview Stat
// =====================================================

private struct OverviewStat: View {

    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {

        VStack(spacing: 8) {

            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.onSurface)

            MetadataLabel(text: label, color: .outline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// =====================================================
// MARK: - Phase Section
// =====================================================

private struct PhaseSection: View {

    let phase: String
    let drills: [DrillItem]

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            // Phase label
            HStack(spacing: 10) {

                Rectangle()
                    .fill(phaseColor)
                    .frame(width: 3, height: 16)
                    .clipShape(Capsule())

                MetadataLabel(text: phase, color: phaseColor)
                    .tracking(2)
            }
            .padding(.horizontal, 24)

            // Drill cards
            VStack(spacing: 10) {
                ForEach(drills) { drill in
                    DrillCard(drill: drill)
                        .padding(.horizontal, 24)
                }
            }
        }
    }

    private var phaseColor: Color {
        switch phase {
        case "Activation": return .primary
        case "Drill":      return .tertiary
        default:           return Color(hex: "#4CAF82")
        }
    }
}

// =====================================================
// MARK: - Drill Card
// =====================================================

private struct DrillCard: View {

    let drill: DrillItem
    @State private var expanded = false

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            // ── Main Row ──────────────────────────
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    expanded.toggle()
                }
            } label: {

                HStack(spacing: 14) {

                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.containerHigh)
                            .frame(width: 46, height: 46)

                        Image(systemName: drill.icon)
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(drill.priority.color)
                    }

                    // Name + sets×reps
                    VStack(alignment: .leading, spacing: 4) {

                        Text(drill.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.onSurface)

                        HStack(spacing: 8) {

                            MetadataLabel(
                                text: "\(drill.sets) sets × \(drill.reps)",
                                color: .onSurfaceVariant
                            )

                            Text("·")
                                .foregroundColor(.outline)

                            Text(drill.priority.label)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(drill.priority.color)
                        }
                    }

                    Spacer()

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.outline)
                }
                .padding(14)
            }
            .buttonStyle(ScaleButtonStyle())

            // ── Expanded Focus Detail ─────────────
            if expanded {

                Color.outlineVariant.opacity(0.15)
                    .frame(height: 1)
                    .padding(.horizontal, 14)

                HStack(spacing: 10) {

                    Image(systemName: "scope")
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(.outline)

                    Text(drill.focus)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.onSurfaceVariant)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.containerLow)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    expanded
                    ? drill.priority.color.opacity(0.2)
                    : Color.white.opacity(0.04),
                    lineWidth: 1
                )
        )
    }
}

// =====================================================
// MARK: - Preview
// =====================================================

#Preview {
    DrillPlanView(
        exerciseName: "Push-Ups",
        formScore: 0.70,
        issueCount: 2
    )
    .preferredColorScheme(.dark)
}
