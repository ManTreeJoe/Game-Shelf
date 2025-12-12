import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var viewModel: LibraryViewModel
    @EnvironmentObject var config: AppConfig
    @StateObject private var gamepadController = GamepadController()
    @State private var columnCount: Int = 5
    @State private var hasAppeared = false
    @State private var isCompactTitle = false
    
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 20), count: columnCount)
    }
    
    var body: some View {
        ZStack {
            // Animated synthwave background
            AnimatedSynthwaveBackground()
                .ignoresSafeArea()
            
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Content
                if viewModel.isLoading {
                    loadingView
            } else if viewModel.filteredRoms.isEmpty {
                    emptyStateView
            } else {
                    libraryGrid
                }
            }
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            SettingsView()
                .environmentObject(config)
        }
        .sheet(item: $viewModel.selectedROM) { rom in
            GameDetailView(rom: rom)
                .environmentObject(viewModel)
                .environmentObject(config)
        }
        .sheet(isPresented: $viewModel.showingArtworkFetcher) {
            ArtworkFetcherView(fetcher: viewModel.artworkFetcher)
        }
        .sheet(isPresented: $viewModel.showingQuickLaunch) {
            QuickLaunchView()
                .environmentObject(viewModel)
        }
        // Keyboard shortcuts
        .onKeyPress(.upArrow) {
            viewModel.isUsingKeyboardNavigation = true
            viewModel.selectPreviousRow(columns: columnCount)
            return .handled
        }
        .onKeyPress(.downArrow) {
            viewModel.isUsingKeyboardNavigation = true
            viewModel.selectNextRow(columns: columnCount)
            return .handled
        }
        .onKeyPress(.leftArrow) {
            viewModel.isUsingKeyboardNavigation = true
            viewModel.selectPrevious()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            viewModel.isUsingKeyboardNavigation = true
            viewModel.selectNext()
            return .handled
        }
        .onKeyPress(.return) {
            viewModel.launchSelected()
            return .handled
        }
        .onKeyPress(.space) {
            viewModel.openSelectedDetails()
            return .handled
        }
        .keyboardShortcut("k", modifiers: .command)
        .alert("Launch Error", isPresented: .init(
            get: { viewModel.launchError != nil },
            set: { if !$0 { viewModel.launchError = nil } }
        )) {
            Button("OK") { viewModel.launchError = nil }
            Button("Open Settings") { viewModel.showingSettings = true }
        } message: {
            Text(viewModel.launchError ?? "")
        }
        .onChange(of: viewModel.searchText) { _, _ in viewModel.applyFilters() }
        .onChange(of: viewModel.selectedPlatform) { _, _ in viewModel.applyFilters() }
        .onChange(of: viewModel.sortOption) { _, _ in viewModel.applyFilters() }
        .onChange(of: viewModel.filterOption) { _, _ in viewModel.applyFilters() }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                hasAppeared = true
            }
            // Attach gamepad controller
            gamepadController.attach(to: viewModel)
            gamepadController.updateColumnCount(columnCount)
        }
        .onChange(of: columnCount) { _, newCount in
            gamepadController.updateColumnCount(newCount)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // Row 1: Logo + Search bar
            HStack(spacing: 16) {
                // Logo/Title with neon glow - responsive layout
                HStack(spacing: 10) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .neonGlow(Theme.neonPink, radius: 12)
                    
                    // Dynamic title - use ResponsiveTitle component
                    ResponsiveTitle(isCompact: isCompactTitle)
                        .neonGlow(Theme.neonPink, radius: 8)
                }
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : -10)
                .animation(.smooth, value: hasAppeared)
                
                // Search with synthwave styling - now fills available space
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Theme.neonCyan)
                    
                    TextField("Search games...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .font(.synthwaveBody(14))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.backgroundTertiary.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.neonCyan.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(12)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : -10)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: hasAppeared)
            }
            
            // Row 2: Filters and toolbar buttons
            HStack(spacing: 12) {
                // Filter options
                Menu {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.filterOption = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if viewModel.filterOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: filterIcon)
                        Text(viewModel.filterOption.rawValue)
                    }
                    .font(.synthwave(12, weight: .medium))
                    .foregroundColor(Theme.neonCyan)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.backgroundTertiary.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.neonCyan.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.15), value: hasAppeared)
                
                // Sort options
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.sortOption = option
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                if viewModel.sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(viewModel.sortOption.rawValue)
                    }
                    .font(.synthwave(12, weight: .medium))
                    .foregroundColor(Theme.neonPurple)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.backgroundTertiary.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Theme.neonPurple.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: hasAppeared)
                
                // Toolbar buttons - grouped for better responsiveness
                HStack(spacing: 6) {
                    // View mode toggle
                    ToolbarIconButton(icon: viewModel.viewMode == .grid ? "list.bullet" : "square.grid.2x2", color: Theme.neonCyan) {
                        withAnimation(.snappy) {
                            viewModel.viewMode = viewModel.viewMode == .grid ? .list : .grid
                        }
                    }
                    .help(viewModel.viewMode == .grid ? "Switch to List View" : "Switch to Grid View")
                    
                    // Random game
                    ToolbarIconButton(icon: "dice", color: Theme.warmAmber) {
                        viewModel.selectRandomGame()
                    }
                    .help("Pick a random game")
                    
                    // Quick launch
                    ToolbarIconButton(icon: "command", color: Theme.neonPink) {
                        viewModel.showingQuickLaunch = true
                    }
                    .help("Quick Launch (⌘K)")
                    
                    // Artwork fetcher
                    ToolbarIconButton(icon: "photo.stack", color: Theme.neonPurple) {
                        viewModel.showingArtworkFetcher = true
                        viewModel.artworkFetcher.startFetching(roms: viewModel.roms)
                    }
                    .help("Fetch artwork for all games")
                    
                    // Refresh
                    ToolbarIconButton(icon: "arrow.clockwise", color: Theme.neonGreen) {
                        Task { await viewModel.scanLibrary() }
                    }
                    .help("Refresh library")
                    
                    // Settings
                    ToolbarIconButton(icon: "gearshape.fill", color: Theme.warmAmber) {
                        viewModel.showingSettings = true
                    }
                    .help("Settings")
                }
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: hasAppeared)
            }
            
            // Platform filter chips
            if !viewModel.platforms.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        PlatformChip(name: "All", isSelected: viewModel.selectedPlatform == nil, color: Theme.neonPink) {
                            withAnimation(.easeOut(duration: 0.2)) {
                                viewModel.selectedPlatform = nil
                            }
                        }
                        
                        ForEach(viewModel.platforms, id: \.self) { platform in
                            PlatformChip(
                                name: platform,
                                isSelected: viewModel.selectedPlatform == platform,
                                color: Theme.platformColor(for: platform)
                            ) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    viewModel.selectedPlatform = platform
                                }
                            }
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 10)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3), value: hasAppeared)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Stats bar
            HStack {
                Text("\(viewModel.filteredRoms.count) games")
                    .font(.synthwave(13, weight: .medium))
                    .foregroundColor(Theme.textTertiary)
                
                // Controller status indicator
                if gamepadController.isControllerConnected {
                    HStack(spacing: 6) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.neonGreen)
                        Text(gamepadController.controllerName)
                            .font(.synthwave(11, weight: .medium))
                            .foregroundColor(Theme.neonGreen)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.neonGreen.opacity(0.15))
                    .cornerRadius(8)
                    .neonGlow(Theme.neonGreen, radius: 4)
                    .transition(.opacity.combined(with: .scale))
                }
                
                Spacer()
                
                // Grid size slider
                HStack(spacing: 8) {
                    Image(systemName: "square.grid.3x3")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTertiary)
                    
                    Slider(value: .init(
                        get: { Double(columnCount) },
                        set: { columnCount = Int($0) }
                    ), in: 3...8, step: 1)
                    .frame(width: 100)
                    .tint(Theme.neonPink)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onChange(of: geometry.size.width) { _, newWidth in
                        withAnimation(.smooth(duration: 0.3)) {
                            isCompactTitle = newWidth < 600
                        }
                    }
                    .onAppear {
                        isCompactTitle = geometry.size.width < 600
                    }
            }
        )
    }
    
    private var filterIcon: String {
        switch viewModel.filterOption {
        case .all: return "square.grid.2x2"
        case .favorites: return "heart.fill"
        case .recentlyPlayed: return "clock.fill"
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            // Animated loading indicator
            ZStack {
                Circle()
                    .stroke(Theme.neonPink.opacity(0.2), lineWidth: 3)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        Theme.synthwaveGradient,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: viewModel.isLoading)
            }
            .neonGlow(Theme.neonPink, radius: 10)
            
            Text("SCANNING LIBRARY...")
                .font(.synthwave(14, weight: .bold))
                .foregroundColor(Theme.textSecondary)
                .tracking(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 64))
                .foregroundStyle(Theme.neonPinkGradient)
                .neonGlow(Theme.neonPink, radius: 15)
            
            VStack(spacing: 8) {
                Text("NO GAMES FOUND")
                    .font(.synthwaveDisplay(22))
                    .foregroundStyle(Theme.synthwaveGradient)
                
                Text("Add ROM directories in Settings to get started")
                    .font(.synthwaveBody(15))
                    .foregroundColor(Theme.textTertiary)
            }
            
            Button {
                viewModel.showingSettings = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                    Text("ADD ROM FOLDER")
                }
                .font(.synthwave(14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Theme.neonPinkGradient)
                .cornerRadius(12)
                .neonGlow(Theme.neonPink, radius: 10)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var libraryGrid: some View {
        ScrollViewReader { proxy in
            ScrollView {
                if viewModel.viewMode == .grid {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(Array(viewModel.filteredRoms.enumerated()), id: \.element.id) { index, rom in
                            GameCardView(
                                rom: rom, 
                                appearDelay: Double(index) * 0.02,
                                isKeyboardSelected: index == viewModel.selectedIndex
                            )
                            .environmentObject(viewModel)
                            .id(rom.id)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))
                            .animation(
                                .spring(response: 0.35, dampingFraction: 0.8)
                                    .delay(Double(index % 12) * 0.03),
                                value: rom.id
                            )
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.filteredRoms.map { $0.id })
                    .padding(.horizontal, 48)
                    .padding(.vertical, 20)
                } else {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(viewModel.filteredRoms.enumerated()), id: \.element.id) { index, rom in
                            ListRowView(
                                rom: rom,
                                isSelected: index == viewModel.selectedIndex
                            )
                            .environmentObject(viewModel)
                            .id(rom.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading)
                                    .combined(with: .opacity)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7).delay(Double(index) * 0.02)),
                                removal: .move(edge: .leading)
                                    .combined(with: .opacity)
                                    .animation(.spring(response: 0.25, dampingFraction: 0.75))
                            ))
                        }
                    }
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.filteredRoms.map { $0.id })
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                }
            }
            .onChange(of: viewModel.selectedIndex) { _, newIndex in
                if newIndex < viewModel.filteredRoms.count {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(viewModel.filteredRoms[newIndex].id, anchor: .center)
                    }
                }
            }
        }
    }
}

