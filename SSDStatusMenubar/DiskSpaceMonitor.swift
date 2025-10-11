import Foundation
import Combine
import OSLog

@MainActor
class DiskSpaceMonitor: ObservableObject {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DiskSpaceMonitor", category: "DiskSpaceMonitor")
    
    let updateInterval: TimeInterval
    @Published var availableCapacity: Int64 = 0
    @Published var totalCapacity: Int64 = Constants.DiskSpace.defaultTotalCapacity
    @Published var isErrorState: Bool = false
    
    private let diskSpaceProvider: DiskSpaceProvider
    private var timer: AnyCancellable?
    private var updateTask: Task<Void, Never>?
    
    /// Creates a disk space monitor.
    /// - Parameters:
    ///   - updateInterval: Time interval between updates.
    ///   - provider: Provider for disk space information.
    init(updateInterval: TimeInterval = Constants.StatusBar.updateInterval,
         provider: DiskSpaceProvider = SystemDiskSpaceProvider()) {
        self.updateInterval = updateInterval
        self.diskSpaceProvider = provider
        startMonitoring()
    }
    
    /// Starts the disk space monitoring timer.
    private func startMonitoring() {
        timer = Timer.publish(every: self.updateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.scheduleUpdate()
            }
        scheduleUpdate() // 初期表示のために一度更新
    }
    
    /// Stops the disk space monitoring timer.
    private func stopMonitoring() {
        timer?.cancel()
        timer = nil
        updateTask?.cancel()
        updateTask = nil
    }
    
    private func scheduleUpdate() {
        updateTask?.cancel()
        updateTask = Task { @MainActor in
            await updateDiskSpace()
        }
    }
    
    func updateDiskSpace() async {
        do {
            let (available, total) = try await diskSpaceProvider.getDiskSpace()
            
            self.availableCapacity = available
            self.totalCapacity = total
            self.isErrorState = false
        } catch {
            self.availableCapacity = 0
            self.totalCapacity = Constants.DiskSpace.defaultTotalCapacity
            self.isErrorState = true
            
            Self.logger.error("Error retrieving disk space: \(error.localizedDescription)")
        }
    }
    
    deinit {
        timer?.cancel()
        updateTask?.cancel()
    }
    
    /// Fraction of disk capacity that is available (0.0 to 1.0).
    var freeSpaceFraction: Double {
        guard totalCapacity > 0 else { return 0.0 }
        return Double(availableCapacity) / Double(totalCapacity)
    }
    
    /// Formatted string of available capacity for status bar display.
    var formattedAvailableCapacity: String {
        return DiskSpaceFormatter.statusBarDisplay.string(fromByteCount: availableCapacity)
    }
}

