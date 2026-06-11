import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct DefaultApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("DefaultApp", id: "main") {
            ContentView()
        }
        .defaultSize(width: 900, height: 600)
        .windowStyle(.hiddenTitleBar)
    }
}
