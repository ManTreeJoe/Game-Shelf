import SwiftUI

struct SmartCollectionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var icon: String = "wand.and.stars"
    @State private var colorHex: String = "7b2cbf"
    @State private var rules: [SmartCollectionRule] = []
    @State private var matchAll: Bool = true
    
    // For adding new rules
    @State private var showingRuleSheet = false
    @State private var selectedRuleType: RuleType = .platform
    @State private var ruleParameter: String = ""
    @State private var ruleNumberParameter: Double = 1
    
    let onSave: (GameCollection) -> Void
    var editingCollection: GameCollection?
    
    enum RuleType: String, CaseIterable {
        case platform = "Platform"
        case unplayed = "Never Played"
        case playedMoreThan = "Played More Than"
        case addedRecently = "Added Recently"
        case playedRecently = "Played Recently"
        case nameContains = "Name Contains"
        
        var requiresInput: Bool {
            switch self {
            case .unplayed: return false
            default: return true
            }
        }
        
        var inputType: InputType {
            switch self {
            case .platform, .nameContains: return .text
            case .playedMoreThan: return .hours
            case .addedRecently, .playedRecently: return .days
            case .unplayed: return .none
            }
        }
        
        enum InputType {
            case text, hours, days, none
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(editingCollection == nil ? "Create Smart Collection" : "Edit Smart Collection")
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Name & Icon
                    HStack(spacing: 16) {
                        // Icon picker
                        Menu {
                            ForEach(CollectionIcons.all, id: \.self) { iconName in
                                Button {
                                    icon = iconName
                                } label: {
                                    Label(iconName, systemImage: iconName)
                                }
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: colorHex).opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: colorHex))
                            }
                        }
                        .buttonStyle(.plain)
                        
                        TextField("Collection Name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 16))
                    }
                    
                    // Color picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.system(size: 13, weight: .medium))
                        
                        HStack(spacing: 8) {
                            ForEach(CollectionIcons.colors, id: \.self) { hex in
                                Button {
                                    colorHex = hex
                                } label: {
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(.white, lineWidth: colorHex == hex ? 3 : 0)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Rules
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Rules")
                                .font(.system(size: 13, weight: .medium))
                            
                            Spacer()
                            
                            Picker("", selection: $matchAll) {
                                Text("Match All").tag(true)
                                Text("Match Any").tag(false)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 200)
                        }
                        
                        // Current rules
                        ForEach(Array(rules.enumerated()), id: \.offset) { index, rule in
                            HStack {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.secondary)
                                
                                Text(rule.displayName)
                                    .font(.system(size: 13))
                                
                                Spacer()
                                
                                Button {
                                    rules.remove(at: index)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(10)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if rules.isEmpty {
                            Text("No rules added. Add at least one rule.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 8)
                        }
                        
                        // Add rule button
                        Button {
                            showingRuleSheet = true
                        } label: {
                            Label("Add Rule", systemImage: "plus.circle.fill")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Divider()
                    
                    // Preset smart collections
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Presets")
                            .font(.system(size: 13, weight: .medium))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                PresetButton(title: "Unplayed", icon: "questionmark.circle") {
                                    name = "Unplayed"
                                    icon = "questionmark.circle.fill"
                                    rules = [.unplayed]
                                }
                                
                                PresetButton(title: "Added This Week", icon: "calendar") {
                                    name = "Added This Week"
                                    icon = "calendar"
                                    rules = [.addedInLast(days: 7)]
                                }
                                
                                PresetButton(title: "Long Sessions", icon: "clock") {
                                    name = "Long Sessions"
                                    icon = "clock.fill"
                                    rules = [.playedMoreThan(hours: 10)]
                                }
                                
                                ForEach(Platform.builtIn.prefix(5), id: \.name) { platform in
                                    PresetButton(title: platform.name, icon: "gamecontroller") {
                                        name = platform.name
                                        icon = "gamecontroller.fill"
                                        colorHex = platform.color.replacingOccurrences(of: "#", with: "")
                                        rules = [.platform(platform.name)]
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            // Footer
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Save") {
                    let collection = GameCollection(
                        id: editingCollection?.id ?? UUID(),
                        name: name,
                        icon: icon,
                        colorHex: colorHex,
                        romPaths: [],
                        isSystem: false,
                        sortOrder: 100,
                        isSmart: true,
                        smartRules: rules,
                        smartRulesMatchAll: matchAll
                    )
                    onSave(collection)
                    dismiss()
                }
                .keyboardShortcut(.return)
                .disabled(name.isEmpty || rules.isEmpty)
            }
            .padding(20)
        }
        .frame(width: 550, height: 600)
        .sheet(isPresented: $showingRuleSheet) {
            AddRuleSheet(
                ruleType: $selectedRuleType,
                parameter: $ruleParameter,
                numberParameter: $ruleNumberParameter
            ) { newRule in
                rules.append(newRule)
            }
        }
        .onAppear {
            if let collection = editingCollection {
                name = collection.name
                icon = collection.icon
                colorHex = collection.colorHex
                rules = collection.smartRules
                matchAll = collection.smartRulesMatchAll
            }
        }
    }
}

struct PresetButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.15))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

struct AddRuleSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var ruleType: SmartCollectionEditorView.RuleType
    @Binding var parameter: String
    @Binding var numberParameter: Double
    let onAdd: (SmartCollectionRule) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Rule")
                .font(.headline)
            
            Picker("Rule Type", selection: $ruleType) {
                ForEach(SmartCollectionEditorView.RuleType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.menu)
            
            switch ruleType.inputType {
            case .text:
                if ruleType == .platform {
                    Picker("Platform", selection: $parameter) {
                        ForEach(Platform.builtIn, id: \.name) { platform in
                            Text(platform.name).tag(platform.name)
                        }
                    }
                    .onAppear {
                        if parameter.isEmpty {
                            parameter = Platform.builtIn.first?.name ?? ""
                        }
                    }
                } else {
                    TextField("Value", text: $parameter)
                        .textFieldStyle(.roundedBorder)
                }
            case .hours:
                HStack {
                    Text("Hours:")
                    TextField("", value: $numberParameter, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            case .days:
                HStack {
                    Text("Days:")
                    TextField("", value: $numberParameter, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            case .none:
                EmptyView()
            }
            
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Add") {
                    if let rule = createRule() {
                        onAdd(rule)
                        dismiss()
                    }
                }
                .disabled(!isValid)
            }
        }
        .padding(20)
        .frame(width: 350, height: 250)
    }
    
    private var isValid: Bool {
        switch ruleType.inputType {
        case .text: return !parameter.isEmpty
        case .hours, .days: return numberParameter > 0
        case .none: return true
        }
    }
    
    private func createRule() -> SmartCollectionRule? {
        switch ruleType {
        case .platform: return .platform(parameter)
        case .unplayed: return .unplayed
        case .playedMoreThan: return .playedMoreThan(hours: numberParameter)
        case .addedRecently: return .addedInLast(days: Int(numberParameter))
        case .playedRecently: return .playedInLast(days: Int(numberParameter))
        case .nameContains: return .nameContains(parameter)
        }
    }
}

