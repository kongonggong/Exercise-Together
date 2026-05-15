//
//  Libraryview.swift
//  Exercise-Together
//
//  ใช้งาน Core Data แทน sample array
//  + NavigationLink to ExerciseDetailView
//  + AddExerciseView sheet
//

import SwiftUI
import CoreData

struct LibraryView: View {

    // MARK: - Core Data

    @Environment(\.managedObjectContext)
    private var viewContext

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\CDExercise.name)]
    ) private var exercises: FetchedResults<CDExercise>


    // MARK: - State

    @State private var searchText: String = ""
    @State private var selectedCategory: ExerciseCategory = .all
    @State private var showAddSheet: Bool = false

    // MARK: - Filtered Exercises

    private var filteredExercises: [CDExercise] {

        exercises.filter { exercise in

            let exerciseName = exercise.name ?? ""
            let primaryMuscle = exercise.primaryMuscle ?? ""

            let matchesSearch =
                searchText.isEmpty
                || exerciseName.localizedCaseInsensitiveContains(searchText)
                || primaryMuscle.localizedCaseInsensitiveContains(searchText)

            let categoryString = exercise.category ?? ""

            let matchesCategory =
                selectedCategory == .all
                || categoryString == selectedCategory.rawValue

            return matchesSearch && matchesCategory
        }
    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack(alignment: .top) {

                Color.surface
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {

                    VStack(alignment: .leading, spacing: 0) {

                        Color.clear
                            .frame(height: 64)

                        // Header
                        LibraryHeaderSection()
                            .padding(.horizontal, 24)
                            .padding(.top, 24)

                        // Search
                        SearchBar(text: $searchText)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)

                        // Category Filter
                        CategoryFilterBar(
                            selected: $selectedCategory
                        )
                        .padding(.top, 16)

                        // Exercise Grid
                        ExerciseGrid(
                            exercises: filteredExercises,
                            onSaveToggle: toggleFavorite
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                        Color.clear
                            .frame(height: 32)
                    }
                }

                // Top App Bar with + button
                TopAppBar(
                    trailingIcon: "plus",
                    trailingAction: { showAddSheet = true }
                )
            }
            
            .sheet(isPresented: $showAddSheet) {
                AddExerciseView(
                    onAdd: { name, category, muscle, level in
                        addExercise(
                            name: name,
                            category: category,
                            primaryMuscle: muscle,
                            level: level,
                            imageName: name
                                .lowercased()
                                .replacingOccurrences(of: " ", with: "_")
                        )
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

// =====================================================
// MARK: - Functions
// =====================================================

extension LibraryView {

    // MARK: - Toggle Favorite

    func toggleFavorite(_ exercise: CDExercise) {

        exercise.isSaved.toggle()

        saveContext()
    }

    // MARK: - Save Context

    func saveContext() {

        do {

            try viewContext.save()

        } catch {

            print(error.localizedDescription)
        }
    }

    // MARK: - Add Exercise

    func addExercise(
        name: String,
        category: String,
        primaryMuscle: String,
        level: String,
        imageName: String
    ) {

        let exercise = CDExercise(context: viewContext)

        exercise.id = UUID()
        exercise.name = name
        exercise.category = category
        exercise.primaryMuscle = primaryMuscle
        exercise.level = level
        exercise.imageName = imageName
        exercise.isSaved = false

        saveContext()
    }
}

// =====================================================
// MARK: - Header
// =====================================================

private struct LibraryHeaderSection: View {

    var body: some View {

        VStack(alignment: .leading, spacing: 6) {

            Text("Library")
                .font(.system(size: 56, weight: .black))
                .tracking(-2)
                .foregroundColor(.onSurface)

            MetadataLabel(
                text: "Precision Movement Database",
                color: .outline
            )
            .tracking(2.4)
        }
    }
}

// =====================================================
// MARK: - Search Bar
// =====================================================

private struct SearchBar: View {

    @Binding var text: String

    var body: some View {

        HStack(spacing: 12) {

            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.outline)

            TextField(
                "Search movements...",
                text: $text
            )
            .font(PerformanceTextStyle.bodyMedium)
            .foregroundColor(.onSurface)
            .autocorrectionDisabled()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.containerLowest)
        .clipShape(
            RoundedRectangle(cornerRadius: 14)
        )
    }
}

// =====================================================
// MARK: - Category Filter
// =====================================================

private struct CategoryFilterBar: View {

    @Binding var selected: ExerciseCategory

    var body: some View {

        ScrollView(.horizontal, showsIndicators: false) {

            HStack(spacing: 6) {

                Color.clear.frame(width: 18)

                ForEach(
                    ExerciseCategory.allCases,
                    id: \.self
                ) { category in

                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selected == category
                    ) {

                        withAnimation(
                            .spring(
                                response: 0.3,
                                dampingFraction: 0.7
                            )
                        ) {
                            selected = category
                        }
                    }
                }

                Color.clear.frame(width: 18)
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
                .font(
                    .system(
                        size: 13,
                        weight: isSelected ? .bold : .medium
                    )
                )
                .foregroundColor(
                    isSelected ? .primary : .outline
                )
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            isSelected
                            ? Color.containerHighest
                            : Color.containerLow
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// =====================================================
// MARK: - Exercise Grid
// =====================================================

private struct ExerciseGrid: View {

    let exercises: [CDExercise]
    let onSaveToggle: (CDExercise) -> Void

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

                ForEach(exercises) { exercise in

                    NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {

                        ExerciseCard(
                            exercise: exercise
                        ) {
                            onSaveToggle(exercise)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// =====================================================
// MARK: - Exercise Card
// =====================================================

private struct ExerciseCard: View {

    let exercise: CDExercise
    let onSave: () -> Void

    var body: some View {

        VStack(alignment: .leading, spacing: 0) {

            // Image Area
            ZStack(alignment: .bottomLeading) {

                Rectangle()
                    .fill(Color.containerHigh)
                    .aspectRatio(4/5, contentMode: .fit)
                    .overlay(
                        Image(
                            systemName:
                                "figure.strengthtraining.traditional"
                        )
                        .font(
                            .system(
                                size: 40,
                                weight: .ultraLight
                            )
                        )
                        .foregroundColor(
                            Color.outline.opacity(0.3)
                        )
                    )

                LinearGradient(
                    colors: [Color.surface, .clear],
                    startPoint: .bottom,
                    endPoint: UnitPoint(x: 0.5, y: 0.4)
                )

                VStack(alignment: .leading, spacing: 4) {

                    MetadataLabel(
                        text:
                            (exercise.category ?? "")
                            .uppercased(),
                        color: .primary
                    )
                    .tracking(1.6)

                    Text(exercise.name ?? "")
                        .font(
                            .system(
                                size: 20,
                                weight: .bold
                            )
                        )
                        .foregroundColor(.onSurface)
                }
                .padding(16)
            }

            // Footer
            HStack(alignment: .center) {

                VStack(alignment: .leading, spacing: 8) {

                    LabeledValue(
                        label: "Primary",
                        value:
                            exercise.primaryMuscle ?? ""
                    )

                    LabeledValue(
                        label: "Level",
                        value:
                            exercise.level ?? ""
                    )
                }

                Spacer()

                Button(action: onSave) {

                    Image(
                        systemName:
                            exercise.isSaved
                            ? "checkmark"
                            : "plus"
                    )
                    .font(
                        .system(
                            size: 16,
                            weight: .medium
                        )
                    )
                    .foregroundColor(
                        exercise.isSaved
                        ? Color(hex: "#002957")
                        : .onSurface
                    )
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(
                            exercise.isSaved
                            ? Color.primary
                            : Color.white.opacity(0.06)
                        )
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(16)
            .background(Color.surface)
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    Color.white.opacity(0.05),
                    lineWidth: 1
                )
        )
    }
}

// =====================================================
// MARK: - Helper
// =====================================================

private struct LabeledValue: View {

    let label: String
    let value: String

    var body: some View {

        VStack(alignment: .leading, spacing: 1) {

            MetadataLabel(
                text: label,
                color: .outline
            )
            .font(.system(size: 9, weight: .bold))
            .tracking(2)

            Text(value)
                .font(
                    .system(
                        size: 12,
                        weight: .medium
                    )
                )
                .foregroundColor(.onSurface)
        }
    }
}

// =====================================================
// MARK: - Empty State
// =====================================================

private struct EmptySearchState: View {

    var body: some View {

        VStack(spacing: 16) {

            Image(systemName: "magnifyingglass")
                .font(
                    .system(
                        size: 36,
                        weight: .ultraLight
                    )
                )
                .foregroundColor(.outline)

            Text("No movements found")
                .font(
                    PerformanceTextStyle.bodyLarge
                )
                .foregroundColor(.onSurfaceVariant)

            MetadataLabel(
                text: "Try a different search term"
            )
        }
    }
}

// =====================================================
// MARK: - Preview
// =====================================================

#Preview {

    LibraryView()
        .preferredColorScheme(.dark)
}
