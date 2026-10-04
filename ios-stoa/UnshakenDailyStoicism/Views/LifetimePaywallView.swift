import SwiftUI
import RevenueCat

/// Lifetime unlock paywall shown after the 7-day trial of completed days.
struct LifetimePaywallView: View {
    var store: LifetimeStore
    @Environment(\.dismiss) private var dismiss
    @State private var legalDocument: LegalView.Document?

    var body: some View {
        ZStack {
            MarbleBackground()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.charcoal)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(Theme.surface.opacity(0.9)))
                    }
                    .buttonStyle(PressableButtonStyle())
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 22) {
                        Image(systemName: "laurel.leading")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(Theme.bronze)
                            .padding(.top, 18)

                        VStack(spacing: 8) {
                            Text("Your first week is complete")
                                .font(.system(size: 30, weight: .semibold, design: .serif))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.charcoal)
                            Text("Seven days of Stoic practice, on us. Keep every day from here for one single payment.")
                                .font(.system(size: 16))
                                .lineSpacing(4)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Theme.warmGray)
                        }

                        VStack(spacing: 14) {
                            benefitRow(icon: "book.fill", title: "All 366 daily readings", subtitle: "Every quote, reflection, and practice")
                            benefitRow(icon: "flame.fill", title: "Streaks, levels, and badges", subtitle: "Your full journey, saved forever")
                            benefitRow(icon: "moon.stars.fill", title: "Daily reminders", subtitle: "The reading arrives before the day fills up")
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity)
                        .cardSurface(cornerRadius: 20)
                        .padding(.horizontal, 2)

                        purchaseButton

                        Text("One payment. Yours forever. No subscription.")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.muted)

                        HStack(spacing: 20) {
                            legalLinkButton("Terms of Use", .terms)
                            legalLinkButton("Privacy Policy", .privacy)
                        }

                        Button {
                            Task { await store.restore() }
                        } label: {
                            if store.isRestoring {
                                ProgressView()
                            } else {
                                Text("Restore Purchases")
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        .foregroundStyle(Theme.bronze)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { store.error != nil },
            set: { if !$0 { store.error = nil } }
        )) {
            Button("OK") { store.error = nil }
        } message: {
            Text(store.error ?? "")
        }
        .onChange(of: store.isLifetime) { _, isLifetime in
            if isLifetime { dismiss() }
        }
        .task {
            // Retry once when the paywall opens empty, e.g. a flaky network at launch.
            if store.lifetimePackage == nil && !store.isLoading {
                await store.fetchOfferings()
            }
        }
        .sheet(item: $legalDocument) { document in
            LegalView(document: document)
                .presentationDetents([.medium, .large])
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.visible)
        }
    }

    private func legalLinkButton(_ title: String, _ document: LegalView.Document) -> some View {
        Button {
            legalDocument = document
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
        }
        .foregroundStyle(Theme.bronze)
    }

    // MARK: - Pieces

    private func benefitRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.bronze)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Theme.bronzeTint.opacity(0.7)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.charcoal)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.warmGray)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var purchaseButton: some View {
        if store.isLoading {
            ProgressView()
                .frame(height: 54)
        } else if let package = store.lifetimePackage {
            Button {
                Task { await store.purchaseLifetime() }
            } label: {
                HStack(spacing: 8) {
                    if store.isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Unlock Lifetime")
                            .font(.system(size: 17, weight: .semibold))
                        Text(package.localizedPriceString)
                            .font(.system(size: 17, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.bronze))
                .shadow(color: Theme.bronze.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(PressableButtonStyle())
            .disabled(store.isPurchasing)
        } else {
            VStack(spacing: 10) {
                Text("The lifetime unlock is unavailable right now.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.warmGray)
                Button {
                    Task { await store.fetchOfferings() }
                } label: {
                    Text("Try again")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(Theme.bronze)
            }
            .frame(height: 54)
        }
    }
}
