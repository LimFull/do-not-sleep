import SwiftUI

struct MenuBarContent: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var monitor: IdleMonitor

    var body: some View {
        Toggle("잠자기 방지", isOn: $settings.isEnabled)

        Divider()

        if settings.isEnabled {
            Text("입력 없음 \(durationText(monitor.idleSeconds))")

            let remaining = max(
                TimeInterval(settings.idleMinutes * 60) - monitor.idleSeconds,
                0
            )
            Text("다음 마우스 이동까지 \(durationText(remaining))")
        } else {
            Text("현재 일시 정지됨")
        }

        if monitor.permissionRequired {
            Button("접근성 권한 요청…") {
                AccessibilityPermission.request()
                AccessibilityPermission.openSystemSettings()
            }
        }

        Divider()

        SettingsLink {
            Label("설정…", systemImage: "gearshape")
        }

        Button("종료") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func durationText(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(Int(seconds.rounded(.down)), 0)
        let minutes = totalSeconds / 60
        let remainder = totalSeconds % 60

        if minutes > 0 {
            return "\(minutes)분 \(remainder)초"
        }
        return "\(remainder)초"
    }
}
