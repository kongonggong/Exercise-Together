//
//  ExerciseDetailView.swift
//  Exercise-Together
//
//  Created by Sanpon Soontornnon on 14/5/2569 BE.
//

import SwiftUI
import CoreData
import AVKit

struct ExerciseDetailView: View {

    // MARK: - Properties

    let exercise: CDExercise

    @Environment(\.managedObjectContext)
    private var viewContext

    @State private var isSaved: Bool = false

    // MARK: - Body

    var body: some View {

        ZStack(alignment: .top) {

            Color.surface
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {

                VStack(alignment: .leading, spacing: 0) {

                    // Top spacing
                    Color.clear
                        .frame(height: 90)

                    // MARK: - Hero Image

                    HeroSection(exercise: exercise)
                        .padding(.horizontal, 24)

                    // MARK: - Main Content

                    VStack(alignment: .leading, spacing: 28) {

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
                    .padding(.top, 32)

                    Color.clear
                        .frame(height: 40)
                }
            }

            TopBar(
                isSaved: exercise.isSaved,
                onSave: toggleFavorite
            )
        }
        .navigationBarHidden(true)
    }
}

// =====================================================
// MARK: - Sections
// =====================================================

extension ExerciseDetailView {

    private var titleSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text(exercise.name ?? "Unknown Exercise")
                .font(.system(size: 42, weight: .black))
                .tracking(-1.5)
                .foregroundColor(.onSurface)

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

        HStack(spacing: 16) {

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

            Button {

                print("Start Analysis")

            } label: {

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

                print("Watch Reference")

            } label: {

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
    }
}

// =====================================================
// MARK: - Functions
// =====================================================

extension ExerciseDetailView {

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
// MARK: - Hero Section
// =====================================================

private struct HeroSection: View {

    let exercise: CDExercise

    var body: some View {

        ZStack(alignment: .bottomLeading) {

            Rectangle()
                .fill(Color.containerHigh)
                .aspectRatio(4/5, contentMode: .fit)
                .clipShape(
                    RoundedRectangle(cornerRadius: 28)
                )
                .overlay(

                    Image(
                        systemName:
                            "figure.strengthtraining.traditional"
                    )
                    .font(
                        .system(
                            size: 80,
                            weight: .ultraLight
                        )
                    )
                    .foregroundColor(
                        Color.outline.opacity(0.25)
                    )
                )

            LinearGradient(
                colors: [
                    Color.surface,
                    .clear
                ],
                startPoint: .bottom,
                endPoint: UnitPoint(x: 0.5, y: 0.45)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 28)
            )

            VStack(alignment: .leading, spacing: 6) {

                MetadataLabel(
                    text:
                        (exercise.category ?? "")
                        .uppercased(),
                    color: .primary
                )

                Text(exercise.name ?? "")
                    .font(
                        .system(
                            size: 34,
                            weight: .black
                        )
                    )
                    .foregroundColor(.onSurface)
            }
            .padding(24)
        }
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
        .padding(.top, 12)
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

    exercise.name = "Bench Press"
    exercise.category = "Chest"
    exercise.level = "Intermediate"
    exercise.primaryMuscle = "Pectorals"
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
    .preferredColorScheme(.dark)
}
