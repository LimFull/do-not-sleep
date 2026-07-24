import ApplicationServices
import Foundation

@MainActor
final class IdleMonitor: NSObject, ObservableObject {
    @Published private(set) var idleSeconds: TimeInterval = 0
    @Published private(set) var lastNudgeDate: Date?
    @Published private(set) var permissionRequired = !AccessibilityPermission.isGranted

    private let settings: AppSettings
    nonisolated(unsafe) private var timer: Timer?
    private var attemptedDuringCurrentIdlePeriod = false

    init(settings: AppSettings) {
        self.settings = settings
        super.init()

        tick()
        let timer = Timer(
            timeInterval: 1,
            target: self,
            selector: #selector(timerDidFire),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    deinit {
        timer?.invalidate()
    }

    @objc private func timerDidFire() {
        tick()
    }

    private func tick() {
        idleSeconds = Self.systemIdleSeconds()
        permissionRequired = !AccessibilityPermission.isGranted

        guard settings.isEnabled else {
            attemptedDuringCurrentIdlePeriod = false
            return
        }

        let threshold = TimeInterval(settings.idleMinutes * 60)

        if idleSeconds < threshold {
            attemptedDuringCurrentIdlePeriod = false
            return
        }

        guard !attemptedDuringCurrentIdlePeriod else { return }

        guard MouseNudger.nudge() else {
            permissionRequired = true
            return
        }

        attemptedDuringCurrentIdlePeriod = true
        lastNudgeDate = Date()
    }

    private static func systemIdleSeconds() -> TimeInterval {
        let eventTypes: [CGEventType] = [
            .leftMouseDown,
            .leftMouseUp,
            .rightMouseDown,
            .rightMouseUp,
            .mouseMoved,
            .leftMouseDragged,
            .rightMouseDragged,
            .keyDown,
            .keyUp,
            .flagsChanged,
            .scrollWheel,
            .otherMouseDown,
            .otherMouseUp,
            .otherMouseDragged
        ]

        return eventTypes
            .map {
                CGEventSource.secondsSinceLastEventType(
                    .combinedSessionState,
                    eventType: $0
                )
            }
            .min() ?? 0
    }
}

@MainActor
private enum MouseNudger {
    static func nudge() -> Bool {
        guard AccessibilityPermission.isGranted,
              let currentEvent = CGEvent(source: nil) else {
            return false
        }

        let current = currentEvent.location
        var displayID = CGDirectDisplayID()
        var displayCount: UInt32 = 0
        let lookupResult = CGGetDisplaysWithPoint(
            current,
            1,
            &displayID,
            &displayCount
        )

        let target: CGPoint
        if lookupResult == .success, displayCount > 0 {
            let bounds = CGDisplayBounds(displayID)
            let canMoveRight = current.x + 1 < bounds.maxX
            target = CGPoint(x: current.x + (canMoveRight ? 1 : -1), y: current.y)
        } else {
            target = CGPoint(x: current.x + 1, y: current.y)
        }

        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: target,
            mouseButton: .left
        ) else {
            return false
        }

        event.post(tap: .cghidEventTap)
        return true
    }
}
