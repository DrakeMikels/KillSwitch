import AppKit

enum AppIconProvider {
    static func headerImage() -> NSImage {
        iconImage(size: NSSize(width: 20, height: 20), inset: 0)
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

    private static func fallbackImage(size: NSSize) -> NSImage {
        let image = NSImage(
            systemSymbolName: "power.circle.fill",
            accessibilityDescription: AppConstants.appName
        ) ?? NSImage(size: size)
        image.size = size
        image.isTemplate = true
        return image
    }
}
