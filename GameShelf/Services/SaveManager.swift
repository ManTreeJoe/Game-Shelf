import Foundation
import AppKit

/// Represents a save file from an emulator
struct SaveFile: Identifiable, Hashable {
    let id: String
    let name: String
    let path: URL
    let emulator: String
    let type: SaveType
    let size: Int64
    let dateModified: Date
    let gameId: String?  // Associated game/ROM identifier
    
    enum SaveType: String, CaseIterable {
        case saveState = "Save State"
        case batterySave = "Battery Save"
        case memoryCard = "Memory Card"
        case saveData = "Save Data"
        
        var icon: String {
            switch self {
            case .saveState: return "camera.fill"
            case .batterySave: return "battery.100"
            case .memoryCard: return "creditcard.fill"
            case .saveData: return "doc.fill"
            }
        }
    }
    
    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: dateModified, relativeTo: Date())
    }
}

/// Manages save files from various emulators
class SaveManager: ObservableObject {
    static let shared = SaveManager()
    
    @Published var saves: [SaveFile] = []
    @Published var isScanning = false
    
    private let fileManager = FileManager.default
    
    /// Emulator save locations
    private var emulatorPaths: [(emulator: String, paths: [(URL, SaveFile.SaveType)])] {
        let home = fileManager.homeDirectoryForCurrentUser
        let appSupport = home.appendingPathComponent("Library/Application Support")
        
        return [
            ("OpenEmu", [
                (appSupport.appendingPathComponent("OpenEmu/Save States"), .saveState),
                (appSupport.appendingPathComponent("OpenEmu/Battery Saves"), .batterySave),
            ]),
            ("Dolphin", [
                (appSupport.appendingPathComponent("Dolphin/StateSaves"), .saveState),
                (appSupport.appendingPathComponent("Dolphin/GC"), .saveData),
                (appSupport.appendingPathComponent("Dolphin/Wii"), .saveData),
            ]),
            ("PPSSPP", [
                (appSupport.appendingPathComponent("PPSSPP/PSP/SAVEDATA"), .saveData),
                (appSupport.appendingPathComponent("PPSSPP/PSP/PPSSPP_STATE"), .saveState),
            ]),
            ("PCSX2", [
                (appSupport.appendingPathComponent("PCSX2/sstates"), .saveState),
                (appSupport.appendingPathComponent("PCSX2/memcards"), .memoryCard),
            ]),
        ]
    }
    
    /// Scan all emulator save locations
    func scanAllSaves() {
        isScanning = true
        var foundSaves: [SaveFile] = []
        
        for (emulator, paths) in emulatorPaths {
            for (path, saveType) in paths {
                let saves = scanDirectory(path, emulator: emulator, type: saveType)
                foundSaves.append(contentsOf: saves)
            }
        }
        
        // Sort by date modified (most recent first)
        foundSaves.sort { $0.dateModified > $1.dateModified }
        
        Task { @MainActor in
            self.saves = foundSaves
            self.isScanning = false
        }
    }
    
    /// Scan a specific directory for save files
    private func scanDirectory(_ directory: URL, emulator: String, type: SaveFile.SaveType) -> [SaveFile] {
        guard fileManager.fileExists(atPath: directory.path) else { return [] }
        
        var saves: [SaveFile] = []
        
        // Common save file extensions
        let saveExtensions: Set<String> = [
            "sav", "srm", "state", "ss0", "ss1", "ss2", "ss3", "ss4", "ss5", "ss6", "ss7", "ss8", "ss9",
            "oesavestate", "gci", "raw", "mcd", "mcr", "ps2", "p2s"
        ]
        
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        
        while let url = enumerator.nextObject() as? URL {
            // Check if it's a file
            guard let resourceValues = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey]),
                  resourceValues.isRegularFile == true else {
                continue
            }
            
            let ext = url.pathExtension.lowercased()
            
            // Check if it's a save file
            guard saveExtensions.contains(ext) || type == .saveData else { continue }
            
            let size = Int64(resourceValues.fileSize ?? 0)
            let dateModified = resourceValues.contentModificationDate ?? Date()
            
            // Try to extract game identifier from filename
            let filename = url.deletingPathExtension().lastPathComponent
            let gameId = extractGameId(from: filename, emulator: emulator)
            
            let save = SaveFile(
                id: url.path,
                name: filename,
                path: url,
                emulator: emulator,
                type: type,
                size: size,
                dateModified: dateModified,
                gameId: gameId
            )
            
            saves.append(save)
        }
        
        return saves
    }
    
    /// Extract a game identifier from a save filename
    private func extractGameId(from filename: String, emulator: String) -> String? {
        // Different emulators use different naming conventions
        // We'll try to extract a common identifier
        
        // Remove common suffixes like "(USA)", "(Europe)", etc.
        var cleaned = filename
        let patterns = [
            "\\s*\\([^)]*\\)",  // (USA), (Europe), etc.
            "\\s*\\[[^\\]]*\\]", // [!], [b1], etc.
            "\\.state\\d*$",     // .state0, .state1, etc.
            "\\.ss\\d+$",        // .ss0, .ss1, etc.
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
    
    /// Find saves that match a specific ROM
    func saves(for rom: ROM) -> [SaveFile] {
        let romName = rom.displayName.lowercased()
        let romFilename = rom.path.deletingPathExtension().lastPathComponent.lowercased()
        
        return saves.filter { save in
            let saveName = save.name.lowercased()
            let saveGameId = save.gameId?.lowercased() ?? ""
            
            // Check for matches
            return saveName.contains(romName) ||
                   saveName.contains(romFilename) ||
                   saveGameId.contains(romName) ||
                   romName.contains(saveGameId) ||
                   romFilename.contains(saveGameId)
        }
    }
    
    /// Backup a save file to a specified location
    func backupSave(_ save: SaveFile, to destination: URL) throws {
        let destFile = destination.appendingPathComponent(save.path.lastPathComponent)
        try fileManager.copyItem(at: save.path, to: destFile)
    }
    
    /// Backup all saves for a ROM
    func backupSaves(for rom: ROM, to destination: URL) throws {
        let romSaves = saves(for: rom)
        
        // Create a subfolder for this game
        let gameFolder = destination.appendingPathComponent(rom.displayName)
        try fileManager.createDirectory(at: gameFolder, withIntermediateDirectories: true)
        
        for save in romSaves {
            try backupSave(save, to: gameFolder)
        }
    }
    
    /// Export all saves to a backup folder
    func exportAllSaves(to destination: URL) throws {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        let backupFolder = destination.appendingPathComponent("GameShelf_Saves_\(timestamp)")
        try fileManager.createDirectory(at: backupFolder, withIntermediateDirectories: true)
        
        // Group saves by emulator
        let grouped = Dictionary(grouping: saves) { $0.emulator }
        
        for (emulator, emulatorSaves) in grouped {
            let emulatorFolder = backupFolder.appendingPathComponent(emulator)
            try fileManager.createDirectory(at: emulatorFolder, withIntermediateDirectories: true)
            
            for save in emulatorSaves {
                try backupSave(save, to: emulatorFolder)
            }
        }
    }
    
    /// Open save file location in Finder
    func revealInFinder(_ save: SaveFile) {
        NSWorkspace.shared.selectFile(save.path.path, inFileViewerRootedAtPath: save.path.deletingLastPathComponent().path)
    }
    
    /// Delete a save file
    func deleteSave(_ save: SaveFile) throws {
        try fileManager.removeItem(at: save.path)
        
        Task { @MainActor in
            self.saves.removeAll { $0.id == save.id }
        }
    }
}

