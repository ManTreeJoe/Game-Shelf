import Foundation
import SwiftUI

// MARK: - Smart Collection Rules

enum SmartCollectionRule: Codable, Hashable {
    case platform(String)
    case unplayed
    case playedMoreThan(hours: Double)
    case addedInLast(days: Int)
    case playedInLast(days: Int)
    case nameContains(String)
    case fileSizeLargerThan(bytes: Int64)
    
    func matches(_ rom: ROM, stats: GameStats) -> Bool {
        switch self {
        case .platform(let platform):
            return rom.platform == platform
        case .unplayed:
            return stats.sessionCount == 0
        case .playedMoreThan(let hours):
            return stats.totalPlayTime >= hours * 3600
        case .addedInLast(let days):
            let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
            return rom.dateAdded >= cutoff
        case .playedInLast(let days):
            guard let lastPlayed = stats.lastPlayed else { return false }
            let cutoff = Date().addingTimeInterval(-Double(days) * 24 * 60 * 60)
            return lastPlayed >= cutoff
        case .nameContains(let text):
            return rom.name.localizedCaseInsensitiveContains(text)
        case .fileSizeLargerThan(let bytes):
            return rom.fileSize >= bytes
        }
    }
    
    var displayName: String {
        switch self {
        case .platform(let p): return "Platform: \(p)"
        case .unplayed: return "Never played"
        case .playedMoreThan(let h): return "Played more than \(Int(h))h"
        case .addedInLast(let d): return "Added in last \(d) days"
        case .playedInLast(let d): return "Played in last \(d) days"
        case .nameContains(let t): return "Name contains: \(t)"
        case .fileSizeLargerThan(let b): return "Size > \(ByteCountFormatter.string(fromByteCount: b, countStyle: .file))"
        }
    }
}

struct GameCollection: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var romPaths: [String]
    var isSystem: Bool
    var sortOrder: Int
    var isSmart: Bool
    var smartRules: [SmartCollectionRule]
    var smartRulesMatchAll: Bool  // true = AND, false = OR
    
    init(id: UUID = UUID(), name: String, icon: String = "folder.fill", colorHex: String = "ff2a6d", romPaths: [String] = [], isSystem: Bool = false, sortOrder: Int = 0, isSmart: Bool = false, smartRules: [SmartCollectionRule] = [], smartRulesMatchAll: Bool = true) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.romPaths = romPaths
        self.isSystem = isSystem
        self.sortOrder = sortOrder
        self.isSmart = isSmart
        self.smartRules = smartRules
        self.smartRulesMatchAll = smartRulesMatchAll
    }
    
    func matchesSmartRules(_ rom: ROM, stats: GameStats) -> Bool {
        guard isSmart, !smartRules.isEmpty else { return false }
        
        if smartRulesMatchAll {
            return smartRules.allSatisfy { $0.matches(rom, stats: stats) }
        } else {
            return smartRules.contains { $0.matches(rom, stats: stats) }
        }
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    var gameCount: Int {
        romPaths.count
    }
    
    // System collections
    static let allGames = GameCollection(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "All Games",
        icon: "square.grid.2x2.fill",
        colorHex: "ff2a6d",
        isSystem: true,
        sortOrder: 0
    )
    
    static let favorites = GameCollection(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Favorites",
        icon: "heart.fill",
        colorHex: "ff2a6d",
        isSystem: true,
        sortOrder: 1
    )
    
    static let recentlyPlayed = GameCollection(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Recently Played",
        icon: "clock.fill",
        colorHex: "05d9e8",
        isSystem: true,
        sortOrder: 2
    )
    
    static let systemCollections: [GameCollection] = [allGames, favorites, recentlyPlayed]
}

// MARK: - Collection Icons

struct CollectionIcons {
    static let all: [String] = [
        "folder.fill",
        "star.fill",
        "heart.fill",
        "gamecontroller.fill",
        "trophy.fill",
        "flag.fill",
        "bookmark.fill",
        "tag.fill",
        "bolt.fill",
        "flame.fill",
        "crown.fill",
        "sparkles",
        "wand.and.stars",
        "globe.americas.fill",
        "moon.fill",
        "sun.max.fill",
        "cloud.fill",
        "snowflake",
        "leaf.fill",
        "tortoise.fill",
        "hare.fill",
        "ant.fill",
        "ladybug.fill",
        "fish.fill",
        "pawprint.fill",
        "music.note",
        "guitars.fill",
        "pianokeys",
        "theatermasks.fill",
        "film.fill",
        "tv.fill",
        "desktopcomputer",
        "keyboard.fill",
        "hammer.fill",
        "wrench.and.screwdriver.fill",
        "paintbrush.fill",
        "pencil.tip",
        "scroll.fill",
        "book.fill",
        "graduationcap.fill",
        "airplane",
        "car.fill",
        "bicycle",
        "figure.run",
        "figure.boxing",
        "soccerball",
        "basketball.fill",
        "football.fill",
        "tennisball.fill",
        "baseball.fill"
    ]
    
    static let colors: [String] = [
        "ff2a6d", // Pink
        "05d9e8", // Cyan
        "7b2cbf", // Purple
        "39ff14", // Green
        "f9a825", // Amber
        "ff6b2a", // Orange
        "00ff87", // Mint
        "ff00ff", // Magenta
        "00bfff", // Sky blue
        "ff4444", // Red
        "44ff44", // Lime
        "4444ff", // Blue
    ]
}

