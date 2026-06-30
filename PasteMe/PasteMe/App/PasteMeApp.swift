import SwiftUI

@main
struct PasteMeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Menu bar app - no main window needed
        Settings {
            EmptyView()
        }
    }
}
