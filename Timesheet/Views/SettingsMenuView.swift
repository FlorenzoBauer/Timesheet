struct SettingsMenuView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var theme = ThemeManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    ColorPicker("Accent Color", selection: Binding(
                        get: { theme.accentColor },
                        set: { theme.updateAccentColor($0) }
                    ))
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0").foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .preferredColorScheme(.dark)
            .scrollContentBackground(.hidden)
            .background(
                theme.backgroundColor.opacity(0.9) // Transparent Dark Effect
                    .background(.ultraThinMaterial)
            )
        }
    }
}