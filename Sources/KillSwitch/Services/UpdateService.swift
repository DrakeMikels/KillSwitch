import AppKit
import Foundation

struct UpdateService {
    let releasesURL: URL?

    init(releasesURL: URL? = AppConstants.releasesURL) {
        self.releasesURL = releasesURL
    }

    var isConfigured: Bool {
        releasesURL != nil
    }

    func checkForUpdates() {
        guard let releasesURL else { return }
        NSWorkspace.shared.open(releasesURL)
    }
}

