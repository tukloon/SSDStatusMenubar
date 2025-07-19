import SwiftUI
import AppKit
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {

    
    static let quitKeyEquivalent: String = "q"
    static let menuFontSize: CGFloat = 14.0

    var statusItem: NSStatusItem?
    var hostingView: NSHostingView<SSDUsageView>?
    var diskSpaceMonitor = DiskSpaceMonitor()
    private var totalCapacityMenuItem: NSMenuItem? // 総容量表示用のメニュー項目
    private var usedCapacityMenuItem: NSMenuItem? // 使用容量表示用のメニュー項目


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupStatusBarView()

        setupStatusBarMenu() // メニュー設定を呼び出し

        // Observe disk space changes
        setupObservers()
    }

    private func setupStatusBarView() {
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
    }

    private var cancellables = Set<AnyCancellable>()

    private func createAttributedTitle(text: String) -> NSAttributedString {
        let font = NSFont.systemFont(ofSize: AppDelegate.menuFontSize)
        return NSAttributedString(string: text, attributes: [.foregroundColor: NSColor.labelColor, .font: font])
    }

    private func createMenuItem(withText text: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: "", action: action, keyEquivalent: "")
        item.target = self
        item.attributedTitle = createAttributedTitle(text: text)
        return item
    }

    private func setupStatusBarMenu() {
        let menu = NSMenu()

        totalCapacityMenuItem = createMenuItem(withText: "Total: Calculating...", action: #selector(dismissMenu(_:)))
        menu.addItem(totalCapacityMenuItem!)

        usedCapacityMenuItem = createMenuItem(withText: "Used: Calculating...", action: #selector(dismissMenu(_:)))
        menu.addItem(usedCapacityMenuItem!)

        menu.addItem(NSMenuItem.separator()) // 区切り線を追加
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: AppDelegate.quitKeyEquivalent))
        statusItem?.menu = menu
    }

    /// Subscribe to diskSpaceMonitor updates and refresh view
    private func setupObservers() {
        diskSpaceMonitor.$availableCapacity
            .combineLatest(diskSpaceMonitor.$totalCapacity, diskSpaceMonitor.$isErrorState)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] available, total, isError in
                self?.updateView(available: available, total: total, isError: isError)
            }
            .store(in: &cancellables)
    }

    private func updateView(available: Int64, total: Int64, isError: Bool) {
        let newView = SSDUsageView(availableCapacity: available, totalCapacity: total, isErrorState: isError)
        hostingView?.rootView = newView

        // Update frame based on new content
        adjustHostingViewFrame()

        // Update menu item titles
        let used = total - available
        updateMenuItems(total: total, used: used, isError: isError)
    }

    /// Update menu titles based on capacity values
    private func updateMenuItems(total: Int64, used: Int64, isError: Bool) {
        if isError {
            totalCapacityMenuItem?.attributedTitle = createAttributedTitle(text: "Total: Error")
            usedCapacityMenuItem?.attributedTitle = createAttributedTitle(text: "Used: Error")
        } else {
            let formattedTotal = DiskSpaceFormatter.menuDisplay.string(fromByteCount: total)
            totalCapacityMenuItem?.attributedTitle = createAttributedTitle(text: "Total: \(formattedTotal)")
            let formattedUsed = DiskSpaceFormatter.menuDisplay.string(fromByteCount: used)
            usedCapacityMenuItem?.attributedTitle = createAttributedTitle(text: "Used: \(formattedUsed)")
        }
    }

    /// Update hostingView and statusItem button frames based on content size
    private func adjustHostingViewFrame() {
        guard let hostingView = hostingView,
              let button = statusItem?.button else { return }
        let newSize = hostingView.fittingSize
        hostingView.frame = NSRect(x: 0, y: 0, width: newSize.width, height: NSStatusBar.system.thickness)
        button.frame = hostingView.frame
    }

    @objc private func dismissMenu(_ sender: NSMenuItem) {
        statusItem?.menu?.cancelTracking()
    }
}
