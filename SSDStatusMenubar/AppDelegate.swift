import SwiftUI
import AppKit
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {

    private var statusItem: NSStatusItem?
    private var hostingView: NSHostingView<SSDUsageView>?
    private var diskSpaceMonitor = DiskSpaceMonitor()
    private var menuManager: StatusMenuManager?
    private var cancellables = Set<AnyCancellable>()


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupStatusBar()
        setupObservers()
    }

    private func setupStatusBar() {
        // Create status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Setup view
        setupStatusBarView()
        
        // Setup menu
        if let statusItem = statusItem {
            menuManager = StatusMenuManager(statusItem: statusItem)
            menuManager?.setUpdateCallback { [weak self] in
                Task { @MainActor in
                    await self?.diskSpaceMonitor.updateDiskSpace()
                }
            }
        }
    }
    
    private func setupStatusBarView() {
        // 初期ビューを設定
        let initialView = SSDUsageView(diskSpaceMonitor: diskSpaceMonitor)
        hostingView = NSHostingView(rootView: initialView)
        
        // NSHostingViewのサイズをコンテンツに合わせて調整
        if let newSize = hostingView?.fittingSize {
            hostingView?.frame = NSRect(x: 0, y: 0, width: newSize.width, height: NSStatusBar.system.thickness)
        }

        if let button = statusItem?.button {
            button.addSubview(hostingView!)
            button.frame = hostingView!.frame
        }
    }


    private func setupObservers() {
        // Subscribe to disk space monitor updates
        diskSpaceMonitor.$availableCapacity
            .combineLatest(diskSpaceMonitor.$totalCapacity, diskSpaceMonitor.$isErrorState)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] available, total, isError in
                self?.updateUI(available: available, total: total, isError: isError)
            }
            .store(in: &cancellables)
    }

    private func updateUI(available: Int64, total: Int64, isError: Bool) {
        // Update status bar view
        updateStatusBarView(available: available, total: total, isError: isError)
        
        // Update menu
        let used = total - available
        menuManager?.updateCapacityDisplay(total: total, used: used, isError: isError)
    }
    
    private func updateStatusBarView(available: Int64, total: Int64, isError: Bool) {
        // フレームの調整を実行
        // @ObservedObject が正しく動作するはずですが、念のため手動更新も確保
        DispatchQueue.main.async { [weak self] in
            self?.adjustHostingViewFrame()
        }
    }

    private func adjustHostingViewFrame() {
        guard let hostingView = hostingView,
              let button = statusItem?.button else { return }
        
        let newSize = hostingView.fittingSize
        hostingView.frame = NSRect(x: 0, y: 0, width: newSize.width, height: NSStatusBar.system.thickness)
        button.frame = hostingView.frame
    }
}
