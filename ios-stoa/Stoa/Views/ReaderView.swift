import SwiftUI

/// Full-screen swipeable card reader for one day's entry.
/// Four cards: quote, reflection, action, and the completion card.
struct ReaderView: View {
    let entry: DailyEntry
    let canComplete: Bool
    let onComplete: (RewardInfo?) -> Void

    @Environment(ProgressStore.self) private var progress
    @Environment(\.dismiss) private var dismiss

    @State private var page = 0

    private enum CardKind {
        case quote, reflection, action, complete
    }

    private var cardCount: Int { 4 }

    var body: some View {
        ZStack {
            MarbleBackground()
            VStack(spacing: 0) {
                topBar
                TabView(selection: $page) {
                    quoteCard.tag(0)
                    reflectionCard.tag(1)
                    actionCard.tag(2)
                    completeCard.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .padding(.top, 14)
                bottomBar
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 8) {
            ForEach(0..<cardCount, id: \.self) { index in
                Capsule()
                    .fill(index <= page ? Theme.bronze : Theme.sand)
                    .frame(height: 5)
                    .animation(.easeInOut(duration: 0.2), value: page)
            }
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
            .accessibilityLabel("Close reader")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Cards

    private var quoteCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(entry.tag)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Theme.bronze))
                Spacer()
            }
            Spacer()
            Text(entry.quote)
                .font(.system(size: 32, weight: .medium, design: .serif))
                .lineSpacing(8)
                .foregroundStyle(Theme.charcoal)
            Rectangle()
                .fill(Theme.bronze)
                .frame(width: 42, height: 2)
            if !entry.author.isEmpty {
                Text("\(entry.author)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.bronze)
            }
            Spacer()
        }
        .padding(26)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: 32)
        .padding(.horizontal, 20)
    }

    private var reflectionCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(entry.title)
                .font(.system(size: 32, weight: .semibold, design: .serif))
                .lineSpacing(4)
                .foregroundStyle(Theme.bronzeDeep)
            Rectangle()
                .fill(Theme.bronze)
                .frame(width: 42, height: 2)
            Text(entry.body)
                .font(.system(size: 19, design: .serif))
                .lineSpacing(7)
                .foregroundStyle(Theme.charcoal)
            Spacer()
        }
        .padding(26)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: 32)
        .padding(.horizontal, 20)
    }

    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("TODAY'S PRACTICE")
                .font(.system(size: 12, weight: .bold))
                .kerning(1.5)
                .foregroundStyle(Theme.bronze)
            Text(entry.action)
                .font(.system(size: 27, weight: .medium, design: .serif))
                .lineSpacing(7)
                .foregroundStyle(Theme.charcoal)
            Text("Carry it with you. The smallest action is the one that counts.")
                .font(.system(size: 15))
                .lineSpacing(5)
                .foregroundStyle(Theme.warmGray)
            Spacer()
        }
        .padding(26)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: 32)
        .padding(.horizontal, 20)
    }

    private var completeCard: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.bronzeTint)
                    .frame(width: 96, height: 96)
                Image(systemName: progress.isCompletedToday ? "checkmark" : "flame.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Theme.bronze)
            }
            Text(progress.isCompletedToday || !canComplete ? "The day is yours" : "End of today's entry")
                .font(.system(.title3, design: .serif))
                .foregroundStyle(Theme.charcoal)
            if canComplete {
                Button {
                    let info = progress.completeToday()
                    onComplete(info)
                } label: {
                    Text(progress.isCompletedToday ? "Done for today" : "Mark day complete")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.bronze))
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.horizontal, 8)
            } else {
                Text("From the archive. Past readings don't add XP. Come back to today's entry for that.")
                    .font(.system(size: 14))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.warmGray)
                    .padding(.horizontal, 8)
            }
            Spacer()
        }
        .padding(26)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardSurface(cornerRadius: 32)
        .padding(.horizontal, 20)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            navButton(systemName: "chevron.left", enabled: page > 0) {
                withAnimation { page -= 1 }
            }
            Spacer()
            Text(page < cardCount - 1 ? "Swipe for next" : "You're done")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.warmGray)
            Spacer()
            navButton(systemName: "chevron.right", enabled: page < cardCount - 1) {
                withAnimation { page += 1 }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }

    private func navButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(enabled ? Theme.charcoal : Theme.muted)
                .frame(width: 46, height: 46)
                .background(Circle().fill(Theme.surface.opacity(0.9)))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!enabled)
        .accessibilityLabel(enabled ? systemName.contains("left") ? "Previous card" : "Next card" : "")
    }
}
