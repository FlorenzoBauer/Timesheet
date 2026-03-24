import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    
    // Use EnvironmentObject to tap into the single app-wide manager
    @EnvironmentObject var subManager: SubscriptionManager
    
    // Theme Integration
    @StateObject private var theme = ThemeManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 35) {
                // 1. HERO HEADER
                VStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(theme.effectiveAccent.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    
                    VStack(spacing: 5) {
                        Text("Companshift Pro")
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            // Using standard primary/secondary colors for better dark mode support
                            .foregroundColor(.primary)
                        
                        Text("One-time upgrade. Lifetime access.")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 40)

                // 2. FEATURE LIST
                VStack(alignment: .leading, spacing: 25) {
                    FeatureRow(icon: "briefcase.fill", title: "Unlimited Jobs", subtitle: "Track as many side hustles as you want.", theme: theme)
                    FeatureRow(icon: "chart.bar.fill", title: "Advanced Analytics", subtitle: "Deep dive into your monthly earnings.", theme: theme)
                    FeatureRow(icon: "square.and.arrow.up.fill", title: "PDF & CSV Export", subtitle: "Professional reports for your records.", theme: theme)
                }
                .padding(.horizontal, 30)

                Spacer()

                // 3. ACTION BUTTONS
                VStack(spacing: 16) {
                    Button {
                        Task { await subManager.purchase() }
                    } label: {
                        Group {
                            if subManager.isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text("Upgrade Now — $2.99")
                                    .font(.system(size: 18, weight: .black, design: .rounded))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(theme.effectiveAccent)
                        .cornerRadius(20)
                        .shadow(color: theme.effectiveAccent.opacity(0.3), radius: 10, y: 5)
                    }
                    .disabled(subManager.isPurchasing)
                    .padding(.horizontal, 25)

                    Button("Restore Purchase") {
                        Task { await subManager.restore() }
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.secondary)
                }
                .padding(.bottom, 30)
            }
            .background(
                Group {
                    if theme.isDarkMode {
                        theme.backgroundColor.ignoresSafeArea()
                    } else {
                        Color(uiColor: .systemBackground).ignoresSafeArea()
                    }
                }
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary.opacity(0.5))
                            .font(.title3)
                    }
                }
            }
            // Auto-dismiss when purchase is successful
            .onChange(of: subManager.isProUser) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let theme: ThemeManager
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 30)
                .foregroundColor(theme.effectiveAccent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
}
