import SwiftUI

/// In-app legal disclosures: Privacy Policy and Terms of Use (EULA).
/// Shown as a sheet from the paywall and Profile so the links are always
/// reachable inside the app, as required for apps with in-app purchases.
struct LegalView: View {
    enum Document: String, CaseIterable, Identifiable {
        case privacy = "Privacy Policy"
        case terms = "Terms of Use"

        var id: String { rawValue }
    }

    @State var document: Document
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Picker("Document", selection: $document) {
                        ForEach(Document.allCases) { doc in
                            Text(doc.rawValue).tag(doc)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Theme.bronze)
                    .padding(.bottom, 6)

                    if document == .privacy {
                        privacyBody
                    } else {
                        termsBody
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Theme.canvas.ignoresSafeArea())
            .navigationTitle("Legal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Privacy Policy

    private var privacyBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            legalParagraph("Last updated: September 29, 2026. Stoa is a reading app with no accounts, no ads, and no third-party tracking.")

            legalHeading("What we store")
            legalParagraph("Your reading progress, streaks, XP, badges, and reflections are stored only on your device using Apple's standard local storage. They are never uploaded to a server, and deleting the app deletes them permanently.")

            legalHeading("Notifications")
            legalParagraph("If you turn on the daily reminder, Stoa schedules local notifications on your device. No information leaves your phone.")

            legalHeading("Purchases")
            legalParagraph("The lifetime unlock is processed by Apple and RevenueCat, our payment service provider. RevenueCat receives your purchase history and a device identifier, used only to activate and restore your purchase. Stoa never sees your payment details.")

            legalHeading("What we do not do")
            legalParagraph("Stoa does not collect your name, email, location, contacts, or browsing. It does not use advertising identifiers, analytics trackers, or advertising networks of any kind.")

            legalHeading("Children")
            legalParagraph("Stoa is not directed at children under 13 and collects no data from them.")

            legalParagraph("Questions about this policy can be sent to the developer through the App Store support link.")

            legalLink(
                text: "View Privacy Policy online",
                url: URL(string: "https://winningsaas.com/legal/stoa/privacy")!
            )
        }
    }

    // MARK: - Terms of Use

    private var termsBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            legalParagraph("These terms govern your use of Stoa. By using the app you agree to them.")

            legalHeading("The license")
            legalParagraph("Stoa is licensed, not sold, to you. The one-time lifetime purchase grants you a perpetual, non-transferable license to use the app and its content on Apple devices signed into your Apple Account.")

            legalHeading("Purchases and refunds")
            legalParagraph("The lifetime unlock is a single one-time payment. There is no subscription and no recurring charge. All purchases and refunds are handled by Apple under its standard policies.")

            legalParagraph("Purchases are also governed by Apple's standard licensed application end user license agreement.")

            legalLink(
                text: "View Terms of Service online",
                url: URL(string: "https://winningsaas.com/legal/stoa/terms")!
            )

            legalHeading("Content")
            legalParagraph("The daily readings are original works written for Stoa. Classical quotations are drawn from public-domain translations. You may not redistribute, resell, or republish the app's content.")

            legalHeading("No warranty")
            legalParagraph("Stoa is provided as is, without warranties of any kind. The readings are for reflection and education, not medical, psychological, or financial advice.")

            legalHeading("Changes")
            legalParagraph("If these terms change, the updated version will appear in the app before or with the next release.")
        }
    }

    // MARK: - Pieces

    private func legalHeading(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Theme.charcoal)
            .padding(.top, 4)
    }

    private func legalParagraph(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .lineSpacing(4)
            .foregroundStyle(Theme.warmGray)
    }

    private func legalLink(text: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 6) {
                Text(text)
                    .font(.system(size: 14, weight: .semibold))
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
            }
        }
        .tint(Theme.bronze)
    }
}
