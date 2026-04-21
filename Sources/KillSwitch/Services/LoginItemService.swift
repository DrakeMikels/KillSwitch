import Foundation
import ServiceManagement

struct LoginItemService {
    func setEnabled(_ enabled: Bool) {
        guard #available(macOS 13.0, *) else { return }

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("KillSwitch could not update launch-at-login state: %@", error.localizedDescription)
        }
    }
}

