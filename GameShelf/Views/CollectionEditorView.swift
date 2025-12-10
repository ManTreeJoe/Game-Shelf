import SwiftUI

enum CollectionEditorMode {
    case create
    case edit(GameCollection)
}

struct CollectionEditorView: View {
    let mode: CollectionEditorMode
    let onSave: (GameCollection) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedIcon: String = "folder.fill"
    @State private var selectedColor: String = "ff2a6d"
    @State private var isHoveringIcon: String? = nil
    
    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var existingCollection: GameCollection? {
        if case .edit(let collection) = mode {
            return collection
        }
        return nil
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                // Preview
                ZStack {
                    Circle()
                        .fill(Color(hex: selectedColor).opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: selectedIcon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(Color(hex: selectedColor))
                        .neonGlow(Color(hex: selectedColor), radius: 8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isEditing ? "Edit Collection" : "New Collection")
                        .font(.synthwaveDisplay(18))
                        .foregroundColor(.white)
                    
                    Text(name.isEmpty ? "Enter a name..." : name)
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
                .background(Theme.textTertiary.opacity(0.3))
            
            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NAME")
                            .font(.synthwave(11, weight: .bold))
                            .foregroundColor(Theme.textTertiary)
                            .tracking(2)
                        
                        TextField("Collection name", text: $name)
                            .textFieldStyle(.plain)
                            .font(.synthwaveBody(16))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Theme.backgroundTertiary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Theme.neonPink.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                    
                    // Color picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("COLOR")
                            .font(.synthwave(11, weight: .bold))
                            .foregroundColor(Theme.textTertiary)
                            .tracking(2)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                            ForEach(CollectionIcons.colors, id: \.self) { colorHex in
                                Button {
                                    withAnimation(.snappy) {
                                        selectedColor = colorHex
                                    }
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: colorHex))
                                            .frame(width: 36, height: 36)
                                        
                                        if selectedColor == colorHex {
                                            Circle()
                                                .stroke(.white, lineWidth: 3)
                                                .frame(width: 36, height: 36)
                                            
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .neonGlow(Color(hex: colorHex), radius: 8, isActive: selectedColor == colorHex)
                                }
                                .buttonStyle(.plain)
                                .scaleEffect(selectedColor == colorHex ? 1.1 : 1.0)
                                .animation(.snappy, value: selectedColor)
                            }
                        }
                    }
                    
                    // Icon picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ICON")
                            .font(.synthwave(11, weight: .bold))
                            .foregroundColor(Theme.textTertiary)
                            .tracking(2)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                            ForEach(CollectionIcons.all, id: \.self) { icon in
                                Button {
                                    withAnimation(.snappy) {
                                        selectedIcon = icon
                                    }
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.3) : Theme.backgroundTertiary)
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: icon)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(
                                                selectedIcon == icon ? Color(hex: selectedColor) :
                                                    (isHoveringIcon == icon ? Color(hex: selectedColor) : Theme.textSecondary)
                                            )
                                    }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                selectedIcon == icon ? Color(hex: selectedColor) : .clear,
                                                lineWidth: 2
                                            )
                                    )
                                    .neonGlow(Color(hex: selectedColor), radius: 6, isActive: selectedIcon == icon)
                                }
                                .buttonStyle(.plain)
                                .scaleEffect(selectedIcon == icon ? 1.1 : (isHoveringIcon == icon ? 1.05 : 1.0))
                                .animation(.snappy, value: selectedIcon)
                                .onHover { hovering in
                                    isHoveringIcon = hovering ? icon : nil
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            
            Divider()
                .background(Theme.textTertiary.opacity(0.3))
            
            // Actions
            HStack {
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.synthwave(14, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Theme.backgroundTertiary)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button {
                    let collection = GameCollection(
                        id: existingCollection?.id ?? UUID(),
                        name: name.trimmingCharacters(in: .whitespaces),
                        icon: selectedIcon,
                        colorHex: selectedColor,
                        romPaths: existingCollection?.romPaths ?? [],
                        isSystem: false,
                        sortOrder: existingCollection?.sortOrder ?? 999
                    )
                    onSave(collection)
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isEditing ? "checkmark" : "plus")
                        Text(isEditing ? "Save Changes" : "Create Collection")
                    }
                    .font(.synthwave(14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        isValid ? Theme.neonPinkGradient : LinearGradient(colors: [Theme.textTertiary], startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(8)
                    .neonGlow(Theme.neonPink, radius: 8, isActive: isValid)
                }
                .buttonStyle(.plain)
                .disabled(!isValid)
                .keyboardShortcut(.return)
            }
            .padding(16)
            .background(Theme.backgroundSecondary)
        }
        .frame(width: 450, height: 550)
        .background(Theme.background)
        .onAppear {
            if let collection = existingCollection {
                name = collection.name
                selectedIcon = collection.icon
                selectedColor = collection.colorHex
            }
        }
    }
}

#Preview("Create") {
    CollectionEditorView(mode: .create) { _ in }
}

#Preview("Edit") {
    let collection = GameCollection(
        name: "RPGs",
        icon: "wand.and.stars",
        colorHex: "7b2cbf"
    )
    
    return CollectionEditorView(mode: .edit(collection)) { _ in }
}

