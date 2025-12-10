import SwiftUI

struct QuickLaunchView: View {
    @EnvironmentObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedIndex = 0
    @FocusState private var isSearchFocused: Bool
    
    private var filteredResults: [ROM] {
        if searchText.isEmpty {
            return Array(viewModel.roms.prefix(10))
        }
        return viewModel.roms.filter { rom in
            rom.name.localizedCaseInsensitiveContains(searchText) ||
            rom.platform.localizedCaseInsensitiveContains(searchText)
        }.prefix(10).map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.neonCyan)
                
                TextField("Search games...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .focused($isSearchFocused)
                    .onSubmit {
                        launchSelected()
                    }
                
                Text("⌘K")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.backgroundTertiary)
                    .cornerRadius(4)
            }
            .padding(20)
            .background(Theme.backgroundSecondary)
            
            Divider()
                .background(Theme.textTertiary.opacity(0.3))
            
            // Results
            if filteredResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.textTertiary)
                    
                    Text("No games found")
                        .font(.synthwave(14))
                        .foregroundColor(Theme.textTertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(Array(filteredResults.enumerated()), id: \.element.id) { index, rom in
                                QuickLaunchRow(
                                    rom: rom,
                                    isSelected: index == selectedIndex
                                ) {
                                    viewModel.launchROM(rom)
                                    dismiss()
                                }
                                .id(index)
                            }
                        }
                        .padding(8)
                    }
                    .onChange(of: selectedIndex) { _, newValue in
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
            }
            
            Divider()
                .background(Theme.textTertiary.opacity(0.3))
            
            // Hints
            HStack(spacing: 20) {
                KeyHint(keys: ["↑", "↓"], action: "Navigate")
                KeyHint(keys: ["↵"], action: "Launch")
                KeyHint(keys: ["esc"], action: "Close")
            }
            .padding(12)
            .background(Theme.backgroundSecondary)
        }
        .frame(width: 500, height: 400)
        .background(Theme.background)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.neonCyan.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 30)
        .onAppear {
            isSearchFocused = true
            selectedIndex = 0
        }
        .onChange(of: searchText) { _, _ in
            selectedIndex = 0
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedIndex < filteredResults.count - 1 {
                selectedIndex += 1
            }
            return .handled
        }
        .onKeyPress(.escape) {
            dismiss()
            return .handled
        }
        .onKeyPress(.return) {
            launchSelected()
            return .handled
        }
    }
    
    private func launchSelected() {
        guard selectedIndex < filteredResults.count else { return }
        viewModel.launchROM(filteredResults[selectedIndex])
        dismiss()
    }
}

struct QuickLaunchRow: View {
    let rom: ROM
    let isSelected: Bool
    let onLaunch: () -> Void
    
    var body: some View {
        Button(action: onLaunch) {
            HStack(spacing: 12) {
                // Platform color indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.platformColor(for: rom.platform))
                    .frame(width: 4, height: 32)
                
                // Game info
                VStack(alignment: .leading, spacing: 2) {
                    Text(rom.displayName)
                        .font(.synthwaveBody(14))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(rom.platform)
                        .font(.synthwave(11))
                        .foregroundColor(Theme.platformColor(for: rom.platform))
                }
                
                Spacer()
                
                // File extension
                Text(rom.fileExtension)
                    .font(.synthwave(10, weight: .medium))
                    .foregroundColor(Theme.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.backgroundTertiary)
                    .cornerRadius(4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Theme.neonCyan.opacity(0.15) : .clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Theme.neonCyan.opacity(0.5) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct KeyHint: View {
    let keys: [String]
    let action: String
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Theme.backgroundTertiary)
                    .cornerRadius(4)
            }
            
            Text(action)
                .font(.synthwave(10))
                .foregroundColor(Theme.textTertiary)
        }
    }
}

#Preview {
    ZStack {
        Theme.background
        QuickLaunchView()
            .environmentObject(LibraryViewModel(config: AppConfig()))
    }
}

