import Foundation
import SwiftData

@Model
class TaskSettings {
    var defaultTimeToComplete: Int {
        didSet {
            print("TaskSettings: defaultTimeToComplete changed to", defaultTimeToComplete)
        }
    }
    
    init(defaultTimeToComplete: Int = 30) {
        self.defaultTimeToComplete = defaultTimeToComplete
        print("TaskSettings: loaded with defaultTimeToComplete =", self.defaultTimeToComplete)
    }
}
