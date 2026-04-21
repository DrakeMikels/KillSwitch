import Darwin
import Foundation

struct MemoryMonitorService {
    func snapshot() -> MemorySnapshot {
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        let pageSize = currentPageSize()

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

        let kernelStatus = withUnsafeMutablePointer(to: &stats) { statsPointer in
            statsPointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { integerPointer in
                host_statistics64(
                    mach_host_self(),
                    HOST_VM_INFO64,
                    integerPointer,
                    &count
                )
            }
        }

        guard kernelStatus == KERN_SUCCESS else {
            return MemorySnapshot(
                totalBytes: totalBytes,
                usedBytes: totalBytes / 2,
                availableBytes: totalBytes / 2,
                usedPercent: 0.5,
                pressureLevel: .elevated,
                capturedAt: .now
            )
        }

        let freeBytes = UInt64(stats.free_count + stats.speculative_count) * pageSize
        let inactiveBytes = UInt64(stats.inactive_count) * pageSize
        let availableBytes = min(totalBytes, freeBytes + inactiveBytes)
        let usedBytes = min(totalBytes, totalBytes > availableBytes ? totalBytes - availableBytes : 0)
        let usedPercent = totalBytes > 0 ? Double(usedBytes) / Double(totalBytes) : 0

        return MemorySnapshot(
            totalBytes: totalBytes,
            usedBytes: usedBytes,
            availableBytes: availableBytes,
            usedPercent: usedPercent,
            pressureLevel: pressureLevel(
                availableBytes: availableBytes,
                totalBytes: totalBytes,
                compressedBytes: UInt64(stats.compressor_page_count) * pageSize
            ),
            capturedAt: .now
        )
    }

    private func currentPageSize() -> UInt64 {
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        return UInt64(pageSize)
    }

    private func pressureLevel(
        availableBytes: UInt64,
        totalBytes: UInt64,
        compressedBytes: UInt64
    ) -> PressureLevel {
        guard totalBytes > 0 else { return .normal }

        let availableRatio = Double(availableBytes) / Double(totalBytes)
        let compressedRatio = Double(compressedBytes) / Double(totalBytes)

        if availableRatio > 0.25 && compressedRatio < 0.05 {
            return .normal
        }
        if availableRatio > 0.16 && compressedRatio < 0.10 {
            return .elevated
        }
        if availableRatio > 0.08 {
            return .high
        }
        return .critical
    }
}

