import AppKit
import Combine
import QuartzCore

private enum MenuPopoverScale {
    static let factor: CGFloat = AppConstants.popoverScale

    static func metric(_ value: CGFloat) -> CGFloat {
        (value * factor).rounded(.toNearestOrEven)
    }

    static func font(_ value: CGFloat) -> CGFloat {
        (value * factor * 10).rounded(.toNearestOrEven) / 10
    }

    static var buttonControlSize: NSControl.ControlSize {
        factor >= 0.9 ? .small : .mini
    }

    static var headerSymbolConfiguration: NSImage.SymbolConfiguration {
        NSImage.SymbolConfiguration(
            pointSize: font(14),
            weight: .regular
        )
    }
}

private enum MenuPopoverLayout {
    static let outerInset: CGFloat = MenuPopoverScale.metric(20)
    static let stackSpacing: CGFloat = MenuPopoverScale.metric(16)
    static let sectionCardInset: CGFloat = MenuPopoverScale.metric(14)
    static let rowVerticalPadding: CGFloat = MenuPopoverScale.metric(10)
    static let quitButtonColumnWidth: CGFloat = MenuPopoverScale.metric(68)
}

private enum MenuPopoverColors {
    static let panelBackground = NSColor(
        calibratedRed: 0.10,
        green: 0.11,
        blue: 0.13,
        alpha: 1
    )

    static func pressureGradient(for level: PressureLevel) -> [NSColor] {
        switch level {
        case .normal:
            return [.systemMint, .systemGreen]
        case .elevated:
            return [.systemYellow, .systemOrange]
        case .high:
            return [.systemOrange, .systemRed]
        case .critical:
            return [.systemRed, .systemPink]
        }
    }

    static func applicationGradient(for percent: Double) -> [NSColor] {
        switch percent {
        case 0.5...:
            return [
                NSColor(calibratedRed: 1.0, green: 0.38, blue: 0.34, alpha: 1),
                NSColor(calibratedRed: 1.0, green: 0.18, blue: 0.31, alpha: 1),
            ]
        case 0.2...:
            return [
                NSColor(calibratedRed: 1.0, green: 0.73, blue: 0.25, alpha: 1),
                NSColor(calibratedRed: 1.0, green: 0.56, blue: 0.18, alpha: 1),
            ]
        default:
            return [
                NSColor(calibratedRed: 0.29, green: 0.92, blue: 0.52, alpha: 1),
                NSColor(calibratedRed: 0.09, green: 0.79, blue: 0.42, alpha: 1),
            ]
        }
    }

    static let systemMemoryGradient: [NSColor] = [
        NSColor(calibratedRed: 0.18, green: 0.62, blue: 1.0, alpha: 1),
        NSColor(calibratedRed: 0.08, green: 0.48, blue: 0.98, alpha: 1),
    ]
}

private enum MenuPopoverAppearance {
    static let dark = NSAppearance(named: .darkAqua)
}

@MainActor
final class MenuPopoverViewController: NSViewController {
    private let viewModel: MenuBarViewModel
    private var cancellables = Set<AnyCancellable>()

    private let contentStack = NSStackView()
    private let summaryCard = SummaryCardView()
    private let applicationsSection = ApplicationsSectionView()
    private let statusLabel = NSTextField(labelWithString: "")
    private let settingsButton = NSButton(title: "Settings", target: nil, action: nil)

