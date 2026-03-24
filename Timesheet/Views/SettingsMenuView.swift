import SwiftUI

struct SettingsMenuView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var theme = ThemeManager.shared
    
    // MARK: - SUBSCRIPTION MANAGER
    // We now pull the manager from the Environment (App Level)
    @EnvironmentObject var subManager: SubscriptionManager
    
    @State private var showingPaywall = false
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

    var body: some View {
        NavigationStack {
            List {
                appearanceSection
                themeColorsSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundColor(theme.effectiveAccent)
                }
            }
            .preferredColorScheme(theme.isDarkMode ? .dark : .light)
            .scrollContentBackground(.hidden)
            .background(backgroundView)
            // FIXED: We call PaywallView() and inject the subManager via environment
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
                    .environmentObject(subManager)
            }
        }
    }

    // MARK: - SECTION: APPEARANCE
    
    private var appearanceSection: some View {
        Section("Appearance") {
            Toggle(isOn: $theme.isDarkMode) {
                Label("Dark Mode", systemImage: theme.isDarkMode ? "moon.fill" : "sun.max.fill")
            }
            .tint(theme.effectiveAccent)
        }
        .listRowBackground(rowBackground)
    }

    // MARK: - SECTION: THEME COLORS (PRO)
    
    private var themeColorsSection: some View {
        Section {
            // Custom Theme Toggle
            HStack {
                Toggle("Custom Theme", isOn: Binding(
                    get: { theme.useCustomColors },
                    set: { newValue in
                        if subManager.isProUser {
                            theme.useCustomColors = newValue
                        } else {
                            showingPaywall = true
                            theme.useCustomColors = false
                        }
                    }
                ))
                .tint(theme.effectiveAccent)
                
                if !subManager.isProUser {
                    proBadge
                }
            }

            // Accent Color Picker
            ColorPicker("Accent Color", selection: Binding(
                get: { theme.accentColor },
                set: { theme.updateAccentColor($0) }
            ))
            .disabled(!theme.useCustomColors || !subManager.isProUser)
            .opacity(theme.useCustomColors && subManager.isProUser ? 1.0 : 0.5)
            
            // Background Color Picker (Dark Mode Only)
            if theme.useCustomColors && theme.isDarkMode && subManager.isProUser {
                ColorPicker("Background", selection: Binding(
                    get: { theme.backgroundColor },
                    set: { theme.updateBackgroundColor($0) }
                ))
            }
            
            // Quick Upgrade Button for Non-Pro Users
            if !subManager.isProUser {
                upgradeButton
            }
        } header: {
            Text("Theme Colors")
        } footer: {
            footerContent
        }
        .listRowBackground(rowBackground)
    }

    // MARK: - SECTION: ABOUT
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundColor(.secondary)
            }
            
            // Apple Requirement: Users must be able to restore purchases
            Button(action: {
                Task {
                    await subManager.restore()
                }
            }) {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundColor(theme.effectiveAccent)
            }
        }
        .listRowBackground(rowBackground)
    }

    // MARK: - COMPONENT HELPERS

    private var proBadge: some View {
        Text("PRO")
            .font(.system(size: 8, weight: .black))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(theme.effectiveAccent)
            .foregroundColor(.black)
            .cornerRadius(4)
    }

    private var upgradeButton: some View {
        Button(action: { showingPaywall = true }) {
            Label("UPGRADE TO PRO", systemImage: "crown.fill")
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundColor(theme.effectiveAccent)
        }
    }

    private var footerContent: some View {
        Group {
            if !subManager.isProUser {
                Text("Unlock Custom Themes and Backgrounds with Pro.")
                    .foregroundColor(theme.effectiveAccent)
            } else if !theme.useCustomColors {
                Text("Default: Pink Blush (AccentMain)")
            } else if !theme.isDarkMode {
                Text("Custom backgrounds are only available in Dark Mode.")
            }
        }
    }

    private var rowBackground: some View {
        theme.isDarkMode ? Color.white.opacity(0.05) : Color.black.opacity(0.03)
    }

    private var backgroundView: some View {
        ZStack {
            if theme.isDarkMode {
                theme.backgroundColor.opacity(0.9)
            } else {
                Color.white.opacity(0.8)
            }
            // Note: Ensure VisualEffectView is defined in your project
            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        }
        .ignoresSafeArea()
    }
}
