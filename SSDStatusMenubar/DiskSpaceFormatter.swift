import Foundation

struct DiskSpaceFormatter {
    
    static let menuDisplay: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .decimal
        formatter.allowedUnits = [.useGB]
        formatter.includesUnit = true
        formatter.includesActualByteCount = false
        return formatter
    }()
    
    static let statusBarDisplay: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .decimal
        formatter.allowedUnits = [.useGB]
        formatter.includesUnit = false
        formatter.zeroPadsFractionDigits = true
        return formatter
    }()
}

extension Int64 {
    func formattedBytes() -> String {
        return DiskSpaceFormatter.menuDisplay.string(fromByteCount: self)
    }
}