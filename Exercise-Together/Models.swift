// =====================================================
// Models.swift
// โมเดลข้อมูลทั้งหมดของแอป Performance Lab
// =====================================================

import SwiftUI

// MARK: - Dashboard Models

struct WorkoutSession: Identifiable {
    let id = UUID()
    let name: String
    let dayTime: String
    let duration: Int        // นาที
    let volumeLbs: Int
    let icon: String         // SF Symbol name
}

struct PerformanceMetric {
    let label: String
    let value: Double        // 0.0 – 1.0
    var color: Color = .primary
}

// MARK: - Library Models

enum ExerciseCategory: String, CaseIterable {
    case all        = "All"
    case compounds  = "Compounds"
    case isolations = "Isolations"
    case cardio     = "Cardio"
}

enum DifficultyLevel: String {
    case beginner     = "Beginner"
    case intermediate = "Intermediate"
    case advanced     = "Advanced"
    case expert       = "Expert"
}

struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let category: ExerciseCategory
    let primaryMuscle: String
    let level: DifficultyLevel
    let imageName: String    // Asset catalog name
    var isSaved: Bool = false
}

// MARK: - Form Analysis Models

enum ChecklistStatus {
    case optimal
    case pending
    case needsCorrection

    var icon: String {
        switch self {
        case .optimal:          return "checkmark.circle.fill"
        case .pending:          return "checkmark.circle"
        case .needsCorrection:  return "exclamationmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .optimal:          return .primary
        case .pending:          return .onSurfaceVariant
        case .needsCorrection:  return .tertiary
        }
    }

    var label: String {
        switch self {
        case .optimal:          return "Optimal"
        case .pending:          return "Pending"
        case .needsCorrection:  return "Correction Needed"
        }
    }
}

struct ChecklistItem: Identifiable {
    let id = UUID()
    let title: String
    let status: ChecklistStatus
}

// MARK: - Compare Models

enum CompareIssueType {
    case warning
    case passed
}

struct CompareIssue: Identifiable {
    let id = UUID()
    let type: CompareIssueType
    let title: String
    let description: String

    var icon: String {
        switch type {
        case .warning: return "exclamationmark.triangle.fill"
        case .passed:  return "checkmark.circle.fill"
        }
    }

    var iconColor: Color {
        switch type {
        case .warning: return .tertiary
        case .passed:  return .primary
        }
    }
}
