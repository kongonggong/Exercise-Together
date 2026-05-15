import CoreData

struct ExerciseSeeder {

    static func seed(context: NSManagedObjectContext) {

        let request: NSFetchRequest<CDExercise> =
            CDExercise.fetchRequest()

        let count = (try? context.count(for: request)) ?? 0

        if count > 0 {
            return
        }

        let exercises: [(String, String, String, String, String)] = [

            (
                "Curl Forearm",
                "Isolations",
                "Forearm",
                "Beginner",
                "2-Curl_Forearm"
            ),

            (
                "Curl Upper Arms",
                "Isolations",
                "Biceps",
                "Beginner",
                "2-Curl_Upper-Arms"
            ),

            (
                "Shoulders",
                "Isolations",
                "Shoulders",
                "Intermediate",
                "3-Shoulders"
            ),

            (
                "Lateral Raise",
                "Isolations",
                "Shoulders",
                "Beginner",
                "4-Lateral-Raise-"
            ),

            (
                "Front Raise",
                "Isolations",
                "Shoulders",
                "Beginner",
                "5-Front-Raise"
            ),

            (
                "Arm Triceps Extension",
                "Isolations",
                "Triceps",
                "Intermediate",
                "6-Arm-Triceps-Extension"
            ),

            (
                "Overhead Triceps Extension",
                "Isolations",
                "Triceps",
                "Intermediate",
                "6-Overhead-Triceps-Extension"
            ),

            (
                "Incline Row",
                "Compounds",
                "Back",
                "Intermediate",
                "7-Incline-Row_Back"
            ),

            (
                "Inverted Row",
                "Compounds",
                "Back",
                "Intermediate",
                "7-Inverted-Row_Back"
            ),

            (
                "Pull Up",
                "Compounds",
                "Back",
                "Advanced",
                "Pull-up_Back"
            )
        ]

        for item in exercises {

            let exercise = CDExercise(context: context)

            exercise.id = UUID()
            exercise.name = item.0
            exercise.category = item.1
            exercise.primaryMuscle = item.2
            exercise.level = item.3

            // ใช้เก็บชื่อ video
            exercise.imageName = item.4

            exercise.isSaved = false
        }

        do {

            try context.save()
            print("Seeder Success")

        } catch {

            print(error.localizedDescription)
        }
    }
}
