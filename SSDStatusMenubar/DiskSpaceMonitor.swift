
import Foundation
import Combine

class DiskSpaceMonitor: ObservableObject {
    static let updateInterval: TimeInterval = 10.0
    @Published var availableCapacity: Int64 = 0
    @Published var totalCapacity: Int64 = 1 // 0除算を避けるため初期値を1に設定
    @Published var isErrorState: Bool = false

    private var timer: AnyCancellable?

    init() {
        startMonitoring()
    }

    func startMonitoring() {
        timer = Timer.publish(every: DiskSpaceMonitor.updateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateDiskSpace()
            }
        updateDiskSpace() // 初期表示のために一度更新
    }

    func stopMonitoring() {
        timer?.cancel()
        timer = nil
    }

    private func updateDiskSpace() {
        do {
            let fileURL = URL(fileURLWithPath: "/")
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey])
            
            if let available = values.volumeAvailableCapacityForImportantUsage, let total = values.volumeTotalCapacity {
                self.availableCapacity = available
                self.totalCapacity = Int64(total)
                self.isErrorState = false
            } else {
                self.availableCapacity = 0
                self.totalCapacity = 1
                self.isErrorState = true
            }
        } catch {
            self.availableCapacity = 0
            self.totalCapacity = 1
            self.isErrorState = true
            print("Error retrieving disk space: \(error.localizedDescription)")
        }
    }
}
