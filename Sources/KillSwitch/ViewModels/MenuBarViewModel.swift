import AppKit
import Combine
import Foundation

@MainActor
final class MenuBarViewModel: ObservableObject {
    private let settingsStore: SettingsStore
    private let memoryMonitorService: MemoryMonitorService
    private let runningApplicationsService: RunningApplicationsService
    private let processMemoryService: ProcessMemoryService
    private let applicationQuitService: ApplicationQuitService
    private let updateService: UpdateService

    private var refreshLoopTask: Task<Void, Never>?

    @Published var snapshot: MemorySnapshot
    @Published var topApplications: [AppMemoryStat]
    @Published var isRefreshing = false
    @Published var statusMessage: String?
    @Published var lastUpdatedAt: Date?
    @Published var unattributedMemoryBytes: UInt64 = 0

    init(
        settingsStore: SettingsStore,
        memoryMonitorService: MemoryMonitorService = MemoryMonitorService(),
        runningApplicationsService: RunningApplicationsService = RunningApplicationsService(),
        processMemoryService: ProcessMemoryService = ProcessMemoryService(),
        applicationQuitService: ApplicationQuitService = ApplicationQuitService(),
        updateService: UpdateService = UpdateService()
    ) {
        self.settingsStore = settingsStore
        self.memoryMonitorService = memoryMonitorService
        self.runningApplicationsService = runningApplicationsService
        self.processMemoryService = processMemoryService
        self.applicationQuitService = applicationQuitService
        self.updateService = updateService
        self.snapshot = PreviewData.snapshot
        self.topApplications = PreviewData.topApplications
        self.lastUpdatedAt = PreviewData.snapshot.capturedAt
    }

    var menuBarSymbolName: String {
        snapshot.pressureLevel.menuBarSymbolName
    }

    var isUpdateCheckAvailable: Bool {
        updateService.isConfigured
    }

    func startRefreshing() {
        guard refreshLoopTask == nil else { return }

        refresh()

        refreshLoopTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }

                let interval = self.settingsStore.settings.refreshInterval.seconds
                try? await Task.sleep(for: .seconds(interval))

                guard !Task.isCancelled else { return }
                self.refresh()
            }
        }
    }

    func stopRefreshing() {
        refreshLoopTask?.cancel()
        refreshLoopTask = nil
    }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let snapshot = memoryMonitorService.snapshot()
        let runningApplications = runningApplicationsService.runningApplications()
        let processSnapshots = processMemoryService.runningProcessSnapshots()

        let applications: [AppMemoryStat] = runningApplications.compactMap { application in
            guard let attribution = processMemoryService.attributedMemory(
                for: application,
                using: processSnapshots
            ) else {
                return nil
            }

            let percentOfTotal = snapshot.totalBytes > 0
                ? Double(attribution.memoryBytes) / Double(snapshot.totalBytes)
                : 0
            let impactPercent: Double

            if snapshot.availableBytes > 0 {
                impactPercent = min(
                    Double(attribution.memoryBytes) / Double(snapshot.availableBytes),
                    1
                )
            } else {
                impactPercent = attribution.memoryBytes > 0 ? 1 : 0
            }

            return AppMemoryStat(
                pid: application.processIdentifier,
                name: application.localizedName ?? "Unknown App",
                bundleIdentifier: application.bundleIdentifier,
                icon: settingsStore.settings.showAppIcons ? application.icon : nil,
                memoryBytes: attribution.memoryBytes,
                memoryPercentOfTotal: percentOfTotal,
                memoryImpactPercent: impactPercent,
                isFrontmost: application.isActive,
                processCount: attribution.processCount
            )
        }

        let filteredApplications = filteredApplications(
            from: applications,
            settings: settingsStore.settings,
            totalMemoryBytes: snapshot.totalBytes
        )
        let attributedApplicationBytes = applications.reduce(into: UInt64(0)) { partialResult, stat in
            partialResult += stat.memoryBytes
        }
        let unattributedMemoryBytes = snapshot.usedBytes > attributedApplicationBytes
            ? snapshot.usedBytes - attributedApplicationBytes
            : 0

        self.snapshot = snapshot
        self.topApplications = filteredApplications
        self.lastUpdatedAt = snapshot.capturedAt
        self.unattributedMemoryBytes = unattributedMemoryBytes
        self.statusMessage = statusMessage(
            filteredApplications: filteredApplications,
            unattributedMemoryBytes: unattributedMemoryBytes,
            totalMemoryBytes: snapshot.totalBytes
        )
    }

    func quit(_ stat: AppMemoryStat) {
        guard let application = runningApplicationsService.application(for: stat.pid) else {
            statusMessage = "KillSwitch could not find \(stat.name) anymore."
            return
        }

        do {
            try applicationQuitService.terminate(application)
            statusMessage = "Requested a graceful quit for \(stat.name)."

            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(900))
                self?.refresh()
            }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func openAboutPanel() {
        NSApp.activate(ignoringOtherApps: true)
        let aboutOptions: [NSApplication.AboutPanelOptionKey: Any] = [
            .applicationIcon: AppIconProvider.applicationIconImage(),
            .applicationName: AppConstants.appName,
        ]
        NSApp.orderFrontStandardAboutPanel(aboutOptions)
    }

    func checkForUpdates() {
        guard updateService.isConfigured else {
            statusMessage = "Update checks are not wired yet."
            return
        }

        updateService.checkForUpdates()
    }

    private func filteredApplications(
        from applications: [AppMemoryStat],
        settings: SettingsModel,
        totalMemoryBytes: UInt64
    ) -> [AppMemoryStat] {
        let rankedByMemory = applications.sorted { $0.memoryBytes > $1.memoryBytes }
        let threshold = settings.baseloadLimit.thresholdBytes(for: totalMemoryBytes)
        let forcedTopIDs = Set(rankedByMemory.prefix(AppConstants.topApplicationCount).map(\.id))

        let filtered = rankedByMemory.filter { stat in
            forcedTopIDs.contains(stat.id) || stat.memoryBytes >= threshold
        }

        switch settings.sortMode {
        case .memory:
            return filtered.sorted { $0.memoryBytes > $1.memoryBytes }
        case .name:
            return filtered.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
    }

    private func statusMessage(
        filteredApplications: [AppMemoryStat],
        unattributedMemoryBytes: UInt64,
        totalMemoryBytes: UInt64
    ) -> String? {
        if filteredApplications.isEmpty {
            return "No user apps matched the current filter."
        }

        guard totalMemoryBytes > 0 else { return nil }

        let otherPercent = Double(unattributedMemoryBytes) / Double(totalMemoryBytes)
        guard unattributedMemoryBytes >= 1_073_741_824 || otherPercent >= 0.15 else {
            return nil
        }

        return "\(Formatters.memory(unattributedMemoryBytes)) is outside visible apps."
    }
}
