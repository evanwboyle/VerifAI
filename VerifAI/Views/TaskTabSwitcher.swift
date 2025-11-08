import SwiftUI
import CoreData

struct TaskTabSwitcher: View {
    @Environment(\.managedObjectContext) private var context
    @State private var latestTask: TaskEntity? = nil

    var body: some View {
        VStack {
            Group {
                if let task = latestTask, task.startTime != nil {
                    SubmitIterationView()
                } else {
                    NewTaskView()
                }
            }
        }
        .onAppear {
            guard context != nil else {
                return
            }
            let request: NSFetchRequest<TaskEntity> = TaskEntity.fetchRequest()
            request.sortDescriptors = []
            do {
                let tasks = try context.fetch(request)
                latestTask = tasks.first
            } catch {
                // Optionally handle error
            }
        }
    }
}
