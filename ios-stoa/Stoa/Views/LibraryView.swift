import SwiftUI

/// Browse all 365 entries by month. Past and today's entries open in the
/// reader; future days stay locked to protect the daily ritual.
struct LibraryView: View {
    @Environment(ContentStore.self) private var content
    @Environment(ProgressStore.self) private var progress

    var onOpenEntry: (DailyEntry) -> Void

    @State private var expandedMonths: Set<Int> = []

    private var year: Int { content.currentYear }
    private var currentMonth: Int { Calendar.current.component(.month, from: Date()) }

    var body: some View {
        ZStack {
            MarbleBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    VStack(spacing: 12) {
                        ForEach(1...12, id: \.self) { month in
                            monthCard(month)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .onAppear {
            if expandedMonths.isEmpty {
                expandedMonths = [currentMonth]
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Library")
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.charcoal)
            Text("A year of daily practice. Future days stay sealed.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.warmGray)
        }
    }

    // MARK: - Month Card

    private func monthCard(_ month: Int) -> some View {
        let entries = content.entries(inMonth: month)
        let readCount = entries.filter { progress.completedSet.contains(ProgressStore.key(forDate: month, day: $0.day, year: year)) }.count
        let isExpanded = expandedMonths.contains(month)

        return VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    if isExpanded {
                        expandedMonths.remove(month)
                    } else {
                        expandedMonths.insert(month)
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(monthName(month))
                            .font(.system(.title3, design: .serif, weight: .semibold))
                            .foregroundStyle(Theme.charcoal)
                        Text("\(content.themes[month] ?? "") · \(readCount)/\(entries.count) read")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.warmGray)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.muted)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableButtonStyle())

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(entries) { entry in
                        entryRow(entry, month: month)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
        .cardSurface(cornerRadius: 20)
    }

    private func entryRow(_ entry: DailyEntry, month: Int) -> some View {
        let date = entry.date(inYear: year)
        let isFuture = date.map { $0 > Date() } ?? true
        let done = progress.completedSet.contains(ProgressStore.key(forDate: month, day: entry.day, year: year))

        return Button {
            if !isFuture {
                onOpenEntry(entry)
            }
        } label: {
            HStack(spacing: 12) {
                Text("\(entry.day)")
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundStyle(done ? Theme.bronze : Theme.muted)
                    .frame(width: 28, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isFuture ? Theme.muted : Theme.charcoal)
                    Text(entry.quote)
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .foregroundStyle(Theme.warmGray)
                }
                Spacer()
                if isFuture {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)
                } else if done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.bronze)
                }
            }
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(isFuture)
    }

    private func monthName(_ month: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Calendar.current.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date())
    }
}

extension ProgressStore {
    /// Convenience key builder for a specific month/day/year.
    nonisolated static func key(forDate month: Int, day: Int, year: Int, calendar: Calendar = .current) -> String {
        let date = calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
        return key(for: date, calendar: calendar)
    }
}