// MARK: - Responsive Title

struct ResponsiveTitle: View {
    let isCompact: Bool
    
    var body: some View {
        Group {
            if isCompact {
                // Stacked: GAME above SHELF
                VStack(alignment: .leading, spacing: 0) {
                    Text("GAME")
                        .font(.synthwaveDisplay(14))
                    Text("SHELF")
                        .font(.synthwaveDisplay(14))
                }
            } else {
                // Side by side
                Text("GAME SHELF")
                    .font(.synthwaveDisplay(20))
            }
        }
        .foregroundColor(.white)
        .animation(.smooth(duration: 0.3), value: isCompact)
    }
}

// MARK: - Toolbar Icon Button

struct ToolbarIconButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(color)
                .padding(8)
                .background(Theme.backgroundTertiary.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct PlatformChip: View {
    let name: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.synthwave(12, weight: .semibold))
                .foregroundColor(isSelected ? .white : Theme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Theme.backgroundTertiary.opacity(isHovered ? 0.9 : 0.6)
                        }
                    }
                )
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? color.opacity(0.8) : (isHovered ? color.opacity(0.4) : .clear),
                            lineWidth: 1
                        )
                )
                .clipShape(Capsule())
                .neonGlow(color, radius: 6, isActive: isSelected)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    LibraryView()
        .environmentObject(LibraryViewModel(config: AppConfig()))
        .environmentObject(AppConfig())
        .frame(width: 1200, height: 800)
}
