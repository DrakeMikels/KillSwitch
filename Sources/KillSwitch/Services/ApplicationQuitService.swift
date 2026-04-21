import AppKit
import Foundation

struct ApplicationQuitService {
    enum TerminationError: LocalizedError {
        case failedToTerminate(String)

        var errorDescription: String? {
            switch self {
            case let .failedToTerminate(name):
                return "KillSwitch could not quit \(name) gracefully."
            }
        }
    }

    func terminate(_ application: NSRunningApplication) throws {
        let didRequestTermination = application.terminate()
        guard didRequestTermination else {
            throw TerminationError.failedToTerminate(application.localizedName ?? "that app")
        }
    }
}

