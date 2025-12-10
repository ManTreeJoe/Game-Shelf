import SwiftUI

struct ContentView: View {
    @EnvironmentObject var config: AppConfig
    @StateObject private var viewModel = LibraryViewModel(config: AppConfig())
    @State private var selectedCollection: GameCollection? = GameCollection.allGames
    @State private var showSidebar = true
    @State private var sidebarWidth: CGFloat = 220
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            // Background
            AnimatedSynthwaveBackground()
                .ignoresSafeArea()
            
            HStack(spacing: 0) {
                // Sidebar
                if showSidebar {
                    SidebarView(selectedCollection: $selectedCollection)
                        .frame(width: sidebarWidth)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
                
                // Divider
                if showSidebar {
                    Rectangle()
                        .fill(Theme.textTertiary.opacity(0.2))
                        .frame(width: 1)
                }
                
                // Main content
                VStack(spacing: 0) {
                    // Toolbar
                    toolbarView
                    
                    // Library
                    LibraryView()
                        .environmentObject(viewModel)
                }
            }
            
            // VHS overlay for that extra retro feel
            VHSOverlay(isActive: false)
                .opacity(0.3)
                .allowsHitTesting(false)
        }
        .environmentObject(viewModel)
        .sheet(isPresented: $showOnboarding) {
            OnboardingView {
                showOnboarding = false
                Task {
                    await viewModel.scanLibrary()
                }
            }
            .environmentObject(config)
        }
        .task {
            // Check for first run - do this fresh each time
            if !config.hasCompletedOnboarding {
                showOnboarding = true
            }
            
            // Initialize viewModel with actual config
            viewModel.updateConfig(config)
            await viewModel.scanLibrary()
        }
        .onChange(of: selectedCollection) { _, newCollection in
            updateFilterForCollection(newCollection)
        }
    }
    
    private var toolbarView: some View {
        HStack {
            // Sidebar toggle
            Button {
                withAnimation(.snappy) {
                    showSidebar.toggle()
                }
            } label: {
                Image(systemName: showSidebar ? "sidebar.left" : "sidebar.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(showSidebar ? Theme.neonCyan : Theme.textSecondary)
                    .padding(8)
                    .background(Theme.backgroundTertiary.opacity(0.5))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .help("Toggle Sidebar")
            
            // Current collection indicator
            if let collection = selectedCollection {
                HStack(spacing: 8) {
                    Image(systemName: collection.icon)
                        .foregroundColor(collection.color)
                        .neonGlow(collection.color, radius: 4)
                    
                    Text(collection.name)
                        .font(.synthwave(14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.leading, 8)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Theme.backgroundSecondary.opacity(0.5))
    }
    
    private func updateFilterForCollection(_ collection: GameCollection?) {
        guard let collection = collection else { return }
        
        switch collection.id {
        case GameCollection.allGames.id:
            viewModel.filterOption = .all
            viewModel.collectionFilter = nil
        case GameCollection.favorites.id:
            viewModel.filterOption = .favorites
            viewModel.collectionFilter = nil
        case GameCollection.recentlyPlayed.id:
            viewModel.filterOption = .recentlyPlayed
            viewModel.collectionFilter = nil
        default:
            viewModel.filterOption = .all
            viewModel.collectionFilter = collection
        }
        
        viewModel.applyFilters()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppConfig())
        .frame(width: 1200, height: 800)
}
