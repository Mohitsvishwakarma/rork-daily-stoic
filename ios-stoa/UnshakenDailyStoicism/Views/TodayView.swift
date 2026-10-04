import SwiftUI

/// The home screen: streak, today's reading card, primary read action, XP level.
struct TodayView: View {
    @Environment(ContentStore.self) private var content
    @Environment(ProgressStore.self) private var progress

    var onOpenEntry: (DailyEntry) -> Void

    var body: some View {
        ZStack {
            MarbleBackground()
            ScrollView {
                VStack(spacing: 16) {
                    headerRow
                    if let entry = content.entry(for: Date()) {
                        mainCard(entry)
                        readButton(entry)
                    }
                    xpCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .center) {
            StreakChip(streak: progress.streak())
            Spacer()
            WeekDots()
        }
    }

    // MARK: - Reading Card

    private func mainCard(_ entry: DailyEntry) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text(dayLabel)
                    .font(.system(.title3, design: .serif))
                    .foregroundStyle(Theme.charcoal)
                Spacer()
                if progress.isCompletedToday {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                        Text("Completed")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(Theme.bronze)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Theme.bronzeTint))
                } else {
                    Text(entry.tag)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Theme.bronze))
                }
            }

            Text(entry.quote)
                .font(.system(size: 26, weight: .medium, design: .serif))
                .lineSpacing(7)
                .foregroundStyle(Theme.charcoal)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: 28)
    }

    private var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Read Button

    private func readButton(_ entry: DailyEntry) -> some View {
        Button {
            onOpenEntry(entry)
        } label: {
            HStack(spacing: 8) {
                Text(progress.isCompletedToday ? "Revisit today's entry" : "Read today's entry · 2 min")
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.bronze))
            .shadow(color: Theme.bronze.opacity(0.3), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - XP Card

    private var xpCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Level \(progress.level) · \(progress.tierName)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.charcoal)
                Spacer()
                Text("\(progress.xpIntoLevel) / \(progress.xpForNextLevel) XP")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.warmGray)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.sand)
                    Capsule()
                        .fill(Theme.bronze)
                        .frame(width: max(0, geo.size.width * CGFloat(progress.xpIntoLevel) / CGFloat(progress.xpForNextLevel)))
                        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress.xpIntoLevel)
                }
            }
            .frame(height: 8)

            Text(progress.isCompletedToday ? "Today is complete. Come back tomorrow." : "Keep going. A calmer, stronger you is ahead.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.warmGray)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: 20)
    }
}

// MARK: - Streak Chip

struct StreakChip: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 15, weight: .semibold))
            Text(streak > 0 ? "\(streak)-day streak" : "Begin today")
                .font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(Theme.bronze)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(Theme.bronzeTint.opacity(0.75)))
    }
}

// MARK: - Week Dots

struct WeekDots: View {
    @Environment(ProgressStore.self) private var progress

    private let letters = ["M", "T", "W", "T", "F", "S", "S"]

    private var weekDays: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today) ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
    }

    var body: some View {
        HStack(spacing: 11) {
            ForEach(Array(weekDays.enumerated()), id: \.offset) { index, day in
                let done = progress.completedSet.contains(ProgressStore.key(for: day))
                let isToday = Calendar.current.isDateInToday(day)
                VStack(spacing: 6) {
                    Text(letters[index])
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.warmGray)
                    ZStack {
                        if isToday && !done {
                            Circle()
                                .strokeBorder(Theme.muted, lineWidth: 1.5)
                                .frame(width: 20, height: 20)
                        }
                        Circle()
                            .fill(done ? Theme.bronze : Theme.sand)
                            .frame(width: 13, height: 13)
                    }
                }
            }
        }
    }
}
