//
//  ExerciseSeeder.swift
//  Exercise-Together
//
//  Created by Sanpon Soontornnon on 14/5/2569 BE.
//

import CoreData

struct ExerciseSeeder {

    static func seed(
        context: NSManagedObjectContext
    ) {

        let request: NSFetchRequest<CDExercise> =
            CDExercise.fetchRequest()

        do {

            let count =
                try context.count(for: request)

            // ถ้ามีข้อมูลแล้ว ไม่ต้อง seed ซ้ำ
            if count > 0 {
                return
            }

            // MARK: - Exercise 1

            let bench =
                CDExercise(context: context)

            bench.name = "Bench Press"
            bench.category = "Chest"
            bench.level = "Intermediate"
            bench.primaryMuscle = "Pectorals"
            bench.isSaved = false

            // MARK: - Exercise 2

            let squat =
                CDExercise(context: context)

            squat.name = "Squat"
            squat.category = "Legs"
            squat.level = "Beginner"
            squat.primaryMuscle = "Quadriceps"
            squat.isSaved = true

            // MARK: - Exercise 3

            let deadlift =
                CDExercise(context: context)

            deadlift.name = "Deadlift"
            deadlift.category = "Back"
            deadlift.level = "Advanced"
            deadlift.primaryMuscle = "Hamstrings"
            deadlift.isSaved = false

            try context.save()

            print("✅ Seeded Exercises")

        } catch {

            print(error.localizedDescription)
        }
    }
}
