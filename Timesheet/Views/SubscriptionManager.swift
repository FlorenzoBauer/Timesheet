import Foundation
import StoreKit
import SwiftUI
import Combine // Required for ObservableObject conformance

@MainActor
class SubscriptionManager: ObservableObject {
    // This is the source of truth the UI will watch
    @Published var isProUser: Bool = false
    @Published var isPurchasing: Bool = false
    
    // This handles the background saving
    @AppStorage("isProUser") private var persistedProStatus: Bool = false
    
    private let proProductID = "com.florenzo.companshift.pro"
    private var updates: Task<Void, Never>? = nil
    
    init() {
        // 1. Set the UI to match what we last saved
        self.isProUser = persistedProStatus
        
        // 2. Check Apple's servers for updates
        Task {
            await updatePurchaseStatus()
        }
        
        // 3. Listen for changes (like refunds or family sharing)
        updates = Task.detached { [weak self] in
            for await _ in Transaction.updates {
                await self?.updatePurchaseStatus()
            }
        }
    }
    
    func updatePurchaseStatus() async {
        var isPurchased = false
        
        // Check current entitlements from Apple
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == proProductID {
                    isPurchased = true
                    break
                }
            }
        }
        
        // Update both memory (UI) and storage (Persistence)
        self.isProUser = isPurchased
        self.persistedProStatus = isPurchased
    }
    
    func purchase() async {
        isPurchasing = true
        defer { isPurchasing = false }
        
        do {
            let products = try await Product.products(for: [proProductID])
            guard let proProduct = products.first else { return }
            
            let result = try await proProduct.purchase()
            
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    self.isProUser = true
                    self.persistedProStatus = true
                }
            default: break
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
    
    func restore() async {
        isPurchasing = true // Show your loading spinner
        defer { isPurchasing = false }
        
        do {
            try await AppStore.sync()
            await updatePurchaseStatus()
            
            // If it worked, show a popup so the reviewer is happy
            if isProUser {
                // Trigger a simple 'Restored!' alert here
                print("Successfully restored!")
            }
        } catch {
            print("Restore failed: \(error)")
        }
    }
}
