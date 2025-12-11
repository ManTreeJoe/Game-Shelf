import Foundation
import SwiftUI

enum SortOption: String, CaseIterable {
    case name = "Name"
    case platform = "Platform"
    case dateAdded = "Date Added"
    case size = "Size"
}

enum FilterOption: String, CaseIterable {
    case all = "All Games"
    case favorites = "Favorites"
    case recentlyPlayed = "Recently Played"
}

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var roms: [ROM] = []
    @Published var filteredRoms: [ROM] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedPlatform: String? = nil
    @Published var sortOption: SortOption = .name
    @Published var filterOption: FilterOption = .all
    @Published var selectedROM: ROM? = nil
    @Published var showingSettings = false
    @Published var launchError: String? = nil
    @Published var collectionFilter: GameCollection? = nil
    @Published var showingArtworkFetcher = false
    @Published var artworkFetcher = BatchArtworkFetcher()
    @Published var selectedIndex: Int = 0
    @Published var showingQuickLaunch = false
    @Published var viewMode: ViewMode = .grid
    @Published var isUsingKeyboardNavigation = false  // Track if keyboard/controller is active
    
    enum ViewMode: String, CaseIterable {
        case grid = "Grid"
        case list = "List"
    }
    
    var config: AppConfig
    private var launcher: EmulatorLauncher
    
    init(config: AppConfig) {
        self.config = config
        self.launcher = EmulatorLauncher(config: config)
    }
    
    func updateConfig(_ newConfig: AppConfig) {
        self.config = newConfig
        self.launcher = EmulatorLauncher(config: newConfig)
    }
    
    var platforms: [String] {
        Array(Set(roms.map { $0.platform })).sorted()
    }
    
    func scanLibrary() async {
        isLoading = true
        
        // Load cached ROMs first for immediate display
        let cachedROMs = ROMCache.shared.loadFromCache()
        if !cachedROMs.isEmpty && roms.isEmpty {
            roms = cachedROMs.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            applyFilters()
        }
        
        // Scan ROMs from available directories
        let scanner = ROMScanner(config: config)
        var scannedGames = await scanner.scan()
        
        // Scan Steam games if enabled
        if config.includeSteamGames {
            let steamScanner = SteamScanner()
            if steamScanner.isSteamInstalled {
                let steamGames = steamScanner.scan()
                scannedGames.append(contentsOf: steamGames)
            }
        }
        
        // Merge with cache to preserve unavailable games
        let allGames = ROMCache.shared.mergeWithCache(scannedROMs: scannedGames, cachedROMs: cachedROMs)
        
        // Sort combined list
        roms = allGames.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        // Save to cache for offline access
        ROMCache.shared.saveToCache(roms)
        
        applyFilters()
        isLoading = false
    }
    
    /// Get count of unavailable games
    var unavailableCount: Int {
        roms.filter { !$0.isAvailable }.count
    }
    
    /// Get count of available games
    var availableCount: Int {
        roms.filter { $0.isAvailable }.count
    }
    
    func applyFilters() {
        var result = roms
        
        // Apply collection filter first
        if let collection = collectionFilter {
            if collection.isSmart {
                // Smart collection - filter by rules
                result = result.filter { rom in
                    let stats = SessionTracker.shared.getStats(for: rom)
                    return collection.matchesSmartRules(rom, stats: stats)
                }
            } else {
                let pathSet = Set(collection.romPaths)
                result = result.filter { pathSet.contains($0.path.path) }
            }
        } else {
            // Apply filter option
            switch filterOption {
            case .all:
                break
            case .favorites:
                let favs = Set(config.favorites)
                result = result.filter { favs.contains($0.path.path) }
            case .recentlyPlayed:
                let recent = config.recentlyPlayed
                result = result.filter { recent.contains($0.path.path) }
                // Sort by recency
                result.sort { rom1, rom2 in
                    let idx1 = recent.firstIndex(of: rom1.path.path) ?? Int.max
                    let idx2 = recent.firstIndex(of: rom2.path.path) ?? Int.max
                    return idx1 < idx2
                }
                filteredRoms = result
                return
            }
        }
        
        // Apply platform filter
        if let platform = selectedPlatform {
            result = result.filter { $0.platform == platform }
        }
        
        // Apply search
        if !searchText.isEmpty {
            result = result.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.platform.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sort
        switch sortOption {
        case .name:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .platform:
            result.sort { $0.platform < $1.platform }
        case .dateAdded:
            result.sort { $0.dateAdded > $1.dateAdded }
        case .size:
            result.sort { $0.fileSize > $1.fileSize }
        }
        
        filteredRoms = result
    }
    
    func launchROM(_ rom: ROM) {
        do {
            try launcher.launch(rom)
            launchError = nil
        } catch {
            launchError = error.localizedDescription
        }
    }
    
    func toggleFavorite(_ rom: ROM) {
        config.toggleFavorite(rom.path.path)
        objectWillChange.send()
    }
    
    func isFavorite(_ rom: ROM) -> Bool {
        config.favorites.contains(rom.path.path)
    }
    
    func openInFinder(_ rom: ROM) {
        launcher.openInFinder(rom)
    }
    
    func hasEmulator(for rom: ROM) -> Bool {
        // Steam games don't need an emulator
        if rom.isSteamGame {
            return true
        }
        return config.emulator(forROM: rom) != nil
    }
    
    // MARK: - Collection Management
    
    func addToCollection(_ rom: ROM, collection: GameCollection) {
        config.addRomToCollection(rom.path.path, collectionId: collection.id)
    }
    
    func removeFromCollection(_ rom: ROM, collection: GameCollection) {
        config.removeRomFromCollection(rom.path.path, collectionId: collection.id)
    }
    
    func isInCollection(_ rom: ROM, collection: GameCollection) -> Bool {
        collection.romPaths.contains(rom.path.path)
    }
    
    // MARK: - Platform Override
    
    func changePlatform(_ rom: ROM, to platform: String) {
        config.setPlatformOverride(platform, forRomPath: rom.path.path)
        // Rescan to update the ROM list
        Task {
            await scanLibrary()
        }
    }
    
    func resetPlatform(_ rom: ROM) {
        config.removePlatformOverride(forRomPath: rom.path.path)
        // Rescan to update the ROM list
        Task {
            await scanLibrary()
        }
    }
    
    // MARK: - Keyboard Navigation
    
    func selectNext() {
        guard !filteredRoms.isEmpty else { return }
        selectedIndex = min(selectedIndex + 1, filteredRoms.count - 1)
        selectedROM = nil
    }
    
    func selectPrevious() {
        guard !filteredRoms.isEmpty else { return }
        selectedIndex = max(selectedIndex - 1, 0)
        selectedROM = nil
    }
    
    func selectNextRow(columns: Int) {
        guard !filteredRoms.isEmpty else { return }
        selectedIndex = min(selectedIndex + columns, filteredRoms.count - 1)
        selectedROM = nil
    }
    
    func selectPreviousRow(columns: Int) {
        guard !filteredRoms.isEmpty else { return }
        selectedIndex = max(selectedIndex - columns, 0)
        selectedROM = nil
    }
    
    func launchSelected() {
        guard selectedIndex < filteredRoms.count else { return }
        launchROM(filteredRoms[selectedIndex])
    }
    
    func openSelectedDetails() {
        guard selectedIndex < filteredRoms.count else { return }
        selectedROM = filteredRoms[selectedIndex]
    }
    
    var currentlySelectedRom: ROM? {
        guard selectedIndex < filteredRoms.count else { return nil }
        return filteredRoms[selectedIndex]
    }
    
    // MARK: - Random Game
    
    func launchRandomGame() {
        guard !filteredRoms.isEmpty else { return }
        let randomIndex = Int.random(in: 0..<filteredRoms.count)
        selectedIndex = randomIndex
        launchROM(filteredRoms[randomIndex])
    }
    
    func selectRandomGame() {
        guard !filteredRoms.isEmpty else { return }
        selectedIndex = Int.random(in: 0..<filteredRoms.count)
    }
    
    // MARK: - Duplicate Detection
    
    func findDuplicates() -> [[ROM]] {
        var nameGroups: [String: [ROM]] = [:]
        
        for rom in roms {
            let key = rom.displayName.lowercased()
            nameGroups[key, default: []].append(rom)
        }
        
        return nameGroups.values.filter { $0.count > 1 }.sorted { $0[0].name < $1[0].name }
    }
}
