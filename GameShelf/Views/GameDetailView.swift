import SwiftUI

struct GameDetailView: View {
    let rom: ROM
    @EnvironmentObject var viewModel: LibraryViewModel
    @EnvironmentObject var config: AppConfig
    @Environment(\.dismiss) private var dismiss
    
    @State private var coverImage: NSImage?
    @State private var isLoadingArt = true
    @State private var showingArtworkPicker = false
    @State private var metadata: GameMetadata?
    @State private var isHoveringPlay = false
    @State private var hasAppeared = false
    @State private var isDroppingArt = false
    @StateObject private var saveManager = SaveManager.shared
    @State private var gameSaves: [SaveFile] = []
    
    private var platformColor: Color {
        Theme.platformColor(for: rom.platform)
    }
    
    private var stats: GameStats {
        SessionTracker.shared.getStats(for: rom)
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Content
            ScrollView {
                VStack(spacing: 0) {
                    // Hero section
                    heroSection
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 20)
                    
                    // Info sections
                    VStack(spacing: 24) {
                        // Quick stats
                        quickStatsSection
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(.smooth.delay(0.1), value: hasAppeared)
                        
                        // Play statistics
                        if stats.sessionCount > 0 {
                            StatsView(rom: rom)
                                .opacity(hasAppeared ? 1 : 0)
                                .offset(y: hasAppeared ? 0 : 20)
                                .animation(.smooth.delay(0.15), value: hasAppeared)
                        }
                        
                        // File info
                        fileInfoSection
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(.smooth.delay(0.2), value: hasAppeared)
                        
                        // Collections
                        collectionsSection
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(.smooth.delay(0.25), value: hasAppeared)
                        
                        // Save files
                        if !gameSaves.isEmpty {
                            savesSection
                                .opacity(hasAppeared ? 1 : 0)
                                .offset(y: hasAppeared ? 0 : 20)
                                .animation(.smooth.delay(0.3), value: hasAppeared)
                        }
                    }
                    .padding(24)
                }
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 32, height: 32)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(20)
                }
                
                Spacer()
            }
        }
        .frame(minWidth: 600, minHeight: 700)
        .onAppear {
            withAnimation(.smooth) {
                hasAppeared = true
            }
        }
        .task {
            await loadArtwork()
            // Scan for save files
            saveManager.scanAllSaves()
            gameSaves = saveManager.saves(for: rom)
        }
        .sheet(isPresented: $showingArtworkPicker) {
            ArtworkPickerView(rom: rom) { image in
                coverImage = image
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            Theme.background
            
            // Blurred cover art as background if available
            if let cover = coverImage {
                Image(nsImage: cover)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 50)
                    .opacity(0.3)
                    .ignoresSafeArea()
            }
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    Theme.background.opacity(0.7),
                    Theme.background,
                    Theme.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Scanlines
            ScanlineOverlay(spacing: 2, opacity: 0.04)
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 24) {
            // Cover art
            ZStack {
                if let image = coverImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(16)
                        .shadow(color: platformColor.opacity(0.5), radius: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(platformColor.opacity(0.5), lineWidth: 2)
                        )
                        .neonGlow(platformColor, radius: 20)
                } else {
                    // Placeholder
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [platformColor.opacity(0.3), Theme.backgroundTertiary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 220, height: 300)
                        .overlay(
                            VStack(spacing: 16) {
                                if isLoadingArt {
                                    ProgressView()
                                        .tint(platformColor)
                                } else {
                                    Image(systemName: "gamecontroller.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(platformColor.opacity(0.5))
                                    
                                    Button {
                                        Task { await fetchArtwork() }
                                    } label: {
                                        Text("Fetch Artwork")
                                            .font(.synthwave(12, weight: .medium))
                                            .foregroundColor(platformColor)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(platformColor.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .overlay(
                Group {
                    if isDroppingArt {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Theme.neonCyan, lineWidth: 3)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.neonCyan.opacity(0.1)))
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 40))
                                    Text("Drop to set cover art")
                                        .font(.synthwave(14, weight: .medium))
                                }
                                .foregroundColor(Theme.neonCyan)
                            )
                    }
                }
            )
            .onTapGesture {
                showingArtworkPicker = true
            }
            .onDrop(of: [.fileURL, .image], isTargeted: $isDroppingArt) { providers in
                handleArtworkDrop(providers: providers)
            }
            
            Text("Drop image to set cover art • Click to browse")
                .font(.synthwave(10))
                .foregroundColor(Theme.textTertiary)
            
            // Title and platform
            VStack(spacing: 8) {
                Text(rom.displayName)
                    .font(.synthwaveDisplay(28))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .neonGlow(platformColor, radius: 6)
                
                HStack(spacing: 12) {
                    // Platform badge
                    HStack(spacing: 6) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 12))
                        Text(rom.platform)
                    }
                    .font(.synthwave(13, weight: .semibold))
                    .foregroundColor(platformColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(platformColor.opacity(0.15))
                    .cornerRadius(20)
                    .neonGlow(platformColor, radius: 4)
                    
                    // Extension badge
                    Text(rom.fileExtension.uppercased())
                        .font(.synthwave(11, weight: .bold))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Theme.backgroundTertiary)
                        .cornerRadius(20)
                }
            }
            
            // Action buttons
            HStack(spacing: 16) {
                // Play button
                Button {
                    viewModel.launchROM(rom)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .bold))
                        Text("PLAY")
                            .font(.synthwave(16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(
                        viewModel.hasEmulator(for: rom) ?
                            AnyShapeStyle(Theme.neonPinkGradient) :
                            AnyShapeStyle(Theme.warmAmber)
                    )
                    .cornerRadius(14)
                    .neonGlow(viewModel.hasEmulator(for: rom) ? Theme.neonPink : Theme.warmAmber, radius: 15, isActive: isHoveringPlay)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!viewModel.hasEmulator(for: rom))
                .onHover { hovering in
                    isHoveringPlay = hovering
                }
                
                // Favorite button
                Button {
                    viewModel.toggleFavorite(rom)
                } label: {
                    Image(systemName: viewModel.isFavorite(rom) ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.isFavorite(rom) ? Theme.neonPink : .white)
                        .padding(14)
                        .background(Theme.backgroundTertiary)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(viewModel.isFavorite(rom) ? Theme.neonPink.opacity(0.5) : .clear, lineWidth: 1)
                        )
                        .neonGlow(Theme.neonPink, radius: 8, isActive: viewModel.isFavorite(rom))
                }
                .buttonStyle(ScaleButtonStyle())
                
                // Show in Finder button
                Button {
                    viewModel.openInFinder(rom)
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .padding(14)
                        .background(Theme.backgroundTertiary)
                        .cornerRadius(14)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            if !viewModel.hasEmulator(for: rom) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Theme.warmAmber)
                    
                    Text("No emulator configured for \(rom.fileExtension) files")
                        .font(.synthwave(12))
                        .foregroundColor(Theme.warmAmber)
                    
                    Button("Configure") {
                        viewModel.showingSettings = true
                    }
                    .font(.synthwave(12, weight: .bold))
                    .foregroundColor(Theme.neonCyan)
                }
                .padding(.top, 8)
            }
        }
        .padding(.top, 60)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Quick Stats
    
    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            QuickStatCard(
                icon: "clock.fill",
                value: stats.formattedTotalPlayTime,
                label: "Play Time",
                color: Theme.neonPink
            )
            
            QuickStatCard(
                icon: "play.circle.fill",
                value: "\(stats.sessionCount)",
                label: "Sessions",
                color: Theme.neonCyan
            )
            
            QuickStatCard(
                icon: "calendar",
                value: stats.formattedLastPlayed ?? "Never",
                label: "Last Played",
                color: Theme.neonPurple
            )
            
            QuickStatCard(
                icon: "internaldrive.fill",
                value: rom.formattedSize,
                label: "File Size",
                color: Theme.warmAmber
            )
        }
    }
    
    // MARK: - File Info
    
    private var fileInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "FILE INFORMATION", icon: "doc.fill")
            
            VStack(spacing: 12) {
                FileInfoRow(label: "Filename", value: rom.path.lastPathComponent)
                FileInfoRow(label: "Location", value: rom.path.deletingLastPathComponent().path)
                FileInfoRow(label: "Extension", value: rom.fileExtension.uppercased())
                FileInfoRow(label: "Size", value: rom.formattedSize)
                FileInfoRow(label: "Added", value: formattedDate(rom.dateAdded))
            }
            .padding(16)
            .background(Theme.backgroundTertiary)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Collections
    
    private var collectionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "COLLECTIONS", icon: "folder.fill")
            
            let gameCollections = config.collections(containing: rom.path.path)
            
            if gameCollections.isEmpty {
                HStack {
                    Text("Not in any collections")
                        .font(.synthwave(13))
                        .foregroundColor(Theme.textTertiary)
                    
                    Spacer()
                    
                    Menu("Add to Collection") {
                        ForEach(config.collections) { collection in
                            Button {
                                config.addRomToCollection(rom.path.path, collectionId: collection.id)
                            } label: {
                                Label(collection.name, systemImage: collection.icon)
                            }
                        }
                        
                        if config.collections.isEmpty {
                            Text("No collections created yet")
                        }
                    }
                    .font(.synthwave(12, weight: .medium))
                }
                .padding(16)
                .background(Theme.backgroundTertiary)
                .cornerRadius(12)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(gameCollections) { collection in
                            CollectionBadge(collection: collection) {
                                config.removeRomFromCollection(rom.path.path, collectionId: collection.id)
                            }
                        }
                        
                        // Add to collection button
                        Menu {
                            ForEach(config.collections.filter { !gameCollections.contains($0) }) { collection in
                                Button {
                                    config.addRomToCollection(rom.path.path, collectionId: collection.id)
                                } label: {
                                    Label(collection.name, systemImage: collection.icon)
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add")
                            }
                            .font(.synthwave(12, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Theme.backgroundTertiary)
                            .cornerRadius(20)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Save Files
    
    private var savesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                SectionHeader(title: "SAVE FILES", icon: "doc.badge.clock.fill")
                
                Spacer()
                
                Button {
                    backupSaves()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Backup All")
                    }
                    .font(.synthwave(11, weight: .medium))
                    .foregroundColor(Theme.neonCyan)
                }
                .buttonStyle(.plain)
            }
            
            VStack(spacing: 8) {
                ForEach(gameSaves) { save in
                    SaveFileRow(save: save) {
                        saveManager.revealInFinder(save)
                    }
                }
            }
            .padding(16)
            .background(Theme.backgroundTertiary)
            .cornerRadius(12)
        }
    }
    
    private func backupSaves() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder to save backups"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try saveManager.backupSaves(for: rom, to: url)
                // Show success (could add an alert here)
            } catch {
                print("Backup failed: \(error)")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func loadArtwork() async {
        let cacheKey = rom.path.path.safeFileName + "_cover"
        if let cached = await ImageCache.shared.image(forKey: cacheKey) {
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.3)) {
                    coverImage = cached
                    isLoadingArt = false
                }
            }
        } else {
            await MainActor.run {
                isLoadingArt = false
            }
        }
    }
    
    private func fetchArtwork() async {
        await MainActor.run { isLoadingArt = true }
        
        if let image = await ArtworkScraper.shared.fetchArtwork(for: rom) {
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.3)) {
                    coverImage = image
                    isLoadingArt = false
                }
            }
        } else {
            await MainActor.run { isLoadingArt = false }
        }
    }
    
    private func handleArtworkDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            // Handle image files
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil),
                          let image = NSImage(contentsOf: url) else { return }
                    
                    Task {
                        await saveCustomArtwork(image)
                    }
                }
                return true
            }
            
            // Handle dragged images directly
            if provider.hasItemConformingToTypeIdentifier("public.image") {
                provider.loadItem(forTypeIdentifier: "public.image", options: nil) { item, error in
                    var image: NSImage?
                    
                    if let nsImage = item as? NSImage {
                        image = nsImage
                    } else if let data = item as? Data {
                        image = NSImage(data: data)
                    } else if let url = item as? URL {
                        image = NSImage(contentsOf: url)
                    }
                    
                    if let image = image {
                        Task {
                            await saveCustomArtwork(image)
                        }
                    }
                }
                return true
            }
        }
        return false
    }
    
    private func saveCustomArtwork(_ image: NSImage) async {
        // Cache the image
        let cacheKey = rom.path.path.safeFileName + "_cover"
        await ImageCache.shared.store(image, forKey: cacheKey)
        
        // Update UI
        await MainActor.run {
            withAnimation(.easeIn(duration: 0.3)) {
                coverImage = image
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Theme.neonCyan)
            
            Text(title)
                .font(.synthwave(11, weight: .bold))
                .foregroundColor(Theme.textTertiary)
                .tracking(2)
        }
    }
}

