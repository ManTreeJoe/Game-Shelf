import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var config: AppConfig
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .directories
    
    enum SettingsTab: String, CaseIterable {
        case directories = "ROM Directories"
        case emulators = "Emulators"
        case platforms = "Platforms"
        case backup = "Backup & Restore"
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationSplitView {
                List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                    Label {
                        Text(tab.rawValue)
                    } icon: {
                        tabIcon(for: tab)
                    }
                }
                .listStyle(.sidebar)
                .frame(minWidth: 180)
            } detail: {
                switch selectedTab {
                case .directories:
                    DirectoriesSettingsView()
                case .emulators:
                    EmulatorsSettingsView()
                case .platforms:
                    PlatformsSettingsView()
                case .backup:
                    BackupSettingsView()
                }
            }
            
            // Close button
            Button {
                dismiss()
            } label: {
                    Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .symbolRenderingMode(.hierarchical)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            .padding(12)
            .help("Close Settings")
        }
        .frame(minWidth: 700, minHeight: 500)
    }
    
    private func tabIcon(for tab: SettingsTab) -> some View {
        switch tab {
        case .directories:
            return Image(systemName: "folder.fill")
        case .emulators:
            return Image(systemName: "arcade.stick.console.fill")
        case .backup:
            return Image(systemName: "arrow.triangle.2.circlepath")
        case .platforms:
            return Image(systemName: "gamecontroller.fill")
        }
    }
}

// MARK: - Directories Settings

struct DirectoriesSettingsView: View {
    @EnvironmentObject var config: AppConfig
    @State private var isAddingDirectory = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("ROM Directories")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Add folders containing your ROM files. Subfolders will be scanned automatically.")
                    .font(.system(size: 13))
                        .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider()
            
            // Directory list
            if config.romDirectories.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No ROM directories added")
                        .font(.headline)
                    
