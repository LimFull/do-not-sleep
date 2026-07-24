import Foundation
import ServiceManagement

@MainActor
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    private enum Key {
        static let isEnabled = "isEnabled"
        static let idleMinutes = "idleMinutes"
    }

    private let defaults: UserDefaults

    @Published var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: Key.isEnabled)
            if isEnabled {
                AccessibilityPermission.request()
            }
        }
    }

    @Published var idleMinutes: Int {
        didSet {
            let validValue = min(max(idleMinutes, 1), 120)
            if idleMinutes != validValue {
                idleMinutes = validValue
                return
            }
            defaults.set(validValue, forKey: Key.idleMinutes)
        }
    }

    @Published private(set) var launchAtLogin = false
    @Published private(set) var loginItemNeedsApproval = false
    @Published var loginItemError: String?

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if defaults.object(forKey: Key.isEnabled) == nil {
            isEnabled = true
        } else {
            isEnabled = defaults.bool(forKey: Key.isEnabled)
        }

        let storedMinutes = defaults.integer(forKey: Key.idleMinutes)
        idleMinutes = storedMinutes == 0 ? 5 : min(max(storedMinutes, 1), 120)

        refreshLoginItemStatus()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        loginItemError = nil

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            loginItemError = error.localizedDescription
        }

        refreshLoginItemStatus()
    }

    func refreshLoginItemStatus() {
        switch SMAppService.mainApp.status {
        case .enabled:
            launchAtLogin = true
            loginItemNeedsApproval = false
        case .requiresApproval:
            launchAtLogin = true
            loginItemNeedsApproval = true
        case .notRegistered, .notFound:
            launchAtLogin = false
            loginItemNeedsApproval = false
        @unknown default:
            launchAtLogin = false
            loginItemNeedsApproval = false
        }
    }

    func openLoginItemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
