import Foundation
import SwiftUI
import AppKit

actor ImageCache {
    static let shared = ImageCache()
    
    private var memoryCache: [String: NSImage] = [:]
    private let maxMemoryCacheSize = 100
    private var accessOrder: [String] = []
    
    private static var cacheDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let cacheFolder = appSupport.appendingPathComponent("GameShelf/ImageCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheFolder, withIntermediateDirectories: true)
        return cacheFolder
    }
    
    // MARK: - Public API
    
    func image(forKey key: String) async -> NSImage? {
        // Check memory cache first
        if let cached = memoryCache[key] {
            updateAccessOrder(key)
            return cached
        }
        
        // Check disk cache
        let diskPath = Self.cacheDirectory.appendingPathComponent(key.safeFileName)
        if FileManager.default.fileExists(atPath: diskPath.path),
           let image = NSImage(contentsOf: diskPath) {
            // Add to memory cache
            addToMemoryCache(key: key, image: image)
            return image
        }
        
        return nil
    }
    
    func store(_ image: NSImage, forKey key: String) async {
        // Store in memory cache
        addToMemoryCache(key: key, image: image)
        
        // Store on disk
        let diskPath = Self.cacheDirectory.appendingPathComponent(key.safeFileName)
        if let tiffData = image.tiffRepresentation,
           let bitmapRep = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapRep.representation(using: .png, properties: [:]) {
            try? pngData.write(to: diskPath)
        }
    }
    
    func downloadAndCache(from url: URL, forKey key: String) async -> NSImage? {
        // Check cache first
        if let cached = await image(forKey: key) {
            return cached
        }
        
        // Download
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let image = NSImage(data: data) else {
                return nil
            }
            
            // Cache it
            await store(image, forKey: key)
            return image
        } catch {
            print("Failed to download image: \(error)")
            return nil
        }
    }
    
    func clearMemoryCache() {
        memoryCache.removeAll()
        accessOrder.removeAll()
    }
    
    func clearDiskCache() {
        let fileManager = FileManager.default
        if let files = try? fileManager.contentsOfDirectory(at: Self.cacheDirectory, includingPropertiesForKeys: nil) {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
    }
    
    func diskCacheSize() -> Int64 {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: Self.cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for file in files {
            if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }
        return totalSize
    }
    
    // MARK: - Private Helpers
    
    private func addToMemoryCache(key: String, image: NSImage) {
        // Evict if necessary
        while memoryCache.count >= maxMemoryCacheSize, let oldestKey = accessOrder.first {
            memoryCache.removeValue(forKey: oldestKey)
            accessOrder.removeFirst()
        }
        
        memoryCache[key] = image
        updateAccessOrder(key)
    }
    
    private func updateAccessOrder(_ key: String) {
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
    }
    
    // Get the disk cache path for a ROM
    static func coverArtPath(forRomPath romPath: String) -> URL {
        let key = romPath.safeFileName + "_cover"
        return cacheDirectory.appendingPathComponent(key + ".png")
    }
}

// MARK: - String Extension for Safe Filenames

extension String {
    var safeFileName: String {
        // Create a safe filename by hashing or sanitizing
        let invalidChars = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        var safe = self.components(separatedBy: invalidChars).joined(separator: "_")
        
        // Limit length
        if safe.count > 100 {
            safe = String(safe.prefix(100))
        }
        
        // If still problematic, use hash
        if safe.isEmpty {
            safe = String(self.hashValue)
        }
        
        return safe
    }
}

// MARK: - SwiftUI Image Loading

struct CachedAsyncImage: View {
    let romPath: String
    let placeholder: AnyView
    
    @State private var image: NSImage?
    @State private var isLoading = true
    
    init(romPath: String, @ViewBuilder placeholder: () -> some View) {
        self.romPath = romPath
        self.placeholder = AnyView(placeholder())
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        let key = romPath.safeFileName + "_cover"
        if let cached = await ImageCache.shared.image(forKey: key) {
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.2)) {
                    self.image = cached
                    self.isLoading = false
                }
            }
        } else {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

