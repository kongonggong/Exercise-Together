// =====================================================
// LibraryView.swift
// หน้า Library — ฐานข้อมูลท่าออกกำลังกาย
// =====================================================

import SwiftUI

struct LibraryView: View {
    // State
    @State private var searchText: String = ""
    @State private var selectedCategory: ExerciseCategory = .all
    @State private var exercises: [Exercise] = Exercise.samples

    // Computed: กรอง exercises ตาม search + category
    private var filteredExercises: [Exercise] {
        exercises.filter { exercise in
            let matchesSearch = searchText.isEmpty
                || exercise.name.localizedCaseInsensitiveContains(searchText)
                || exercise.primaryMuscle.localizedCaseInsensitiveContains(searchText)

            let matchesCategory = selectedCategory == .all
                || exercise.category == selectedCategory

            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Color.clear.frame(height: 64) // Top Bar offset

                    // ── Page Title ────────────────────────
                    LibraryHeaderSection()
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    // ── Search Bar ────────────────────────
                    SearchBar(text: $searchText)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    // ── Category Filter Chips ─────────────
                    CategoryFilterBar(selected: $selectedCategory)
                        .padding(.top, 16)

                    // ── Exercise Grid ─────────────────────
                    ExerciseGrid(exercises: filteredExercises) { index in
                        exercises[exercises.firstIndex(where: { $0.id == filteredExercises[index].id })!].isSaved.toggle()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    Color.clear.frame(height: 32)
                }
            }

            TopAppBar(trailingIcon: "magnifyingglass")
        }
    }
}

// MARK: - Library Header

private struct LibraryHeaderSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Library")
                .font(.system(size: 56, weight: .black))
                .tracking(-2)
                .foregroundColor(.onSurface)

            MetadataLabel(text: "Precision Movement Database", color: .outline)
                .tracking(2.4)
        }
    }
}

// MARK: - Search Bar

private struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.outline)

            TextField("Search movements...", text: $text)
                .font(PerformanceTextStyle.bodyMedium)
                .foregroundColor(.onSurface)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.containerLowest)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Category Filter Bar (Scrollable Chips)

private struct CategoryFilterBar: View {
    @Binding var selected: ExerciseCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Color.clear.frame(width: 18) // Leading inset

                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selected == category
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selected = category
                        }
                    }
                }

                Color.clear.frame(width: 18) // Trailing inset
            }
        }
    }
}

private struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .primary : .outline)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.containerHighest : Color.containerLow)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Exercise Grid (2 คอลัมน์)

private struct ExerciseGrid: View {
    let exercises: [Exercise]
    let onSaveToggle: (Int) -> Void

    // 2-column grid
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
    ]

    var body: some View {
        if exercises.isEmpty {
            EmptySearchState()
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
        } else {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                    ExerciseCard(exercise: exercise) {
                        onSaveToggle(index)
                    }
                }
            }
        }
    }
}

// ── Exercise Card ──────────────────────────────────────

private struct ExerciseCard: View {
    let exercise: Exercise
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Image Area ────────────────────────────
            ZStack(alignment: .bottomLeading) {
                // Placeholder (สีแทน image จริง)
                Rectangle()
                    .fill(Color.containerHigh)
                    .aspectRatio(4/5, contentMode: .fit)
                    .overlay(
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 40, weight: .ultraLight))
                            .foregroundColor(Color.outline.opacity(0.3))
                    )

                // Gradient overlay ด้านล่าง
                LinearGradient(
                    colors: [Color.surface, .clear],
                    startPoint: .bottom,
                    endPoint: UnitPoint(x: 0.5, y: 0.4)
                )

                // Category Badge + Name
                VStack(alignment: .leading, spacing: 4) {
                    MetadataLabel(
                        text: exercise.category.rawValue.uppercased(),
                        color: exercise.category == .compounds ? .primary : .tertiary
                    )
                    .tracking(1.6)

                    Text(exercise.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.onSurface)
                }
                .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 0))

            // ── Card Footer ───────────────────────────
            HStack(alignment: .center) {
                // Muscle + Level
                VStack(alignment: .leading, spacing: 8) {
                    LabeledValue(label: "Primary", value: exercise.primaryMuscle)
                    LabeledValue(label: "Level",   value: exercise.level.rawValue)
                }

                Spacer()

                // Save Button
                Button(action: onSave) {
                    Image(systemName: exercise.isSaved ? "checkmark" : "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(exercise.isSaved ? Color(hex: "#002957") : .onSurface)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle().fill(exercise.isSaved ? Color.primary : Color.white.opacity(0.06))
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(16)
            .background(Color.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

// ── Helper: Labeled stat ────────────────────────────────

private struct LabeledValue: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            MetadataLabel(text: label, color: .outline)
                .font(.system(size: 9, weight: .bold))
                .tracking(2)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.onSurface)
        }
    }
}

// ── Empty State ─────────────────────────────────────────

private struct EmptySearchState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundColor(.outline)
            Text("No movements found")
                .font(PerformanceTextStyle.bodyLarge)
                .foregroundColor(.onSurfaceVariant)
            MetadataLabel(text: "Try a different search term")
        }
    }
}

// MARK: - Preview

#Preview {
    LibraryView()
        .preferredColorScheme(.dark)
}
