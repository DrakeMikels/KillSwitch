#!/usr/bin/env swift

import AppKit
import Foundation

let fileManager = FileManager.default
let rootURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let resourcesURL = rootURL.appendingPathComponent("Resources", isDirectory: true)
let sourceMarkURL = resourcesURL.appendingPathComponent("KillSwitchToggleIcon.pdf")
let outputURL = resourcesURL.appendingPathComponent("AppIcon.icns")
let iconsetURL = rootURL.appendingPathComponent("dist/AppIcon.iconset", isDirectory: true)

guard let baseMark = NSImage(contentsOf: sourceMarkURL) else {
    fputs("Unable to load \(sourceMarkURL.path)\n", stderr)
    exit(1)
}

let iconSpecs: [(name: String, size: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

for spec in iconSpecs {
    let image = renderIcon(mark: baseMark, size: spec.size)
    let destinationURL = iconsetURL.appendingPathComponent(spec.name)
    try writePNG(image: image, to: destinationURL)
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconsetURL.path, "-o", outputURL.path]
try iconutil.run()
iconutil.waitUntilExit()

guard iconutil.terminationStatus == 0 else {
    fputs("iconutil failed with status \(iconutil.terminationStatus)\n", stderr)
    exit(Int32(iconutil.terminationStatus))
}

private func renderIcon(mark: NSImage, size: Int) -> NSImage {
    let canvasSize = NSSize(width: size, height: size)

    return NSImage(size: canvasSize, flipped: false) { rect in
        let backgroundRect = rect.insetBy(dx: rect.width * 0.02, dy: rect.height * 0.02)
        let cornerRadius = rect.width * 0.225
        let backgroundPath = NSBezierPath(
            roundedRect: backgroundRect,
            xRadius: cornerRadius,
            yRadius: cornerRadius
        )

        let gradient = NSGradient(colors: [
            NSColor(calibratedRed: 0.16, green: 0.19, blue: 0.28, alpha: 1),
            NSColor(calibratedRed: 0.08, green: 0.35, blue: 0.62, alpha: 1),
            NSColor(calibratedRed: 0.06, green: 0.62, blue: 0.75, alpha: 1),
        ])
        gradient?.draw(in: backgroundPath, angle: -52)

        let innerGlowPath = NSBezierPath(
            roundedRect: backgroundRect.insetBy(dx: rect.width * 0.055, dy: rect.height * 0.055),
            xRadius: rect.width * 0.16,
            yRadius: rect.height * 0.16
        )
        NSColor.white.withAlphaComponent(0.06).setFill()
        innerGlowPath.fill()

        let highlightPath = NSBezierPath(
            roundedRect: NSRect(
                x: backgroundRect.minX + rect.width * 0.07,
                y: backgroundRect.midY + rect.height * 0.06,
                width: backgroundRect.width - rect.width * 0.14,
                height: rect.height * 0.26
            ),
            xRadius: rect.width * 0.14,
            yRadius: rect.height * 0.14
        )
        NSColor.white.withAlphaComponent(0.12).setFill()
        highlightPath.fill()

        NSColor.white.withAlphaComponent(0.10).setStroke()
        backgroundPath.lineWidth = max(2, rect.width * 0.028)
        backgroundPath.stroke()

        let markInsetX = rect.width * 0.19
        let markInsetY = rect.height * 0.18
        let markRect = backgroundRect.insetBy(dx: markInsetX, dy: markInsetY)
        let tintedMark = tint(image: mark, color: NSColor.white.withAlphaComponent(0.96))

        NSGraphicsContext.current?.saveGraphicsState()
        let shadow = NSShadow()
        shadow.shadowBlurRadius = rect.width * 0.05
        shadow.shadowOffset = NSSize(width: 0, height: -rect.height * 0.015)
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
        shadow.set()
        tintedMark.draw(
            in: markRect,
            from: .zero,
            operation: .sourceOver,
            fraction: 1,
            respectFlipped: true,
            hints: [.interpolation: NSImageInterpolation.high.rawValue]
        )
        NSGraphicsContext.current?.restoreGraphicsState()

        return true
    }
}

private func tint(image: NSImage, color: NSColor) -> NSImage {
    let tintedImage = NSImage(size: image.size)
    tintedImage.lockFocus()
    let rect = NSRect(origin: .zero, size: image.size)
    image.draw(in: rect)
    color.setFill()
    rect.fill(using: .sourceAtop)
    tintedImage.unlockFocus()
    return tintedImage
}

private func writePNG(image: NSImage, to url: URL) throws {
    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "KillSwitchIcon", code: 1)
    }

    try pngData.write(to: url)
}
