import Foundation
import SwiftData
import os.log

@Model
class TaskSettings {
    var defaultTimeToComplete: Int {
        didSet {
            os_log("TaskSettings: defaultTimeToComplete changed to %d", defaultTimeToComplete)
        }
    }
    
    init(defaultTimeToComplete: Int = 30) {
        self.defaultTimeToComplete = defaultTimeToComplete
        os_log("TaskSettings: loaded with defaultTimeToComplete = %d", defaultTimeToComplete)
    }
}
