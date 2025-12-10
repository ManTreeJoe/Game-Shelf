import Foundation

struct Platform: Identifiable, Codable, Hashable {
    var id: String { name }
    var name: String
    var extensions: [String]
    var color: String
    var icon: String
    
    static let builtIn: [Platform] = [
        Platform(name: "NES", extensions: [".nes", ".nez"], color: "#E60012", icon: "gamecontroller"),
        Platform(name: "SNES", extensions: [".sfc", ".smc"], color: "#7B5AA6", icon: "gamecontroller"),
        Platform(name: "Game Boy", extensions: [".gb"], color: "#8B956D", icon: "gamecontroller"),
        Platform(name: "Game Boy Color", extensions: [".gbc"], color: "#6B4D9F", icon: "gamecontroller"),
        Platform(name: "Game Boy Advance", extensions: [".gba"], color: "#5A5EB9", icon: "gamecontroller"),
        Platform(name: "Nintendo 64", extensions: [".n64", ".z64", ".v64"], color: "#009E60", icon: "gamecontroller"),
        Platform(name: "GameCube", extensions: [".gcm", ".gcz"], color: "#6A5ACD", icon: "gamecontroller"),
        Platform(name: "Wii", extensions: [".wbfs", ".wad", ".nkit", ".iso", ".wia", ".rvz"], color: "#00A1E0", icon: "gamecontroller"),
        Platform(name: "Nintendo DS", extensions: [".nds"], color: "#CCCCCC", icon: "gamecontroller"),
        Platform(name: "Nintendo 3DS", extensions: [".3ds", ".cia"], color: "#D12228", icon: "gamecontroller"),
        Platform(name: "Nintendo Switch", extensions: [".nsp", ".xci"], color: "#E60012", icon: "gamecontroller"),
        Platform(name: "PlayStation", extensions: [".bin", ".cue", ".chd"], color: "#003087", icon: "gamecontroller"),
        Platform(name: "PlayStation 2", extensions: [".iso"], color: "#003087", icon: "gamecontroller"),
        Platform(name: "PSP", extensions: [".cso", ".iso"], color: "#000000", icon: "gamecontroller"),
        Platform(name: "Sega Genesis", extensions: [".md", ".gen"], color: "#17569B", icon: "gamecontroller"),
        Platform(name: "Sega Master System", extensions: [".sms"], color: "#17569B", icon: "gamecontroller"),
        Platform(name: "Game Gear", extensions: [".gg"], color: "#000000", icon: "gamecontroller"),
        Platform(name: "Sega Saturn", extensions: [".cue", ".chd"], color: "#000000", icon: "gamecontroller"),
        Platform(name: "Dreamcast", extensions: [".cdi", ".gdi"], color: "#FF6600", icon: "gamecontroller"),
    ]
}
