//
//  RestrictionsManager.swift
//  VerifAI
//
//  Created by Evan Boyle on 11/7/25.
//

import Foundation
import FamilyControls
import ManagedSettings
import ManagedSettingsUI
import DeviceActivity
import os.log

typealias ApplicationToken = ManagedSettings.ApplicationToken

class RestrictionsManager: ObservableObject {
    static let shared = RestrictionsManager()

    @Published var activitySelection = FamilyActivitySelection()
    @Published var isMonitoring = false
    @Published var statusMessage = "Ready to configure restrictions"

    private let storeName = ManagedSettingsStore.Name("verifaiRestrictions")
    private let activityName = DeviceActivityName("verifaiBlockingSchedule")
    private let logger = Logger(subsystem: "com.verifai", category: "RestrictionsManager")

    // MARK: - Configuration

    func configureRestrictions() {
        // Use App Groups container for inter-process communication with extension
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.verifai.screentime") else {
            logger.error("❌ Failed to access App Groups container")
            statusMessage = "Failed to access App Groups container"
            return
        }

        var store = ManagedSettingsStore(named: storeName)

        // Apply restrictions based on selection
        // Extract and set application tokens
        let applicationTokens: Set<ApplicationToken> = Set(
            activitySelection.applications.compactMap { $0.token }
        )

        logger.info("📝 Configuring restrictions with \(applicationTokens.count) apps")
        logger.info("📁 Using App Groups container: \(container.path)")

        if !applicationTokens.isEmpty {
            store.shield.applications = applicationTokens
            logger.info("🔒 Shield applications set: \(applicationTokens.count)")
            statusMessage = "Restrictions configured for \(applicationTokens.count) app(s)"
        } else {
            logger.info("⚠️ No apps selected for restriction")
            statusMessage = "No apps selected"
        }
    }

    // MARK: - Monitoring Control

    func startMonitoring() async {
        do {
            logger.info("🚀 Starting monitoring...")

            // Create a 24/7 schedule
            let schedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
                intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
                repeats: true
            )

            let center = DeviceActivityCenter()
            logger.info("📅 Schedule created: 24/7")
            try await center.startMonitoring(activityName, during: schedule)
            logger.info("✅ Monitoring started successfully for activity: \(self.activityName.rawValue)")

            DispatchQueue.main.async {
                self.isMonitoring = true
                self.statusMessage = "✅ Monitoring active - Apps are now restricted!"
            }
        } catch {
            logger.error("❌ Failed to start monitoring: \(error.localizedDescription)")
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
