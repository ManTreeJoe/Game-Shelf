import SwiftUI

struct GameCardView: View {
    let rom: ROM
    let appearDelay: Double
    let isKeyboardSelected: Bool
    
    @EnvironmentObject var viewModel: LibraryViewModel
    @State private var isHovered = false
    @State private var isPressed = false
    @State private var hasAppeared = false
    @State private var glitchOffset: CGFloat = 0
    @State private var showGlitch = false
    @State private var coverImage: NSImage?
    @State private var isLoadingArt = true
    @State private var showingArtworkPicker = false
    
    private var platformColor: Color {
        Theme.platformColor(for: rom.platform)
    }
    
    private var isHighlighted: Bool {
        isHovered || (isKeyboardSelected && viewModel.isUsingKeyboardNavigation)
    }
    
    init(rom: ROM, appearDelay: Double = 0, isKeyboardSelected: Bool = false) {
        self.rom = rom
        self.appearDelay = appearDelay
        self.isKeyboardSelected = isKeyboardSelected
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Game art with CRT effect
            ZStack {
                // Cover art or placeholder
                if let image = coverImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .transition(.opacity)
                } else {
                    // CRT-style background placeholder
                    CRTCardBackground(platformColor: platformColor)
                    
                    // Game icon/text
                VStack(spacing: 12) {
                        if isLoadingArt {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(platformColor)
                        } else {
                            Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [platformColor, platformColor.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                                .neonGlow(platformColor, radius: 8, isActive: isHighlighted)
                        }
                        
                        Text(rom.displayName.prefix(1).uppercased())
                            .font(.synthwaveDisplay(28))
                            .foregroundColor(.white.opacity(0.2))
                    }
                    // RGB split/glitch effect on hover
                    .modifier(RGBSplitEffect(isActive: isHighlighted, offset: 2))
                }
                
                // Scanline overlay on cover art
                if coverImage != nil {
                    ScanlineOverlay(spacing: 2, opacity: 0.08)
                    
                    // CRT vignette
                    RadialGradient(
                        colors: [.clear, .clear, Color.black.opacity(0.3)],
                        center: .center,
                        startRadius: 50,
                        endRadius: 120
                    )
                }
                
                // Glitch line effect
                if showGlitch {
                    GlitchLineEffect()
                }
                
                // Hover overlay with actions
                if isHovered && rom.isAvailable {
                    Color.black.opacity(0.7)
                        .transition(.opacity)
                    
                    VStack(spacing: 12) {
                        // Play button
                        Button {
                            viewModel.launchROM(rom)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.hasEmulator(for: rom) ? "play.fill" : "exclamationmark.triangle.fill")
                                Text(viewModel.hasEmulator(for: rom) ? "PLAY" : "NO EMU")
                            }
                            .font(.synthwave(13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                viewModel.hasEmulator(for: rom) ?
                                    AnyShapeStyle(Theme.neonPinkGradient) :
                                    AnyShapeStyle(Theme.warmAmber)
                            )
                            .cornerRadius(10)
                            .neonGlow(viewModel.hasEmulator(for: rom) ? Theme.neonPink : Theme.warmAmber, radius: 8)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        // Action buttons
                        HStack(spacing: 16) {
                            Button {
                                viewModel.toggleFavorite(rom)
                            } label: {
                                Image(systemName: viewModel.isFavorite(rom) ? "heart.fill" : "heart")
                                    .font(.system(size: 18))
                                    .foregroundColor(viewModel.isFavorite(rom) ? Theme.neonPink : .white.opacity(0.8))
                                    .neonGlow(Theme.neonPink, radius: 6, isActive: viewModel.isFavorite(rom))
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            Button {
                                viewModel.openInFinder(rom)
                            } label: {
                                Image(systemName: "folder")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .buttonStyle(ScaleButtonStyle())
                            
                            // Add artwork button
                            Button {
                                showingArtworkPicker = true
                            } label: {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
                
                // Favorite badge (when not hovering)
                if viewModel.isFavorite(rom) && !isHovered {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.neonPink)
                                .neonGlow(Theme.neonPink, radius: 6)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
                
                // Unavailable overlay (drive disconnected)
                if !rom.isAvailable {
                    Color.black.opacity(0.6)
                    
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "externaldrive.badge.xmark")
                                .font(.system(size: 11, weight: .semibold))
                            Text("OFFLINE")
                                .font(.synthwave(10, weight: .bold))
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.warmAmber.opacity(0.8))
                        .cornerRadius(6)
                        .padding(8)
                    }
                }
                
                // Neon border glow on hover or keyboard/gamepad selection
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(platformColor, lineWidth: 2)
                        .neonGlow(platformColor, radius: 12)
                        .transition(.opacity)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Game info
            VStack(alignment: .leading, spacing: 4) {
                Text(rom.displayName)
                    .font(.synthwaveBody(14))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 8) {
                    Text(rom.platform)
                        .font(.synthwave(11, weight: .semibold))
                        .foregroundColor(platformColor)
                    
                    Text("•")
                        .foregroundColor(Theme.textTertiary)
                    
                    Text(rom.formattedSize)
                        .font(.synthwave(11))
                        .foregroundColor(Theme.textTertiary)
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 2)
        }
        .scaleEffect(isPressed ? 0.96 : (isHighlighted ? 1.05 : 1.0))
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isKeyboardSelected)
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isPressed)
        .onHover { hovering in
            // When mouse is used, disable keyboard navigation highlighting
            if hovering {
                Task { @MainActor in
                    viewModel.isUsingKeyboardNavigation = false
                }
            }
            withAnimation(.easeOut(duration: 0.2)) {
                isHovered = hovering
            }
            
            // Occasional glitch effect
            if hovering && Bool.random() {
                triggerGlitch()
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onTapGesture(count: 2) {
            // Double-click to launch the game
            viewModel.launchROM(rom)
        }
        .onTapGesture(count: 1) {
            // Single-click to open game details
            viewModel.selectedROM = rom
        }
        .contextMenu {
            Button {
                viewModel.launchROM(rom)
            } label: {
                Label("Play", systemImage: "play.fill")
            }
            .disabled(!viewModel.hasEmulator(for: rom) || !rom.isAvailable)
            
            if !rom.isAvailable {
                Label("Drive Disconnected", systemImage: "externaldrive.badge.xmark")
                    .foregroundColor(Theme.warmAmber)
            }
            
            Divider()
            
            Button {
                viewModel.toggleFavorite(rom)
            } label: {
                Label(
                    viewModel.isFavorite(rom) ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: viewModel.isFavorite(rom) ? "heart.slash" : "heart"
                )
            }
            
            // Collections submenu
            Menu("Add to Collection") {
                ForEach(viewModel.config.collections) { collection in
                    Button {
                        viewModel.addToCollection(rom, collection: collection)
                    } label: {
                        Label(collection.name, systemImage: collection.icon)
                    }
                }
                
                if viewModel.config.collections.isEmpty {
                    Text("No collections yet")
                }
            }
            
            // Change Platform submenu
            Menu("Change Platform") {
                ForEach(Platform.builtIn) { platform in
                    Button {
                        viewModel.changePlatform(rom, to: platform.name)
                    } label: {
                        HStack {
                            Text(platform.name)
                            if rom.platform == platform.name {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Divider()
                
                if viewModel.config.getPlatformOverride(forRomPath: rom.path.path) != nil {
                    Button(role: .destructive) {
                        viewModel.resetPlatform(rom)
                    } label: {
                        Label("Reset to Auto-Detect", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            
            Divider()
            
            Button {
                Task { await fetchArtwork() }
            } label: {
                Label("Fetch Artwork", systemImage: "photo")
            }
            
            Button {
                viewModel.openInFinder(rom)
            } label: {
                Label("Show in Finder", systemImage: "folder")
            }
            
            Divider()
            
            Text("File: \(rom.path.lastPathComponent)")
                .font(.caption)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(appearDelay)) {
                hasAppeared = true
            }
        }
        .task {
            await loadCachedArtwork()
        }
        .sheet(isPresented: $showingArtworkPicker) {
            ArtworkPickerView(rom: rom) { image in
                // Save the artwork to cache
                let cacheKey = rom.path.path.safeFileName + "_cover"
                Task {
                    await ImageCache.shared.store(image, forKey: cacheKey)
                    await MainActor.run {
                        withAnimation(.easeIn(duration: 0.3)) {
                            coverImage = image
                        }
                    }
                }
            }
        }
    }
    
    private func triggerGlitch() {
        showGlitch = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            showGlitch = false
        }
    }
    
    private func loadCachedArtwork() async {
        let cacheKey = rom.path.path.safeFileName + "_cover"
        if let cached = await ImageCache.shared.image(forKey: cacheKey) {
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.3)) {
                    coverImage = cached
                    isLoadingArt = false
                }
            }
        } else if rom.isSteamGame {
            // Auto-fetch Steam artwork
            await fetchSteamArtwork()
        } else {
            await MainActor.run {
                isLoadingArt = false
            }
        }
    }
    
    private func fetchSteamArtwork() async {
        guard let url = rom.steamHeaderURL ?? rom.steamCapsuleURL else {
            await MainActor.run { isLoadingArt = false }
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = NSImage(data: data) {
                let cacheKey = rom.path.path.safeFileName + "_cover"
                await ImageCache.shared.store(image, forKey: cacheKey)
                await MainActor.run {
                    withAnimation(.easeIn(duration: 0.3)) {
                        coverImage = image
                        isLoadingArt = false
                    }
                }
            } else {
                await MainActor.run { isLoadingArt = false }
            }
        } catch {
            await MainActor.run { isLoadingArt = false }
        }
    }
    
    private func fetchArtwork() async {
        await MainActor.run {
            isLoadingArt = true
        }
        
        if let image = await ArtworkScraper.shared.fetchArtwork(for: rom) {
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.3)) {
                    coverImage = image
                    isLoadingArt = false
                }
            }
        } else {
            await MainActor.run {
                isLoadingArt = false
            }
        }
    }
}

// MARK: - RGB Split Effect

struct RGBSplitEffect: ViewModifier {
    let isActive: Bool
    let offset: CGFloat
    
    func body(content: Content) -> some View {
        ZStack {
            if isActive {
                // Red channel offset
                content
                    .colorMultiply(.red)
                    .opacity(0.5)
                    .offset(x: -offset, y: 0)
                    .blendMode(.screen)
                
                // Blue channel offset
                content
                    .colorMultiply(.blue)
                    .opacity(0.5)
                    .offset(x: offset, y: 0)
                    .blendMode(.screen)
            }
            
            content
        }
    }
}

// MARK: - Glitch Line Effect

struct GlitchLineEffect: View {
    @State private var linePosition: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            Theme.neonCyan.opacity(0.3),
                            Theme.neonPink.opacity(0.4),
                            Theme.neonCyan.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
                .offset(y: linePosition)
                .onAppear {
                    linePosition = -10
                    withAnimation(.linear(duration: 0.15)) {
                        linePosition = geo.size.height + 10
                    }
                }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    let rom = ROM(
        id: "test",
        name: "Super Mario Bros. 3 (USA)",
        path: URL(fileURLWithPath: "/test/game.nes"),
        fileExtension: ".nes",
        platform: "NES",
        fileSize: 524288,
        dateAdded: Date()
    )
    
    return ZStack {
        AnimatedSynthwaveBackground()
        
        GameCardView(rom: rom)
            .environmentObject(LibraryViewModel(config: AppConfig()))
            .frame(width: 200)
            .padding()
    }
    .frame(width: 400, height: 400)
}