    init(viewModel: MenuBarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.preferredContentSize = NSSize(
            width: AppConstants.popoverWidth,
            height: AppConstants.popoverFallbackHeight
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let rootView = NSView(frame: NSRect(
            x: 0,
            y: 0,
            width: AppConstants.popoverWidth,
            height: AppConstants.popoverFallbackHeight
        ))
        rootView.translatesAutoresizingMaskIntoConstraints = false
        rootView.wantsLayer = true
        rootView.appearance = MenuPopoverAppearance.dark
        rootView.layer?.backgroundColor = MenuPopoverColors.panelBackground.cgColor

        contentStack.orientation = .vertical
        contentStack.spacing = MenuPopoverLayout.stackSpacing
        contentStack.alignment = .leading
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        rootView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: rootView.leadingAnchor, constant: MenuPopoverLayout.outerInset),
            contentStack.trailingAnchor.constraint(equalTo: rootView.trailingAnchor, constant: -MenuPopoverLayout.outerInset),
            contentStack.topAnchor.constraint(equalTo: rootView.topAnchor, constant: MenuPopoverLayout.outerInset),
            contentStack.bottomAnchor.constraint(equalTo: rootView.bottomAnchor, constant: -MenuPopoverLayout.outerInset),
            rootView.widthAnchor.constraint(equalToConstant: AppConstants.popoverWidth),
        ])

        self.view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bindViewModel()
        render()
    }

    func prepareForPresentation() {
        viewModel.startRefreshing()
        viewModel.refresh()
        render()
    }

    func endPresentation() {
        viewModel.stopRefreshing()
    }

    private func configureUI() {
        let header = HeaderView(
            onRefresh: { [weak self] in self?.viewModel.refresh() },
            onMenu: { [weak self] sourceView in self?.showActionsMenu(from: sourceView) }
        )

        let footer = NSStackView()
        footer.orientation = .horizontal
        footer.alignment = .centerY
        footer.spacing = MenuPopoverScale.metric(8)
        footer.translatesAutoresizingMaskIntoConstraints = false

        statusLabel.font = .systemFont(ofSize: MenuPopoverScale.font(12))
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.lineBreakMode = .byTruncatingTail

        settingsButton.bezelStyle = .rounded
        settingsButton.controlSize = MenuPopoverScale.buttonControlSize
        settingsButton.target = self
        settingsButton.action = #selector(openSettings)

        footer.addArrangedSubview(statusLabel)
        footer.addArrangedSubview(NSView.spacer())
        footer.addArrangedSubview(settingsButton)

        contentStack.addArrangedSubview(header)
        contentStack.addArrangedSubview(summaryCard)
        contentStack.addArrangedSubview(applicationsSection)
        contentStack.addArrangedSubview(footer)

        NSLayoutConstraint.activate([
            header.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            summaryCard.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            applicationsSection.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
            footer.widthAnchor.constraint(equalTo: contentStack.widthAnchor),
        ])

        contentStack.setCustomSpacing(MenuPopoverScale.metric(12), after: applicationsSection)

        header.updateIcon(AppIconProvider.headerImage())
    }

    private func bindViewModel() {
        viewModel.$snapshot
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)

        viewModel.$topApplications
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)

        viewModel.$statusMessage
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)

        viewModel.$unattributedMemoryBytes
            .sink { [weak self] _ in self?.render() }
            .store(in: &cancellables)
    }

    private func render() {
        guard let header = contentStack.arrangedSubviews.first as? HeaderView else { return }

        header.update(
            title: AppConstants.appName,
            subtitle: "Memory utility"
        )

        summaryCard.update(snapshot: viewModel.snapshot)
        applicationsSection.update(
            applications: viewModel.topApplications,
            unattributedMemoryBytes: viewModel.unattributedMemoryBytes,
            totalMemoryBytes: viewModel.snapshot.totalBytes,
            onQuit: { [weak self] stat in
                self?.viewModel.quit(stat)
            }
        )
        statusLabel.stringValue = viewModel.statusMessage ?? "Graceful quit keeps save prompts"
    }

    private func showActionsMenu(from sourceView: NSView) {
        let menu = NSMenu()

        let refreshItem = NSMenuItem(
            title: "Refresh Now",
            action: #selector(refreshNow),
            keyEquivalent: ""
        )
        refreshItem.target = self
        menu.addItem(refreshItem)

        let updatesItem = NSMenuItem(
            title: "Check for Updates…",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updatesItem.target = self
        updatesItem.isEnabled = viewModel.isUpdateCheckAvailable
        menu.addItem(updatesItem)

        let aboutItem = NSMenuItem(
            title: "About KillSwitch",
            action: #selector(openAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ""
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(
            title: "Quit KillSwitch",
            action: #selector(quitApp),
            keyEquivalent: ""
        )
        quitItem.target = self
        menu.addItem(quitItem)

        let origin = NSPoint(x: sourceView.bounds.minX, y: sourceView.bounds.maxY + MenuPopoverScale.metric(6))
        menu.popUp(positioning: nil, at: origin, in: sourceView)
    }

    @objc
    private func refreshNow() {
        viewModel.refresh()
    }

    @objc
    private func checkForUpdates() {
        viewModel.checkForUpdates()
    }

    @objc
    private func openAbout() {
        viewModel.openAboutPanel()
    }

    @objc
    private func openSettings() {
        AppCommands.openSettings()
    }

    @objc
    private func quitApp() {
        NSApp.terminate(nil)
    }
}

private final class HeaderView: NSView {
    private let iconView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private let refreshButton = NSButton()
    private let menuButton = NSButton()
    private let onRefresh: () -> Void
    private let onMenu: (NSView) -> Void

    init(
        onRefresh: @escaping () -> Void,
        onMenu: @escaping (NSView) -> Void
    ) {
        self.onRefresh = onRefresh
        self.onMenu = onMenu
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(title: String, subtitle: String) {
        titleLabel.stringValue = title
        subtitleLabel.stringValue = subtitle
    }

    func updateIcon(_ image: NSImage) {
        iconView.image = image
    }

    private func setup() {
        let titleStack = NSStackView(views: [titleLabel, subtitleLabel])
        titleStack.orientation = .vertical
        titleStack.spacing = MenuPopoverScale.metric(2)
        titleStack.alignment = .leading

        titleLabel.font = .systemFont(ofSize: MenuPopoverScale.font(14), weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: MenuPopoverScale.font(12))
        subtitleLabel.textColor = .secondaryLabelColor

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: MenuPopoverScale.metric(24)),
            iconView.heightAnchor.constraint(equalToConstant: MenuPopoverScale.metric(24)),
        ])

        refreshButton.image = NSImage(
            systemSymbolName: "arrow.clockwise",
            accessibilityDescription: "Refresh"
        )?.withSymbolConfiguration(MenuPopoverScale.headerSymbolConfiguration)
        refreshButton.isBordered = false
        refreshButton.target = self
        refreshButton.action = #selector(didTapRefresh)

        menuButton.image = NSImage(
            systemSymbolName: "ellipsis",
            accessibilityDescription: "More"
        )?.withSymbolConfiguration(MenuPopoverScale.headerSymbolConfiguration)
        menuButton.isBordered = false
        menuButton.target = self
        menuButton.action = #selector(didTapMenu)

        let trailingButtons = NSStackView(views: [refreshButton, menuButton])
        trailingButtons.orientation = .horizontal
        trailingButtons.spacing = MenuPopoverScale.metric(4)

        let row = NSStackView()
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = MenuPopoverScale.metric(10)
        row.translatesAutoresizingMaskIntoConstraints = false

        row.addArrangedSubview(iconView)
        row.addArrangedSubview(titleStack)
        row.addArrangedSubview(NSView.spacer())
        row.addArrangedSubview(trailingButtons)

        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @objc
    private func didTapRefresh() {
        onRefresh()
    }

    @objc
    private func didTapMenu() {
        onMenu(menuButton)
    }
}

