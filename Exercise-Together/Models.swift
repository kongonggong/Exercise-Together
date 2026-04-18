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

// MARK: - Sample Data

extension WorkoutSession {
    static let samples: [WorkoutSession] = [
        WorkoutSession(name: "Heavy Leg Day",     dayTime: "MON • 08:45 AM", duration: 72, volumeLbs: 12450, icon: "figure.strengthtraining.traditional"),
        WorkoutSession(name: "Upper Body Push",   dayTime: "WED • 07:00 AM", duration: 58, volumeLbs: 9800,  icon: "figure.arms.open"),
        WorkoutSession(name: "Olympic Pulls",     dayTime: "FRI • 06:30 AM", duration: 90, volumeLbs: 15200, icon: "figure.gymnastics"),
    ]
}

extension Exercise {
    static let samples: [Exercise] = [
        Exercise(name: "Barbell Squat",  category: .compounds,  primaryMuscle: "Quads",     level: .advanced,     imageName: "exercise_squat"),
        Exercise(name: "Bench Press",    category: .compounds,  primaryMuscle: "Chest",     level: .intermediate, imageName: "exercise_bench"),
        Exercise(name: "Bicep Curl",     category: .isolations, primaryMuscle: "Biceps",    level: .beginner,     imageName: "exercise_curl"),
        Exercise(name: "Deadlift",       category: .compounds,  primaryMuscle: "Posterior", level: .expert,       imageName: "exercise_deadlift"),
        Exercise(name: "Lateral Raise",  category: .isolations, primaryMuscle: "Deltoids",  level: .beginner,     imageName: "exercise_lateral"),
        Exercise(name: "Pull-Up",        category: .compounds,  primaryMuscle: "Lats",      level: .intermediate, imageName: "exercise_pullup"),
    ]
}

extension ChecklistItem {
    static let squatChecklist: [ChecklistItem] = [
        ChecklistItem(title: "Neutral Spine Alignment", status: .optimal),
        ChecklistItem(title: "Hip Crease Depth",        status: .pending),
        ChecklistItem(title: "Knee Tracking",           status: .needsCorrection),
        ChecklistItem(title: "Weight Distribution",     status: .optimal),
    ]
}

extension CompareIssue {
    static let squatIssues: [CompareIssue] = [
        CompareIssue(type: .warning, title: "Hip Elevation",       description: "Hips rise before bar breaks floor. Drive chest up simultaneously."),
        CompareIssue(type: .passed,  title: "Shoulder Position",   description: "Bar path and shoulder alignment matches reference closely."),
    ]
}
