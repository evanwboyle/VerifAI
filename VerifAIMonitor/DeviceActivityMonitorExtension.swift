//
  //  DeviceActivityMonitor.swift
  //  VerifAIMonitor
  //

  import DeviceActivity
  import Foundation

  class DeviceActivityMonitor: DeviceActivity.DeviceActivityMonitor {
      override func intervalDidStart(for activity: DeviceActivityName) {
          super.intervalDidStart(for: activity)
          print("[VerifAI] Restriction interval started")
      }

      override func intervalDidEnd(for activity: DeviceActivityName) {
          super.intervalDidEnd(for: activity)
          print("[VerifAI] Restriction interval ended")
      }
  }
