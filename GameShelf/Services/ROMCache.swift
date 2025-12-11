import Foundation

/// Manages persistent caching of ROM library data for offline viewing
class ROMCache {
    static let shared = ROMCache()
    
    private let cacheFileName = "rom_cache.json"
    
    private var cacheURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let gameShelfDir = appSupport.appendingPathComponent("GameShelf")
        
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: gameShelfDir, withIntermediateDirectories: true)
        
        return gameShelfDir.appendingPathComponent(cacheFileName)
    }
    
    private init() {}
    
    /// Save ROMs to persistent cache
    func saveToCache(_ roms: [ROM]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(roms)
            try data.write(to: cacheURL, options: .atomic)
            print("ROMCache: Saved \(roms.count) ROMs to cache")
        } catch {
            print("ROMCache: Failed to save cache - \(error.localizedDescription)")
        }
    }
    
    /// Load ROMs from persistent cache
    func loadFromCache() -> [ROM] {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            print("ROMCache: No cache file found")
            return []
        }
        
        do {
            let data = try Data(contentsOf: cacheURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let roms = try decoder.decode([ROM].self, from: data)
            print("ROMCache: Loaded \(roms.count) ROMs from cache")
            return roms
        } catch {
            print("ROMCache: Failed to load cache - \(error.localizedDescription)")
            return []
        }
    }
    
    /// Merge newly scanned ROMs with cached ROMs
    /// - Returns: Combined list with cached ROMs that aren't in the new scan (unavailable) + new ROMs
    func mergeWithCache(scannedROMs: [ROM], cachedROMs: [ROM]) -> [ROM] {
        var result = scannedROMs
        
        // Find cached ROMs that aren't in the scanned list (drive disconnected)
        let scannedIDs = Set(scannedROMs.map { $0.id })
        let missingFromScan = cachedROMs.filter { !scannedIDs.contains($0.id) }
        
        // Add missing ROMs (they'll show as unavailable)
        result.append(contentsOf: missingFromScan)
        
        print("ROMCache: Merged \(scannedROMs.count) scanned + \(missingFromScan.count) cached = \(result.count) total")
        
        return result
    }
    
    /// Clear the cache
    func clearCache() {
        try? FileManager.default.removeItem(at: cacheURL)
        print("ROMCache: Cache cleared")
    }
    
    /// Get cache statistics
    var cacheInfo: (count: Int, lastModified: Date?) {
        guard FileManager.default.fileExists(atPath: cacheURL.path) else {
            return (0, nil)
        }
        
        let roms = loadFromCache()
        let attributes = try? FileManager.default.attributesOfItem(atPath: cacheURL.path)
        let lastModified = attributes?[.modificationDate] as? Date
        
        return (roms.count, lastModified)
    }
}

