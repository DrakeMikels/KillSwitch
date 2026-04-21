import AppKit

struct RunningApplicationsService {
    func runningApplications() -> [NSRunningApplication] {
        let currentBundleIdentifier = Bundle.main.bundleIdentifier
        let currentPID = ProcessInfo.processInfo.processIdentifier

        return NSWorkspace.shared.runningApplications.filter { application in
            guard !application.isTerminated else { return false }
            guard application.activationPolicy == .regular else { return false }
            guard application.processIdentifier != currentPID else { return false }
            guard application.bundleIdentifier != currentBundleIdentifier else { return false }
            return application.localizedName?.isEmpty == false
        }
    }

    func application(for pid: pid_t) -> NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first { $0.processIdentifier == pid }
    }
}

