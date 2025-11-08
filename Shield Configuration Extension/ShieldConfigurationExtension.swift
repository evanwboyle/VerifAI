//
//  ShieldConfigurationExtension.swift
//  Shield Configuration Extension
//
//  Created on 29/05/24.
//  
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        let appName = application.bundleIdentifier // No localizedName available
        let title = ShieldConfiguration.Label(text: "Replacing doomscrolling with blank", color: .label)
        let subtitle = ShieldConfiguration.Label(text: "\(appName ?? "This app") is restricted, go to VerifAI for more details.", color: .secondaryLabel)
        let primaryButtonLabel = ShieldConfiguration.Label(text: "Go to VerifAI", color: .label)
        let secondaryButtonLabel = ShieldConfiguration.Label(text: "Quit App", color: .label)
        let config = ShieldConfiguration(
            backgroundColor: .systemCyan,
            title: title,
            subtitle: subtitle,
            primaryButtonLabel: primaryButtonLabel,
            primaryButtonBackgroundColor: .systemBlue,
            secondaryButtonLabel: secondaryButtonLabel
        )
        return config
    }
    
    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        let appName = application.bundleIdentifier
        let title = ShieldConfiguration.Label(text: "Replacing doomscrolling with blank", color: .label)
        let subtitle = ShieldConfiguration.Label(text: "\(appName ?? "This app") is restricted, go to VerifAI for more details.", color: .secondaryLabel)
        let primaryButtonLabel = ShieldConfiguration.Label(text: "Go to VerifAI", color: .label)
        let secondaryButtonLabel = ShieldConfiguration.Label(text: "Quit App", color: .label)
        let config = ShieldConfiguration(
            backgroundColor: .systemCyan,
            title: title,
            subtitle: subtitle,
            primaryButtonLabel: primaryButtonLabel,
            primaryButtonBackgroundColor: .systemBlue,
            secondaryButtonLabel: secondaryButtonLabel
        )
        return config
    }
    
    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        // Customize the shield as needed for web domains.
        ShieldConfiguration()
    }
    
    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        // Customize the shield as needed for web domains shielded because of their category.
        ShieldConfiguration()
    }
}
