//
//  RestrictionsManager.swift
//  VerifAI
//
//  Created by Evan Boyle on 11/7/25.
//

import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

typealias ApplicationToken = ManagedSettings.ApplicationToken

class RestrictionsManager: ObservableObject {
    static let shared = RestrictionsManager()

    @Published var activitySelection = FamilyActivitySelection()
    @Published var isMonitoring = false
    @Published var statusMessage = "Ready to configure restrictions"

    private let storeName = ManagedSettingsStore.Name("verifaiRestrictions")
    private let activityName = DeviceActivityName("verifaiBlockingSchedule")

    // MARK: - Configuration

    func configureRestrictions() {
        var store = ManagedSettingsStore(named: storeName)

        // Apply restrictions based on selection
        // Extract and set application tokens
        let applicationTokens: Set<ApplicationToken> = Set(
            activitySelection.applications.compactMap { $0.token }
        )

        if !applicationTokens.isEmpty {
            store.shield.applications = applicationTokens
            statusMessage = "Restrictions configured for \(applicationTokens.count) app(s)"
        } else {
            statusMessage = "No apps selected"
        }
    }

    // MARK: - Monitoring Control

    func startMonitoring() async {
        do {
            // Create a 24/7 schedule
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
                intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
                repeats: true
            )

            let center = DeviceActivityCenter()
            try await center.startMonitoring(activityName, during: schedule)

            DispatchQueue.main.async {
                self.isMonitoring = true
                self.statusMessage = "✅ Monitoring active - Apps are now restricted!"
            }
        } catch {
            DispatchQueue.main.async {
                self.statusMessage = "❌ Failed to start monitoring: \(error.localizedDescription)"
                self.isMonitoring = false
            }
        }
    }

    func stopMonitoring() async {
        do {
            let center = DeviceActivityCenter()
            try await center.stopMonitoring([activityName])

            DispatchQueue.main.async {
                self.isMonitoring = false
                self.statusMessage = "Monitoring stopped"
            }

            // Clear restrictions
            clearRestrictions()
        } catch {
            DispatchQueue.main.async {
                self.statusMessage = "❌ Failed to stop monitoring: \(error.localizedDescription)"
            }
        }
    }

    func clearRestrictions() {
        var store = ManagedSettingsStore(named: storeName)
        store.shield.applications = Set()

        statusMessage = "Restrictions cleared"
    }
}
