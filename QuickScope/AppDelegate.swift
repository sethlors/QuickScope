import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Hide the dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            // Try to create the icon, fall back to a simple folder if needed
            let iconImage = NSImage(systemSymbolName: "folder.badge.magnifyingglass", accessibilityDescription: "QuickScope") 
                         ?? NSImage(systemSymbolName: "folder", accessibilityDescription: "QuickScope")
                         ?? NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: "QuickScope")
            
            button.image = iconImage
            button.toolTip = "QuickScope - Folder Preview Extension"
            
            // Ensure the button is visible
            button.imagePosition = .imageOnly
            
            print("QuickScope: Status item created successfully")
        } else {
            print("QuickScope: Failed to create status item button")
        }
        
        // Create menu
        let menu = NSMenu()
        
        let aboutItem = NSMenuItem(title: "About QuickScope", action: #selector(aboutClicked), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit QuickScope", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc func aboutClicked() {
        let alert = NSAlert()
        alert.messageText = "QuickScope"
        alert.informativeText = "Folder preview extension for macOS Quick Look.\n\nPress spacebar on any folder in Finder to see its contents."
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    @objc func quitClicked() {
        NSApplication.shared.terminate(self)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
