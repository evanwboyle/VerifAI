//
//  ShieldViewModel.swift
//  Screen Time
//
//  Created on 29/05/24.
//
//

import Foundation
import FamilyControls
import ManagedSettings
import os.log

private let logger = Logger(subsystemName: "ShieldViewModel", category: "ViewModel")

class ShieldViewModel: ObservableObject {
    @Published var familyActivitySelection = FamilyActivitySelection()
    @Published var isMonitoring = false

    private let store = ManagedSettingsStore.shared

    func shieldActivities() {
        store.shield(familyActivitySelection: familyActivitySelection)
    }

    func unshieldActivities() {
        store.shield(familyActivitySelection: FamilyActivitySelection())
    }

    func clearRestrictions() {
        unshieldActivities()
        familyActivitySelection = FamilyActivitySelection()
        isMonitoring = false
    }
    
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        } catch {
            logger.error("Failed to get authorization: \(error)")
        }
    }
}

