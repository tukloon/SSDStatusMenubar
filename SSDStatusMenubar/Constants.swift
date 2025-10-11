import Foundation
import SwiftUI

enum Constants {
    enum Menu {
        static let quitKeyEquivalent = "q"
        static let fontSize: CGFloat = 14.0
    }
    
    enum StatusBar {
        static let updateInterval: TimeInterval = 5.0
    }
    
    enum View {
        static let hStackSpacing: CGFloat = 4
        static let mainFontSize: CGFloat = 12
        static let unitFontSize: CGFloat = 6
        static let underlineHeight: CGFloat = 7
        static let underlineOffsetY: CGFloat = 6.5
        static let barWidth: CGFloat = 30
        static let barHeight: CGFloat = 20
        static let horizontalPadding: CGFloat = 5
        static let innerPadding: CGFloat = 2
        static let cornerRadius: CGFloat = 2
        static let minimumScale: CGFloat = 0.5
    }
    
    enum DiskSpace {
        static let defaultTotalCapacity: Int64 = 1 // 0除算を避けるため
    }
}