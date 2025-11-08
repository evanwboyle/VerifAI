import Foundation

class UserTask {
    var userPrompt: String
    var iterations: Int
    var containsBefore: Bool
    var iterationSet: [Iteration]
    var startTime: Date?
    var endTime: Date?
    var active: Bool {
        return startTime != nil && endTime == nil
    }
    
    init(userPrompt: String, iterations: Int, containsBefore: Bool, iterationSet: [Iteration], startTime: Date? = nil, endTime: Date? = nil) {
        self.userPrompt = userPrompt
        self.iterations = iterations
        self.containsBefore = containsBefore
        self.iterationSet = iterationSet
        self.startTime = startTime
        self.endTime = endTime
    }
    
    var description: String {
        return "Task(userPrompt: \(userPrompt), iterations: \(iterations), containsBefore: \(containsBefore), iterationSet: \(iterationSet), startTime: \(startTime?.description ?? "nil"), endTime: \(endTime?.description ?? "nil"), active: \(active))"
    }
}

class UserTaskList {
    var items: [UserTask]
    
    init(items: [UserTask] = []) {
        self.items = items
    }
    
    var description: String {
        return "TaskList(items: \(items))"
    }
}

class Iteration {
    var expectingPrompt: String
    var descriptionPrompt: String?
    
    init(expectingPrompt: String, descriptionPrompt: String? = nil) {
        self.expectingPrompt = expectingPrompt
        self.descriptionPrompt = descriptionPrompt
    }
    
    // Note: If `descriptionPrompt` is empty, the iteration has not run yet.
    var description: String {
        return "Iteration(expectingPrompt: \(expectingPrompt), descriptionPrompt: \(descriptionPrompt ?? "nil"))"
    }
}
