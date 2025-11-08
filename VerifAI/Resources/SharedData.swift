import Foundation
//
//  SharedData.swift
//  VerifAI
//
//  Created by Evan Boyle on 11/8/25.
//


class SharedData {
    static let defaultsGroup: UserDefaults? = UserDefaults(suiteName: "group.com.verifai.screentime.sharedData")
    
    static var activeTask: Bool {
        get {
            return defaultsGroup?.bool(forKey: "activeTask") ?? false
        }
        set {
            defaultsGroup?.set(newValue, forKey: "activeTask")
        }
    }
    }

