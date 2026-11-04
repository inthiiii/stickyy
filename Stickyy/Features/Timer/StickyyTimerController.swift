import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class StickyyTimerController {
    enum Phase: Equatable, Sendable {
        case idle
        case running
        case finished
    }

    static let maximumMinutes = 60

    private(set) var phase: Phase = .idle
    private(set) var remainingSeconds = 0
    private(set) var durationMinutes = 5

    @ObservationIgnored
    private let now: () -> Date

    @ObservationIgnored
    private let automaticallyTicks: Bool

    @ObservationIgnored
    private let completion: @MainActor () -> Void

    @ObservationIgnored
    private let notificationAuthorizationRequest: @MainActor () -> Void

    @ObservationIgnored
    private var deadline: Date?

    @ObservationIgnored
    private var tickerTask: Task<Void, Never>?

    @ObservationIgnored
    private var preferenceObserver: NSObjectProtocol?

    init(
        automaticallyTicks: Bool = true,
        now: @escaping () -> Date = Date.init,
        notificationAuthorizationRequest: @escaping @MainActor () -> Void = {
            StickyyTimerNotificationController.shared
                .requestAuthorizationIfNeeded()
        },
        completion: @escaping @MainActor () -> Void = StickyyTimerController
            .announceCompletion
    ) {
        self.automaticallyTicks = automaticallyTicks
        self.now = now
        self.notificationAuthorizationRequest = notificationAuthorizationRequest
        self.completion = completion

        preferenceObserver = NotificationCenter.default.addObserver(
            forName: .stickyyTimerPreferenceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard !StickyyPreferences.timerEnabled() else { return }
                self?.cancel()
            }
        }
    }

    var isRunning: Bool { phase == .running }

    var isExpanded: Bool { phase != .idle }

    var displayText: String {
        guard phase != .finished else {
            return String(localized: "Done")
        }
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func start(minutes requestedMinutes: Int) {
        let minutes = min(
            max(requestedMinutes, 1),
            StickyyTimerController.maximumMinutes
        )
        tickerTask?.cancel()
        durationMinutes = minutes
        remainingSeconds = minutes * 60
        deadline = now().addingTimeInterval(TimeInterval(remainingSeconds))
        phase = .running
        notificationAuthorizationRequest()
        publishStateChange()
        startTickerIfNeeded()
    }

    func cancel() {
        tickerTask?.cancel()
        tickerTask = nil
        deadline = nil
        remainingSeconds = 0
        phase = .idle
        publishStateChange()
    }

    func refresh() {
        guard phase == .running, let deadline else { return }
        let seconds = Int(ceil(deadline.timeIntervalSince(now())))
        guard seconds > 0 else {
            finish()
            return
        }
        let updatedSeconds = min(
            seconds,
            StickyyTimerController.maximumMinutes * 60
        )
        guard updatedSeconds != remainingSeconds else { return }
        remainingSeconds = updatedSeconds
        publishStateChange()
    }

    private func startTickerIfNeeded() {
        guard automaticallyTicks else { return }
        tickerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
                guard let self, phase == .running else { return }
                refresh()
            }
        }
    }

    private func finish() {
        tickerTask?.cancel()
        tickerTask = nil
        deadline = nil
        remainingSeconds = 0
        phase = .finished
        publishStateChange()
        completion()
    }

    private func publishStateChange() {
        NotificationCenter.default.post(
            name: .stickyyTimerDidChange,
            object: self
        )
    }

    private static func announceCompletion() {
        StickyyTimerNotificationController.shared.notifyTimerFinished()
        NSApp.requestUserAttention(.criticalRequest)
    }
}
