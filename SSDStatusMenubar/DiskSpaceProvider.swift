import Foundation

enum DiskSpaceError: LocalizedError {
    case retrievalFailed(underlying: Error)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .retrievalFailed(let error):
            return "Failed to retrieve disk space: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid disk space data"
        }
    }
}

protocol DiskSpaceProvider {
    func getDiskSpace() async throws -> (available: Int64, total: Int64)
}

class SystemDiskSpaceProvider: DiskSpaceProvider {
    private let url: URL
    
    init(url: URL = URL(fileURLWithPath: "/")) {
        self.url = url
    }
    
    func getDiskSpace() async throws -> (available: Int64, total: Int64) {
        do {
            let values = try url.resourceValues(forKeys: [
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeTotalCapacityKey
            ])
            
            guard let availableCapacity = values.volumeAvailableCapacityForImportantUsage,
                  let totalCapacity = values.volumeTotalCapacity else {
                throw DiskSpaceError.invalidData
            }
            
            return (available: Int64(availableCapacity), total: Int64(totalCapacity))
        } catch let error as DiskSpaceError {
            throw error
        } catch {
            throw DiskSpaceError.retrievalFailed(underlying: error)
        }
    }
}

// For testing purposes
class MockDiskSpaceProvider: DiskSpaceProvider {
    private let mockAvailable: Int64
    private let mockTotal: Int64
    private let shouldFail: Bool
    
    init(available: Int64 = 140_000_000_000, total: Int64 = 250_000_000_000, shouldFail: Bool = false) {
        self.mockAvailable = available
        self.mockTotal = total
        self.shouldFail = shouldFail
    }
    
    func getDiskSpace() async throws -> (available: Int64, total: Int64) {
        if shouldFail {
            throw DiskSpaceError.invalidData
        }
        return (available: mockAvailable, total: mockTotal)
    }
}