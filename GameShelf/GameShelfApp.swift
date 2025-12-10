import SwiftUI

@main
struct GameShelfApp: App {
    @StateObject private var config = AppConfig.load()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(config)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
        
        Settings {
            SettingsView()
                .environmentObject(config)
        }
    }
}
