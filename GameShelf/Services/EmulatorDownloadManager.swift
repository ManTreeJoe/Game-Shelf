import Foundation
import AppKit

/// Information about a standalone emulator
struct EmulatorInfo: Identifiable {
    let id: String
    let name: String
    let appName: String  // e.g., "OpenEmu.app"
    let platforms: [String]
    let downloadURL: String?  // nil if manual download required
    let websiteURL: String
    let description: String
    
    var installPath: String {
        "/Applications/\(appName)"
    }
    
    var isInstalled: Bool {
        FileManager.default.fileExists(atPath: installPath)
    }
}

/// Manages downloading and installing standalone emulators
class EmulatorDownloadManager: ObservableObject {
    static let shared = EmulatorDownloadManager()
    
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var statusMessage = ""
    @Published var currentEmulator: String?
    
    /// Callback to configure emulator in AppConfig after installation
    var onEmulatorInstalled: ((EmulatorInfo) -> Void)?
    
    /// All supported emulators
    static let emulators: [EmulatorInfo] = [
        EmulatorInfo(
            id: "openemu",
            name: "OpenEmu",
            appName: "OpenEmu.app",
            platforms: ["NES", "SNES", "Nintendo 64", "Game Boy", "Game Boy Color", "Game Boy Advance", 
                       "Nintendo DS", "Sega Genesis", "Sega Master System", "PlayStation", "Arcade"],
            downloadURL: nil,  // GitHub releases require API call
            websiteURL: "https://openemu.org",
            description: "All-in-one retro gaming for macOS"
        ),
        EmulatorInfo(
            id: "dolphin",
            name: "Dolphin",
            appName: "Dolphin.app",
            platforms: ["GameCube", "Wii"],
            downloadURL: nil,  // Dynamic URL from website
            websiteURL: "https://dolphin-emu.org/download/",
            description: "GameCube and Wii emulator"
        ),
        EmulatorInfo(
            id: "ppsspp",
            name: "PPSSPP",
            appName: "PPSSPP.app",
            platforms: ["PSP"],
            downloadURL: nil,  // Dynamic URL from website
            websiteURL: "https://www.ppsspp.org/download",
            description: "PlayStation Portable emulator"
        ),
        EmulatorInfo(
            id: "pcsx2",
            name: "PCSX2",
            appName: "PCSX2.app",
            platforms: ["PlayStation 2"],
            downloadURL: nil,  // Dynamic URL from website
            websiteURL: "https://pcsx2.net/downloads",
            description: "PlayStation 2 emulator"
        )
    ]
    
    /// Platforms that each emulator handles
    static let platformToEmulator: [String: String] = {
        var mapping: [String: String] = [:]
        for emulator in emulators {
            for platform in emulator.platforms {
                mapping[platform] = emulator.id
            }
        }
        return mapping
    }()
    
    /// Get the recommended emulator for a platform
    static func recommendedEmulator(for platform: String) -> EmulatorInfo? {
        guard let emulatorId = platformToEmulator[platform] else { return nil }
        return emulators.first { $0.id == emulatorId }
    }
    
    /// Get required emulators for a set of platforms
    static func requiredEmulators(for platforms: Set<String>) -> [EmulatorInfo] {
        var requiredIds = Set<String>()
        for platform in platforms {
            if let emulatorId = platformToEmulator[platform] {
                requiredIds.insert(emulatorId)
            }
        }
        return emulators.filter { requiredIds.contains($0.id) }
    }
    
    /// Check if an emulator is installed
    func isInstalled(_ emulator: EmulatorInfo) -> Bool {
        return emulator.isInstalled
    }
    
    /// Check if an emulator is installed by ID
    func isInstalled(emulatorId: String) -> Bool {
        guard let emulator = Self.emulators.first(where: { $0.id == emulatorId }) else {
            return false
        }
        return emulator.isInstalled
    }
    
