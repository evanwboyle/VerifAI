//
//  PersistenceController.swift
//  VerifAI
//
//  Created by Evan Boyle on 11/8/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "VerifAI") // Must match your .xcdatamodeld filename
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
}