private final class SummaryCardView: CardContainerView {
    private let titleLabel = NSTextField(labelWithString: "Unified Memory")
    private let valueLabel = NSTextField(labelWithString: "")
    private let availableLabel = NSTextField(labelWithString: "")
    private let meter = MeterBarView()
    private let footerLabel = NSTextField(labelWithString: "Memory in use")
    private let percentLabel = NSTextField(labelWithString: "")

    init() {
        super.init(frame: .zero)
        setupSummary()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(snapshot: MemorySnapshot) {
        valueLabel.stringValue = "\(Formatters.memory(snapshot.usedBytes)) / \(Formatters.memory(snapshot.totalBytes))"
        availableLabel.stringValue = "\(Formatters.memory(snapshot.availableBytes)) available"
        percentLabel.stringValue = Formatters.percent(snapshot.usedPercent)
        meter.progress = snapshot.usedPercent
        meter.fillColors = MenuPopoverColors.pressureGradient(for: snapshot.pressureLevel)
    }

    private func setupSummary() {
        titleLabel.font = .systemFont(ofSize: MenuPopoverScale.font(13), weight: .medium)
        titleLabel.textColor = .secondaryLabelColor

        valueLabel.font = .systemFont(ofSize: MenuPopoverScale.font(17), weight: .semibold)
        availableLabel.font = .systemFont(ofSize: MenuPopoverScale.font(12))
        availableLabel.textColor = .secondaryLabelColor

        footerLabel.font = .systemFont(ofSize: MenuPopoverScale.font(12))
        footerLabel.textColor = .secondaryLabelColor
        percentLabel.font = .systemFont(ofSize: MenuPopoverScale.font(12), weight: .semibold)
        percentLabel.textColor = .secondaryLabelColor

        let bottomRow = NSStackView(views: [footerLabel, NSView.spacer(), percentLabel])
        bottomRow.orientation = .horizontal
        bottomRow.alignment = .centerY

        let stack = NSStackView(views: [
            titleLabel,
            valueLabel,
            availableLabel,
            meter,
            bottomRow,
        ])
        stack.orientation = .vertical
        stack.spacing = MenuPopoverScale.metric(8)
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            meter.heightAnchor.constraint(equalToConstant: MenuPopoverScale.metric(12)),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: MenuPopoverLayout.sectionCardInset),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -MenuPopoverLayout.sectionCardInset),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: MenuPopoverLayout.sectionCardInset),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -MenuPopoverLayout.sectionCardInset),
        ])
    }
}

