import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var config: AppConfig
    @State private var currentStep = 0
    @State private var selectedPlatforms: Set<String> = []
    @StateObject private var downloadManager = EmulatorDownloadManager.shared
    let onComplete: () -> Void
    
    private let steps = ["Welcome", "Platforms", "Setup", "ROM Folders", "Ready"]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "0a0a0f"),
                    Color(hex: "1a0a20"),
                    Color(hex: "0a0a0f")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with progress and skip
                HStack {
                    // Progress indicator
                    HStack(spacing: 8) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Capsule()
                                .fill(index <= currentStep ? Theme.neonCyan : Theme.textTertiary.opacity(0.3))
                                .frame(height: 4)
                                .animation(.snappy, value: currentStep)
                        }
                    }
                    
                    Spacer()
                    
                    // Skip button
                    Button {
                        config.hasCompletedOnboarding = true
                        onComplete()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 20)
                }
                .padding(.horizontal, 40)
                .padding(.top, 30)
                
                // Content
                TabView(selection: $currentStep) {
                    WelcomeStep()
                        .tag(0)
                    
                    PlatformSelectionStep(selectedPlatforms: $selectedPlatforms)
                        .tag(1)
                    
                    EmulatorSetupStep(selectedPlatforms: selectedPlatforms)
                        .environmentObject(downloadManager)
                        .tag(2)
                    
                    RomFoldersStep()
                        .tag(3)
                    
                    ReadyStep()
                        .tag(4)
                }
                .animation(.snappy, value: currentStep)
                
                // Navigation
                HStack {
                    if currentStep > 0 {
                        Button {
                            withAnimation { currentStep -= 1 }
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(Theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    if currentStep < steps.count - 1 {
                        Button {
                            withAnimation { currentStep += 1 }
                        } label: {
                            Label("Continue", systemImage: "chevron.right")
                                .labelStyle(.trailingIcon)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.neonCyan)
                    } else {
                        Button {
                            config.hasCompletedOnboarding = true
                            onComplete()
                        } label: {
                            Label("Get Started", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.neonPink)
                    }
                }
                .padding(30)
            }
        }
        .frame(minWidth: 800, idealWidth: 900, minHeight: 600, idealHeight: 700)
    }
}

// MARK: - Step Views