    /// Open the download page for an emulator
    func openDownloadPage(for emulator: EmulatorInfo) {
        if let url = URL(string: emulator.websiteURL) {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Download and install an emulator
    @MainActor
    func downloadAndInstall(_ emulator: EmulatorInfo) async throws {
        guard !isDownloading else { return }
        
        isDownloading = true
        currentEmulator = emulator.name
        downloadProgress = 0
        statusMessage = "Preparing download..."
        
        defer {
            isDownloading = false
            currentEmulator = nil
        }
        
        switch emulator.id {
        case "openemu":
            try await downloadOpenEmu()
        case "dolphin":
            try await downloadDolphin()
        case "ppsspp":
            try await downloadPPSSPP()
        case "pcsx2":
            try await downloadPCSX2()
        default:
            throw DownloadError.unsupportedEmulator
        }
        
        // Notify that emulator was installed successfully
        onEmulatorInstalled?(emulator)
    }
    
    /// Configure an installed emulator in AppConfig
    static func configureEmulator(_ emulator: EmulatorInfo, in config: AppConfig) {
        // Check if already configured
        if config.emulators.contains(where: { $0.name == emulator.name }) {
            return
        }
        
        // Get file extensions for the platforms this emulator handles
        var extensions: [String] = []
        for platform in emulator.platforms {
            if let platformInfo = Platform.builtIn.first(where: { $0.name == platform }) {
                extensions.append(contentsOf: platformInfo.extensions)
            }
        }
        
        // Create emulator config
        let emulatorConfig = EmulatorConfig(
            name: emulator.name,
            path: emulator.installPath,
            extensions: extensions,
            platforms: emulator.platforms,
            arguments: ["%ROM%"]
        )
        
        config.addEmulator(emulatorConfig)
    }
    
    /// Configure all installed emulators in AppConfig
    static func configureAllInstalled(in config: AppConfig) {
        for emulator in emulators where emulator.isInstalled {
            configureEmulator(emulator, in: config)
        }
    }
    
    // MARK: - Download Methods
    
    private func downloadOpenEmu() async throws {
        statusMessage = "Fetching latest OpenEmu release..."
        
        // Get latest release from GitHub API
        let apiURL = URL(string: "https://api.github.com/repos/OpenEmu/OpenEmu/releases/latest")!
        let (data, _) = try await URLSession.shared.data(from: apiURL)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let assets = json["assets"] as? [[String: Any]],
              let dmgAsset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".dmg") == true }),
              let downloadURLString = dmgAsset["browser_download_url"] as? String,
              let downloadURL = URL(string: downloadURLString) else {
            throw DownloadError.failedToGetDownloadURL
        }
        
        await MainActor.run {
            statusMessage = "Downloading OpenEmu..."
            downloadProgress = 0.1
        }
        