struct QuickStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .neonGlow(color, radius: 6, isActive: isHovered)
            
            Text(value)
                .font(.synthwave(16, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.synthwave(10))
                .foregroundColor(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.backgroundTertiary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? color.opacity(0.4) : .clear, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.quick) {
                isHovered = hovering
            }
        }
    }
}

struct FileInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.synthwave(12))
                .foregroundColor(Theme.textTertiary)
            
            Spacer()
            
            Text(value)
                .font(.synthwave(12, weight: .medium))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

struct CollectionBadge: View {
    let collection: GameCollection
    let onRemove: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: collection.icon)
                .foregroundColor(collection.color)
            
            Text(collection.name)
                .font(.synthwave(12, weight: .medium))
                .foregroundColor(.white)
            
            if isHovered {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(collection.color.opacity(0.2))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(collection.color.opacity(0.5), lineWidth: 1)
        )
        .cornerRadius(20)
        .neonGlow(collection.color, radius: 6, isActive: isHovered)
        .onHover { hovering in
            withAnimation(.quick) {
                isHovered = hovering
            }
        }
    }
}

struct SaveFileRow: View {
    let save: SaveFile
    let onReveal: () -> Void
    
    @State private var isHovered = false
    
    private var typeColor: Color {
        switch save.type {
        case .saveState: return Theme.neonCyan
        case .batterySave: return Theme.neonGreen
        case .memoryCard: return Theme.neonPurple
        case .saveData: return Theme.warmAmber
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: save.type.icon)
                .font(.system(size: 16))
                .foregroundColor(typeColor)
                .frame(width: 24)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(save.name)
                    .font(.synthwave(12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(save.type.rawValue)
                        .font(.synthwave(10))
                        .foregroundColor(typeColor)
                    
                    Text("•")
                        .foregroundColor(Theme.textTertiary)
                    
                    Text(save.emulator)
                        .font(.synthwave(10))
                        .foregroundColor(Theme.textTertiary)
                    
                    Text("•")
                        .foregroundColor(Theme.textTertiary)
                    
                    Text(save.formattedSize)
                        .font(.synthwave(10))
                        .foregroundColor(Theme.textTertiary)
                }
            }
            
            Spacer()
            
            // Date
            Text(save.formattedDate)
                .font(.synthwave(10))
                .foregroundColor(Theme.textSecondary)
            
            // Reveal button
            if isHovered {
                Button {
                    onReveal()
                } label: {
                    Image(systemName: "arrow.right.circle")
                        .font(.system(size: 14))
                        .foregroundColor(Theme.neonCyan)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isHovered ? Theme.backgroundSecondary : .clear)
        .cornerRadius(8)
        .onHover { hovering in
            withAnimation(.quick) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    let rom = ROM(
        id: "test",
        name: "Super Mario Bros. 3 (USA)",
        path: URL(fileURLWithPath: "/Games/NES/Super Mario Bros. 3.nes"),
        fileExtension: ".nes",
        platform: "NES",
        fileSize: 524288,
        dateAdded: Date()
    )
    
    return GameDetailView(rom: rom)
        .environmentObject(LibraryViewModel(config: AppConfig()))
        .environmentObject(AppConfig())
}

