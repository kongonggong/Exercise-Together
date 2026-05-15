// =====================================================
// ContentView.swift
// Root View — Tab Navigation หลักของแอป
// =====================================================

import SwiftUI

// MARK: - Tab Definition

enum AppTab: Int, CaseIterable {
    case dashboard    = 0
    case library      = 1
    case formAnalysis = 2
    case compare      = 3

    var icon: String {
        switch self {
        case .dashboard:    return "chart.bar.fill"
        case .library:      return "books.vertical.fill"
        case .formAnalysis: return "figure.walk.motion"
        case .compare:      return "rectangle.split.2x1.fill"
        }
    }

    var label: String {
        switch self {
        case .dashboard:    return "Dashboard"
        case .library:      return "Library"
        case .formAnalysis: return "Form"
        case .compare:      return "Compare"
        }
    }
}

final class AppNavigationState: ObservableObject {
    @Published var selectedTab: AppTab = .dashboard
    @Published var compareReferenceVideoName: String? = "biceps-curl"
    @Published var compareReferenceTitle: String = "Biceps Curl"

    func openCompare(referenceVideoName: String?, referenceTitle: String) {
        compareReferenceVideoName = referenceVideoName
        compareReferenceTitle = referenceTitle

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedTab = .compare
        }
    }
}

// MARK: - Root Content View

struct ContentView: View {
    @StateObject private var appNavigation = AppNavigationState()

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Page Content ──────────────────────────────
            TabView(selection: $appNavigation.selectedTab) {
                DashboardView()
                    .tag(AppTab.dashboard)

                LibraryView()
                    .tag(AppTab.library)

                FormAnalysisView()
                    .tag(AppTab.formAnalysis)

                CompareView(
                    referenceVideoName: appNavigation.compareReferenceVideoName,
                    referenceTitle: appNavigation.compareReferenceTitle
                )
                    .id("\(appNavigation.compareReferenceVideoName ?? "none")-\(appNavigation.compareReferenceTitle)")
                    .tag(AppTab.compare)
            }
            .tabViewStyle(.page(indexDisplayMode: .never)) // Custom tab bar แทน native
            .ignoresSafeArea()

            // ── Custom Tab Bar (Glassmorphic) ─────────────
            CustomTabBar(selectedTab: $appNavigation.selectedTab)
        }
        .preferredColorScheme(.dark)
        .environmentObject(appNavigation)
    }
}

// MARK: - Custom Tab Bar

private struct CustomTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(
            // Glassmorphic bottom bar
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.containerLow.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 8)
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

// ── Individual Tab Bar Item ────────────────────────────

private struct TabBarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Icon
                Image(systemName: tab.icon)
                    .font(.system(size: isSelected ? 20 : 18, weight: isSelected ? .bold : .light))
                    .foregroundColor(isSelected ? .primary : .outline)
                    .scaleEffect(isSelected ? 1.1 : 1.0)

                // Label
                Text(tab.label)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .tracking(0.5)
                    //.foregroundColor(isSelected ? .primary : .outline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
