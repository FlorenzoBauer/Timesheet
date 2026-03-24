import Foundation
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    // This saves the "Pro" status to the phone's memory
    @AppStorage("isProUser") var isProUser: Bool = false
    
    func purchase() async {
        do {
            let products = try await Product.products(for: ["com.yourname.timesheet.pro"])
            if let proProduct = products.first {
                let result = try await proProduct.purchase()
                
                switch result {
                case .success(let verification):
                    // Payment worked!
                    if case .verified(_) = verification {
                        isProUser = true
                    }
                case .pending, .userCancelled:
                    break
                @unknown default:
                    break
                }
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
    
    func restore() async {
        // Checks Apple's records for previous purchases
        for await result in Transaction.currentEntitlements {
            if case .verified(_) = result {
                isProUser = true
            }
        }
    }
}