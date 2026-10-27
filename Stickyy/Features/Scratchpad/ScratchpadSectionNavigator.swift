import Foundation
import SwiftUI

enum ScratchpadSections {
    static let divider = "────────────"

    static func anchors(in text: String) -> [Int] {
        let source = text as NSString
        var anchors = [0]
        var searchLocation = 0

        while searchLocation < source.length {
            let searchRange = NSRange(
                location: searchLocation,
                length: source.length - searchLocation
            )
            let dividerRange = source.range(
                of: divider,
                options: [],
                range: searchRange
            )
            guard dividerRange.location != NSNotFound else { break }

            var nextSection = NSMaxRange(dividerRange)
            while nextSection < source.length,
                  CharacterSet.newlines.contains(
                      UnicodeScalar(source.character(at: nextSection))!
                  ) {
                nextSection += 1
            }
            anchors.append(nextSection)
            searchLocation = NSMaxRange(dividerRange)
        }

        return anchors
    }
}

struct ScratchpadSectionNavigationRequest: Equatable, Sendable {
    let id = UUID()
    let location: Int
}

struct ScratchpadSectionNavigator: View {
    let text: String
    let accessibilityPrefix: String
    let onNavigate: (Int) -> Void

    @State private var selectedSection = 0

    private var anchors: [Int] {
        ScratchpadSections.anchors(in: text)
    }

    private var navigatorHeight: CGFloat {
        min(CGFloat(anchors.count * 23 + 14), 164)
    }

    var body: some View {
        if anchors.count > 1 {
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    VStack(spacing: 7) {
                        ForEach(Array(anchors.enumerated()), id: \.offset) {
                            index,
                            location in
                            Button {
                                selectedSection = index
                                onNavigate(location)
                                withAnimation(.easeOut(duration: 0.18)) {
                                    proxy.scrollTo(index, anchor: .center)
                                }
                            } label: {
                                Circle()
                                    .fill(
                                        index == selectedSection
                                            ? Color.primary
                                            : Color.primary.opacity(0.32)
                                    )
                                    .frame(
                                        width: index == selectedSection ? 7 : 6,
                                        height: index == selectedSection ? 7 : 6
                                    )
                                    .frame(width: 16, height: 16)
                                    .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .help("Go to section \(index + 1)")
                            .accessibilityLabel("Go to section \(index + 1)")
                            .accessibilityIdentifier(
                                "\(accessibilityPrefix)Section_\(index + 1)"
                            )
                            .id(index)
                        }
                    }
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(anchors.count > 7 ? .visible : .hidden)
            }
            .frame(width: 32, height: navigatorHeight)
            // A nested backdrop material can invalidate the parent Liquid
            // Glass surface. This adaptive solid tint keeps the navigator
            // legible without altering the note's background blur.
            .background(
                Color(nsColor: .windowBackgroundColor).opacity(0.78),
                in: Capsule()
            )
            .overlay {
                Capsule().strokeBorder(Color.primary.opacity(0.1))
            }
            .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
            .padding(.trailing, 8)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Note sections")
            .accessibilityIdentifier("\(accessibilityPrefix)SectionNavigator")
            .onChange(of: anchors.count) {
                selectedSection = min(selectedSection, anchors.count - 1)
            }
        }
    }
}
