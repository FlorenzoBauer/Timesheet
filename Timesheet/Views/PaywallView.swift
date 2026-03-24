import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    
    // Replace this with your actual Group ID from App Store Connect later
    // For now, it will look for any subscriptions in your StoreKit Config file
    let groupID = "YOUR_SUBSCRIPTION_GROUP_ID" 

    var body: some View {
        SubscriptionStoreView(groupID: groupID) {
            // CUSTOM HEADER: This is where you sell the "Pro" features
            VStack(spacing: 15) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)
                    .padding(.top, 40)
                
                Text("Unlock Shiftly Pro")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color(red: 0.4, green: 0.3, blue: 0.32))
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(icon: "calendar.badge.plus", text: "Unlimited Jobs & Tracking")
                    FeatureRow(icon: "chart.pie.fill", text: "Advanced Monthly Analytics")
                    FeatureRow(icon: "icloud.and.arrow.up.fill", text: "Cloud Sync Across Devices")
                }
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .containerBackground(Color(red: 1.0, green: 0.92, blue: 0.93).gradient, for: .subscriptionStoreHeader)
        }
        // This adds the "Restore Purchases" and "Terms" buttons automatically
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.visible, for: .policies)
        // Adjust the button color to match your theme
        .tint(Color(red: 0.95, green: 0.75, blue: 0.78))
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(Color(red: 0.95, green: 0.75, blue: 0.78))
                .frame(width: 30)
            Text(text)
                .font(.body)
                .foregroundStyle(Color(red: 0.4, green: 0.3, blue: 0.32))
        }
    }
}