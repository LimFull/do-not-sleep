import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var accessibilityGranted = AccessibilityPermission.isGranted

    var body: some View {
        Form {
            Section("동작") {
                Toggle("잠자기 방지 활성화", isOn: $settings.isEnabled)

                Stepper(
                    "입력이 없을 때 \(settings.idleMinutes)분 후 마우스 이동",
                    value: $settings.idleMinutes,
                    in: 1...120
                )

                Text("키보드와 마우스 입력이 모두 없을 때 포인터로 작은 원을 그립니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("시스템") {
                Toggle(
                    "로그인 시 자동 실행",
                    isOn: Binding(
                        get: { settings.launchAtLogin },
                        set: { settings.setLaunchAtLogin($0) }
                    )
                )

                if settings.loginItemNeedsApproval {
                    HStack {
                        Text("시스템 설정에서 로그인을 허용해야 합니다.")
                            .foregroundStyle(.orange)
                        Spacer()
                        Button("로그인 항목 열기") {
                            settings.openLoginItemSettings()
                        }
                    }
                }

                if let error = settings.loginItemError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                }

                HStack {
                    Label(
                        accessibilityGranted ? "접근성 권한 허용됨" : "접근성 권한 필요",
                        systemImage: accessibilityGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(accessibilityGranted ? .green : .orange)

                    Spacer()

                    if !accessibilityGranted {
                        Button("권한 설정 열기") {
                            AccessibilityPermission.request()
                            AccessibilityPermission.openSystemSettings()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 330)
        .onAppear {
            refreshSystemState()
        }
        .onReceive(
            Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        ) { _ in
            accessibilityGranted = AccessibilityPermission.isGranted
        }
    }

    private func refreshSystemState() {
        accessibilityGranted = AccessibilityPermission.isGranted
        settings.refreshLoginItemStatus()
    }
}
