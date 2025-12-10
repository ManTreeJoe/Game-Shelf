import Foundation

struct GameMetadata: Codable, Identifiable {
    var id: String { romPath }
    let romPath: String
    var title: String?
    var description: String?
    var releaseYear: Int?
    var developer: String?
    var publisher: String?
    var genres: [String]
    var coverArtPath: String?
    var screenshotPaths: [String]
    var lastUpdated: Date
    var manuallyEdited: Bool
    
    init(
        romPath: String,
        title: String? = nil,
        description: String? = nil,
        releaseYear: Int? = nil,
        developer: String? = nil,
        publisher: String? = nil,
        genres: [String] = [],
        coverArtPath: String? = nil,
        screenshotPaths: [String] = [],
        lastUpdated: Date = Date(),
        manuallyEdited: Bool = false
    ) {
        self.romPath = romPath
        self.title = title
        self.description = description
        self.releaseYear = releaseYear
        self.developer = developer
        self.publisher = publisher
        self.genres = genres
        self.coverArtPath = coverArtPath
        self.screenshotPaths = screenshotPaths
        self.lastUpdated = lastUpdated
        self.manuallyEdited = manuallyEdited
    }
}

// MARK: - Metadata Database

class MetadataDatabase: ObservableObject {
    @Published private var metadata: [String: GameMetadata] = [:]
    
    private static var databaseURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("GameShelf", isDirectory: true)
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        return appFolder.appendingPathComponent("metadata.json")
    }
    
    init() {
        load()
    }
    
    func load() {
        guard FileManager.default.fileExists(atPath: Self.databaseURL.path),
              let data = try? Data(contentsOf: Self.databaseURL),
              let decoded = try? JSONDecoder().decode([String: GameMetadata].self, from: data) else {
            return
        }
        metadata = decoded
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(metadata) else { return }
        try? data.write(to: Self.databaseURL)
    }
    
    func get(forRomPath path: String) -> GameMetadata? {
        metadata[path]
    }
    
    func set(_ meta: GameMetadata) {
        metadata[meta.romPath] = meta
        save()
        objectWillChange.send()
    }
    
    func remove(forRomPath path: String) {
        metadata.removeValue(forKey: path)
        save()
        objectWillChange.send()
    }
    
    func hasCoverArt(forRomPath path: String) -> Bool {
        guard let meta = metadata[path],
              let coverPath = meta.coverArtPath else { return false }
        return FileManager.default.fileExists(atPath: coverPath)
    }
}

// MARK: - Search Result from API

struct ArtworkSearchResult: Identifiable {
    let id: String
    let title: String
    let platform: String
    let releaseYear: Int?
    let coverURL: URL?
    let thumbnailURL: URL?
    
    var displayTitle: String {
        if let year = releaseYear {
            return "\(title) (\(year))"
        }
        return title
    }
}

