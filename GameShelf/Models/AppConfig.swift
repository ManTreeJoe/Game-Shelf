import Foundation

struct EmulatorConfig: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var path: String
    var extensions: [String]
    var platforms: [String]  // NEW: Platforms this emulator handles
    var arguments: [String]
    
    init(id: UUID = UUID(), name: String, path: String = "", extensions: [String] = [], platforms: [String] = [], arguments: [String] = ["%ROM%"]) {
        self.id = id
        self.name = name
        self.path = path
        self.extensions = extensions
        self.platforms = platforms
        self.arguments = arguments
    }
}

class AppConfig: ObservableObject, Codable {
    @Published var romDirectories: [String] = []
    @Published var emulators: [EmulatorConfig] = []
    @Published var customPlatforms: [Platform] = []
    @Published var recentlyPlayed: [String] = []  // ROM paths
    @Published var favorites: [String] = []  // ROM paths
    @Published var collections: [GameCollection] = []  // Custom collections
    @Published var platformOverrides: [String: String] = [:]  // ROM path -> Platform name
    @Published var includeSteamGames: Bool = true  // Include Steam library in game list
    
    // Onboarding state (separate from main config)
    var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") }
        set { 
            UserDefaults.standard.set(newValue, forKey: "hasCompletedOnboarding")
            objectWillChange.send()
        }
    }
    
    enum CodingKeys: CodingKey {
        case romDirectories, emulators, customPlatforms, recentlyPlayed, favorites, collections, platformOverrides, includeSteamGames
    }
    
    init() {}
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        romDirectories = try container.decodeIfPresent([String].self, forKey: .romDirectories) ?? []
        emulators = try container.decodeIfPresent([EmulatorConfig].self, forKey: .emulators) ?? []
        customPlatforms = try container.decodeIfPresent([Platform].self, forKey: .customPlatforms) ?? []
        recentlyPlayed = try container.decodeIfPresent([String].self, forKey: .recentlyPlayed) ?? []
        favorites = try container.decodeIfPresent([String].self, forKey: .favorites) ?? []
        collections = try container.decodeIfPresent([GameCollection].self, forKey: .collections) ?? []
        platformOverrides = try container.decodeIfPresent([String: String].self, forKey: .platformOverrides) ?? [:]
        includeSteamGames = try container.decodeIfPresent(Bool.self, forKey: .includeSteamGames) ?? true
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(romDirectories, forKey: .romDirectories)
        try container.encode(emulators, forKey: .emulators)
        try container.encode(customPlatforms, forKey: .customPlatforms)
        try container.encode(recentlyPlayed, forKey: .recentlyPlayed)
        try container.encode(favorites, forKey: .favorites)
        try container.encode(collections, forKey: .collections)
        try container.encode(platformOverrides, forKey: .platformOverrides)
        try container.encode(includeSteamGames, forKey: .includeSteamGames)
    }
    
    // MARK: - Persistence
    
    private static var configURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("GameShelf", isDirectory: true)
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        return appFolder.appendingPathComponent("config.json")
    }
    
    static func load() -> AppConfig {
        guard FileManager.default.fileExists(atPath: configURL.path),
              let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            return AppConfig()
        }
        return config
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: Self.configURL)
    }
    
    // MARK: - Emulator Management
    
    func emulator(forExtension ext: String) -> EmulatorConfig? {
        emulators.first { $0.extensions.contains(ext.lowercased()) }
    }
    
    func emulator(forPlatform platform: String) -> EmulatorConfig? {
        emulators.first { $0.platforms.contains(platform) }
    }
    
    func emulator(forROM rom: ROM) -> EmulatorConfig? {
        // First try platform-based matching (higher priority)
        if let platformEmulator = emulator(forPlatform: rom.platform) {
            return platformEmulator
        }
        // Fall back to extension-based matching
        return emulator(forExtension: rom.fileExtension)
    }
    
    func addEmulator(_ emulator: EmulatorConfig) {
        emulators.append(emulator)
        save()
    }
    
    func updateEmulator(_ emulator: EmulatorConfig, at index: Int) {
        guard index < emulators.count else { return }
        emulators[index] = emulator
        save()
    }
    
    func removeEmulator(at index: Int) {
        guard index < emulators.count else { return }
        emulators.remove(at: index)
        save()
    }
    
    // MARK: - Platform Management
    
    var allPlatforms: [Platform] {
        Platform.builtIn + customPlatforms
    }
    
    func platform(forExtension ext: String) -> Platform? {
        allPlatforms.first { $0.extensions.contains(ext.lowercased()) }
    }
    
    func addCustomPlatform(_ platform: Platform) {
        customPlatforms.append(platform)
        save()
    }
    
    // MARK: - Directory Management
    
    func addRomDirectory(_ path: String) {
        guard !romDirectories.contains(path) else { return }
        romDirectories.append(path)
        save()
    }
    
    func removeRomDirectory(at index: Int) {
        guard index < romDirectories.count else { return }
        romDirectories.remove(at: index)
        save()
    }
    
    func removeRomDirectory(_ path: String) {
        romDirectories.removeAll { $0 == path }
        save()
    }
    
    // MARK: - Favorites & Recent
    
    func toggleFavorite(_ romPath: String) {
        if favorites.contains(romPath) {
            favorites.removeAll { $0 == romPath }
        } else {
            favorites.append(romPath)
        }
        save()
    }
    
    func addToRecentlyPlayed(_ romPath: String) {
        recentlyPlayed.removeAll { $0 == romPath }
        recentlyPlayed.insert(romPath, at: 0)
        if recentlyPlayed.count > 20 {
            recentlyPlayed = Array(recentlyPlayed.prefix(20))
        }
        save()
    }
    
    // MARK: - Collection Management
    
    func addCollection(_ collection: GameCollection) {
        collections.append(collection)
        save()
        objectWillChange.send()
    }
    
    func updateCollection(_ collection: GameCollection) {
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index] = collection
            save()
            objectWillChange.send()
        }
    }
    
    func removeCollection(_ id: UUID) {
        collections.removeAll { $0.id == id }
        save()
        objectWillChange.send()
    }
    
    func addRomToCollection(_ romPath: String, collectionId: UUID) {
        if let index = collections.firstIndex(where: { $0.id == collectionId }) {
            if !collections[index].romPaths.contains(romPath) {
                collections[index].romPaths.append(romPath)
                save()
                objectWillChange.send()
            }
        }
    }
    
    func removeRomFromCollection(_ romPath: String, collectionId: UUID) {
        if let index = collections.firstIndex(where: { $0.id == collectionId }) {
            collections[index].romPaths.removeAll { $0 == romPath }
            save()
            objectWillChange.send()
        }
    }
    
    func collections(containing romPath: String) -> [GameCollection] {
        collections.filter { $0.romPaths.contains(romPath) }
    }
    
    // MARK: - Platform Override
    
    func setPlatformOverride(_ platform: String, forRomPath path: String) {
        platformOverrides[path] = platform
        save()
        objectWillChange.send()
    }
    
    func removePlatformOverride(forRomPath path: String) {
        platformOverrides.removeValue(forKey: path)
        save()
        objectWillChange.send()
    }
    
    func getPlatformOverride(forRomPath path: String) -> String? {
        platformOverrides[path]
    }
    
    // MARK: - Import/Export
    
    struct ExportData: Codable {
        let romDirectories: [String]
        let emulators: [EmulatorConfig]
        let customPlatforms: [Platform]
        let collections: [GameCollection]
        let favorites: [String]
        let platformOverrides: [String: String]
        let exportDate: Date
        let appVersion: String
    }
    
    func exportData() -> Data? {
        let exportData = ExportData(
            romDirectories: romDirectories,
            emulators: emulators,
            customPlatforms: customPlatforms,
            collections: collections,
            favorites: favorites,
            platformOverrides: platformOverrides,
            exportDate: Date(),
            appVersion: "1.0"
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(exportData)
    }
    
    func exportToFile() -> URL? {
        guard let data = exportData() else { return nil }
        
        let fileName = "GameShelf_Backup_\(formattedDate()).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Export failed: \(error)")
            return nil
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }
    
    func importData(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let imported = try decoder.decode(ExportData.self, from: data)
        
        // Merge or replace data
        romDirectories = imported.romDirectories
        emulators = imported.emulators
        customPlatforms = imported.customPlatforms
        collections = imported.collections
        favorites = imported.favorites
        platformOverrides = imported.platformOverrides
        
        save()
        objectWillChange.send()
    }
    
    func importDataMerge(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let imported = try decoder.decode(ExportData.self, from: data)
        
        // Merge data (add new items, don't overwrite existing)
        for dir in imported.romDirectories where !romDirectories.contains(dir) {
            romDirectories.append(dir)
        }
        
        for emulator in imported.emulators {
            if !emulators.contains(where: { $0.name == emulator.name }) {
                emulators.append(emulator)
            }
        }
        
        for collection in imported.collections {
            if !collections.contains(where: { $0.id == collection.id }) {
                collections.append(collection)
            }
        }
        
        for favorite in imported.favorites where !favorites.contains(favorite) {
            favorites.append(favorite)
        }
        
        for (path, platform) in imported.platformOverrides {
            if platformOverrides[path] == nil {
                platformOverrides[path] = platform
            }
        }
        
        save()
        objectWillChange.send()
    }
}
