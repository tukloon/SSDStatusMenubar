import SwiftUI

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

    var freeSpacePercentage: Double {
        guard totalCapacity > 0 else { return 0.0 }
        return Double(availableCapacity) / Double(totalCapacity)
    }

    var formattedCapacityInMeter: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useAll]
        formatter.includesUnit = false
        formatter.isAdaptive = true
        formatter.zeroPadsFractionDigits = true // 小数点以下をゼロ埋め
        return formatter.string(fromByteCount: availableCapacity)
    }

    var body: some View {
        HStack(spacing: Self.hStackSpacing) {
            if isErrorState { // Use the new property
                Text("Error")
                    .font(.system(size: Self.mainFontSize))
                    .foregroundColor(.red) // エラーテキストを赤色に
                    .padding(.horizontal, Self.innerPadding)
            } else {
                // グラフィカルなバーと残り容量テキスト
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        

                        // 残量を示すバー
                        RoundedRectangle(cornerRadius: Self.cornerRadius)
                            .fill(Color.accentColor) // アクセントカラーに
                            .frame(width: geometry.size.width * CGFloat(freeSpacePercentage))

                        // 下線
                        Rectangle()
                            .fill(Color.secondary) // セカンダリカラーに
                            .frame(height: Self.underlineHeight) // 下線の太さ
                            .offset(y: Self.underlineOffsetY) // バーの最下部に配置
                        
                        // メーター内の残り容量テキスト
                        VStack(alignment: .trailing) {
                            Text(formattedCapacityInMeter)
                                .font(.system(size: Self.mainFontSize)) // フォントサイズを調整
                                .foregroundColor(.primary) // プライマリカラーに
                                .lineLimit(1)
                                .minimumScaleFactor(Self.minimumScale)
                            Text("GB")
                                .font(.system(size: Self.unitFontSize)) // GBのフォントサイズを小さく
                                .foregroundColor(.primary) // プライマリカラーに
                        }
                        .frame(width: geometry.size.width, alignment: .trailing) // バーの幅全体に広げ、右寄せ
                        .padding(.horizontal, Self.innerPadding) // 左右に少しパディング
                    }
                }
            }
        }
        .frame(width: Self.barWidth, height: Self.barHeight) // バーの固定サイズ
        .padding(.horizontal, Self.horizontalPadding) // メニューバー内でのパディング
    }
}


// Xcodeのキャンバス（プレビュー機能）用
struct SSDUsageView_Previews: PreviewProvider {
    static var previews: some View {
        SSDUsageView(availableCapacity: 500_000_000_000, totalCapacity: 1_000_000_000_000, isErrorState: false) // Update preview
            .previewLayout(.fixed(width: 50, height: 20))
    }
}