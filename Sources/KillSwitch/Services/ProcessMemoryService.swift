import AppKit
import Darwin

struct ProcessSnapshot {
    let pid: pid_t
    let executablePath: String
    let memoryBytes: UInt64
}

struct ProcessAttribution {
    let memoryBytes: UInt64
    let processCount: Int
}

struct ProcessMemoryService {
    func residentMemoryBytes(for pid: pid_t) -> UInt64? {
        var taskInfo = proc_taskinfo()

        let result = withUnsafeMutableBytes(of: &taskInfo) { buffer -> Int32 in
            guard let baseAddress = buffer.baseAddress else { return 0 }
            return proc_pidinfo(
                pid,
                PROC_PIDTASKINFO,
                0,
                baseAddress,
                Int32(buffer.count)
            )
        }

        guard result == Int32(MemoryLayout<proc_taskinfo>.stride) else {
            return nil
        }

        return UInt64(taskInfo.pti_resident_size)
    }

    func runningProcessSnapshots(excluding excludedPIDs: Set<pid_t> = []) -> [ProcessSnapshot] {
        let maxProcessCount = Int(proc_listallpids(nil, 0))
        guard maxProcessCount > 0 else { return [] }

        var pids = [pid_t](repeating: 0, count: maxProcessCount)
        let bytes = Int32(pids.count * MemoryLayout<pid_t>.stride)
        let processCount = pids.withUnsafeMutableBufferPointer { buffer in
            proc_listallpids(buffer.baseAddress, bytes)
        }

        guard processCount > 0 else { return [] }

        return pids
            .prefix(Int(processCount))
            .filter { $0 > 0 && !excludedPIDs.contains($0) }
            .compactMap(processSnapshot(for:))
    }

    func attributedMemory(
        for application: NSRunningApplication,
        using snapshots: [ProcessSnapshot]
    ) -> ProcessAttribution? {
        let matchedSnapshots = matchingSnapshots(for: application, using: snapshots)

        guard !matchedSnapshots.isEmpty else {
            guard let memoryBytes = residentMemoryBytes(for: application.processIdentifier) else {
                return nil
            }

            return ProcessAttribution(memoryBytes: memoryBytes, processCount: 1)
        }

        let totalBytes = matchedSnapshots.reduce(into: UInt64(0)) { partialResult, snapshot in
            partialResult += snapshot.memoryBytes
        }

        return ProcessAttribution(memoryBytes: totalBytes, processCount: matchedSnapshots.count)
    }

    private func processSnapshot(for pid: pid_t) -> ProcessSnapshot? {
        guard let memoryBytes = residentMemoryBytes(for: pid) else {
            return nil
        }

        var pathBuffer = [CChar](repeating: 0, count: Int(PROC_PIDPATHINFO_SIZE))
        let pathLength = proc_pidpath(pid, &pathBuffer, UInt32(pathBuffer.count))
        guard pathLength > 0 else {
            return nil
        }

        let executablePath = String(cString: pathBuffer).standardizedExecutablePath
        return ProcessSnapshot(pid: pid, executablePath: executablePath, memoryBytes: memoryBytes)
    }

    private func matchingSnapshots(
        for application: NSRunningApplication,
        using snapshots: [ProcessSnapshot]
    ) -> [ProcessSnapshot] {
        let bundleRootPath = application.bundleURL?.path.standardizedExecutablePath

        return snapshots.filter { snapshot in
            if snapshot.pid == application.processIdentifier {
                return true
            }

            guard let bundleRootPath else {
                return false
            }

            return snapshot.executablePath.hasPrefix(bundleRootPath + "/")
        }
    }
}

private extension String {
    var standardizedExecutablePath: String {
        let expandedPath = NSString(string: self).expandingTildeInPath
        let resolvedPath = NSString(string: expandedPath).resolvingSymlinksInPath
        return NSString(string: resolvedPath).standardizingPath
    }
}
