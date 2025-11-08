class SharedData {
    static let defaultsGroup: UserDefaults? = UserDefaults(suiteName: "group.com.b4k3r.FirebaseTest.sharedData")
    
    enum Keys: String {
        case isUserPremium = "isUserPremiumKey"
        
        var key: String {
            switch self {
            default: self.rawValue
            }
        }
    }
}