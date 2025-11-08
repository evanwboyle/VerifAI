import Foundation

class UserTask {
    var userPrompt: String
    var rubric: String?
    var iterations: Int
    var iterationSet: [Iteration]
    var startTime: Date?
    var endTime: Date?
    var active: Bool {
        return startTime != nil && endTime == nil
    }

    init(userPrompt: String, rubric: String? = nil, iterations: Int = 0, iterationSet: [Iteration], startTime: Date? = nil, endTime: Date? = nil) {
        self.userPrompt = userPrompt
        self.rubric = rubric
        self.iterations = iterations
        self.iterationSet = iterationSet
        self.startTime = startTime
        self.endTime = endTime
    }
    
    var description: String {
        return "Task(userPrompt: \(userPrompt), iterations: \(iterations), rubric: \(rubric ?? "nil"), iterationSet: \(iterationSet), startTime: \(startTime?.description ?? "nil"), endTime: \(endTime?.description ?? "nil"))"
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
    var currentState: String?
    
    init(currentState: String?) {
        self.currentState = currentState
    }
    
    // Note: If `currentState` is empty, the iteration has not run yet.
    var description: String {
        return "Iteration(currentState: \(currentState ?? "nil"))"
    }
}

func getBefore() -> Data? {
    // Placeholder: Implement logic to get the 'before' image
    // Return image data or nil if not available
    return nil
}

func extractXMLTag(_ xml: String, tag: String) -> String? {
    // Simple XML tag extraction
    guard let start = xml.range(of: "<\(tag)>"), let end = xml.range(of: "</\(tag)>") else { return nil }
    return String(xml[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
}

func addNewTask(to taskList: UserTaskList, userPrompt: String, iterations: Int, containsBefore: Bool) {
    let task = UserTask(userPrompt: userPrompt, iterations: iterations, iterationSet: [])
    var rubric: String? = nil
    if containsBefore {
        var initialstate: String? = nil
        var beforeImage: Data? = nil
        // Try to get the before image until successful
        repeat {
            beforeImage = getBefore()
        } while beforeImage == nil
        let systemPrompt = "You are an expert at evaluating progress towards goals. Given the user's prompt and the initial image, respond with two XML tags: <rubric> (a short guideline for measuring progress towards the user's goal) and <initialstate> (a 1-2 sentence description of the initial state of the image, especially as it relates to the rubric)."
        GrokService.shared.callGrokAPI(message: userPrompt, imageData: beforeImage, systemPrompt: systemPrompt) { result in
            switch result {
            case .success(let output):
                rubric = extractXMLTag(output, tag: "rubric")
                initialstate = extractXMLTag(output, tag: "initialstate")
                if let rubric = rubric, let initialstate = initialstate {
                    task.rubric = rubric
                    task.iterationSet.append(Iteration(currentState: initialstate))
                }
            case .failure(let error):
                print("Grok API error: \(error)")
                // Handle error as needed
            }
        }
    } else {
        let systemPrompt = "You are an expert at evaluating progress towards goals. Given the user's prompt, respond with one XML tag: <rubric>, which contains a short guideline for measuring progress towards the user's goal."
        GrokService.shared.callGrokAPI(message: userPrompt, systemPrompt: systemPrompt) { result in
            switch result {
            case .success(let output):
                rubric = extractXMLTag(output, tag: "rubric")
                if let rubric = rubric {
                    task.rubric = rubric
                }
            case .failure(let error):
                print("Grok API error: \(error)")
                // Handle error as needed
            }
        }
    }
    for _ in 1...iterations {
        task.iterationSet.append(Iteration(currentState: nil))
    }
    taskList.items.append(task)
}