struct WelcomeStep: View {
    @State private var hasAppeared = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.synthwaveGradient)
                .neonGlow(Theme.neonPink, radius: 20)
                .scaleEffect(hasAppeared ? 1 : 0.5)
                .opacity(hasAppeared ? 1 : 0)
            
            VStack(spacing: 12) {
                Text("Welcome to Game Shelf")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Theme.synthwaveGradient)
                
                Text("Your retro game library, beautifully organized.")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textSecondary)
            }
            .offset(y: hasAppeared ? 0 : 20)
            .opacity(hasAppeared ? 1 : 0)
            
            Spacer()
            
            // Feature highlights
            HStack(spacing: 40) {
                FeatureCard(icon: "folder.fill", title: "Organize", description: "Scan your ROM folders")
                FeatureCard(icon: "photo.fill", title: "Artwork", description: "Auto-fetch cover art")
                FeatureCard(icon: "play.fill", title: "Launch", description: "Play with any emulator")
            }
            .opacity(hasAppeared ? 1 : 0)
            .animation(.easeOut.delay(0.3), value: hasAppeared)
            
            Spacer()
        }
        .padding(40)
        .onAppear {
            withAnimation(.smooth) {
                hasAppeared = true
            }
        }
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(Theme.neonCyan)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .frame(width: 140)
        .padding(16)
        .background(Theme.backgroundSecondary.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Platform Selection Step

struct PlatformSelectionStep: View {
    @Binding var selectedPlatforms: Set<String>
    
    // All available platforms grouped by type
    private let platformGroups: [(name: String, platforms: [(id: String, name: String, icon: String)])] = [
        ("Nintendo", [
            ("NES", "NES", "rectangle.fill"),
            ("SNES", "SNES", "rectangle.fill"),
            ("Nintendo 64", "Nintendo 64", "rectangle.fill"),
            ("Game Boy", "Game Boy", "rectangle.portrait.fill"),
            ("Game Boy Color", "Game Boy Color", "rectangle.portrait.fill"),
            ("Game Boy Advance", "Game Boy Advance", "rectangle.portrait.fill"),
            ("Nintendo DS", "Nintendo DS", "rectangle.portrait.fill"),
            ("GameCube", "GameCube", "opticaldisc.fill"),
            ("Wii", "Wii", "opticaldisc.fill"),
        ]),
        ("Sony", [
            ("PlayStation", "PlayStation", "opticaldisc.fill"),
            ("PlayStation 2", "PlayStation 2", "opticaldisc.fill"),
            ("PSP", "PSP", "rectangle.portrait.fill"),
        ]),
        ("Sega", [
            ("Sega Genesis", "Sega Genesis", "rectangle.fill"),
            ("Sega Master System", "Sega Master System", "rectangle.fill"),
            ("Dreamcast", "Dreamcast", "opticaldisc.fill"),
        ]),
        ("Arcade", [
            ("Arcade", "Arcade", "arcade.stick.console.fill"),
        ]),
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.synthwaveGradient)
                
                Text("What Do You Want to Play?")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Select the platforms you have games for. We'll set up the best emulators automatically.")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 500)
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(platformGroups, id: \.name) { group in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(group.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.textTertiary)
                                .padding(.leading, 4)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 10) {
                                ForEach(group.platforms, id: \.id) { platform in
                                    PlatformToggle(
                                        name: platform.name,
                                        icon: platform.icon,
                                        isSelected: selectedPlatforms.contains(platform.id)
                                    ) {
                                        if selectedPlatforms.contains(platform.id) {
                                            selectedPlatforms.remove(platform.id)
                                        } else {
                                            selectedPlatforms.insert(platform.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
            
            HStack {
                Button("Select All") {
                    for group in platformGroups {
                        for platform in group.platforms {
                            selectedPlatforms.insert(platform.id)
                        }
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.neonCyan)
                
                Text("•")
                    .foregroundColor(Theme.textTertiary)
                
                Button("Clear All") {
                    selectedPlatforms.removeAll()
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.textTertiary)
            }
            .font(.system(size: 12))
            
            Text("\(selectedPlatforms.count) platforms selected")
                .font(.system(size: 12))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.vertical, 20)
    }
}

struct PlatformToggle: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Theme.neonCyan : Theme.textTertiary)
                
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : Theme.textSecondary)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Theme.neonCyan.opacity(0.15) : Theme.backgroundTertiary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Theme.neonCyan.opacity(0.5) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Emulator Setup Step

struct EmulatorSetupStep: View {
    let selectedPlatforms: Set<String>
    @EnvironmentObject var config: AppConfig
    @EnvironmentObject var downloadManager: EmulatorDownloadManager
    @State private var setupComplete = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var installedEmulators: Set<String> = []
    
    // Get required emulators for selected platforms
    private var requiredEmulators: [EmulatorInfo] {
        EmulatorDownloadManager.requiredEmulators(for: selectedPlatforms)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.neonGreen)
                
                Text("Emulator Setup")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Based on your selections, here's what you need:")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
            }
            
            if selectedPlatforms.isEmpty {
                Text("Go back and select some platforms first!")
                    .foregroundColor(Theme.warmAmber)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(requiredEmulators) { emulator in
                            EmulatorCard(
                                emulator: emulator,
                                isInstalled: emulator.isInstalled,
                                isDownloading: downloadManager.isDownloading && downloadManager.currentEmulator == emulator.name,
                                downloadProgress: downloadManager.downloadProgress,
                                statusMessage: downloadManager.statusMessage
                            ) {
                                Task {
                                    do {
                                        try await downloadManager.downloadAndInstall(emulator)
                                    } catch EmulatorDownloadManager.DownloadError.manualDownloadRequired(_) {
                                        // This opens the download page, not really an error
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        showingError = true
                                    }
                                }
                            } onOpenPage: {
                                downloadManager.openDownloadPage(for: emulator)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                // Install all button
                if !downloadManager.isDownloading {
                    let missingEmulators = requiredEmulators.filter { !$0.isInstalled }
                    if !missingEmulators.isEmpty {
                        Button {
                            Task { await installAllMissing() }
                        } label: {
                            Label("Install All Missing Emulators", systemImage: "arrow.down.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.neonGreen)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(Theme.neonGreen)
                            Text("All required emulators are installed!")
                                .foregroundColor(Theme.neonGreen)
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        ProgressView(value: downloadManager.downloadProgress)
                            .progressViewStyle(.linear)
                            .frame(maxWidth: 300)
                        
                        Text(downloadManager.statusMessage)
                            .font(.system(size: 12))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .alert("Download Error", isPresented: $showingError) {
            Button("OK") { showingError = false }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .onAppear {
            // Configure callback to auto-configure emulators when installed
            downloadManager.onEmulatorInstalled = { emulator in
                EmulatorDownloadManager.configureEmulator(emulator, in: config)
                installedEmulators.insert(emulator.id)
            }
            
            // Also configure any already-installed emulators
            EmulatorDownloadManager.configureAllInstalled(in: config)
        }
    }
    
    private func installAllMissing() async {
        for emulator in requiredEmulators where !emulator.isInstalled {
            do {
                try await downloadManager.downloadAndInstall(emulator)
            } catch EmulatorDownloadManager.DownloadError.manualDownloadRequired(_) {
                // Skip - page was opened
                continue
            } catch {
                errorMessage = "Failed to install \(emulator.name): \(error.localizedDescription)"
                showingError = true
                break
            }
        }
    }
}

struct EmulatorCard: View {
    let emulator: EmulatorInfo
    let isInstalled: Bool
    let isDownloading: Bool
    let downloadProgress: Double
    let statusMessage: String
    let onDownload: () -> Void
    let onOpenPage: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(isInstalled ? Theme.neonGreen.opacity(0.15) : Theme.neonCyan.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: isInstalled ? "checkmark.circle.fill" : "arrow.down.circle")
                    .font(.system(size: 24))
                    .foregroundColor(isInstalled ? Theme.neonGreen : Theme.neonCyan)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(emulator.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if isInstalled {
                        Text("Installed")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.neonGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Theme.neonGreen.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                
                Text(emulator.description)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textTertiary)
                
                Text(emulator.platforms.joined(separator: " • "))
                    .font(.system(size: 11))
                    .foregroundColor(Theme.neonCyan.opacity(0.8))
                    .lineLimit(2)
            }
            
            Spacer()
            
            if !isInstalled {
                VStack(spacing: 6) {
                    if isDownloading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button {
                            onDownload()
                        } label: {
                            Text("Install")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.neonCyan)
                        
                        Button {
                            onOpenPage()
                        } label: {
                            Text("Manual")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(Theme.textTertiary)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.backgroundSecondary)
        .cornerRadius(12)
    }
}

struct RomFoldersStep: View {
    @EnvironmentObject var config: AppConfig
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "folder.fill.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(Theme.neonCyan)
                
                Text("Add Your ROM Folders")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Where are your game ROMs stored?")
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
            }
            
            // Current folders
            VStack(spacing: 8) {
                ForEach(config.romDirectories, id: \.self) { dir in
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(Theme.neonCyan)
                        
                        Text(dir)
                            .font(.system(size: 13))
                            .lineLimit(1)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button {
                            config.removeRomDirectory(dir)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(Theme.backgroundTertiary)
                    .cornerRadius(8)
                }
                
                if config.romDirectories.isEmpty {
                    Text("No folders added yet")
                        .font(.system(size: 13))
                        .foregroundColor(Theme.textTertiary)
                        .padding(.vertical, 20)
                }
            }
            .frame(maxWidth: 500)
            
            Button {
                selectFolder()
            } label: {
                Label("Add Folder", systemImage: "plus")
            }
            .buttonStyle(.bordered)
            
            Text("You can add more folders later in Settings")
                .font(.system(size: 12))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(40)
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder containing ROMs"
        
        if panel.runModal() == .OK, let url = panel.url {
            config.addRomDirectory(url.path)
        }
    }
}


struct ReadyStep: View {
    @State private var hasAppeared = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Theme.neonGreen)
                .neonGlow(Theme.neonGreen, radius: 20)
                .scaleEffect(hasAppeared ? 1 : 0.5)
                .opacity(hasAppeared ? 1 : 0)
            
            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Theme.synthwaveGradient)
                
                Text("Your game library is ready to explore.")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.textSecondary)
            }
            .offset(y: hasAppeared ? 0 : 20)
            .opacity(hasAppeared ? 1 : 0)
            
            Spacer()
            
            VStack(spacing: 16) {
                TipCard(icon: "magnifyingglass", tip: "Press ⌘K for quick search")
                TipCard(icon: "arrow.left.and.right", tip: "Use arrow keys to navigate")
                TipCard(icon: "return", tip: "Press Enter to launch a game")
            }
            .opacity(hasAppeared ? 1 : 0)
            .animation(.easeOut.delay(0.3), value: hasAppeared)
            
            Spacer()
        }
        .padding(40)
        .onAppear {
            withAnimation(.smooth) {
                hasAppeared = true
            }
        }
    }
}

struct TipCard: View {
    let icon: String
    let tip: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(Theme.neonCyan)
                .frame(width: 24)
            
            Text(tip)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Theme.backgroundSecondary.opacity(0.5))
        .cornerRadius(8)
    }
}

struct LabelStyle_TrailingIcon: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.title
            configuration.icon
        }
    }
}

extension LabelStyle where Self == LabelStyle_TrailingIcon {
    static var trailingIcon: Self { .init() }
}

#Preview {
    OnboardingView {}
        .environmentObject(AppConfig())
}
