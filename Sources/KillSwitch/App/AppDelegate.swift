import AppKit
import OSLog

private enum PopoverActivation {
    static let maxAttempts = 5
    static let retryDelay: TimeInterval = 0.025
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let logger = Logger(
        subsystem: AppConstants.bundleIdentifier,
        category: "Settings"
    )
    private static var appServices: AppServices?

    private var statusItem: NSStatusItem?
    private let popover = NSPopover()
    private var popoverController: MenuPopoverViewController?
    private var pendingPopoverShowWorkItem: DispatchWorkItem?

    static func configure(appServices: AppServices) {
        self.appServices = appServices
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let appServices = Self.appServices else {
            assertionFailure("AppServices must be configured before launch")
            return
        }

        let showDockIcon = appServices.settingsStore.settings.showDockIcon
        DockIconController.apply(showDockIcon: showDockIcon)
        configureStatusItem()
        configurePopover(viewModel: appServices.menuBarViewModel)
        AppCommands.configure(
            settingsStore: appServices.settingsStore,
            closePopover: { [weak self] in
                self?.closePopover()
            }
        )

        if CommandLine.arguments.contains("--open-settings") {
            logger.notice("Launching with --open-settings")
            DispatchQueue.main.async {
                AppCommands.openSettings()
            }
        }
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = AppIconProvider.menuBarImage()
            button.imagePosition = .imageOnly
            button.title = ""
            button.toolTip = AppConstants.appName
            button.target = self
            button.action = #selector(togglePopover(_:))
        }
        self.statusItem = statusItem
    }

    private func configurePopover(viewModel: MenuBarViewModel) {
        popover.behavior = .transient
        popover.animates = false
        popover.delegate = self
        popover.appearance = NSAppearance(named: .darkAqua)

        let controller = MenuPopoverViewController(viewModel: viewModel)
        self.popoverController = controller
        popover.contentViewController = controller
        popover.contentSize = controller.preferredContentSize
    }

    @objc
    private func togglePopover(_ sender: Any?) {
        if popover.isShown || pendingPopoverShowWorkItem != nil {
            closePopover()
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard
            let button = statusItem?.button,
            let popoverController
        else { return }

        requestPopoverActivation()
        presentPopoverWhenActive(
            from: button,
            controller: popoverController,
            remainingAttempts: PopoverActivation.maxAttempts
        )
    }

    fileprivate func closePopover() {
        pendingPopoverShowWorkItem?.cancel()
        pendingPopoverShowWorkItem = nil
        statusItem?.button?.highlight(false)
        popover.performClose(nil)
    }

    private func requestPopoverActivation() {
        NSRunningApplication.current.activate(options: [.activateAllWindows])
        NSApp.activate()
    }

    private func presentPopoverWhenActive(
        from button: NSStatusBarButton,
        controller: MenuPopoverViewController,
        remainingAttempts: Int
    ) {
        pendingPopoverShowWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self, weak button] in
            guard let self, let button else { return }

            if !(NSRunningApplication.current.isActive || NSApp.isActive), remainingAttempts > 0 {
                self.requestPopoverActivation()
                self.presentPopoverWhenActive(
                    from: button,
                    controller: controller,
                    remainingAttempts: remainingAttempts - 1
                )
                return
            }

            self.pendingPopoverShowWorkItem = nil
            controller.prepareForPresentation()
            self.popover.contentSize = controller.preferredContentSize
            button.highlight(true)
            self.popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
            self.configurePresentedPopoverWindow()
            DispatchQueue.main.async { [weak self] in
                self?.configurePresentedPopoverWindow()
            }
        }

        pendingPopoverShowWorkItem = workItem
        let delay = remainingAttempts == PopoverActivation.maxAttempts ? 0.0 : PopoverActivation.retryDelay
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func configurePresentedPopoverWindow() {
        guard let window = popover.contentViewController?.view.window else { return }

        let appearance = NSAppearance(named: .darkAqua)
        window.appearance = appearance
        window.backgroundColor = NSColor(
            calibratedRed: 0.10,
            green: 0.11,
            blue: 0.13,
            alpha: 1
        )
        window.contentView?.appearance = appearance
        if let rootView = window.contentView?.superview ?? window.contentView {
            forcePopoverAppearance(in: rootView, appearance: appearance)
        }
    }

    private func forcePopoverAppearance(in view: NSView, appearance: NSAppearance?) {
        view.appearance = appearance

        if let visualEffectView = view as? NSVisualEffectView {
            visualEffectView.state = .active
            visualEffectView.isEmphasized = false
        }

        for subview in view.subviews {
            forcePopoverAppearance(in: subview, appearance: appearance)
        }
    }
}

extension AppDelegate: NSPopoverDelegate {
    func popoverDidShow(_ notification: Notification) {
        requestPopoverActivation()
        configurePresentedPopoverWindow()
        popover.contentViewController?.view.window?.makeKeyAndOrderFront(nil)
    }

    func popoverDidClose(_ notification: Notification) {
        statusItem?.button?.highlight(false)
        popoverController?.endPresentation()
    }
}
