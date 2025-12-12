import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Artwork Scraper

actor ArtworkScraper {
    static let shared = ArtworkScraper()
    
    private let metadataDB = MetadataDatabase()
    
    // LibRetro Thumbnails base URL (free, no API key needed)
    private let libretroBaseURL = "https://thumbnails.libretro.com"
    
    // Platform mapping for LibRetro thumbnail naming
    private let platformMapping: [String: String] = [
        "NES": "Nintendo - Nintendo Entertainment System",
        "SNES": "Nintendo - Super Nintendo Entertainment System",
        "Game Boy": "Nintendo - Game Boy",
        "Game Boy Color": "Nintendo - Game Boy Color",
        "Game Boy Advance": "Nintendo - Game Boy Advance",
        "Nintendo 64": "Nintendo - Nintendo 64",
        "GameCube": "Nintendo - GameCube",
        "Wii": "Nintendo - Wii",
        "Nintendo DS": "Nintendo - Nintendo DS",
        "Nintendo 3DS": "Nintendo - Nintendo 3DS",
        "PlayStation": "Sony - PlayStation",
        "PlayStation 2": "Sony - PlayStation 2",
        "PSP": "Sony - PlayStation Portable",
        "Sega Genesis": "Sega - Mega Drive - Genesis",
        "Sega Master System": "Sega - Master System - Mark III",
        "Game Gear": "Sega - Game Gear",
        "Dreamcast": "Sega - Dreamcast",
        "Sega Saturn": "Sega - Saturn",
    ]
    
    // MARK: - Public API
    
    func fetchArtwork(for rom: ROM) async -> NSImage? {
        // Check if we already have cached artwork
        let cacheKey = rom.path.path.safeFileName + "_cover"
        if let cached = await ImageCache.shared.image(forKey: cacheKey) {
            return cached
        }
        
        // Try to fetch from LibRetro thumbnails
        if let image = await fetchFromLibRetro(rom: rom) {
            await ImageCache.shared.store(image, forKey: cacheKey)
            
            // Update metadata
            await MainActor.run {
                var meta = metadataDB.get(forRomPath: rom.path.path) ?? GameMetadata(romPath: rom.path.path)
                meta.coverArtPath = ImageCache.coverArtPath(forRomPath: rom.path.path).path
                meta.lastUpdated = Date()
                metadataDB.set(meta)
            }
            
            return image
        }
        
        return nil
    }
    
    func searchArtwork(query: String, platform: String) async -> [ArtworkSearchResult] {
        // For now, just return empty - in a full implementation,
        // you'd query a database like IGDB or ScreenScraper
        return []
    }
    
    // MARK: - LibRetro Thumbnails
    
    private func fetchFromLibRetro(rom: ROM) async -> NSImage? {
        guard let libRetroPlatform = platformMapping[rom.platform] else {
            return nil
        }
        
        // LibRetro uses the exact game name (without extension)
        // URL format: https://thumbnails.libretro.com/{System}/Named_Boxarts/{Game}.png
        let gameName = rom.name
            .replacingOccurrences(of: "&", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        
        // URL encode the components
        guard let encodedPlatform = libRetroPlatform.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let encodedName = gameName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }
        
        let boxartURL = "\(libretroBaseURL)/\(encodedPlatform)/Named_Boxarts/\(encodedName).png"
        
        if let url = URL(string: boxartURL),
           let image = await downloadImage(from: url) {
            return image
        }
        
        // Try without region codes
        let cleanName = cleanGameName(gameName)
        if cleanName != gameName,
           let encodedCleanName = cleanName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
            let cleanURL = "\(libretroBaseURL)/\(encodedPlatform)/Named_Boxarts/\(encodedCleanName).png"
            if let url = URL(string: cleanURL),
               let image = await downloadImage(from: url) {
                return image
            }
        }
        
        return nil
    }
    
    private func downloadImage(from url: URL) async -> NSImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            return NSImage(data: data)
        } catch {
            return nil
        }
    }
    
    private func cleanGameName(_ name: String) -> String {
        // Remove common region/version codes
        var cleaned = name
        
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
}

// MARK: - Batch Artwork Fetcher

class BatchArtworkFetcher: ObservableObject {
    @Published var progress: Double = 0
    @Published var currentGame: String = ""
    @Published var isRunning = false
    @Published var successCount = 0
    @Published var failCount = 0
    
