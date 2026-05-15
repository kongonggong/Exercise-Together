//
//  ExerciseDetailView.swift
//  Exercise-Together
//
//  Created by Sanpon Soontornnon on 14/5/2569 BE.
//

import SwiftUI
import CoreData

struct ExerciseDetailView: View {

    // MARK: - Properties

    let exercise: CDExercise

    @Environment(\.managedObjectContext)
    private var viewContext

    @EnvironmentObject private var appNavigation: AppNavigationState

    @State private var isSaved: Bool = false
    @State private var isShowingMissingVideoAlert = false

    // MARK: - Body

    var body: some View {

        ZStack(alignment: .top) {

            Color.surface
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {

                VStack(alignment: .leading, spacing: 0) {

                    // Top spacing
                    Color.clear
                        .frame(height: 104)

                    // MARK: - Main Content

                    VStack(alignment: .leading, spacing: 24) {

                        // Exercise Title
                        titleSection

                        // Quick Info
                        infoSection

                        // Description
                        descriptionSection

                        // Target Muscles
                        targetMuscleSection

                        // Action Buttons
                        actionButtons
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    Color.clear
                        .frame(height: 132)
                }
            }

            TopBar(
                isSaved: exercise.isSaved,
                onSave: toggleFavorite
            )
        }
        .navigationBarHidden(true)
        .alert("Video not found", isPresented: $isShowingMissingVideoAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The reference video for this exercise is missing from the app bundle.")
        }
    }
}

// =====================================================
// MARK: - Sections
// =====================================================

extension ExerciseDetailView {

    private var titleSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text(exercise.name ?? "Unknown Exercise")
                .font(.system(size: 40, weight: .black))
                .tracking(-1)
                .foregroundColor(.onSurface)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            HStack(spacing: 10) {

                InfoBadge(
                    title: (exercise.category ?? "").uppercased(),
                    color: .primary
                )

                InfoBadge(
                    title: (exercise.level ?? "").uppercased(),
                    color: .tertiary
                )
            }
        }
    }

    private var infoSection: some View {

        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {

            DetailInfoCard(
                title: "PRIMARY",
                value: exercise.primaryMuscle ?? "-"
            )

            DetailInfoCard(
                title: "TYPE",
                value: "Strength"
            )

            DetailInfoCard(
                title: "MODE",
                value: "Offline"
            )
        }
    }

    private var descriptionSection: some View {

        VStack(alignment: .leading, spacing: 12) {

            sectionTitle("Description")

            Text("""
This movement focuses on developing proper movement mechanics, stability, and controlled execution.

Upload your own movement video to compare against the reference motion and analyze your exercise form precision.
""")
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.onSurfaceVariant)
            .lineSpacing(4)
        }
    }

    private var targetMuscleSection: some View {

        VStack(alignment: .leading, spacing: 14) {

            sectionTitle("Target Muscle")

            HStack {

                MuscleTag(
                    text: exercise.primaryMuscle ?? "-"
                )

                Spacer()
            }
        }
    }

    private var actionButtons: some View {

        VStack(spacing: 14) {

            NavigationLink(destination: FormAnalysisView(initialExercise: analysisExerciseName)) {

                HStack {

                    Image(systemName: "video.fill")

                    Text("Start Form Analysis")
                        .fontWeight(.bold)
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.primary)
                .clipShape(
                    RoundedRectangle(cornerRadius: 18)
                )
            }

            Button {
                if referenceVideoURLForExercise() != nil {
                    appNavigation.openCompare(
                        referenceVideoName: exercise.imageName,
                        referenceTitle: exercise.name ?? "Reference"
                    )
                } else {
                    isShowingMissingVideoAlert = true
                }
            } label: {
                watchReferenceLabel
            }
        }
        .padding(.bottom, 12)
    }

    private var watchReferenceLabel: some View {
        HStack {

            Image(systemName: "play.circle")

            Text("Watch Reference")
                .fontWeight(.semibold)
        }
        .foregroundColor(.onSurface)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(Color.containerLow)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }
}

// =====================================================
// MARK: - Functions
// =====================================================

extension ExerciseDetailView {

    private var analysisExerciseName: String {
        switch exercise.name ?? "" {
        case "Forearm Curl", "Biceps Curl":
            return "Arm Curls"
        case "Shoulder Press":
            return "Shoulder Press"
        case "Lateral Raise":
            return "Lateral Raises"
        case "Front Raise":
            return "Front Raises"
        case "Triceps Extension", "Overhead Triceps Extension":
            return "Arm Extensions"
        case "Incline Row", "Inverted Row":
            return "Upright Rows"
        default:
            return "Push-Ups"
        }
    }

    private func referenceVideoURLForExercise() -> URL? {
        ReferenceVideoLibrary.url(for: exercise.imageName)
    }

    func toggleFavorite() {

        exercise.isSaved.toggle()

        do {

            try viewContext.save()

        } catch {

            print(error.localizedDescription)
        }
    }

    func sectionTitle(_ title: String) -> some View {

        Text(title)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(.onSurface)
    }
}

// =====================================================
// MARK: - Top Bar
// =====================================================

private struct TopBar: View {

    let isSaved: Bool
    let onSave: () -> Void

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {

        HStack {

            Button {

                dismiss()

            } label: {

                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.onSurface)
                    .frame(width: 44, height: 44)
                    .background(Color.containerLow)
                    .clipShape(Circle())
            }

            Spacer()

            Button(action: onSave) {

                Image(
                    systemName:
                        isSaved
                        ? "heart.fill"
                        : "heart"
                )
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(
                    isSaved
                    ? .primary
                    : .onSurface
                )
                .frame(width: 44, height: 44)
                .background(Color.containerLow)
                .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 58)
    }
}

// =====================================================
// MARK: - Detail Info Card
// =====================================================

private struct DetailInfoCard: View {

    let title: String
    let value: String

    var body: some View {

        VStack(alignment: .leading, spacing: 6) {

            MetadataLabel(
                text: title,
                color: .outline
            )
            .tracking(2)

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.onSurface)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.containerLow)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }
}

// =====================================================
// MARK: - Muscle Tag
// =====================================================

private struct MuscleTag: View {

    let text: String

    var body: some View {

        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.containerLow)
            )
    }
}

// =====================================================
// MARK: - Info Badge
// =====================================================

private struct InfoBadge: View {

    let title: String
    let color: Color

    var body: some View {

        Text(title)
            .font(.system(size: 11, weight: .black))
            .tracking(1.5)
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.containerLow)
            )
    }
}

// =====================================================
// MARK: - Preview
// =====================================================
#Preview {

    let context =
        PersistenceController.preview
        .container
        .viewContext

    let exercise = CDExercise(context: context)

    exercise.name = "Biceps Curl"
    exercise.category = "Arms"
    exercise.level = "Intermediate"
    exercise.primaryMuscle = "Biceps"
    exercise.imageName = "biceps-curl"
    exercise.isSaved = true

    return NavigationStack {

        ExerciseDetailView(
            exercise: exercise
        )
    }
    .environment(
        \.managedObjectContext,
         context
    )
    .environmentObject(AppNavigationState())
    .preferredColorScheme(.dark)
}
