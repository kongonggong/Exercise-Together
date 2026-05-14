//
//  SettingView.swift
//  Exercise-Together
//
//  Created by Sanpon Soontornnon on 14/5/2569 BE.
//

import SwiftUI

// =====================================================
// MARK: - Settings Model
// =====================================================

private enum WeightUnit: String, CaseIterable {
    case lbs = "lbs"
    case kg  = "kg"
}

private enum DistanceUnit: String, CaseIterable {
    case miles = "Miles"
    case km    = "Kilometres"
}

// =====================================================
// MARK: - Main View
// =====================================================

struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss

    // MARK: - Preferences State

    @AppStorage("weightUnit")       private var weightUnit     = WeightUnit.lbs.rawValue
    @AppStorage("distanceUnit")     private var distanceUnit   = DistanceUnit.miles.rawValue
    @AppStorage("hapticEnabled")    private var hapticEnabled  = true
    @AppStorage("autoStopTracking") private var autoStop       = true
    @AppStorage("showSkeletonHint") private var skeletonHint   = true
    @AppStorage("repCounting")      private var repCounting    = true

    // MARK: - Body

    var body: some View {

        ZStack {

            Color.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {

                VStack(spacing: 0) {

                    Color.clear.frame(height: 8)

                    // ── Header ─────────────────────────
                    headerSection

                    // ── Sections ───────────────────────
                    VStack(spacing: 24) {

                        settingsSection(
                            icon: "figure.strengthtraining.traditional",
                            title: "Workout Preferences",
                            iconColor: .primary
                        ) {
                            unitPicker(
                                label: "Weight Unit",
                                options: WeightUnit.allCases.map(\.rawValue),
                                selected: $weightUnit
                            )

                            divider

                            unitPicker(
                                label: "Distance Unit",
                                options: DistanceUnit.allCases.map(\.rawValue),
                                selected: $distanceUnit
                            )
                        }

                        settingsSection(
                            icon: "camera.viewfinder",
                            title: "Tracking",
                            iconColor: .tertiary
                        ) {
                            toggleRow(
                                label: "Rep Counting",
                                sublabel: "Count repetitions automatically during sessions",
                                value: $repCounting
                            )

                            divider

                            toggleRow(
                                label: "Auto-Stop on Inactivity",
                                sublabel: "Stop tracking after 10 seconds of no movement",
                                value: $autoStop
                            )

                            divider

                            toggleRow(
                                label: "Show Skeleton Overlay",
                                sublabel: "Display joint skeleton when camera is idle",
                                value: $skeletonHint
                            )
                        }

                        settingsSection(
                            icon: "hand.tap.fill",
                            title: "Accessibility",
                            iconColor: Color(hex: "#4CAF82")
                        ) {
                            toggleRow(
                                label: "Haptic Feedback",
                                sublabel: "Vibrate on rep count and form alerts",
                                value: $hapticEnabled
                            )
                        }

                        settingsSection(
                            icon: "info.circle.fill",
                            title: "About",
                            iconColor: .outline
                        ) {
                            infoRow(label: "Version",     value: "1.0.0")
                            divider
                            infoRow(label: "Build",       value: "2025.1")
                            divider
                            infoRow(label: "Model",       value: "Vision + CoreML")
                        }
                    }
                    .padding(.horizontal, 24)

                    // ── Reset ──────────────────────────
                    resetButton
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    Color.clear.frame(height: 48)
                }
            }
        }
    }
}

// =====================================================
// MARK: - Sections
// =====================================================

extension SettingsView {

    // MARK: Header

    private var headerSection: some View {

        HStack(alignment: .top) {

            VStack(alignment: .leading, spacing: 6) {

                Text("Settings")
                    .font(.system(size: 34, weight: .black))
                    .tracking(-1)
                    .foregroundColor(.onSurface)

                MetadataLabel(text: "Preferences & Configuration", color: .outline)
                    .tracking(2)
            }

            Spacer()

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.outline)
                    .frame(width: 40, height: 40)
                    .background(Color.containerLow)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 28)
    }

    // MARK: Settings Section Card

    @ViewBuilder
    private func settingsSection<Content: View>(
        icon: String,
        title: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {

        VStack(alignment: .leading, spacing: 0) {

            // Section Header
            HStack(spacing: 10) {

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(iconColor)
                    .frame(width: 20)

                MetadataLabel(text: title, color: .onSurfaceVariant)
                    .tracking(1.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Color.outlineVariant.opacity(0.15)
                .frame(height: 1)

            content()
        }
        .background(Color.containerLow)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: Unit Picker Row

    @ViewBuilder
    private func unitPicker(
        label: String,
        options: [String],
        selected: Binding<String>
    ) -> some View {

        HStack {

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.onSurface)

            Spacer()

            HStack(spacing: 4) {
                ForEach(options, id: \.self) { option in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                            selected.wrappedValue = option
                        }
                    } label: {
                        Text(option)
                            .font(.system(
                                size: 12,
                                weight: selected.wrappedValue == option ? .bold : .medium
                            ))
                            .foregroundColor(
                                selected.wrappedValue == option ? Color(hex: "#002957") : .outline
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        selected.wrappedValue == option
                                        ? Color.primary
                                        : Color.containerHighest
                                    )
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: Toggle Row

    @ViewBuilder
    private func toggleRow(
        label: String,
        sublabel: String,
        value: Binding<Bool>
    ) -> some View {

        HStack(alignment: .top, spacing: 12) {

            VStack(alignment: .leading, spacing: 3) {

                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.onSurface)

                Text(sublabel)
                    .font(.system(size: 12))
                    .foregroundColor(.onSurfaceVariant)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: value)
                .labelsHidden()
                .tint(.primary)
                .scaleEffect(0.85)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: Info Row

    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {

        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.onSurface)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.outline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: Divider

    private var divider: some View {
        Color.outlineVariant.opacity(0.15)
            .frame(height: 1)
            .padding(.leading, 16)
    }

    // MARK: Reset Button

    private var resetButton: some View {

        Button {
            // Reset all AppStorage keys
            UserDefaults.standard.removeObject(forKey: "weightUnit")
            UserDefaults.standard.removeObject(forKey: "distanceUnit")
            UserDefaults.standard.removeObject(forKey: "hapticEnabled")
            UserDefaults.standard.removeObject(forKey: "autoStopTracking")
            UserDefaults.standard.removeObject(forKey: "showSkeletonHint")
            UserDefaults.standard.removeObject(forKey: "repCounting")
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .medium))
                Text("Reset to Defaults")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(Color(hex: "#FF6B6B"))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(hex: "#FF6B6B").opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(hex: "#FF6B6B").opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// =====================================================
// MARK: - Preview
// =====================================================

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