                    Text("Click the button below to add a folder containing your ROMs")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(config.romDirectories.enumerated()), id: \.offset) { index, directory in
                        DirectoryRow(path: directory) {
                            config.removeRomDirectory(at: index)
                        }
                    }
                }
                .listStyle(.inset)
            }
            
            Divider()
            
            // Add button
            HStack {
                Spacer()
                
                Button {
                    selectDirectory()
                } label: {
                    Label("Add Directory", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .padding(16)
            }
            
            Divider()
            
            // Steam Integration
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Steam Integration")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text("Include your Steam library in the game list")
                    .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                    
                    Spacer()
                    
                    Toggle("", isOn: $config.includeSteamGames)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                
                if config.includeSteamGames {
                    let steamScanner = SteamScanner()
                    HStack(spacing: 8) {
                        if steamScanner.isSteamInstalled {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Steam detected • \(steamScanner.scan().count) games found")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
            } else {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Steam not installed")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading, 36)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
    
    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder containing ROM files"
        
        if panel.runModal() == .OK, let url = panel.url {
            config.addRomDirectory(url.path)
        }
    }
}

struct DirectoryRow: View {
    let path: String
    let onDelete: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
                            Image(systemName: "folder.fill")
                .font(.system(size: 24))
                                .foregroundColor(.accentColor)
                            
            VStack(alignment: .leading, spacing: 2) {
                Text(URL(fileURLWithPath: path).lastPathComponent)
                    .font(.system(size: 14, weight: .medium))
                
                Text(path)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                    .truncationMode(.middle)
                            }
                            
                            Spacer()
                            
            Button {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
            } label: {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                                Image(systemName: "trash")
                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Emulators Settings

struct EmulatorEditItem: Identifiable {
    let id = UUID()
    let index: Int
    let emulator: EmulatorConfig
}

struct EmulatorsSettingsView: View {
    @EnvironmentObject var config: AppConfig
    @State private var showingAddEmulator = false
    @State private var editingEmulator: EmulatorEditItem? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Emulators")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Configure which emulator to use for each file type. Add your own if one isn't listed.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider()
            
            // Emulator list
            if config.emulators.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "arcade.stick.console")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No emulators configured")
                        .font(.headline)
                    
                    Text("Add an emulator to start playing your games")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(config.emulators.enumerated()), id: \.offset) { index, emulator in
                        EmulatorRow(emulator: emulator) {
                            editingEmulator = EmulatorEditItem(index: index, emulator: emulator)
                        } onDelete: {
                            config.removeEmulator(at: index)
                        }
                    }
                }
                .listStyle(.inset)
            }
            
            Divider()
            
            // Add button
            HStack {
                Spacer()
                
                Button {
                    showingAddEmulator = true
                } label: {
                    Label("Add Emulator", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .padding(16)
            }
        }
        .sheet(isPresented: $showingAddEmulator) {
            EmulatorEditorView(mode: .add) { emulator in
                config.addEmulator(emulator)
            }
        }
        .sheet(item: $editingEmulator) { item in
            EmulatorEditorView(mode: .edit(item.emulator)) { emulator in
                config.updateEmulator(emulator, at: item.index)
            }
        }
    }
}

struct EmulatorRow: View {
    let emulator: EmulatorConfig
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    private var hasValidPath: Bool {
        !emulator.path.isEmpty && FileManager.default.fileExists(atPath: emulator.path)
    }
    
    var body: some View {
            HStack(spacing: 12) {
            // Icon
                ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(hasValidPath ? Color.accentColor.opacity(0.15) : Color.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                
                Image(systemName: hasValidPath ? "arcade.stick.console.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                    .foregroundColor(hasValidPath ? .accentColor : .orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(emulator.name)
                    .font(.system(size: 14, weight: .semibold))
                
                // Show platforms first (green badges)
                if !emulator.platforms.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(emulator.platforms.prefix(3), id: \.self) { platform in
                            Text(platform)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                        
                        if emulator.platforms.count > 3 {
                            Text("+\(emulator.platforms.count - 3)")
                                .font(.system(size: 10))
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Show extensions (gray badges)
                if !emulator.extensions.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(emulator.extensions.prefix(4), id: \.self) { ext in
                            Text(ext)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)
                        }
                        
                        if emulator.extensions.count > 4 {
                            Text("+\(emulator.extensions.count - 4)")
                                .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                    }
                }
                
                if !hasValidPath {
                    Text(emulator.path.isEmpty ? "No emulator path set" : "Emulator not found")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            Button {
                onEdit()
            } label: {
                Text("Edit")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.bordered)
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Emulator Editor

enum EmulatorEditorMode {
    case add
    case edit(EmulatorConfig)
}

struct EmulatorEditorView: View {
    let mode: EmulatorEditorMode
    let onSave: (EmulatorConfig) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var path: String = ""
    @State private var extensions: [String] = []
    @State private var platforms: [String] = []
    @State private var newExtension: String = ""
    @State private var arguments: String = "%ROM%"
    @State private var emulatorId: UUID = UUID()
    
    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }
    
    private var isValid: Bool {
        !name.isEmpty && (!extensions.isEmpty || !platforms.isEmpty)
    }
    
    private var existingEmulator: EmulatorConfig? {
        if case .edit(let emulator) = mode {
            return emulator
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditing ? "Edit Emulator" : "Add Emulator")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            
            Divider()
            
            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 13, weight: .medium))
                        
                        TextField("e.g., OpenEmu, Dolphin, PPSSPP", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Path
            VStack(alignment: .leading, spacing: 8) {
                Text("Emulator Application")
                            .font(.system(size: 13, weight: .medium))
                
                HStack {
                            TextField("Select emulator app...", text: $path)
                        .textFieldStyle(.roundedBorder)
                                .disabled(true)
                    
                    Button("Browse...") {
                        selectEmulator()
                    }
                }
                
                        Text("Select the .app file or executable for the emulator")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
                    // Extensions
            VStack(alignment: .leading, spacing: 8) {
                        Text("File Extensions")
                            .font(.system(size: 13, weight: .medium))
                        
                        // Current extensions
                        FlowLayout(spacing: 8) {
                            ForEach(extensions, id: \.self) { ext in
                                HStack(spacing: 4) {
                                    Text(ext)
                    .font(.system(size: 12, weight: .medium))
                                    
                                    Button {
                                        extensions.removeAll { $0 == ext }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundColor(.accentColor)
                                .cornerRadius(6)
                            }
                        }
                        
                        // Add extension
                        HStack {
                            TextField("e.g., .nes, .sfc", text: $newExtension)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    addExtension()
                                }
                            
                            Button("Add") {
                                addExtension()
                            }
                            .disabled(newExtension.isEmpty)
                        }
                        
                        // Quick add extensions from platform
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quick add extensions from platform:")
                                .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(Platform.builtIn, id: \.name) { platform in
                                        Button {
                                            for ext in platform.extensions {
                                                if !extensions.contains(ext) {
                                                    extensions.append(ext)
                                                }
                                            }
                                        } label: {
                                            Text(platform.name)
                                                .font(.system(size: 11, weight: .medium))
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 5)
                                                .background(Color.secondary.opacity(0.15))
                                                .cornerRadius(5)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Platforms (takes priority over extensions)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Platforms (Recommended)")
                            .font(.system(size: 13, weight: .medium))
                        
                        Text("Assign this emulator to specific platforms. This takes priority over file extensions.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        // Selected platforms
                        FlowLayout(spacing: 8) {
                            ForEach(platforms, id: \.self) { platform in
                                HStack(spacing: 4) {
                                    Text(platform)
                                        .font(.system(size: 12, weight: .medium))
                                    
                                    Button {
                                        platforms.removeAll { $0 == platform }
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .cornerRadius(6)
                            }
                        }
                        
                        // Platform picker
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(Platform.builtIn, id: \.name) { platform in
                                    Button {
                                        if !platforms.contains(platform.name) {
                                            platforms.append(platform.name)
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text(platform.name)
                                            if platforms.contains(platform.name) {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 9, weight: .bold))
                                            }
                                        }
                                        .font(.system(size: 11, weight: .medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(platforms.contains(platform.name) ? Color.green.opacity(0.3) : Color.secondary.opacity(0.15))
                                        .foregroundColor(platforms.contains(platform.name) ? .green : .primary)
                                        .cornerRadius(5)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    
                    // Arguments
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Launch Arguments (Advanced)")
                            .font(.system(size: 13, weight: .medium))
                        
                        TextField("%ROM%", text: $arguments)
                    .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13, design: .monospaced))
                
                        Text("Use %ROM% as placeholder for the ROM file path. Most emulators just need %ROM%")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button(isEditing ? "Save Changes" : "Add Emulator") {
                    let emulator = EmulatorConfig(
                        id: existingEmulator?.id ?? UUID(),
                        name: name,
                        path: path,
                        extensions: extensions,
                        platforms: platforms,
                        arguments: arguments.components(separatedBy: " ")
                    )
                    onSave(emulator)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .keyboardShortcut(.return)
            }
            .padding(16)
        }
        .frame(width: 550, height: 750)
        .onAppear {
            if case .edit(let emulator) = mode {
                emulatorId = emulator.id
                name = emulator.name
                path = emulator.path
                extensions = emulator.extensions
                platforms = emulator.platforms
                arguments = emulator.arguments.joined(separator: " ")
            }
        }
    }
    
    private func selectEmulator() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [UTType.application, UTType.unixExecutable]
        panel.message = "Select the emulator application"
        
        if panel.runModal() == .OK, let url = panel.url {
            path = url.path
            
            // Try to auto-fill name from app name
            if name.isEmpty {
                name = url.deletingPathExtension().lastPathComponent
            }
        }
    }
    
    private func addExtension() {
        var ext = newExtension.lowercased().trimmingCharacters(in: .whitespaces)
        if !ext.hasPrefix(".") {
            ext = "." + ext
        }
        
        if !extensions.contains(ext) {
            extensions.append(ext)
        }
        newExtension = ""
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Platforms Settings

struct PlatformsSettingsView: View {
    @EnvironmentObject var config: AppConfig
    @State private var showingAddPlatform = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Platforms")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Built-in platforms are shown below. You can add custom platforms for file types not recognized.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider()
            
            List {
                Section("Built-in Platforms") {
                    ForEach(Platform.builtIn) { platform in
                        PlatformRow(platform: platform, isBuiltIn: true)
                    }
                }
                
                if !config.customPlatforms.isEmpty {
                    Section("Custom Platforms") {
                        ForEach(config.customPlatforms) { platform in
                            PlatformRow(platform: platform, isBuiltIn: false)
                        }
                    }
                }
            }
            .listStyle(.inset)
            
            Divider()
            
            // Add button
            HStack {
                Spacer()
                
                Button {
                    showingAddPlatform = true
                } label: {
                    Label("Add Custom Platform", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .padding(16)
            }
        }
        .sheet(isPresented: $showingAddPlatform) {
            AddPlatformView { platform in
                config.addCustomPlatform(platform)
            }
        }
    }
}

struct PlatformRow: View {
    let platform: Platform
    let isBuiltIn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: platform.color.replacingOccurrences(of: "#", with: "")))
                .frame(width: 12, height: 12)
            
            Text(platform.name)
                .font(.system(size: 14, weight: .medium))
            
            Spacer()
            
            HStack(spacing: 6) {
                ForEach(platform.extensions, id: \.self) { ext in
                    Text(ext)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            
            if isBuiltIn {
                Text("Built-in")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddPlatformView: View {
    let onSave: (Platform) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var extensions: [String] = []
    @State private var newExtension = ""
    @State private var color = "#ff6b9d"
    
    private var isValid: Bool {
        !name.isEmpty && !extensions.isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
            Text("Add Custom Platform")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Platform Name")
                        .font(.system(size: 13, weight: .medium))
                    
                    TextField("e.g., Atari 2600", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("File Extensions")
                        .font(.system(size: 13, weight: .medium))
                    
                    FlowLayout(spacing: 8) {
                        ForEach(extensions, id: \.self) { ext in
                            HStack(spacing: 4) {
                                Text(ext)
                                    .font(.system(size: 12, weight: .medium))
                                
                                Button {
                                    extensions.removeAll { $0 == ext }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .cornerRadius(6)
                        }
                    }
                
                HStack {
                        TextField("e.g., .a26", text: $newExtension)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                addExtension()
                            }
                        
                        Button("Add") {
                            addExtension()
                        }
                        .disabled(newExtension.isEmpty)
                    }
                }
                
                ColorPicker("Platform Color", selection: .init(
                    get: { Color(hex: color.replacingOccurrences(of: "#", with: "")) },
                    set: { _ in } // Simplified - would need proper hex conversion
                ))
            }
            .padding(20)
            
            Spacer()
            
            Divider()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Button("Add Platform") {
                    let platform = Platform(
                        name: name,
                        extensions: extensions,
                        color: color,
                        icon: "gamecontroller"
                    )
                    onSave(platform)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
            }
            .padding(16)
        }
        .frame(width: 400, height: 400)
    }
    
    private func addExtension() {
        var ext = newExtension.lowercased().trimmingCharacters(in: .whitespaces)
        if !ext.hasPrefix(".") {
            ext = "." + ext
        }
        
        if !extensions.contains(ext) {
            extensions.append(ext)
        }
        newExtension = ""
    }
}

// MARK: - Backup Settings

struct BackupSettingsView: View {
    @EnvironmentObject var config: AppConfig
    @State private var showingExportSuccess = false
    @State private var showingImportPicker = false
    @State private var importError: String?
    @State private var showingImportSuccess = false
    @State private var showingMergeChoice = false
    @State private var pendingImportURL: URL?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Export section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Export Settings", systemImage: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Save your ROM directories, emulators, platforms, collections, and favorites to a backup file.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Button {
                        exportSettings()
                    } label: {
                        Label("Export to File", systemImage: "doc.badge.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(16)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
                
                // Import section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Import Settings", systemImage: "square.and.arrow.down")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Restore settings from a previously exported backup file.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Button {
                        showingImportPicker = true
                    } label: {
                        Label("Import from File", systemImage: "doc.badge.arrow.down")
                    }
                    .buttonStyle(.bordered)
                    
                    if let error = importError {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
                .padding(16)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
                
                // Summary section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Current Configuration", systemImage: "info.circle")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                        GridRow {
                            Text("ROM Directories")
                                .foregroundColor(.secondary)
                            Text("\(config.romDirectories.count)")
                                .fontWeight(.medium)
                        }
                        GridRow {
                            Text("Emulators")
                                .foregroundColor(.secondary)
                            Text("\(config.emulators.count)")
                                .fontWeight(.medium)
                        }
                        GridRow {
                            Text("Platforms")
                                .foregroundColor(.secondary)
                            Text("\(config.customPlatforms.count)")
                                .fontWeight(.medium)
                        }
                        GridRow {
                            Text("Collections")
                                .foregroundColor(.secondary)
                            Text("\(config.collections.count)")
                                .fontWeight(.medium)
                        }
                        GridRow {
                            Text("Favorites")
                                .foregroundColor(.secondary)
                            Text("\(config.favorites.count)")
                                .fontWeight(.medium)
                        }
                    }
                    .font(.system(size: 13))
                }
                .padding(16)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding(20)
        }
        .navigationTitle("Backup & Restore")
        .alert("Export Successful", isPresented: $showingExportSuccess) {
            Button("OK") {}
        } message: {
            Text("Your settings have been exported successfully.")
        }
        .alert("Import Successful", isPresented: $showingImportSuccess) {
            Button("OK") {}
        } message: {
            Text("Your settings have been imported successfully.")
        }
        .alert("Import Settings", isPresented: $showingMergeChoice) {
            Button("Replace All") {
                if let url = pendingImportURL {
                    importSettings(from: url, merge: false)
                }
            }
            Button("Merge") {
                if let url = pendingImportURL {
                    importSettings(from: url, merge: true)
                }
            }
            Button("Cancel", role: .cancel) {
                pendingImportURL = nil
            }
        } message: {
            Text("Would you like to replace all settings or merge with existing?")
        }
        .fileImporter(
            isPresented: $showingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    pendingImportURL = url
                    showingMergeChoice = true
                }
            case .failure(let error):
                importError = error.localizedDescription
            }
        }
    }
    
    private func exportSettings() {
        guard let url = config.exportToFile() else {
            importError = "Failed to export settings"
            return
        }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = url.lastPathComponent
        
        savePanel.begin { response in
            if response == .OK, let destinationURL = savePanel.url {
                do {
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                    showingExportSuccess = true
                } catch {
                    importError = error.localizedDescription
                }
            }
        }
    }
    
    private func importSettings(from url: URL, merge: Bool) {
        do {
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            
            if merge {
                try config.importDataMerge(from: url)
            } else {
                try config.importData(from: url)
            }
            showingImportSuccess = true
            importError = nil
        } catch {
            importError = error.localizedDescription
        }
        pendingImportURL = nil
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppConfig())
}
