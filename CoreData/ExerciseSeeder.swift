import CoreData

struct ExerciseSeeder {

    private struct SeedExercise {
        let name: String
        let category: String
        let primaryMuscle: String
        let level: String
        let imageName: String
    }

    private static let defaultExercises: [SeedExercise] = [
        SeedExercise(name: "Forearm Curl", category: "Isolations", primaryMuscle: "Forearm", level: "Beginner", imageName: "forearm-curl"),
        SeedExercise(name: "Biceps Curl", category: "Isolations", primaryMuscle: "Biceps", level: "Beginner", imageName: "biceps-curl"),
        SeedExercise(name: "Shoulder Press", category: "Isolations", primaryMuscle: "Shoulders", level: "Intermediate", imageName: "shoulder-press"),
        SeedExercise(name: "Lateral Raise", category: "Isolations", primaryMuscle: "Shoulders", level: "Beginner", imageName: "lateral-raise"),
        SeedExercise(name: "Front Raise", category: "Isolations", primaryMuscle: "Shoulders", level: "Beginner", imageName: "front-raise"),
        SeedExercise(name: "Triceps Extension", category: "Isolations", primaryMuscle: "Triceps", level: "Intermediate", imageName: "triceps-extension"),
        SeedExercise(name: "Overhead Triceps Extension", category: "Isolations", primaryMuscle: "Triceps", level: "Intermediate", imageName: "overhead-triceps-extension"),
        SeedExercise(name: "Incline Row", category: "Compounds", primaryMuscle: "Back", level: "Intermediate", imageName: "incline-row"),
        SeedExercise(name: "Inverted Row", category: "Compounds", primaryMuscle: "Back", level: "Intermediate", imageName: "inverted-row"),
        SeedExercise(name: "Pull-Up", category: "Compounds", primaryMuscle: "Back", level: "Advanced", imageName: "pull-up")
    ]

    private static let legacyMockSessionNames = [
        "Heavy Leg Day",
        "Upper Body Push",
        "Olympic Pulls"
    ]

    private static let legacyExerciseNames = [
        "Curl Forearm",
        "Curl Upper Arms",
        "Shoulders",
        "Arm Triceps Extension",
        "Pull Up",
        "Barbell Squat",
        "Bench Press",
        "Bicep Curl",
        "Deadlift"
    ]

    private static let legacyImageNames = [
        "2-Curl_Forearm",
        "2-Curl_Upper-Arms",
        "2-Curl-Upper-Arms",
        "3-Shoulders",
        "4-Lateral-Raise-",
        "5-Front-Raise",
        "6-Arm-Triceps-Extension",
        "6-Overhead-Triceps-Extension",
        "7-Incline-Row_Back",
        "7-Inverted-Row_Back",
        "Pull-up_Back",
        "exercise_squat",
        "exercise_bench",
        "exercise_curl",
        "exercise_deadlift"
    ]

    static func seed(context: NSManagedObjectContext) {
        removeLegacyDashboardSessions(context: context)
        removeLegacyExercises(context: context)
        upsertDefaultExercises(context: context)

        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
    }

    private static func removeLegacyDashboardSessions(context: NSManagedObjectContext) {
        let request: NSFetchRequest<CDWorkoutSession> = CDWorkoutSession.fetchRequest()
        request.predicate = NSPredicate(
            format: "name IN %@ AND volumeLbs > 0",
            legacyMockSessionNames
        )

        guard let sessions = try? context.fetch(request) else { return }
        sessions.forEach(context.delete)
    }

    private static func removeLegacyExercises(context: NSManagedObjectContext) {
        let request: NSFetchRequest<CDExercise> = CDExercise.fetchRequest()
        request.predicate = NSPredicate(
            format: "name IN %@ OR imageName IN %@",
            legacyExerciseNames,
            legacyImageNames
        )

        guard let exercises = try? context.fetch(request) else { return }
        exercises.forEach(context.delete)
    }

    private static func upsertDefaultExercises(context: NSManagedObjectContext) {
        for seed in defaultExercises {
            let exercise = existingExercise(named: seed.name, context: context)
                ?? CDExercise(context: context)

            if exercise.id == nil {
                exercise.id = UUID()
                exercise.isSaved = false
            }

            exercise.name = seed.name
            exercise.category = seed.category
            exercise.primaryMuscle = seed.primaryMuscle
            exercise.level = seed.level
            exercise.imageName = seed.imageName
        }
    }

    private static func existingExercise(
        named name: String,
        context: NSManagedObjectContext
    ) -> CDExercise? {
        let request: NSFetchRequest<CDExercise> = CDExercise.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }
}
