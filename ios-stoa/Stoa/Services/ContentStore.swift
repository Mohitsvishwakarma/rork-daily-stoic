import Foundation
import Observation

/// Loads the bundled year of daily entries and serves them by date.
@MainActor
@Observable
final class ContentStore {
    private(set) var entries: [DailyEntry] = []
    private(set) var themes: [Int: String] = [:]

    init() {
        load()
    }

    private func load() {
        var all: [DailyEntry] = []
        for month in 1...12 {
            let name = String(format: "content-%02d", month)
            guard let url = Bundle.main.url(forResource: name, withExtension: "json") else { continue }
            do {
                let data = try Data(contentsOf: url)
                let file = try JSONDecoder().decode(MonthFile.self, from: data)
                themes[month] = file.theme
                for raw in file.entries {
                    all.append(DailyEntry(
                        month: file.m,
                        day: raw.d,
                        title: raw.t,
                        tag: raw.g ?? file.theme,
                        quote: raw.q,
                        author: raw.a ?? "",
                        body: raw.b,
                        action: raw.x
                    ))
                }
            } catch {
                // Skip a malformed month file rather than failing the whole library.
                continue
            }
        }
        entries = all.sorted { lhs, rhs in
            lhs.month != rhs.month ? lhs.month < rhs.month : lhs.day < rhs.day
        }
    }

    func entry(for date: Date) -> DailyEntry? {
        let components = Calendar.current.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else { return nil }
        return entry(month: month, day: day)
    }

    func entry(month: Int, day: Int) -> DailyEntry? {
        entries.first { $0.month == month && $0.day == day }
    }

    func entries(inMonth month: Int) -> [DailyEntry] {
        entries.filter { $0.month == month }
    }

    /// Number of days in the given month of the current year.
    func daysInMonth(_ month: Int, year: Int) -> Int {
        let calendar = Calendar.current
        guard let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let interval = calendar.dateInterval(of: .month, for: first) else { return 30 }
        return calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 30
    }

    /// Weekday index (0 = Monday) of the 1st of the month, for calendar leading blanks.
    func leadingBlanks(month: Int, year: Int) -> Int {
        let calendar = Calendar.current
        guard let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)) else { return 0 }
        let weekday = calendar.component(.weekday, from: first)
        return (weekday + 5) % 7
    }

    var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
}
