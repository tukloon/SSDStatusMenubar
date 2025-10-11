import AppKit

@MainActor
class StatusMenuManager: NSObject {
    private weak var statusItem: NSStatusItem?
    private var totalCapacityMenuItem: NSMenuItem?
    private var usedCapacityMenuItem: NSMenuItem?
    private var updateCallback: (() -> Void)?
    
    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        super.init()
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        menu.delegate = self
        
        // Total capacity menu item
        totalCapacityMenuItem = createMenuItem(withText: "Total: Calculating...", action: #selector(dismissMenu(_:)))
        menu.addItem(totalCapacityMenuItem!)
        
        // Used capacity menu item
        usedCapacityMenuItem = createMenuItem(withText: "Used: Calculating...", action: #selector(dismissMenu(_:)))
        menu.addItem(usedCapacityMenuItem!)
        
        // Separator and quit menu item
        menu.addItem(NSMenuItem.separator())
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: Constants.Menu.quitKeyEquivalent
        )
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    func setUpdateCallback(_ callback: @escaping () -> Void) {
        self.updateCallback = callback
    }
    
    private func createMenuItem(withText text: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: "", action: action, keyEquivalent: "")
        item.target = self
        item.attributedTitle = createAttributedTitle(text: text)
        return item
    }
    
    private func createAttributedTitle(text: String) -> NSAttributedString {
        let font = NSFont.systemFont(ofSize: Constants.Menu.fontSize)
        return NSAttributedString(
            string: text,
            attributes: [
                .foregroundColor: NSColor.labelColor,
                .font: font
            ]
        )
    }
    
    func updateCapacityDisplay(total: Int64, used: Int64, isError: Bool) {
        let (totalText, usedText) = isError 
            ? ("Total: Error", "Used: Error")
            : ("Total: \(DiskSpaceFormatter.menuDisplay.string(fromByteCount: total))",
               "Used: \(DiskSpaceFormatter.menuDisplay.string(fromByteCount: used))")
        
        totalCapacityMenuItem?.attributedTitle = createAttributedTitle(text: totalText)
        usedCapacityMenuItem?.attributedTitle = createAttributedTitle(text: usedText)
    }
    
    @objc private func dismissMenu(_ sender: NSMenuItem) {
        statusItem?.menu?.cancelTracking()
    }
}

extension StatusMenuManager: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // メニューが開かれる直前に最新の値を取得
        updateCallback?()
    }
}