private final class ApplicationsSectionView: CardContainerView {
    private let rowsStack = NSStackView()
    private var quitHandler: ((AppMemoryStat) -> Void)?

    init() {
        super.init(frame: .zero)
        setupSection()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(
        applications: [AppMemoryStat],
        unattributedMemoryBytes: UInt64,
        totalMemoryBytes: UInt64,
        onQuit: @escaping (AppMemoryStat) -> Void
    ) {
        self.quitHandler = onQuit

        rowsStack.arrangedSubviews.forEach { subview in
            rowsStack.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }

        if applications.isEmpty {
            let emptyLabel = NSTextField(labelWithString: "No user apps matched the current filter.")
            emptyLabel.font = .systemFont(ofSize: MenuPopoverScale.font(12))
            emptyLabel.textColor = .secondaryLabelColor
            rowsStack.addArrangedSubview(emptyLabel)
        } else {
            for application in applications {
                let row = ApplicationRowNativeView()
                row.update(stat: application, onQuit: onQuit)
                addFullWidthRow(row)
            }
        }

        let showOther = totalMemoryBytes > 0 && (
            unattributedMemoryBytes >= 1_073_741_824 ||
            Double(unattributedMemoryBytes) / Double(totalMemoryBytes) >= 0.15
        )

        if showOther {
            let row = ApplicationRowNativeView()
            row.updateSystemMemory(
                memoryBytes: unattributedMemoryBytes,
                percentOfTotal: Double(unattributedMemoryBytes) / Double(totalMemoryBytes)
            )
            addFullWidthRow(row)
        }
    }

    private func setupSection() {
        let titleLabel = NSTextField(labelWithString: "Top Applications")
        titleLabel.font = .systemFont(ofSize: MenuPopoverScale.font(16), weight: .semibold)

        let sortLabel = NSTextField(labelWithString: "By memory")
        sortLabel.font = .systemFont(ofSize: MenuPopoverScale.font(12))
        sortLabel.textColor = .secondaryLabelColor

        let header = NSStackView(views: [titleLabel, NSView.spacer(), sortLabel])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.translatesAutoresizingMaskIntoConstraints = false

        rowsStack.orientation = .vertical
        rowsStack.spacing = 0
        rowsStack.alignment = .leading
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        let stack = NSStackView(views: [header, rowsStack])
        stack.orientation = .vertical
        stack.spacing = MenuPopoverScale.metric(10)
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: MenuPopoverLayout.sectionCardInset),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -MenuPopoverLayout.sectionCardInset),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: MenuPopoverLayout.sectionCardInset),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -MenuPopoverLayout.sectionCardInset),
            header.widthAnchor.constraint(equalTo: stack.widthAnchor),
            rowsStack.widthAnchor.constraint(equalTo: stack.widthAnchor),
        ])
    }

    private func addFullWidthRow(_ row: NSView) {
        rowsStack.addArrangedSubview(row)
        row.widthAnchor.constraint(equalTo: rowsStack.widthAnchor).isActive = true
    }
}

