import Foundation
import Observation
import RevenueCat

/// Owns purchase state for the one-time lifetime unlock.
/// Backed by the RevenueCat entitlement "lifetime" (product: stoa_lifetime_v1, $19.99).
@MainActor
@Observable
final class LifetimeStore {
    static let entitlementID = "lifetime"

    var isLifetime = false
    var offerings: Offerings?
    var isLoading = false
    var isPurchasing = false
    var isRestoring = false
    var error: String?

    init() {
        Task { await listenForUpdates() }
        Task { await fetchOfferings() }
    }

    /// The $19.99 one-time package from the current offering.
    var lifetimePackage: Package? {
        guard let current = offerings?.current else { return nil }
        return current.package(identifier: "$rc_lifetime") ?? current.lifetime
    }

    private func listenForUpdates() async {
        guard Purchases.isConfigured else { return }
        for await info in Purchases.shared.customerInfoStream {
            isLifetime = info.entitlements[Self.entitlementID]?.isActive == true
        }
    }

    func fetchOfferings() async {
        guard Purchases.isConfigured else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func purchaseLifetime() async {
        guard let package = lifetimePackage, Purchases.isConfigured else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if !result.userCancelled {
                isLifetime = result.customerInfo.entitlements[Self.entitlementID]?.isActive == true
            }
        } catch ErrorCode.purchaseCancelledError {
            // StoreKit cancellation is not an error.
        } catch ErrorCode.paymentPendingError {
            // Awaiting extra auth or parental approval; not a failure.
        } catch {
            self.error = error.localizedDescription
        }
    }

    func restore() async {
        guard Purchases.isConfigured else { return }
        isRestoring = true
        defer { isRestoring = false }
        do {
            let info = try await Purchases.shared.restorePurchases()
            isLifetime = info.entitlements[Self.entitlementID]?.isActive == true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func checkStatus() async {
        guard Purchases.isConfigured else { return }
        do {
            let info = try await Purchases.shared.customerInfo()
            isLifetime = info.entitlements[Self.entitlementID]?.isActive == true
        } catch {
            // Silent: a network miss shouldn't nag the user with an error on launch.
        }
    }
}
