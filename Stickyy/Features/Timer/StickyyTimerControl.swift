import SwiftUI

struct StickyyTimerControl: View {
    @Bindable var timer: StickyyTimerController

    @State private var showsSetup = false

    var body: some View {
        Button {
            if timer.phase == .finished {
                showsSetup = false
                withAnimation(.snappy(duration: 0.38, extraBounce: 0.08)) {
                    timer.cancel()
                }
            } else {
                showsSetup.toggle()
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: timer.phase == .finished ? "timer.circle.fill" : "timer")
                    .contentTransition(.symbolEffect(.replace))

                if timer.isExpanded {
                    Text(timer.displayText)
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(
                timer.phase == .finished ? Color.green : Color.primary
            )
            .padding(.horizontal, timer.isExpanded ? 9 : 0)
            .frame(minWidth: 28, minHeight: 28)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .stickyyPillSurface(Capsule())
        .overlay {
            ZStack {
                if timer.phase == .finished {
                    Capsule()
                        .fill(Color.green.opacity(0.18))
                        .transition(
                            .opacity.combined(with: .scale(scale: 0.9))
                        )
                }
                Capsule().strokeBorder(
                    timer.phase == .finished
                        ? Color.green.opacity(0.72)
                        : Color.primary.opacity(0.1)
                )
            }
            .allowsHitTesting(false)
        }
        .shadow(
            color: timer.phase == .finished
                ? Color.green.opacity(0.28)
                : Color.black.opacity(0.12),
            radius: timer.phase == .finished ? 7 : 4,
            y: 2
        )
        .animation(
            .snappy(duration: 0.36, extraBounce: 0.08),
            value: timer.isExpanded
        )
        .animation(.easeInOut(duration: 0.24), value: timer.phase)
        .help(
            timer.isRunning
                ? "Change or stop the Stickyy timer"
                : timer.phase == .finished
                    ? "Reset the Stickyy timer"
                    : "Set a Stickyy timer"
        )
        .accessibilityLabel(
            timer.isRunning
                ? "Stickyy timer, \(timer.displayText) remaining"
                : timer.phase == .finished
                    ? "Stickyy timer finished"
                    : "Set Stickyy timer"
        )
        .accessibilityValue(timer.isExpanded ? timer.displayText : "")
        .accessibilityIdentifier("stickyyTimerControl")
        .popover(isPresented: $showsSetup, arrowEdge: .bottom) {
            StickyyTimerSetupView(timer: timer) {
                showsSetup = false
            }
        }
    }
}

private struct StickyyTimerSetupView: View {
    @Bindable var timer: StickyyTimerController
    let dismiss: () -> Void

    @State private var selectedMinutes = 5

    private let presets = [5, 15, 25, 60]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Stickyy Timer", systemImage: "timer")
                .font(.headline)

            if timer.isRunning {
                HStack {
                    Text("Time remaining")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(timer.displayText)
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("stickyyTimerRemaining")
            } else if timer.phase == .finished {
                Label("Timer complete", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("stickyyTimerFinished")
            }

            Stepper(
                "\(selectedMinutes) minute\(selectedMinutes == 1 ? "" : "s")",
                value: $selectedMinutes,
                in: 1...StickyyTimerController.maximumMinutes
            )
            .accessibilityIdentifier("stickyyTimerMinutes")

            Slider(
                value: Binding(
                    get: { Double(selectedMinutes) },
                    set: { selectedMinutes = Int($0.rounded()) }
                ),
                in: 1...Double(StickyyTimerController.maximumMinutes),
                step: 1
            )

            HStack(spacing: 6) {
                ForEach(presets, id: \.self) { minutes in
                    Button("\(minutes) min") {
                        selectedMinutes = minutes
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityIdentifier("stickyyTimerPreset_\(minutes)")
                }
            }

            HStack {
                if timer.isExpanded {
                    Button("Cancel Timer", role: .destructive) {
                        timer.cancel()
                        dismiss()
                    }
                    .accessibilityIdentifier("cancelStickyyTimer")
                }

                Spacer()

                Button(timer.isRunning ? "Restart Timer" : "Set Timer") {
                    timer.start(minutes: selectedMinutes)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("startStickyyTimer")
            }
        }
        .padding(16)
        .frame(width: 280)
        .onAppear {
            selectedMinutes = timer.durationMinutes
        }
    }
}
