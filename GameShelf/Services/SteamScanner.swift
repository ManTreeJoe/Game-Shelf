import Foundation

/// Scans for installed Steam games on macOS
class SteamScanner {
    
    /// Default Steam installation path on macOS
    private let defaultSteamPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/Steam")
    
    /// Scan for all installed Steam games
    func scan() -> [ROM] {
        var games: [ROM] = []
        
        // Get all library folders
        let libraryFolders = getLibraryFolders()
        
        for libraryPath in libraryFolders {
            let steamAppsPath = libraryPath.appendingPathComponent("steamapps")
            games.append(contentsOf: scanLibraryFolder(at: steamAppsPath))
        }
        
        return games.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    /// Check if Steam is installed
    var isSteamInstalled: Bool {
        FileManager.default.fileExists(atPath: defaultSteamPath.path)
    }
    
    // MARK: - Private Methods
    
    /// Parse libraryfolders.vdf to get all Steam library locations
    private func getLibraryFolders() -> [URL] {
        var folders: [URL] = [defaultSteamPath]
        
        let libraryFoldersFile = defaultSteamPath
            .appendingPathComponent("steamapps/libraryfolders.vdf")
        
        guard let content = try? String(contentsOf: libraryFoldersFile, encoding: .utf8) else {
            return folders
        }
        
        // Parse VDF format to extract paths
        // Looking for "path" keys with their values
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("\"path\"") {
                // Extract the path value
                if let path = extractQuotedValue(from: trimmed, key: "path") {
                    let url = URL(fileURLWithPath: path)
                    if !folders.contains(url) {
                        folders.append(url)
                    }
                }
            }
        }
        
        return folders
    }
    
    /// Scan a specific Steam library folder for games
    private func scanLibraryFolder(at steamAppsPath: URL) -> [ROM] {
        var games: [ROM] = []
        
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(
            at: steamAppsPath,
            includingPropertiesForKeys: nil
        ) else {
            return games
        }
        
        // Find all appmanifest files
        let manifests = contents.filter { $0.lastPathComponent.hasPrefix("appmanifest_") && $0.pathExtension == "acf" }
        
        for manifest in manifests {
            if let game = parseAppManifest(at: manifest) {
                games.append(game)
            }
        }
        
        return games
    }
    
    /// Parse an appmanifest_*.acf file to extract game info
    private func parseAppManifest(at url: URL) -> ROM? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        
        // Extract required fields from VDF format
        guard let appId = extractValue(from: content, key: "appid"),
              let name = extractValue(from: content, key: "name") else {
            return nil
        }
        
        // Skip tools, SDKs, and other non-game entries
        let lowercaseName = name.lowercased()
        if lowercaseName.contains("redistributable") ||
           lowercaseName.contains("sdk") ||
           lowercaseName.contains("dedicated server") ||
           lowercaseName.contains("proton") ||
           lowercaseName.contains("steamworks") {
            return nil
        }
        
        // Get optional fields
        let sizeOnDisk = Int64(extractValue(from: content, key: "SizeOnDisk") ?? "0") ?? 0
        let installDir = extractValue(from: content, key: "installdir") ?? ""
        
        // Get the game's install path
        let gamePath = url.deletingLastPathComponent()
            .appendingPathComponent("common")
            .appendingPathComponent(installDir)
        
        // Try to get last updated time
        let dateAdded: Date
        if let lastUpdated = extractValue(from: content, key: "LastUpdated"),
           let timestamp = TimeInterval(lastUpdated) {
            dateAdded = Date(timeIntervalSince1970: timestamp)
        } else {
            dateAdded = Date()
        }
        
        return ROM(
            id: "steam_\(appId)",
            name: name,
            path: gamePath,
            fileExtension: ".steam",
            platform: "Steam",
            fileSize: sizeOnDisk,
            dateAdded: dateAdded,
            steamAppId: appId,
            steamIconHash: nil
        )
    }
    
    /// Extract a value from VDF format: "key" "value"
    private func extractValue(from content: String, key: String) -> String? {
        let pattern = "\"\(key)\"\\s+\"([^\"]*)\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(content.startIndex..., in: content)
        guard let match = regex.firstMatch(in: content, options: [], range: range) else {
            return nil
        }
        
        guard let valueRange = Range(match.range(at: 1), in: content) else {
            return nil
        }
        
        return String(content[valueRange])
    }
    
    /// Extract quoted value from a line like: "key" "value"
    private func extractQuotedValue(from line: String, key: String) -> String? {
        let pattern = "\"\(key)\"\\s+\"([^\"]*)\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, options: [], range: range) else {
            return nil
        }
        
        guard let valueRange = Range(match.range(at: 1), in: line) else {
            return nil
        }
        
        return String(line[valueRange])
    }
}