private final class ApplicationRowNativeView: NSView {
    private let iconView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let activeBadge = StatusBadgeView(title: "Active")
    private let quitButton = NSButton(title: "Quit", target: nil, action: nil)
    private let quitButtonColumn = NSView()
    private let meter = MeterBarView()
    private var stat: AppMemoryStat?
    private var quitAction: ((AppMemoryStat) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(stat: AppMemoryStat, onQuit: @escaping (AppMemoryStat) -> Void) {
        self.stat = stat
        self.quitAction = onQuit

        iconView.image = stat.icon ?? NSImage(systemSymbolName: "app.fill", accessibilityDescription: stat.name)
        nameLabel.stringValue = stat.name

        var details = [Formatters.memory(stat.memoryBytes), "\(Int(round(stat.memoryPercentOfTotal * 100)))% total"]
        if stat.processCount > 1 {
            details.append("\(stat.processCount) proc")
        }
        details[1] = "\(Int(round(stat.memoryImpactPercent * 100)))% of available"
        detailLabel.stringValue = details.joined(separator: "   ")
        activeBadge.isHidden = !stat.isFrontmost
        meter.progress = stat.memoryImpactPercent
        meter.fillColors = MenuPopoverColors.applicationGradient(for: stat.memoryImpactPercent)
        quitButton.isHidden = false
    }

    func updateSystemMemory(memoryBytes: UInt64, percentOfTotal: Double) {
        self.stat = nil
        self.quitAction = nil

        iconView.image = NSImage(systemSymbolName: "memorychip", accessibilityDescription: "System memory")
        nameLabel.stringValue = "System / Other Memory"
        detailLabel.stringValue = "\(Formatters.memory(memoryBytes))   \(Int(round(percentOfTotal * 100)))% total"
        activeBadge.isHidden = true
        meter.progress = percentOfTotal
        meter.fillColors = MenuPopoverColors.systemMemoryGradient
        quitButton.isHidden = true
    }

    private func setup() {
        wantsLayer = true

        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.wantsLayer = true
        iconView.layer?.cornerRadius = MenuPopoverScale.metric(8)
        iconView.layer?.masksToBounds = true

        nameLabel.font = .systemFont(ofSize: MenuPopoverScale.font(15), weight: .semibold)
        detailLabel.font = .systemFont(ofSize: MenuPopoverScale.font(12))
        detailLabel.textColor = .secondaryLabelColor

        activeBadge.translatesAutoresizingMaskIntoConstraints = false

        quitButton.bezelStyle = .rounded
        quitButton.controlSize = MenuPopoverScale.buttonControlSize
        quitButton.target = self
        quitButton.action = #selector(didTapQuit)
        quitButton.translatesAutoresizingMaskIntoConstraints = false

        quitButtonColumn.translatesAutoresizingMaskIntoConstraints = false
        quitButtonColumn.addSubview(quitButton)

        let labelRow = NSStackView(views: [nameLabel, activeBadge, NSView.spacer()])
        labelRow.orientation = .horizontal
        labelRow.alignment = .centerY
        labelRow.spacing = MenuPopoverScale.metric(8)

        let textStack = NSStackView(views: [labelRow, detailLabel])
        textStack.orientation = .vertical
        textStack.spacing = MenuPopoverScale.metric(4)
        textStack.alignment = .width
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let topRow = NSStackView(views: [iconView, textStack, NSView.spacer(), quitButtonColumn])
        topRow.orientation = .horizontal
        topRow.alignment = .top
        topRow.spacing = MenuPopoverScale.metric(12)

        let stack = NSStackView(views: [topRow, meter])
        stack.orientation = .vertical
        stack.spacing = MenuPopoverScale.metric(10)
        stack.alignment = .width
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: MenuPopoverScale.metric(32)),
            iconView.heightAnchor.constraint(equalToConstant: MenuPopoverScale.metric(32)),
            activeBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: MenuPopoverScale.metric(72)),
            activeBadge.heightAnchor.constraint(equalToConstant: MenuPopoverScale.metric(24)),
            quitButtonColumn.widthAnchor.constraint(equalToConstant: MenuPopoverLayout.quitButtonColumnWidth),
            quitButton.topAnchor.constraint(equalTo: quitButtonColumn.topAnchor),
            quitButton.trailingAnchor.constraint(equalTo: quitButtonColumn.trailingAnchor),
            meter.heightAnchor.constraint(equalToConstant: MenuPopoverScale.metric(10)),
            topRow.widthAnchor.constraint(equalTo: stack.widthAnchor),
            labelRow.widthAnchor.constraint(equalTo: textStack.widthAnchor),
            meter.widthAnchor.constraint(equalTo: stack.widthAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: MenuPopoverLayout.rowVerticalPadding),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -MenuPopoverLayout.rowVerticalPadding),
            stack.widthAnchor.constraint(equalTo: widthAnchor),
        ])
    }

    @objc
    private func didTapQuit() {
        guard let stat else { return }
        quitAction?(stat)
    }

}

