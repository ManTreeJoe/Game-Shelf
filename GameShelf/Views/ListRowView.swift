import SwiftUI

struct ListRowView: View {
    let rom: ROM
    let isSelected: Bool
    
    @EnvironmentObject var viewModel: LibraryViewModel
    @State private var isHovered = false
    @State private var coverImage: NSImage?
    
    private var platformColor: Color {
        Theme.platformColor(for: rom.platform)
    }
    
    private var isHighlighted: Bool {
        isHovered || (isSelected && viewModel.isUsingKeyboardNavigation)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Cover art thumbnail
            ZStack {
                if let image = coverImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    LinearGradient(
                        colors: [platformColor.opacity(0.3), Theme.backgroundTertiary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 16))
                        .foregroundColor(platformColor.opacity(0.6))
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke((isSelected && viewModel.isUsingKeyboardNavigation) ? platformColor : .clear, lineWidth: 2)
            )
            
            // Game info
            VStack(alignment: .leading, spacing: 4) {
                Text(rom.displayName)
                    .font(.synthwaveBody(14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(rom.platform)
                        .font(.synthwave(11, weight: .semibold))
                        .foregroundColor(platformColor)
                    
                    Text("•")
                        .foregroundColor(Theme.textTertiary)
                    
                    Text(rom.formattedSize)
                        .font(.synthwave(11))
                        .foregroundColor(Theme.textTertiary)
                    
                    if viewModel.isFavorite(rom) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Theme.neonPink)
                    }
                }
            }
            
            Spacer()
            
            // Play stats
            let stats = SessionTracker.shared.getStats(for: rom)
            if stats.sessionCount > 0 {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(stats.formattedTotalPlayTime)
                        .font(.synthwave(11, weight: .medium))
                        .foregroundColor(Theme.neonCyan)
                    
                    if let lastPlayed = stats.formattedLastPlayed {
                        Text(lastPlayed)
                            .font(.synthwave(10))
                            .foregroundColor(Theme.textTertiary)
                    }
                }
            }
            
            // Play button on hover or gamepad selection
            if isHighlighted {
                Button {
                    viewModel.launchROM(rom)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Theme.neonPinkGradient)
                        .clipShape(Circle())
                        .neonGlow(Theme.neonPink, radius: 6)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            isHighlighted ? platformColor.opacity(0.15) :
                Theme.backgroundTertiary.opacity(0.3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHighlighted ? platformColor.opacity(0.6) : .clear, lineWidth: (isSelected && viewModel.isUsingKeyboardNavigation) ? 2 : 1)
                .neonGlow(platformColor, radius: 6, isActive: isSelected && viewModel.isUsingKeyboardNavigation)
        )
        .cornerRadius(10)
        .scaleEffect(isHighlighted ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onHover { hovering in
            // When mouse is used, disable keyboard navigation highlighting
            if hovering {
                Task { @MainActor in
                    viewModel.isUsingKeyboardNavigation = false
                }
            }
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture(count: 2) {
            viewModel.selectedROM = rom
        }
        .onTapGesture(count: 1) {
            if let index = viewModel.filteredRoms.firstIndex(of: rom) {
                viewModel.selectedIndex = index
            }
        }
        .contextMenu {
            Button { viewModel.launchROM(rom) } label: {
                Label("Play", systemImage: "play.fill")
            }
            .disabled(!viewModel.hasEmulator(for: rom))
            
            Divider()
            
            Button { viewModel.toggleFavorite(rom) } label: {
                Label(viewModel.isFavorite(rom) ? "Unfavorite" : "Favorite", 
                      systemImage: viewModel.isFavorite(rom) ? "heart.slash" : "heart")
            }
            
            Button { viewModel.openInFinder(rom) } label: {
                Label("Show in Finder", systemImage: "folder")
            }
        }
        .task {
            await loadCoverArt()
        }
    }
    
    private func loadCoverArt() async {
        let cacheKey = rom.path.path.safeFileName + "_cover"
        if let cached = await ImageCache.shared.image(forKey: cacheKey) {
            await MainActor.run {
                coverImage = cached
            }
        } else if rom.isSteamGame {
            // Auto-fetch Steam artwork
            await fetchSteamArtwork()
        }
    }
    
    private func fetchSteamArtwork() async {
        guard let url = rom.steamHeaderURL ?? rom.steamCapsuleURL else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = NSImage(data: data) {
                let cacheKey = rom.path.path.safeFileName + "_cover"
                await ImageCache.shared.store(image, forKey: cacheKey)
                await MainActor.run {
                    coverImage = image
                }
            }
        } catch {
            // Silently fail
        }
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
    
    return VStack {
        ListRowView(rom: rom, isSelected: false)
        ListRowView(rom: rom, isSelected: true)
    }
    .padding()
    .background(Theme.background)
    .environmentObject(LibraryViewModel(config: AppConfig()))
}

