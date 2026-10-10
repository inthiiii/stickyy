import Testing
@testable import Stickyy

struct StickyyTests {
    @Test("The application identity is configured")
    @MainActor
    func applicationIdentity() {
        #expect(AppEnvironment.productName == "Stickyy")
        #expect(
            AppEnvironment.tagline
                == "Catch a thought before it fades."
        )
    }
}
