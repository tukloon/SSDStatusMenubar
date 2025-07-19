import SwiftUI

/// A view that displays available disk space as a bar meter and text.
struct SSDUsageView: View {
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

    var availableCapacity: Int64
    var totalCapacity: Int64
    var isErrorState: Bool

    private var freeSpacePercentage: Double {
        guard totalCapacity > 0 else { return 0.0 }
        return Double(availableCapacity) / Double(totalCapacity)
    }

    private var formattedCapacityInMeter: String {
        return DiskSpaceFormatter.statusBarDisplay.string(fromByteCount: availableCapacity)
    }

    var body: some View {
        HStack(spacing: Self.hStackSpacing) {
            if isErrorState {
                Text("Error")
                    .font(.system(size: Self.mainFontSize))
                    .foregroundColor(.red)
                    .padding(.horizontal, Self.innerPadding)
            } else {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Filled bar
                        RoundedRectangle(cornerRadius: Self.cornerRadius)
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * CGFloat(freeSpacePercentage))
                        // Underline
                        Rectangle()
                            .fill(Color.secondary)
                            .frame(height: Self.underlineHeight)
                            .offset(y: Self.underlineOffsetY)
                        // Text overlay
                        VStack(alignment: .trailing) {
                            Text(formattedCapacityInMeter)
                                .font(.system(size: Self.mainFontSize))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(Self.minimumScale)
                            Text("GB")
                                .font(.system(size: Self.unitFontSize))
                                .foregroundColor(.primary)
                        }
                        .frame(width: geometry.size.width, alignment: .trailing)
                        .padding(.horizontal, Self.innerPadding)
                    }
                }
            }
        }
        .frame(width: Self.barWidth, height: Self.barHeight)
        .padding(.horizontal, Self.horizontalPadding)
    }
}

struct SSDUsageView_Previews: PreviewProvider {
    static var previews: some View {
        SSDUsageView(
            availableCapacity: 140_000_000_000,
            totalCapacity: 250_000_000_000,
            isErrorState: false
        )
        .previewLayout(.fixed(width: 50, height: 20))
    }
}
