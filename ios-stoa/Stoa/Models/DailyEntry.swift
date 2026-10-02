import Foundation

/// A single day's reading: an original reflection paired with a classical quote.
nonisolated struct DailyEntry: Identifiable, Equatable {
    let month: Int
    let day: Int
    let title: String
    let tag: String
    let quote: String
    let author: String
    let body: String
    let action: String

    var id: String { String(format: "%02d-%02d", month, day) }
}

/// Raw JSON shape of a monthly content file (short keys keep the bundle compact).
nonisolated struct MonthFile: Codable {
    let m: Int
    let theme: String
    let entries: [RawEntry]

    nonisolated struct RawEntry: Codable {
        let d: Int
        let t: String
        let q: String
        let a: String?
        let b: String
        let x: String
        let g: String?
    }
}

extension DailyEntry {
    /// Date this entry falls on in the given year (nil for Feb 29 in non-leap years).
    func date(inYear year: Int, calendar: Calendar = .current) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))
    }
}
