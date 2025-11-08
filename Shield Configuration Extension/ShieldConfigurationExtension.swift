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
import SwiftUICore

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.

class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    var subtitleText: String {
        if SharedData.activeTask {
            return "App is being blocked by VerifAI. You have an active task!! Go to VerifAI to complete the task."
        } else {
            return "App is being blocked by VerifAI. Go to VerifAI to create a task."
        }
    }
    
    var secondaryButtonLabel: ShieldConfiguration.Label? {
        if SharedData.activeTask {
            return nil
        } else {
            return .init(text: "Not Now", color: .darkgreen)
        }
    }
    
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return ShieldConfiguration(backgroundBlurStyle: .light,
                                   backgroundColor: .lightgreen.withAlphaComponent(0.15),
                                   icon: UIImage(named: "logo"),
                                   title: .init(text: "Blocked By VerifAI", color: .darkgreen),
                                   subtitle: .init(text: subtitleText, color: UIColor.secondaryLabel),
                                   primaryButtonLabel: .init(text: "OK", color: .lightgreen),
                                   primaryButtonBackgroundColor: .darkgreen,
                                   secondaryButtonLabel: secondaryButtonLabel)
    }
}
