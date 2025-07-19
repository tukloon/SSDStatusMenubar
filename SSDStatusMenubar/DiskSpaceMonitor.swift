import Foundation
import Combine
import OSLog

class DiskSpaceMonitor: ObservableObject {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DiskSpaceMonitor", category: "DiskSpaceMonitor")
    let updateInterval: TimeInterval
    @Published var availableCapacity: Int64 = 0
    @Published var totalCapacity: Int64 = 1 // 0除算を避けるため初期値を1に設定
    @Published var isErrorState: Bool = false

    private var timer: AnyCancellable?

    /// Creates a disk space monitor.
    /// - Parameters:
    ///   - updateInterval: Time interval between updates.
    ///   - monitoredURL: File system URL to monitor.
    init(updateInterval: TimeInterval = 10.0) {
        self.updateInterval = updateInterval
        startMonitoring()
    }

    /// Starts the disk space monitoring timer.
    private func startMonitoring() {
        timer = Timer.publish(every: self.updateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateDiskSpace()
            }
        updateDiskSpace() // 初期表示のために一度更新
    }

    /// Stops the disk space monitoring timer.
    private func stopMonitoring() {
        timer?.cancel()
        timer = nil
    }

    private func updateDiskSpace() {
        let url = URL(fileURLWithPath: "/")
        do {
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey])
            let freeBytes = Int64(values.volumeAvailableCapacityForImportantUsage ?? 0)
            let totalBytes = Int64(values.volumeTotalCapacity ?? 1)

            DispatchQueue.main.async {
                self.availableCapacity = freeBytes
                self.totalCapacity = totalBytes
                self.isErrorState = false
            }
        } catch {
            DispatchQueue.main.async {
                self.availableCapacity = 0
                self.totalCapacity = 1
                self.isErrorState = true
            }
            Self.logger.error("Error retrieving disk space: \(error.localizedDescription)")
        }
    }
    
    deinit {
        stopMonitoring()
    }

    /// Percentage of disk capacity that is used.
    var usedCapacityPercentage: Double {
        let used = Double(totalCapacity - availableCapacity)
        let total = Double(totalCapacity)
        return (used / total) * 100.0
    }
}

