import Foundation

class UserTask {
    var userPrompt: String
    var rubric: String?
    var iterations: Int
    var iterationSet: [Iteration]
    var startTime: Date?
    var MinsUntilRestricting: Int?
    var restricting: Bool 

    init(userPrompt: String, rubric: String? = nil, iterations: Int = 0, iterationSet: [Iteration], startTime: Date? = nil, MinsUntilRestricting: Int? = \(defaultTime)) {
        self.userPrompt = userPrompt
        self.rubric = rubric
        self.iterations = iterations
        self.iterationSet = iterationSet
        self.startTime = startTime
        self.MinsUntilRestricting = MinsUntilRestricting
        self.restricting = false
    }
    
    var description: String {
        return "Task(userPrompt: \(userPrompt), iterations: \(iterations), rubric: \(rubric ?? "nil"), iterationSet: \(iterationSet), startTime: \(startTime?.description ?? "nil"), MinsUntilRestricting: \(MinsUntilRestricting ?? 0), restricting: \(restricting))"
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

func addNewTask(to taskList: UserTaskList, userPrompt: String, iterations: Int, MinsUntilRestricting: Int?, beforeImage: Data?) {
    let task = UserTask(userPrompt: userPrompt, iterations: iterations, iterationSet: [], MinsUntilRestricting: MinsUntilRestricting)
    var rubric: String? = nil
    if beforeImage != nil {
        var initialstate: String? = nil
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

func updateTaskWithIteration(task: UserTask, imageData: Data) {
    guard let iterationIndex = task.iterationSet.firstIndex(where: { $0.currentState == nil }) else {
        print("No iteration with nil currentState found.")
        return
    }
    let previousState: String
    if iterationIndex == 0 {
        previousState = ""
    } else {
        previousState = task.iterationSet[iterationIndex - 1].currentState ?? ""
    }
    let systemPrompt: String
    if previousState.isEmpty {
        systemPrompt = "You are an expert at evaluating progress towards goals. Given the user's prompt and the current image, respond with two XML tags: <currentstate>, which contains a 1-2 sentence description of the current state of the image, especially as it relates to the rubric, and <passed>, which is either 'yes' or 'no' indicating whether the current state meets the rubric criteria. Since there is no previous state, focus on describing the current state in isolation. Respond with ONLY Yes or no. Never respond with anything else. Be a bit generous."
    } else {
        systemPrompt = "You are an expert at evaluating progress towards goals. Given the user's prompt, the current image, and the previous state: '\(previousState)', respond with two XML tags: <currentstate>, which contains a 1-2 sentence description of the current state of the image, especially as it relates to the rubric and the progress made from the previous state, and <passed>, which is either 'yes' or 'no' indicating whether the current state meets the rubric criteria. Respond with ONLY Yes or no. Never respond with anything else. Be a bit generous."
    }
    GrokService.shared.callGrokAPI(message: task.userPrompt, imageData: imageData, systemPrompt: systemPrompt) { result in
        switch result {
        case .success(let output):
            if let currentState = extractXMLTag(output, tag: "currentstate"),
               let passed = extractXMLTag(output, tag: "passed") {
            if passed.lowercased() == "yes" {
                    task.iterationSet[iterationIndex].currentState = currentState
                    print("Iteration \(iterationIndex) updated with currentState: \(currentState)")
                    return true
                } else if passed.lowercased() == "no" {
                    print("Iteration \(iterationIndex) did not pass the rubric criteria.")
                    return false
                
                }
            } else if passed.lowercased() == "no" {
                print("Iteration \(iterationIndex) did not pass the rubric criteria.")
            } else {
                print("Failed to extract currentState or passed from Grok API response.")
            }
               
        case .failure(let error):
            print("Grok API error: \(error)")
            // Handle error as needed
        }
    }
    
}
