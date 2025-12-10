import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var viewModel: LibraryViewModel
    @EnvironmentObject var config: AppConfig
    @Binding var selectedCollection: GameCollection?
    @State private var showingNewCollection = false
    @State private var showingNewSmartCollection = false
    @State private var editingCollection: GameCollection? = nil
    @State private var isHoveringNewButton = false
    @State private var isHoveringSmartButton = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("LIBRARY")
                    .font(.synthwave(11, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                    .tracking(2)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // System collections
            VStack(spacing: 2) {
                ForEach(GameCollection.systemCollections) { collection in
                    CollectionRow(
                        collection: collection,
                        isSelected: selectedCollection?.id == collection.id,
                        gameCount: gameCount(for: collection)
                    ) {
                        withAnimation(.snappy) {
                            selectedCollection = collection
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            
            // Divider
            Rectangle()
                .fill(Theme.textTertiary.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            // Custom collections header
            HStack {
                Text("COLLECTIONS")
                    .font(.synthwave(11, weight: .bold))
                    .foregroundColor(Theme.textTertiary)
                    .tracking(2)
                
                Spacer()
                
                // Smart collection button
                Button {
                    showingNewSmartCollection = true
                } label: {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 14))
                        .foregroundColor(isHoveringSmartButton ? Theme.neonPurple : Theme.textTertiary)
                        .neonGlow(Theme.neonPurple, radius: 6, isActive: isHoveringSmartButton)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.quick) {
                        isHoveringSmartButton = hovering
                    }
                }
                .help("Create Smart Collection")
                
                Button {
                    showingNewCollection = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isHoveringNewButton ? Theme.neonPink : Theme.textTertiary)
                        .neonGlow(Theme.neonPink, radius: 6, isActive: isHoveringNewButton)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.quick) {
                        isHoveringNewButton = hovering
                    }
                }
                .help("Create Collection")
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // Custom collections list
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(config.collections) { collection in
                        CollectionRow(
                            collection: collection,
                            isSelected: selectedCollection?.id == collection.id,
                            gameCount: collection.gameCount
                        ) {
                            withAnimation(.snappy) {
                                selectedCollection = collection
                            }
                        }
                        .contextMenu {
                            Button {
                                editingCollection = collection
                            } label: {
                                Label("Edit Collection", systemImage: "pencil")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                config.removeCollection(collection.id)
                            } label: {
                                Label("Delete Collection", systemImage: "trash")
                            }
                        }
                    }
                    
                    if config.collections.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 24))
                                .foregroundColor(Theme.textTertiary)
                            
                            Text("No collections yet")
                                .font(.synthwave(12))
                                .foregroundColor(Theme.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 8)
            }
            
            Spacer()
            
            // Stats at bottom
            VStack(spacing: 4) {
                Rectangle()
                    .fill(Theme.textTertiary.opacity(0.2))
                    .frame(height: 1)
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.roms.count)")
                            .font(.synthwave(18, weight: .bold))
                            .foregroundStyle(Theme.neonPinkGradient)
                        
                        Text("Total Games")
                            .font(.synthwave(10))
                            .foregroundColor(Theme.textTertiary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(viewModel.platforms.count)")
                            .font(.synthwave(18, weight: .bold))
                            .foregroundStyle(Theme.neonCyanGradient)
                        
                        Text("Platforms")
                            .font(.synthwave(10))
                            .foregroundColor(Theme.textTertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(Theme.backgroundSecondary)
        .sheet(isPresented: $showingNewCollection) {
            CollectionEditorView(mode: .create) { collection in
                config.addCollection(collection)
            }
        }
        .sheet(isPresented: $showingNewSmartCollection) {
            SmartCollectionEditorView(onSave: { collection in
                config.addCollection(collection)
            })
        }
        .sheet(item: $editingCollection) { collection in
            if collection.isSmart {
                SmartCollectionEditorView(onSave: { updatedCollection in
                    config.updateCollection(updatedCollection)
                }, editingCollection: collection)
            } else {
                CollectionEditorView(mode: .edit(collection)) { updatedCollection in
                    config.updateCollection(updatedCollection)
                }
            }
        }
    }
    
    private func gameCount(for collection: GameCollection) -> Int {
        switch collection.id {
        case GameCollection.allGames.id:
            return viewModel.roms.count
        case GameCollection.favorites.id:
            return config.favorites.count
        case GameCollection.recentlyPlayed.id:
            return min(config.recentlyPlayed.count, 20)
        default:
            if collection.isSmart {
                // Count matching games for smart collections
                return viewModel.roms.filter { rom in
                    let stats = SessionTracker.shared.getStats(for: rom)
                    return collection.matchesSmartRules(rom, stats: stats)
                }.count
            }
            return collection.gameCount
        }
    }
}

// MARK: - Collection Row

struct CollectionRow: View {
    let collection: GameCollection
    let isSelected: Bool
    let gameCount: Int
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Icon
                Image(systemName: collection.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : collection.color)
                    .frame(width: 20)
                    .neonGlow(collection.color, radius: 4, isActive: isSelected)
                
                // Name
                Text(collection.name)
                    .font(.synthwaveBody(13))
                    .foregroundColor(isSelected ? .white : Theme.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                // Count badge
                Text("\(gameCount)")
                    .font(.synthwave(11, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : Theme.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        isSelected ? Color.white.opacity(0.2) : Theme.backgroundTertiary
                    )
                    .cornerRadius(10)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [collection.color, collection.color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else if isHovered {
                        Theme.backgroundTertiary.opacity(0.5)
                    } else {
                        Color.clear
                    }
                }
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? collection.color.opacity(0.5) : .clear, lineWidth: 1)
            )
            .neonGlow(collection.color, radius: 8, isActive: isSelected)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.quick) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Drop Delegate for Drag and Drop

struct CollectionDropDelegate: DropDelegate {
    let collection: GameCollection
    let config: AppConfig
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.fileURL]).first else {
            return false
        }
        
        itemProvider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            DispatchQueue.main.async {
                config.addRomToCollection(url.path, collectionId: collection.id)
            }
        }
        
        return true
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.fileURL])
    }
}

#Preview {
    HStack(spacing: 0) {
        SidebarView(selectedCollection: .constant(GameCollection.allGames))
            .environmentObject(LibraryViewModel(config: AppConfig()))
            .environmentObject(AppConfig())
            .frame(width: 220)
        
        Color.black
    }
    .frame(width: 600, height: 500)
}

