//
//  StoreKitManager.swift
//  FitNotes
//
//  StoreKit 2 integration for subscription management
//

import Foundation
import StoreKit

// MARK: - Product Identifiers
enum StoreProduct: String, CaseIterable {
    case premiumMonthly = "com.fitnotes.premium.monthly"
    case premiumYearly = "com.fitnotes.premium.yearly"

    var displayName: String {
        switch self {
        case .premiumMonthly: return "Premium Monthly"
        case .premiumYearly: return "Premium Yearly"
        }
    }
}

// MARK: - Store Error
enum StoreError: LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed
    case userCancelled
    case pending
    case unknown

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed"
        case .userCancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending approval"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

// MARK: - Subscription Status
enum SubscriptionStatus: Equatable {
    case notSubscribed
    case subscribed(expirationDate: Date?, productId: String)
    case expired
    case inGracePeriod(expirationDate: Date)
    case inBillingRetry

    var isActive: Bool {
        switch self {
        case .subscribed, .inGracePeriod, .inBillingRetry:
            return true
        case .notSubscribed, .expired:
            return false
        }
    }
}

// MARK: - StoreKit Manager
@MainActor
class StoreKitManager: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?
    private let productIds = StoreProduct.allCases.map { $0.rawValue }

    // MARK: - Singleton
    static let shared = StoreKitManager()

    // MARK: - Initialization
    init() {
        // Start listening for transactions
        updateListenerTask = listenForTransactions()

        // Load products and check subscription status
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let storeProducts = try await Product.products(for: productIds)
            // Sort products by price (monthly first, then yearly)
            products = storeProducts.sorted { product1, product2 in
                // Monthly before yearly
                if product1.id.contains("monthly") && product2.id.contains("yearly") {
                    return true
                }
                if product1.id.contains("yearly") && product2.id.contains("monthly") {
                    return false
                }
                return product1.price < product2.price
            }
            isLoading = false
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async throws -> Transaction? {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Update subscription status
                await updateSubscriptionStatus()

                // Finish the transaction
                await transaction.finish()

                isLoading = false
                return transaction

            case .userCancelled:
                isLoading = false
                throw StoreError.userCancelled

            case .pending:
                isLoading = false
                throw StoreError.pending

            @unknown default:
                isLoading = false
                throw StoreError.unknown
            }
        } catch StoreError.userCancelled {
            throw StoreError.userCancelled
        } catch StoreError.pending {
            throw StoreError.pending
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw StoreError.purchaseFailed
        }
    }

    // MARK: - Restore Purchases
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            isLoading = false
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Subscription Status
    func updateSubscriptionStatus() async {
        var foundActiveSubscription = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.productType == .autoRenewable {
                // Check if the subscription is still valid
                if let expirationDate = transaction.expirationDate {
                    if expirationDate > Date() {
                        purchasedProductIDs.insert(transaction.productID)
                        subscriptionStatus = .subscribed(
                            expirationDate: expirationDate,
                            productId: transaction.productID
                        )
                        foundActiveSubscription = true
                    }
                }
            }
        }

        if !foundActiveSubscription {
            purchasedProductIDs.removeAll()
            subscriptionStatus = .notSubscribed
        }

        // Save subscription state
        UserDefaults.standard.set(subscriptionStatus.isActive, forKey: "isPremiumUser")
    }

    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self = self else { return }

                do {
                    let transaction = try await self.checkVerified(result)

                    // Update subscription status on main actor
                    await MainActor.run {
                        Task {
                            await self.updateSubscriptionStatus()
                        }
                    }

                    // Finish the transaction
                    await transaction.finish()
                } catch {
                    // Transaction failed verification
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }

    // MARK: - Verification
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Helper Methods
    func product(for identifier: StoreProduct) -> Product? {
        products.first { $0.id == identifier.rawValue }
    }

    var monthlyProduct: Product? {
        product(for: .premiumMonthly)
    }

    var yearlyProduct: Product? {
        product(for: .premiumYearly)
    }

    var isPremium: Bool {
        subscriptionStatus.isActive
    }

    // MARK: - Price Formatting
    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }

    func formattedPricePerMonth(for product: Product) -> String? {
        guard product.id.contains("yearly") else { return nil }

        let yearlyPrice = product.price
        let monthlyPrice = yearlyPrice / 12

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale

        return formatter.string(from: monthlyPrice as NSNumber)
    }

    func savingsPercentage(yearly: Product, monthly: Product) -> Int {
        let yearlyTotal = yearly.price
        let monthlyTotal = monthly.price * 12
        let savings = (monthlyTotal - yearlyTotal) / monthlyTotal * 100
        return Int(savings.rounded())
    }
}

// MARK: - Subscription Info Extension
extension StoreKitManager {
    var subscriptionExpirationDate: Date? {
        switch subscriptionStatus {
        case .subscribed(let date, _):
            return date
        case .inGracePeriod(let date):
            return date
        default:
            return nil
        }
    }

    var currentSubscriptionProductId: String? {
        switch subscriptionStatus {
        case .subscribed(_, let productId):
            return productId
        default:
            return nil
        }
    }

    func formattedExpirationDate() -> String? {
        guard let date = subscriptionExpirationDate else { return nil }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
