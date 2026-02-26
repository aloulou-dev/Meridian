//
//  ShieldConfigurationExtension.swift
//  MeridianShieldConfig
//
//  Customizes the shield appearance when blocked apps are opened.
//

import ManagedSettingsUI

/// Extension that provides custom shield configuration for blocked apps
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    // MARK: - Application Shield

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return createMeridianShieldConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        return createMeridianShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        return createMeridianShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        return createMeridianShieldConfiguration()
    }

    // MARK: - Shield Configuration

    private func createMeridianShieldConfiguration() -> ShieldConfiguration {
        // Night sky background color
        let backgroundColor = UIColor(red: 0.04, green: 0.05, blue: 0.15, alpha: 1.0)

        // Primary button color (matches Theme.primaryButton)
        let primaryButtonColor = UIColor(red: 0.29, green: 0.56, blue: 0.89, alpha: 1.0)

        return ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: backgroundColor,
            icon: UIImage(systemName: "moon.stars.fill"),
            title: ShieldConfiguration.Label(
                text: "Time to Reflect",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Open Meridian to journal and unlock this app",
                color: UIColor.white.withAlphaComponent(0.7)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Meridian",
                color: .white
            ),
            primaryButtonBackgroundColor: primaryButtonColor,
            secondaryButtonLabel: nil
        )
    }
}
