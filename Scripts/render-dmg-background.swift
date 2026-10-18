import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: render-dmg-background.swift input.svg output.png\n", stderr)
    exit(64)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let targetSize = NSSize(width: 660, height: 420)

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    fputs("Unable to load installer background SVG.\n", stderr)
    exit(1)
}

let targetImage = NSImage(size: targetSize)
targetImage.lockFocus()
NSColor.clear.setFill()
NSRect(origin: .zero, size: targetSize).fill()
sourceImage.draw(
    in: NSRect(origin: .zero, size: targetSize),
    from: NSRect(origin: .zero, size: sourceImage.size),
    operation: .copy,
    fraction: 1
)
targetImage.unlockFocus()

guard
    let tiffData = targetImage.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiffData),
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Unable to render installer background PNG.\n", stderr)
    exit(1)
}

try pngData.write(to: outputURL, options: .atomic)
