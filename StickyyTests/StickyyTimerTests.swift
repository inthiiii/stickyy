import Foundation
import Testing
@testable import Stickyy

@MainActor
struct StickyyTimerTests {
    @Test("Timers clamp to 60 minutes and finish at the deadline")
    func timerClampsAndFinishes() {
        var currentTime = Date(timeIntervalSince1970: 1_000)
        var completionCount = 0
        let timer = StickyyTimerController(
            automaticallyTicks: false,
            now: { currentTime },
            notificationAuthorizationRequest: {},
            completion: { completionCount += 1 }
        )

        timer.start(minutes: 90)

        #expect(timer.phase == .running)
        #expect(timer.durationMinutes == 60)
        #expect(timer.remainingSeconds == 3_600)
        #expect(timer.displayText == "60:00")

        currentTime.addTimeInterval(3_599)
        timer.refresh()
        #expect(timer.remainingSeconds == 1)

        currentTime.addTimeInterval(1)
        timer.refresh()
        #expect(timer.phase == .finished)
        #expect(timer.displayText == "Done")
        #expect(completionCount == 1)

        timer.cancel()
        #expect(timer.phase == .idle)
        #expect(timer.remainingSeconds == 0)
    }

    @Test("Timers clamp short durations to one minute")
    func timerHasOneMinuteMinimum() {
        let timer = StickyyTimerController(
            automaticallyTicks: false,
            notificationAuthorizationRequest: {},
            completion: {}
        )

        timer.start(minutes: 0)

        #expect(timer.durationMinutes == 1)
        #expect(timer.remainingSeconds == 60)
    }
}
