//
//  AddExerciseView.swift
//  Exercise-Together
//
//  Sheet form for adding a new exercise to the Library.
//  Uses the app's DesignSystem colours, typography, and components.
//

import SwiftUI

struct AddExerciseView: View {

    // MARK: - Callback

    let onAdd: (String, String, String, String) -> Void

    // MARK: - Environment

    @Environment(\.dismiss)
    private var dismiss

    // MARK: - Form State

    @State private var name: String = ""
    @State private var selectedCategory: ExerciseCategory = .compounds
    @State private var primaryMuscle: String = ""
    @State private var selectedLevel: DifficultyLevel = .beginner

    // MARK: - Validation

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !primaryMuscle.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Body

    var body: some View {

        ZStack {

            Color.surface
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {

                VStack(alignment: .leading, spacing: 32) {

                    // ── Sheet Handle spacer ──
                    Color.clear.frame(height: 8)

                    // ── Header ──────────────
                    headerSection

                    // ── Name ────────────────
                    formField(
                        label: "Movement Name",
                        placeholder: "e.g. Biceps Curl"
                    ) {
                        FormTextField(
                            placeholder: "e.g. Biceps Curl",
                            text: $name
                        )
                    }

                    // ── Category ────────────
                    formField(label: "Category", placeholder: nil) {
                        CategorySelector(selected: $selectedCategory)
                    }

                    // ── Primary Muscle ───────
                    formField(
                        label: "Primary Muscle",
                        placeholder: "e.g. Biceps"
                    ) {
                        FormTextField(
                            placeholder: "e.g. Biceps",
                            text: $primaryMuscle
                        )
                    }

                    // ── Difficulty Level ─────
                    formField(label: "Difficulty Level", placeholder: nil) {
                        LevelSelector(selected: $selectedLevel)
                    }

                    // ── Preview Card ─────────
                    if !name.isEmpty {
                        previewCard
                    }

                    // ── Action Buttons ───────
                    actionButtons

                    Color.clear.frame(height: 24)
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// =====================================================
// MARK: - Sections
// =====================================================

extension AddExerciseView {

    // MARK: Header

    private var headerSection: some View {

        HStack(alignment: .top) {

            VStack(alignment: .leading, spacing: 6) {

                Text("New Movement")
                    .font(.system(size: 34, weight: .black))
                    .tracking(-1)
                    .foregroundColor(.onSurface)

                MetadataLabel(
                    text: "Add to your library",
                    color: .outline
                )
                .tracking(2)
            }

            Spacer()

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.outline)
                    .frame(width: 40, height: 40)
                    .background(Color.containerLow)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: Preview Card

    private var previewCard: some View {

        VStack(alignment: .leading, spacing: 12) {

            MetadataLabel(
                text: "Preview",
                color: .outline
            )
            .tracking(2)

            HStack(spacing: 16) {

                // Thumbnail placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.containerHigh)
                        .frame(width: 72, height: 72)

                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundColor(Color.outline.opacity(0.4))
                }

                VStack(alignment: .leading, spacing: 6) {

                    Text(name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.onSurface)
                        .lineLimit(1)

                    HStack(spacing: 8) {

                        Text(selectedCategory.rawValue.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .tracking(1.5)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(Color.containerLow)
                            )

                        Text(selectedLevel.rawValue.uppercased())
                            .font(.system(size: 10, weight: .black))
                            .tracking(1.5)
                            .foregroundColor(.tertiary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule().fill(Color.containerLow)
                            )
                    }

                    if !primaryMuscle.isEmpty {
                        MetadataLabel(
                            text: primaryMuscle,
                            color: .onSurfaceVariant
                        )
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(Color.containerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
    }

    // MARK: Action Buttons

    private var actionButtons: some View {

        VStack(spacing: 12) {

            // Primary: Save
            Button {
                guard isFormValid else { return }
                onAdd(
                    name.trimmingCharacters(in: .whitespaces),
                    selectedCategory.rawValue,
                    primaryMuscle.trimmingCharacters(in: .whitespaces),
                    selectedLevel.rawValue
                )
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .bold))

                    Text("Add to Library")
                        .font(.system(size: 14, weight: .black))
                        .tracking(1)
                }
                .foregroundColor(Color(hex: "#002957"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    isFormValid
                    ? LinearGradient.primaryGradient
                    : LinearGradient(
                        colors: [Color.containerHighest, Color.containerHigh],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(!isFormValid)
            .animation(.easeInOut(duration: 0.2), value: isFormValid)

            // Secondary: Cancel
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.outline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.containerLow)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    // MARK: - Form Field Wrapper

    @ViewBuilder
    private func formField<Content: View>(
        label: String,
        placeholder: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {

        VStack(alignment: .leading, spacing: 10) {

            MetadataLabel(
                text: label,
                color: .outline
            )
            .tracking(2)

            content()
        }
    }
}

// =====================================================
// MARK: - Form Text Field
// =====================================================

private struct FormTextField: View {

    let placeholder: String
    @Binding var text: String

    var body: some View {

        TextField(placeholder, text: $text)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.onSurface)
            .autocorrectionDisabled()
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(Color.containerLowest)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        text.isEmpty
                        ? Color.white.opacity(0.05)
                        : Color.primary.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: text.isEmpty)
    }
}

// =====================================================
// MARK: - Category Selector
// =====================================================

private struct CategorySelector: View {

    @Binding var selected: ExerciseCategory

    // exclude .all — users pick a real category
    private let options: [ExerciseCategory] = [
        .compounds, .isolations, .cardio
    ]

    var body: some View {

        HStack(spacing: 8) {

            ForEach(options, id: \.self) { category in

                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        selected = category
                    }
                } label: {

                    Text(category.rawValue)
                        .font(
                            .system(
                                size: 13,
                                weight: selected == category ? .bold : .medium
                            )
                        )
                        .foregroundColor(
                            selected == category ? .primary : .outline
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    selected == category
                                    ? Color.containerHighest
                                    : Color.containerLow
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selected == category
                                    ? Color.primary.opacity(0.25)
                                    : Color.clear,
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
}

// =====================================================
// MARK: - Level Selector
// =====================================================

private struct LevelSelector: View {

    @Binding var selected: DifficultyLevel

    private let levels: [DifficultyLevel] = [
        .beginner, .intermediate, .advanced, .expert
    ]

    private let levelColors: [DifficultyLevel: Color] = [
        .beginner:     Color(hex: "#4CAF82"),   // green
        .intermediate: Color.primary,            // blue
        .advanced:     Color.tertiary,           // orange
        .expert:       Color(hex: "#FF6B6B"),    // red
    ]

    var body: some View {

        VStack(spacing: 8) {

            ForEach(levels, id: \.self) { level in

                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        selected = level
                    }
                } label: {

                    HStack(spacing: 14) {

                        // Color indicator dot
                        Circle()
                            .fill(
                                selected == level
                                ? (levelColors[level] ?? .primary)
                                : Color.outline.opacity(0.3)
                            )
                            .frame(width: 8, height: 8)

                        Text(level.rawValue)
                            .font(
                                .system(
                                    size: 14,
                                    weight: selected == level ? .bold : .medium
                                )
                            )
                            .foregroundColor(
                                selected == level ? .onSurface : .outline
                            )

                        Spacer()

                        if selected == level {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(levelColors[level] ?? .primary)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                selected == level
                                ? Color.containerHighest
                                : Color.containerLow
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                selected == level
                                ? (levelColors[level] ?? .primary).opacity(0.2)
                                : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
}

// =====================================================
// MARK: - Preview
// =====================================================

#Preview {

    AddExerciseView { name, category, muscle, level in
        print("Added: \(name), \(category), \(muscle), \(level)")
    }
    .preferredColorScheme(.dark)
}
