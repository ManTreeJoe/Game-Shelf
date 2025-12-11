import Foundation

struct ROM: Identifiable, Hashable, Equatable, Codable {
    let id: String
    let name: String
    let path: URL
    let fileExtension: String
    let platform: String
    let fileSize: Int64
    let dateAdded: Date
    
    // Steam game support
    let steamAppId: String?
    let steamIconHash: String?
    
    var isSteamGame: Bool {
        steamAppId != nil
    }
    
    /// Check if the ROM file is currently accessible (drive connected)
    var isAvailable: Bool {
        // Steam games are always "available" if Steam is installed
        if isSteamGame {
            return FileManager.default.fileExists(atPath: "/Applications/Steam.app")
        }
        return FileManager.default.fileExists(atPath: path.path)
    }
    
    init(id: String, name: String, path: URL, fileExtension: String, platform: String, fileSize: Int64, dateAdded: Date, steamAppId: String? = nil, steamIconHash: String? = nil) {
        self.id = id
        self.name = name
        self.path = path
        self.fileExtension = fileExtension
        self.platform = platform
        self.fileSize = fileSize
        self.dateAdded = dateAdded
        self.steamAppId = steamAppId
        self.steamIconHash = steamIconHash
    }
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    var displayName: String {
        // Steam games already have clean names
        if isSteamGame {
            return name
        }
        
        // Clean up ROM names - remove region codes, revision numbers, etc.
        var cleaned = name
        // Remove common ROM naming conventions
        let patterns = [
            "\\s*\\([^)]*\\)",  // (USA), (Europe), etc.
            "\\s*\\[[^\\]]*\\]", // [!], [b1], etc.
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                cleaned = regex.stringByReplacingMatches(
                    in: cleaned,
                    range: NSRange(cleaned.startIndex..., in: cleaned),
                    withTemplate: ""
                )
            }
        }
        return cleaned.trimmingCharacters(in: .whitespaces)
    }
    
    /// Steam artwork URL for header/banner image
    var steamHeaderURL: URL? {
        guard let appId = steamAppId else { return nil }
        return URL(string: "https://steamcdn-a.akamaihd.net/steam/apps/\(appId)/library_600x900.jpg")
    }
    
    /// Steam artwork URL for capsule image (fallback)
    var steamCapsuleURL: URL? {
        guard let appId = steamAppId else { return nil }
        return URL(string: "https://steamcdn-a.akamaihd.net/steam/apps/\(appId)/header.jpg")
    }
}
