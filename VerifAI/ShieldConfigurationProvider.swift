//
//  ShieldConfigurationProvider.swift
//  VerifAI
//
//  Created by Evan Boyle on 11/7/25.
//

import ManagedSettings
import ManagedSettingsUI
import DeviceActivity
import SwiftUI

class ShieldConfigurationProvider: ShieldConfigurationDataSource {
    func configuration(for application: Application) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 0.9)
        )
    }

    func configuration(for webDomain: WebDomain) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 0.9)
        )
    }

    func configuration(for activity: DeviceActivityName) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterial,
            backgroundColor: UIColor(red: 0.95, green: 0.3, blue: 0.3, alpha: 0.9)
        )
    }
}