        try await downloadAndInstallDMG(from: downloadURL, appName: "OpenEmu.app", volumeName: "OpenEmu")
    }
    
    private func downloadDolphin() async throws {
        // Dolphin provides direct download links
        // We'll fetch the latest from their download page
        statusMessage = "Fetching latest Dolphin release..."
        
        // Dolphin's latest releases page
        let pageURL = URL(string: "https://dolphin-emu.org/download/")!
        let (pageData, _) = try await URLSession.shared.data(from: pageURL)
        let pageHTML = String(data: pageData, encoding: .utf8) ?? ""
        
        // Try to find the DMG link for macOS
        // Pattern: /download/dev/.../dolphin-master-...-universal.dmg
        let pattern = #"href="([^"]*dolphin[^"]*universal\.dmg)""#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: pageHTML, range: NSRange(pageHTML.startIndex..., in: pageHTML)),
              let range = Range(match.range(at: 1), in: pageHTML) else {
            // Fallback: open download page manually
            openDownloadPage(for: Self.emulators.first { $0.id == "dolphin" }!)
            throw DownloadError.manualDownloadRequired("Dolphin")
        }
        
        var downloadPath = String(pageHTML[range])
        if !downloadPath.hasPrefix("http") {
            downloadPath = "https://dolphin-emu.org" + downloadPath
        }
        
        guard let downloadURL = URL(string: downloadPath) else {
            throw DownloadError.failedToGetDownloadURL
        }
        
        await MainActor.run {
            statusMessage = "Downloading Dolphin..."
            downloadProgress = 0.1
        }
        
        try await downloadAndInstallDMG(from: downloadURL, appName: "Dolphin.app", volumeName: "Dolphin")
    }
    
    private func downloadPPSSPP() async throws {
        statusMessage = "Preparing PPSSPP download..."
        
        // PPSSPP has a download page, but we'll try GitHub releases
        let apiURL = URL(string: "https://api.github.com/repos/hrydgard/ppsspp/releases/latest")!
        let (data, _) = try await URLSession.shared.data(from: apiURL)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let assets = json["assets"] as? [[String: Any]],
              let dmgAsset = assets.first(where: { 
                  let name = ($0["name"] as? String) ?? ""
                  return name.contains("macOS") && name.hasSuffix(".dmg")
              }),
              let downloadURLString = dmgAsset["browser_download_url"] as? String,
              let downloadURL = URL(string: downloadURLString) else {
            // Fallback: open download page manually
            openDownloadPage(for: Self.emulators.first { $0.id == "ppsspp" }!)
            throw DownloadError.manualDownloadRequired("PPSSPP")
        }
        
        await MainActor.run {
            statusMessage = "Downloading PPSSPP..."
            downloadProgress = 0.1
        }
        
        try await downloadAndInstallDMG(from: downloadURL, appName: "PPSSPP.app", volumeName: "PPSSPP")
    }
    
    private func downloadPCSX2() async throws {
        statusMessage = "Preparing PCSX2 download..."
        
        // PCSX2 has GitHub releases
        let apiURL = URL(string: "https://api.github.com/repos/PCSX2/pcsx2/releases/latest")!
        let (data, _) = try await URLSession.shared.data(from: apiURL)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let assets = json["assets"] as? [[String: Any]],
              let dmgAsset = assets.first(where: { 
                  let name = ($0["name"] as? String) ?? ""
                  return name.contains("macos") && name.hasSuffix(".dmg")
              }),
              let downloadURLString = dmgAsset["browser_download_url"] as? String,
              let downloadURL = URL(string: downloadURLString) else {
            // Fallback: open download page manually
            openDownloadPage(for: Self.emulators.first { $0.id == "pcsx2" }!)
            throw DownloadError.manualDownloadRequired("PCSX2")
        }
        
        await MainActor.run {
            statusMessage = "Downloading PCSX2..."
            downloadProgress = 0.1
        }
        
        try await downloadAndInstallDMG(from: downloadURL, appName: "PCSX2.app", volumeName: "PCSX2")
    }
    
    // MARK: - Helper Methods
    
    private func downloadAndInstallDMG(from url: URL, appName: String, volumeName: String) async throws {
        // Download DMG
        let tempDir = FileManager.default.temporaryDirectory
        let dmgPath = tempDir.appendingPathComponent("\(volumeName).dmg")
        
        // Clean up any existing file
        try? FileManager.default.removeItem(at: dmgPath)
        
        let (localURL, response) = try await URLSession.shared.download(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DownloadError.downloadFailed
        }
        
        try FileManager.default.moveItem(at: localURL, to: dmgPath)
        
        await MainActor.run {
            statusMessage = "Mounting disk image..."
            downloadProgress = 0.6
        }
        
        // Mount DMG
        let mountProcess = Process()
        mountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        mountProcess.arguments = ["attach", dmgPath.path, "-nobrowse", "-quiet"]
        
        let pipe = Pipe()
        mountProcess.standardOutput = pipe
        mountProcess.standardError = pipe
        
        try mountProcess.run()
        mountProcess.waitUntilExit()
        
        guard mountProcess.terminationStatus == 0 else {
            throw DownloadError.mountFailed
        }
        
        await MainActor.run {
            statusMessage = "Installing \(appName)..."
            downloadProgress = 0.8
        }
        
        // Find mounted volume - try common patterns
        let volumePaths = [
            "/Volumes/\(volumeName)",
            "/Volumes/\(volumeName) \(volumeName)",
        ]
        
        var actualVolume: String?
        for path in volumePaths {
            if FileManager.default.fileExists(atPath: path) {
                actualVolume = path
                break
            }
        }
        
        // Fallback: scan /Volumes for anything containing the volume name
        if actualVolume == nil {
            if let volumes = try? FileManager.default.contentsOfDirectory(atPath: "/Volumes") {
                for volume in volumes where volume.lowercased().contains(volumeName.lowercased()) {
                    actualVolume = "/Volumes/\(volume)"
                    break
                }
            }
        }
        
        guard let volumePath = actualVolume else {
            throw DownloadError.mountFailed
        }
        
        // Find .app in the volume
        var appSource: URL?
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: volumePath) {
            for item in contents where item.hasSuffix(".app") {
                appSource = URL(fileURLWithPath: volumePath).appendingPathComponent(item)
                break
            }
        }
        
        guard let sourceApp = appSource else {
            // Unmount before throwing
            unmountVolume(volumePath)
            throw DownloadError.installFailed("Could not find app in disk image")
        }
        
        // Copy to Applications
        let destApp = URL(fileURLWithPath: "/Applications").appendingPathComponent(sourceApp.lastPathComponent)
        
        // Remove existing installation if present
        try? FileManager.default.removeItem(at: destApp)
        
        do {
            try FileManager.default.copyItem(at: sourceApp, to: destApp)
        } catch {
            unmountVolume(volumePath)
            throw DownloadError.installFailed(error.localizedDescription)
        }
        
        // Unmount DMG
        unmountVolume(volumePath)
        
        // Clean up DMG
        try? FileManager.default.removeItem(at: dmgPath)
        
        await MainActor.run {
            statusMessage = "Complete!"
            downloadProgress = 1.0
        }
    }
    
    private func unmountVolume(_ path: String) {
        let unmountProcess = Process()
        unmountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        unmountProcess.arguments = ["detach", path, "-quiet"]
        try? unmountProcess.run()
        unmountProcess.waitUntilExit()
    }
    
    // MARK: - Error Types
    
    enum DownloadError: LocalizedError {
        case unsupportedEmulator
        case failedToGetDownloadURL
        case downloadFailed
        case mountFailed
        case installFailed(String)
        case manualDownloadRequired(String)
        
        var errorDescription: String? {
            switch self {
            case .unsupportedEmulator:
                return "This emulator is not supported for automatic download"
            case .failedToGetDownloadURL:
                return "Could not find download URL. Please download manually."
            case .downloadFailed:
                return "Download failed. Please check your internet connection."
            case .mountFailed:
                return "Failed to mount disk image"
            case .installFailed(let message):
                return "Installation failed: \(message)"
            case .manualDownloadRequired(let name):
                return "\(name) requires manual download. Opening download page..."
            }
        }
    }
}

