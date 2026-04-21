import AppKit

enum AppIconProvider {
    static func headerImage() -> NSImage {
        iconImage(size: NSSize(width: 20, height: 20), inset: 0)
    }

    static func applicationIconImage() -> NSImage {
        if let bundledImage = bundledApplicationIcon() {
            return bundledImage
        }

        return fallbackApplicationIcon(size: NSSize(width: 512, height: 512))
    }

    static func menuBarImage() -> NSImage {
        iconImage(size: NSSize(width: 18, height: 18), inset: -1.2)
    }

    private static func iconImage(size: NSSize, inset: CGFloat) -> NSImage {
        guard let assetImage = bundledIcon() else {
            return fallbackImage(size: size)
        }

        let image = NSImage(size: size, flipped: false) { dstRect in
            let drawRect = dstRect.insetBy(dx: inset, dy: inset)
            assetImage.draw(
                in: drawRect,
                from: .zero,
                operation: .sourceOver,
                fraction: 1.0,
                respectFlipped: true,
                hints: [
                    .interpolation: NSImageInterpolation.high.rawValue,
                ]
            )
            return true
        }

        image.isTemplate = true
        return image
    }

    private static func bundledIcon() -> NSImage? {
        guard let url = Bundle.main.url(
            forResource: AppConstants.menuBarImageName,
            withExtension: AppConstants.menuBarImageExtension
        ), let image = NSImage(contentsOf: url) else {
            return nil
        }

        image.isTemplate = true
        return image
    }

    private static func bundledApplicationIcon() -> NSImage? {
        guard let url = Bundle.main.url(
            forResource: AppConstants.applicationIconName,
            withExtension: "icns"
        ), let image = NSImage(contentsOf: url) else {
            return nil
        }

        image.isTemplate = false
        return image
    }

    private static func fallbackImage(size: NSSize) -> NSImage {
        let image = NSImage(
            systemSymbolName: "power.circle.fill",
            accessibilityDescription: AppConstants.appName
        ) ?? NSImage(size: size)
        image.size = size
        image.isTemplate = true
        return image
    }

    private static func fallbackApplicationIcon(size: NSSize) -> NSImage {
        let image = NSImage(size: size, flipped: false) { rect in
            let backgroundPath = NSBezierPath(
                roundedRect: rect,
                xRadius: rect.width * 0.23,
                yRadius: rect.height * 0.23
            )

            let background = NSGradient(colors: [
                NSColor(calibratedRed: 0.18, green: 0.22, blue: 0.31, alpha: 1),
                NSColor(calibratedRed: 0.05, green: 0.50, blue: 0.73, alpha: 1),
            ])
            background?.draw(in: backgroundPath, angle: -55)

            NSColor.white.withAlphaComponent(0.08).setStroke()
            backgroundPath.lineWidth = max(2, rect.width * 0.03)
            backgroundPath.stroke()

            let markRect = rect.insetBy(dx: rect.width * 0.22, dy: rect.height * 0.18)
            if let icon = bundledIcon() {
                let tintedIcon = tint(image: icon, color: NSColor.white.withAlphaComponent(0.96))
                tintedIcon.draw(
                    in: markRect,
                    from: .zero,
                    operation: .sourceOver,
                    fraction: 1,
                    respectFlipped: true,
                    hints: [.interpolation: NSImageInterpolation.high.rawValue]
                )
            } else {
                let fallback = fallbackImage(size: markRect.size)
                fallback.draw(in: markRect)
            }

            return true
        }

        image.isTemplate = false
        return image
    }

    private static func tint(image: NSImage, color: NSColor) -> NSImage {
        let tintedImage = NSImage(size: image.size)
        tintedImage.lockFocus()
        let rect = NSRect(origin: .zero, size: image.size)
        image.draw(in: rect)
        color.setFill()
        rect.fill(using: .sourceAtop)
        tintedImage.unlockFocus()
        tintedImage.isTemplate = false
        return tintedImage
    }
}