private final class StatusBadgeView: NSView {
    private let titleLabel = NSTextField(labelWithString: "")
    private let gradientLayer = CAGradientLayer()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.stringValue = title
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = bounds.height / 2
        layer?.cornerRadius = bounds.height / 2
    }

    private func setup() {
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.12).cgColor

        gradientLayer.colors = [
            NSColor(calibratedRed: 0.17, green: 0.82, blue: 0.49, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.07, green: 0.64, blue: 0.36, alpha: 1).cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer?.insertSublayer(gradientLayer, at: 0)

        titleLabel.font = .systemFont(ofSize: MenuPopoverScale.font(11), weight: .semibold)
        titleLabel.textColor = NSColor.white.withAlphaComponent(0.96)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: MenuPopoverScale.metric(10)),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -MenuPopoverScale.metric(10)),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
}

private class CardContainerView: NSView {
    let contentView = NSView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.cornerRadius = MenuPopoverScale.metric(18)
        layer?.masksToBounds = true
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.08).cgColor
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.12).cgColor

        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class MeterBarView: NSView {
    var progress: Double = 0 {
        didSet { needsDisplay = true }
    }

    var fillColors: [NSColor] = [.systemBlue] {
        didSet { needsDisplay = true }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        let trackPath = NSBezierPath(roundedRect: bounds, xRadius: bounds.height / 2, yRadius: bounds.height / 2)
        NSColor.white.withAlphaComponent(0.10).setFill()
        trackPath.fill()

        let clamped = max(0, min(progress, 1))
        let fillWidth = bounds.width * clamped
        guard fillWidth > 1 else { return }

        let fillRect = NSRect(x: 0, y: 0, width: fillWidth, height: bounds.height)
        let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: bounds.height / 2, yRadius: bounds.height / 2)
        if let gradient = NSGradient(colors: fillColors), fillColors.count > 1 {
            gradient.draw(in: fillPath, angle: 0)
        } else {
            (fillColors.first ?? .systemBlue).setFill()
            fillPath.fill()
        }
    }
}

private extension NSView {
    static func spacer() -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }
}
