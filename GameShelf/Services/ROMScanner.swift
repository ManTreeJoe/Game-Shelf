import Foundation

actor ROMScanner {
    private let config: AppConfig
    
    init(config: AppConfig) {
        self.config = config
    }
    
    func scan() async -> [ROM] {
        var roms: [ROM] = []
        let allPlatforms = await MainActor.run { config.allPlatforms }
        let directories = await MainActor.run { config.romDirectories }
        let platformOverrides = await MainActor.run { config.platformOverrides }
        
        let allExtensions = Set(allPlatforms.flatMap { $0.extensions })
        
        for directory in directories {
            let url = URL(fileURLWithPath: directory)
            let foundRoms = scanDirectory(url, extensions: allExtensions, platforms: allPlatforms, overrides: platformOverrides)
            roms.append(contentsOf: foundRoms)
        }
        
        return roms.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    private nonisolated func scanDirectory(_ url: URL, extensions: Set<String>, platforms: [Platform], overrides: [String: String]) -> [ROM] {
        var roms: [ROM] = []
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .creationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return roms }
        
        while let fileURL = enumerator.nextObject() as? URL {
            let ext = fileURL.pathExtension.lowercased()
            let extWithDot = ".\(ext)"
            
            guard extensions.contains(extWithDot) else { continue }
            
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .creationDateKey])
                guard resourceValues.isRegularFile == true else { continue }
                
                // Check for platform override first, then use extension-based detection
                let platformName: String
                if let override = overrides[fileURL.path] {
                    platformName = override
                } else {
                    platformName = platforms.first { $0.extensions.contains(extWithDot) }?.name ?? "Unknown"
                }
                
                let rom = ROM(
                    id: fileURL.path.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString,
                    name: fileURL.deletingPathExtension().lastPathComponent,
                    path: fileURL,
                    fileExtension: extWithDot,
                    platform: platformName,
                    fileSize: Int64(resourceValues.fileSize ?? 0),
                    dateAdded: resourceValues.creationDate ?? Date()
                )
                roms.append(rom)
            } catch {
                continue
            }
        }
        
        return roms
    }
}
