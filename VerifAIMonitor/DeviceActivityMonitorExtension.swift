//
  //  DeviceActivityMonitor.swift
  //  VerifAIMonitor
  //

  import DeviceActivity
  import ManagedSettings
  import ManagedSettingsUI
  import UIKit
  import Foundation
  import os.log

  typealias ApplicationToken = ManagedSettings.ApplicationToken

  class DeviceActivityMonitor: DeviceActivity.DeviceActivityMonitor {
      let logger = Logger(subsystem: "com.verifai.monitor", category: "DeviceActivityMonitor")

      override init() {
          super.init()
          logger.info("🔧 DeviceActivityMonitor initialized")
          logger.info("🛡️ ShieldConfigurationProvider is available")

          // Log App Groups access
          if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.verifai.screentime") {
              logger.info("✅ App Groups container accessible: \(container.path)")
          } else {
              logger.error("❌ App Groups container NOT accessible")
          }
      }

      override func intervalDidStart(for activity: DeviceActivityName) {
          super.intervalDidStart(for: activity)
          logger.info("✅ Restriction interval started for activity: \(activity.rawValue)")

          // Access the named store used by the main app
          let storeName = ManagedSettingsStore.Name("verifaiRestrictions")
          let store = ManagedSettingsStore(named: storeName)
          let appCount = store.shield.applications?.count ?? 0
          logger.info("📦 ManagedSettingsStore accessed (named: verifaiRestrictions), shield.applications count: \(appCount)")
      }

      override func intervalDidEnd(for activity: DeviceActivityName) {
          super.intervalDidEnd(for: activity)
          logger.info("❌ Restriction interval ended for activity: \(activity.rawValue)")
      }
  }

  // Shield Configuration Provider
  class ShieldConfigurationProvider: ShieldConfigurationDataSource {
      let logger = Logger(subsystem: "com.verifai.monitor", category: "ShieldConfigurationProvider")

      func configuration(for application: Application) -> ShieldConfiguration {
          logger.info("🛡️ Creating shield configuration for app")
          return ShieldConfiguration(
              backgroundBlurStyle: .systemMaterial,
              backgroundColor: UIColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 0.9)
          )
      }

      func configuration(for webDomain: WebDomain) -> ShieldConfiguration {
          logger.info("🌐 Creating shield configuration for web domain")
          return ShieldConfiguration(
              backgroundBlurStyle: .systemMaterial,
              backgroundColor: UIColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 0.9)
          )
      }

      func configuration(for activity: DeviceActivityName) -> ShieldConfiguration {
          logger.info("⏰ Creating shield configuration for activity: \(activity.rawValue)")
          return ShieldConfiguration(
              backgroundBlurStyle: .systemMaterial,
              backgroundColor: UIColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 0.9)
          )
      }
  }
