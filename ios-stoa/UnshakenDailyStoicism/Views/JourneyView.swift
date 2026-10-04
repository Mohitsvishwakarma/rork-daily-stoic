import SwiftUI

/// Progress screen: stats, month calendar of completed days, and badges.
struct JourneyView: View {
    @Environment(ContentStore.self) private var content
    @Environment(ProgressStore.self) private var progress

    @State private var month: Int = Calendar.current.component(.month, from: Date())
    @State private var showAllBadges = false

    private var year: Int { content.currentYear }

    var body: some View {
        ZStack {
            MarbleBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    statTiles
                    calendarCard
                    badgesSection
                    epigram
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .sheet(isPresented: $showAllBadges) {
            AllBadgesSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Journey")
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.charcoal)
            Text("A calmer, stronger you, one day at a time.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.warmGray)
        }
    }

    // MARK: - Stat Tiles

    private var statTiles: some View {
        HStack(spacing: 12) {
            StatTile(symbol: "flame.fill", value: "\(progress.streak())", caption: "current")
            StatTile(symbol: "crown.fill", value: "\(progress.bestStreak)", caption: "best")
            StatTile(symbol: "book.fill", value: "\(progress.totalReads)", caption: "read")
        }
    }

    // MARK: - Calendar

    private var calendarCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text(monthName(month) + " \(year)")
                    .font(.system(.title2, design: .serif))
                    .foregroundStyle(Theme.charcoal)
                Spacer()
                navCircleButton(systemName: "chevron.left", enabled: month > 1) { month -= 1 }
                navCircleButton(systemName: "chevron.right", enabled: month < 12) { month += 1 }
            }

            HStack {
                ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { letter in
                    Text(letter)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.warmGray)
                        .frame(maxWidth: .infinity)
                }
            }

            let blanks = content.leadingBlanks(month: month, year: year)
            let dayCount = content.daysInMonth(month, year: year)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                ForEach(0..<blanks, id: \.self) { _ in
                    Color.clear.frame(height: 36)
                }
                ForEach(1...dayCount, id: \.self) { day in
                    calendarCell(day: day)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .cardSurface(cornerRadius: 24)
    }

    private func calendarCell(day: Int) -> some View {
        let date = Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: 12))
        let key = date.map { ProgressStore.key(for: $0) } ?? ""
        let completed = progress.completedSet.contains(key)
        let isFuture = date.map { $0 > Date() } ?? true
        let isToday = date.map { Calendar.current.isDateInToday($0) } ?? false

        return ZStack {
            Circle()
                .fill(completed ? Theme.bronze : (isFuture ? Color.clear : Theme.sand.opacity(0.7)))
            if isToday && !completed {
                Circle()
                    .strokeBorder(Theme.bronze, lineWidth: 1.5)
            }
            Text("\(day)")
                .font(.system(size: 13, weight: completed ? .bold : .medium))
                .foregroundStyle(completed ? .white : (isFuture ? Theme.muted : Theme.charcoal))
        }
        .frame(height: 36)
        .animation(.easeInOut(duration: 0.2), value: completed)
    }

    private func navCircleButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(enabled ? Theme.charcoal : Theme.muted)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Theme.sand.opacity(0.7)))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!enabled)
    }

    // MARK: - Badges

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Badges")
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.charcoal)
                Spacer()
                Button {
                    showAllBadges = true
                } label: {
                    HStack(spacing: 2) {
                        Text("See All")
                        Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.bronze)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(progress.badges) { badge in
                        BadgeTile(badge: badge)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .contentMargins(.horizontal, 2, for: .scrollContent)
    }

    // MARK: - Epigram

    private var epigram: some View {
        VStack(spacing: 6) {
            Text("“Small steps compound into a different you.”")
                .font(.system(size: 17, weight: .medium, design: .serif).italic())
                .foregroundStyle(Theme.charcoal)
                .multilineTextAlignment(.center)
            Text("SENECA")
                .font(.system(size: 12, weight: .medium))
                .kerning(2)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date())
    }
}

// MARK: - Stat Tile

private struct StatTile: View {
    let symbol: String
    let value: String
    let caption: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.bronze)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Theme.bronzeTint))
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(Theme.charcoal)
            Text(caption)
                .font(.system(size: 13))
                .foregroundStyle(Theme.warmGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .cardSurface(cornerRadius: 20)
    }
}

// MARK: - Badge Tile

struct BadgeTile: View {
    let badge: Badge

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badge.isEarned ? Theme.bronze : Theme.sand.opacity(0.8))
                    .frame(width: 52, height: 52)
                Image(systemName: badge.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(badge.isEarned ? .white : Theme.muted)
            }
            Text(badge.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.charcoal)
                .lineLimit(1)
            Text(badge.subtitle)
                .font(.system(size: 11))
                .foregroundStyle(Theme.warmGray)
                .lineLimit(1)
        }
        .frame(width: 104)
        .padding(.vertical, 14)
        .cardSurface(cornerRadius: 18)
    }
}

// MARK: - All Badges Sheet

private struct AllBadgesSheet: View {
    @Environment(ProgressStore.self) private var progress
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            MarbleBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Badges")
                            .font(.system(.title, design: .serif, weight: .semibold))
                            .foregroundStyle(Theme.charcoal)
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.charcoal)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Theme.surface))
                        }
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 14) {
                        ForEach(progress.badges) { badge in
                            BadgeTile(badge: badge)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}