    private var task: Task<Void, Never>?
    
    func startFetching(roms: [ROM]) {
        guard !isRunning else { return }
        
        isRunning = true
        progress = 0
        successCount = 0
        failCount = 0
        
        task = Task {
            let total = roms.count
            
            for (index, rom) in roms.enumerated() {
                if Task.isCancelled { break }
                
                await MainActor.run {
                    currentGame = rom.displayName
                    progress = Double(index) / Double(total)
                }
                
                let image = await ArtworkScraper.shared.fetchArtwork(for: rom)
                
                await MainActor.run {
                    if image != nil {
                        successCount += 1
                    } else {
                        failCount += 1
                    }
                }
                
                // Small delay to avoid rate limiting
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
            
            await MainActor.run {
                isRunning = false
                progress = 1.0
            }
        }
    }
    
    func cancel() {
        task?.cancel()
        isRunning = false
    }
}

// MARK: - Artwork Picker View

struct ArtworkPickerView: View {
    let rom: ROM
    let onSelect: (NSImage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery: String = ""
    @State private var searchResults: [ArtworkSearchResult] = []
    @State private var isSearching = false
    @State private var selectedImage: NSImage?
    @State private var isLoadingImage = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Select Artwork")
                        .font(.synthwaveDisplay(18))
                        .foregroundColor(.white)
                    
                    Text(rom.displayName)
                        .font(.synthwaveBody(14))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Theme.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(Theme.backgroundSecondary)
            
            Divider()
            
            // Search
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Theme.neonCyan)
                
                TextField("Search for artwork...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .onSubmit {
                        // Search functionality would go here
                    }
                
                if isSearching {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(12)
            .background(Theme.backgroundTertiary)
            .cornerRadius(8)
            .padding(20)
            
            // Content
            if searchResults.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.textTertiary)
                    
                    Text("Search for game artwork or drag an image here")
                        .font(.synthwaveBody(14))
                        .foregroundColor(Theme.textSecondary)
                    
                    Button {
                        openFilePicker()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "folder")
                            Text("Browse Files...")
                        }
                        .font(.synthwave(14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Theme.neonCyanGradient)
                        .cornerRadius(10)
                        .neonGlow(Theme.neonCyan, radius: 8)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
                        ForEach(searchResults) { result in
                            ArtworkResultCard(result: result) { image in
                                selectedImage = image
                            }
                        }
                    }
                    .padding(20)
                }
            }
            
            Divider()
            
            // Actions
            HStack {
                // Drop zone indicator
                Text("Drop image to use custom artwork")
                    .font(.synthwave(12))
                    .foregroundColor(Theme.textTertiary)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.textSecondary)
                
                if let image = selectedImage {
                    Button {
                        onSelect(image)
                        dismiss()
                    } label: {
                        Text("Use Selected")
                            .font(.synthwave(14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Theme.neonPinkGradient)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(Theme.backgroundSecondary)
        }
        .frame(width: 600, height: 500)
        .background(Theme.background)
        .onAppear {
            searchQuery = rom.displayName
        }
    }
    
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image, .png, .jpeg, .gif, .webP, .tiff, .bmp]
        panel.message = "Select an image for \(rom.displayName)"
        panel.prompt = "Select"
        
        if panel.runModal() == .OK, let url = panel.url {
            if let image = NSImage(contentsOf: url) {
                selectedImage = image
                // Auto-apply the selected image
                onSelect(image)
                dismiss()
            }
        }
    }
}

struct ArtworkResultCard: View {
    let result: ArtworkSearchResult
    let onSelect: (NSImage) -> Void
    
    @State private var image: NSImage?
    @State private var isLoading = true
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "photo")
                        .foregroundColor(Theme.textTertiary)
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(Theme.backgroundTertiary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isHovered ? Theme.neonCyan : .clear, lineWidth: 2)
            )
            .neonGlow(Theme.neonCyan, radius: 6, isActive: isHovered)
            
            Text(result.title)
                .font(.synthwave(11))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(2)
        }
        .onHover { hovering in
            withAnimation(.quick) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            if let img = image {
                onSelect(img)
            }
        }
        .task {
            if let url = result.thumbnailURL {
                image = await ImageCache.shared.downloadAndCache(from: url, forKey: result.id)
            }
            isLoading = false
        }
    }
}

