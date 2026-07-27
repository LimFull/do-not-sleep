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
    private static let circleRadius: CGFloat = 250
    private static let revolutions = 1
    private static let pointsPerRevolution = 200
    private static let frameInterval = Duration.milliseconds(50)
    private static let pointerMovementTolerance: CGFloat = 3

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

        let center: CGPoint
        if lookupResult == .success, displayCount > 0 {
            let bounds = CGDisplayBounds(displayID)
            center = circleCenter(near: current, inside: bounds)
        } else {
            center = current
        }

        let points = circlePoints(around: center)
        guard let firstPoint = points.first,
              let firstEvent = mouseEvent(at: firstPoint) else {
            return false
        }

        firstEvent.post(tap: .cghidEventTap)

        Task {
            await animate(
                through: points.dropFirst(),
                from: firstPoint,
                returningTo: current
            )
        }
        return true
    }

    private static func circleCenter(
        near point: CGPoint,
        inside bounds: CGRect
    ) -> CGPoint {
        let inset = circleRadius + 1
        guard bounds.width > inset * 2, bounds.height > inset * 2 else {
            return point
        }

        return CGPoint(
            x: min(max(point.x, bounds.minX + inset), bounds.maxX - inset),
            y: min(max(point.y, bounds.minY + inset), bounds.maxY - inset)
        )
    }

    private static func circlePoints(around center: CGPoint) -> [CGPoint] {
        let pointCount = revolutions * pointsPerRevolution

        return (0...pointCount).map { index in
            let angle =
                2 * Double.pi * Double(index) / Double(pointsPerRevolution)
            return CGPoint(
                x: center.x + circleRadius * CGFloat(cos(angle)),
                y: center.y + circleRadius * CGFloat(sin(angle))
            )
        }
    }

    private static func animate(
        through points: ArraySlice<CGPoint>,
        from firstPoint: CGPoint,
        returningTo originalPoint: CGPoint
    ) async {
        var lastPostedPoint = firstPoint

        for point in points {
            try? await Task.sleep(for: frameInterval)

            guard !Task.isCancelled,
                  pointerIsNear(lastPostedPoint),
                  let event = mouseEvent(at: point) else {
                return
            }

            event.post(tap: .cghidEventTap)
            lastPostedPoint = point
        }

        guard !Task.isCancelled, pointerIsNear(lastPostedPoint) else {
            return
        }

        mouseEvent(at: originalPoint)?.post(tap: .cghidEventTap)
    }

    private static func pointerIsNear(_ point: CGPoint) -> Bool {
        guard let current = CGEvent(source: nil)?.location else {
            return false
        }

        return abs(current.x - point.x) <= pointerMovementTolerance
            && abs(current.y - point.y) <= pointerMovementTolerance
    }

    private static func mouseEvent(at point: CGPoint) -> CGEvent? {
        CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: point,
            mouseButton: .left
        )
    }
}
