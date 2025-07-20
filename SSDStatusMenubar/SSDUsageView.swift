import SwiftUI

/// A view that displays available disk space as a bar meter and text.
struct SSDUsageView: View {
    @ObservedObject var diskSpaceMonitor: DiskSpaceMonitor

    var body: some View {
        HStack(spacing: Constants.View.hStackSpacing) {
            if diskSpaceMonitor.isErrorState {
                Text("Error")
                    .font(.system(size: Constants.View.mainFontSize))
                    .foregroundColor(.red)
                    .padding(.horizontal, Constants.View.innerPadding)
            } else {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Filled bar
                        RoundedRectangle(cornerRadius: Constants.View.cornerRadius)
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * CGFloat(diskSpaceMonitor.freeSpaceFraction))
                        // Underline
                        Rectangle()
                            .fill(Color.secondary)
                            .frame(height: Constants.View.underlineHeight)
                            .offset(y: Constants.View.underlineOffsetY)
                        // Text overlay
                        VStack(alignment: .trailing) {
                            Text(diskSpaceMonitor.formattedAvailableCapacity)
                                .font(.system(size: Constants.View.mainFontSize))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(Constants.View.minimumScale)
                            Text("GB")
                                .font(.system(size: Constants.View.unitFontSize))
                                .foregroundColor(.primary)
                        }
                        .frame(width: geometry.size.width, alignment: .trailing)
                        .padding(.horizontal, Constants.View.innerPadding)
                    }
                }
            }
        }
        .frame(width: Constants.View.barWidth, height: Constants.View.barHeight)
        .padding(.horizontal, Constants.View.horizontalPadding)
    }
}

struct SSDUsageView_Previews: PreviewProvider {
    @MainActor
    static var previews: some View {
        let mockProvider = MockDiskSpaceProvider(
            available: 140_000_000_000,
            total: 250_000_000_000,
            shouldFail: false
        )
        let monitor = DiskSpaceMonitor(provider: mockProvider)
        
        SSDUsageView(diskSpaceMonitor: monitor)
            .previewLayout(.fixed(width: 50, height: 20))
    }
}
