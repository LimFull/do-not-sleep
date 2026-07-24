import AppKit
import SwiftUI

@main
struct DoNotSleepApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings: AppSettings
    @StateObject private var idleMonitor: IdleMonitor

    init() {
        let settings = AppSettings.shared
        _settings = StateObject(wrappedValue: settings)
        _idleMonitor = StateObject(wrappedValue: IdleMonitor(settings: settings))
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(settings)
                .environmentObject(idleMonitor)
        } label: {
            Image(systemName: settings.isEnabled ? "moon.zzz.fill" : "moon.zzz")
                .accessibilityLabel(settings.isEnabled ? "잠자기 방지 켜짐" : "잠자기 방지 꺼짐")
        }

        Settings {
            SettingsView()
                .environmentObject(settings)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        guard AppSettings.shared.isEnabled else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            AccessibilityPermission.request()
        }
    }
}
