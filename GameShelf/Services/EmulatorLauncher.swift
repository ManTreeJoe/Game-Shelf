import Foundation
import AppKit

enum LaunchError: LocalizedError {
    case noEmulatorConfigured(extension: String)
    case emulatorNotFound(path: String)
    case launchFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noEmulatorConfigured(let ext):
            return "No emulator configured for \(ext) files"
        case .emulatorNotFound(let path):
            return "Emulator not found at: \(path)"
        case .launchFailed(let message):
            return "Failed to launch: \(message)"
        }
    }
}

class EmulatorLauncher {
    private let config: AppConfig
    
    init(config: AppConfig) {
        self.config = config
    }
    
    func launch(_ rom: ROM) throws {
        // Handle Steam games differently
        if rom.isSteamGame, let appId = rom.steamAppId {
            try launchSteamGame(appId: appId)
            config.addToRecentlyPlayed(rom.path.path)
            return
        }
        
        // Find configured emulator for this ROM
        guard let emulator = config.emulator(forROM: rom) else {
            throw LaunchError.noEmulatorConfigured(extension: "\(rom.platform) / \(rom.fileExtension)")
        }
        
        let emulatorURL = URL(fileURLWithPath: emulator.path)
        
        guard FileManager.default.fileExists(atPath: emulator.path) else {
            throw LaunchError.emulatorNotFound(path: emulator.path)
        }
        
        // Check if it's a .app bundle or executable
        if emulator.path.hasSuffix(".app") {
            // Launch as macOS app with ROM as argument
            launchApp(at: emulatorURL, with: rom)
        } else {
            // Launch as command-line executable
            try launchExecutable(at: emulatorURL, with: rom, arguments: emulator.arguments)
        }
        
        // Track recently played
        config.addToRecentlyPlayed(rom.path.path)
    }
    
    private func launchSteamGame(appId: String) throws {
        // Use steam:// URL scheme to launch the game
        guard let url = URL(string: "steam://run/\(appId)") else {
            throw LaunchError.launchFailed("Invalid Steam App ID")
        }
        
        // Check if Steam is installed
        let steamPath = "/Applications/Steam.app"
        guard FileManager.default.fileExists(atPath: steamPath) else {
            throw LaunchError.launchFailed("Steam is not installed. Please install Steam from steampowered.com")
        }
        
        NSWorkspace.shared.open(url)
    }
    
    private func launchApp(at appURL: URL, with rom: ROM) {
        // Use 'open -a' command which works more reliably with macOS apps like OpenEmu
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", appURL.path, rom.path.path]
        
        do {
            try process.run()
        } catch {
            print("Failed to launch app: \(error.localizedDescription)")
        }
    }
    
    private func launchExecutable(at executableURL: URL, with rom: ROM, arguments: [String]) throws {
        let process = Process()
        process.executableURL = executableURL
        
        // Replace %ROM% placeholder with actual ROM path
        let args = arguments.map { arg -> String in
            if arg == "%ROM%" {
                return rom.path.path
            }
            return arg
        }
        process.arguments = args
        
        do {
            try process.run()
        } catch {
            throw LaunchError.launchFailed(error.localizedDescription)
        }
    }
    
    func openInFinder(_ rom: ROM) {
        NSWorkspace.shared.selectFile(rom.path.path, inFileViewerRootedAtPath: rom.path.deletingLastPathComponent().path)
    }
}
