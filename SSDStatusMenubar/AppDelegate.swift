import SwiftUI
import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {

    
    static let quitKeyEquivalent: String = "q"
    static let menuFontSize: CGFloat = 14.0

    var statusItem: NSStatusItem?
    var hostingView: NSHostingView<SSDUsageView>?
    var diskSpaceMonitor = DiskSpaceMonitor()
    var totalCapacityMenuItem: NSMenuItem? // 総容量表示用のメニュー項目
    var usedCapacityMenuItem: NSMenuItem? // 使用容量表示用のメニュー項目

    private let byteCountFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter
    }()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // 初期ビューを設定
        let initialView = SSDUsageView(availableCapacity: Int64(0), totalCapacity: Int64(1), isErrorState: false)
        hostingView = NSHostingView(rootView: initialView)
        
        // NSHostingViewのサイズをコンテンツに合わせて調整
        if let newSize = hostingView?.fittingSize {
            hostingView?.frame = NSRect(x: 0, y: 0, width: newSize.width, height: NSStatusBar.system.thickness)
        }

        if let button = statusItem?.button {
            button.addSubview(hostingView!)
            button.frame = hostingView!.frame // ボタンのフレームをビューに合わせる
        }

        setupStatusBarMenu() // メニュー設定を呼び出し

        // DiskSpaceMonitorからの更新を購読
        diskSpaceMonitor.$availableCapacity
            .combineLatest(diskSpaceMonitor.$totalCapacity, diskSpaceMonitor.$isErrorState)
            .sink { [weak self] available, total, isError in
                guard let self = self else { return }
                let newView = SSDUsageView(availableCapacity: available, totalCapacity: total, isErrorState: isError)
                self.hostingView?.rootView = newView
                
                if let newSize = self.hostingView?.fittingSize {
                    self.hostingView?.frame = NSRect(x: 0, y: 0, width: newSize.width, height: NSStatusBar.system.thickness)
                    self.statusItem?.button?.frame = self.hostingView!.frame
                }

                let formatter = self.byteCountFormatter

                if isError {
                    self.totalCapacityMenuItem?.attributedTitle = self.createAttributedTitle(text: "Total: Error")
                    self.usedCapacityMenuItem?.attributedTitle = self.createAttributedTitle(text: "Used: Error")
                } else {
                    let formattedTotalCapacity = formatter.string(fromByteCount: total)
                    self.totalCapacityMenuItem?.attributedTitle = self.createAttributedTitle(text: "Total: \(formattedTotalCapacity)")

                    let usedCapacity = total - available
                    let formattedUsedCapacity = formatter.string(fromByteCount: usedCapacity)
                    self.usedCapacityMenuItem?.attributedTitle = self.createAttributedTitle(text: "Used: \(formattedUsedCapacity)")
                }
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    private func createAttributedTitle(text: String) -> NSAttributedString {
        let font = NSFont.systemFont(ofSize: AppDelegate.menuFontSize)
        return NSAttributedString(string: text, attributes: [.foregroundColor: NSColor.labelColor, .font: font])
    }

    private func setupStatusBarMenu() {
        let menu = NSMenu()

        totalCapacityMenuItem = NSMenuItem(title: "", action: #selector(dismissMenu(_:)), keyEquivalent: "")
        totalCapacityMenuItem?.attributedTitle = createAttributedTitle(text: "Total: Calculating...")
        menu.addItem(totalCapacityMenuItem!)

        usedCapacityMenuItem = NSMenuItem(title: "", action: #selector(dismissMenu(_:)), keyEquivalent: "")
        usedCapacityMenuItem?.attributedTitle = createAttributedTitle(text: "Used: Calculating...")
        menu.addItem(usedCapacityMenuItem!)

        menu.addItem(NSMenuItem.separator()) // 区切り線を追加
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: AppDelegate.quitKeyEquivalent))
        statusItem?.menu = menu
    }

    @objc private func dismissMenu(_ sender: NSMenuItem) {
        statusItem?.menu?.cancelTracking()
    }
}