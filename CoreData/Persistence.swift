//
//  Persistence.swift
//  Exercise-Together
//

import CoreData

struct PersistenceController {

    // MARK: - Shared

    static let shared = PersistenceController()

    // MARK: - Preview

    static var preview: PersistenceController = {

        let controller = PersistenceController(
            inMemory: true
        )

        let context =
            controller.container.viewContext

        let sample =
            CDExercise(context: context)

        sample.name = "Bench Press"
        sample.category = "Chest"
        sample.level = "Intermediate"
        sample.primaryMuscle = "Pectorals"
        sample.isSaved = true

        do {

            try context.save()

        } catch {

            fatalError(
                "Preview error: \(error)"
            )
        }

        return controller

    }()

    // MARK: - Container

    let container: NSPersistentContainer

    // MARK: - Init

    init(inMemory: Bool = false) {

        container = NSPersistentContainer(
            name: "Exercise_Together"
        )

        // Preview ใช้ in-memory store
        if inMemory {

            container
                .persistentStoreDescriptions
                .first?
                .url = URL(
                    fileURLWithPath: "/dev/null"
                )
        }

        container.loadPersistentStores {
            _, error in

            if let error = error as NSError? {

                fatalError(
                    "Unresolved error \(error)"
                )
            }
        }

        container
            .viewContext
            .automaticallyMergesChangesFromParent = true
    }
}
