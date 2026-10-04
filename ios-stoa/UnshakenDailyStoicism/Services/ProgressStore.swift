import Foundation
import Observation

/// All persisted user progress: completed days, XP, reflections, badges, reminder settings.
nonisolated struct ProgressState: Codable {
    var completedDays: [String] = []          // "yyyy-MM-dd"
    var xp: Int = 0
    var reflections: [String: String] = [:]   // dayKey -> reflection text
    var badgeDates: [String: String] = [:]    // badgeId -> dayKey earned
    var nightReads: Int = 0
    var reminderOn: Bool = false
    var reminderHour: Int = 8
    var reminderMinute: Int = 0
    var lastPaywallDayKey: String? = nil
}

/// A badge definition with the metric that unlocks it.
nonisolated struct BadgeDefinition: Identifiable {
    struct Metrics {
        let bestStreak: Int
        let totalReads: Int
        let nightReads: Int
        let reflections: Int
        let level: Int
    }

    let id: String
    let name: String
    let subtitle: String
    let symbol: String
    let condition: (Metrics) -> Bool
}

/// A badge with its earned state, ready for display.
nonisolated struct Badge: Identifiable {
    let id: String
    let name: String
    let subtitle: String
    let symbol: String
    let earnedDate: String?

    var isEarned: Bool { earnedDate != nil }
}

/// Information about a freshly completed day, shown on the reward sheet.
nonisolated struct RewardInfo: Identifiable {
    let id: String
    let streakAfter: Int
    let extended: Bool
    let xpEarned: Int
    let dayKey: String
}

/// Owns all progress state and gamification logic. Persisted in UserDefaults.
@MainActor
@Observable
final class ProgressStore {
    private static let storageKey = "stoa.progress.v1"
    static let xpPerDay = 25
    static let xpPerLevel = 500

    private let defaults: UserDefaults
    private(set) var state: ProgressState

    /// Days of completed reading offered free before the lifetime unlock is asked for.
    /// Counts total completed days, not streak days.
    static let freeTrialDays = 7

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(ProgressState.self, from: data) {
            state = decoded
        } else {
            state = ProgressState()
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: Self.storageKey)
        }
    }

    // MARK: - Keys & Dates

    nonisolated static func key(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 2026, c.month ?? 1, c.day ?? 1)
    }

    nonisolated static func date(fromKey key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        // Noon avoids DST-boundary arithmetic errors.
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
    }

    // MARK: - Derived State

    var completedSet: Set<String> { Set(state.completedDays) }
    var todayKey: String { Self.key(for: Date()) }
    var isCompletedToday: Bool { completedSet.contains(todayKey) }

    /// Current streak as of `date` (counts up to yesterday if today isn't done yet).
    func streak(on date: Date = Date()) -> Int {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: date)
        if !completedSet.contains(Self.key(for: day)) {
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = previous
        }
        var count = 0
        while completedSet.contains(Self.key(for: day)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    var bestStreak: Int {
        let calendar = Calendar.current
        let dates = state.completedDays.compactMap { Self.date(fromKey: $0) }.sorted()
        guard dates.count > 1 else { return dates.count }
        var best = 1
        var run = 1
        for index in 1..<dates.count {
            let diff = calendar.dateComponents([.day], from: dates[index - 1], to: dates[index]).day ?? 0
            run = diff == 1 ? run + 1 : 1
            best = max(best, run)
        }
        return best
    }

    var totalReads: Int { state.completedDays.count }
    var xp: Int { state.xp }

    /// True once 7 days have been completed in total (streak not required).
    var isTrialOver: Bool { state.completedDays.count >= Self.freeTrialDays }

    /// True when the trial is over and the lifetime paywall hasn't been shown today.
    var shouldNudgePaywall: Bool { isTrialOver && state.lastPaywallDayKey != todayKey }

    /// Records that the lifetime paywall was presented today (one nudge per day).
    func markPaywallShown() {
        state.lastPaywallDayKey = todayKey
        persist()
    }

    var level: Int { state.xp / Self.xpPerLevel + 1 }
    var xpIntoLevel: Int { state.xp % Self.xpPerLevel }
    var xpForNextLevel: Int { Self.xpPerLevel }

    static let tierNames = ["Seeker", "Student", "Apprentice", "Practitioner", "Guardian", "Philosopher", "Sage"]
    var tierName: String {
        Self.tierNames[min(level - 1, Self.tierNames.count - 1)]
    }

    var sortedReflections: [(key: String, text: String)] {
        state.reflections.sorted { $0.key > $1.key }.map { (key: $0.key, text: $0.value) }
    }

    // MARK: - Badges

    static let badgeDefinitions: [BadgeDefinition] = [
        BadgeDefinition(id: "first-light", name: "First Light", subtitle: "1 reading", symbol: "sunrise.fill") { $0.totalReads >= 1 },
        BadgeDefinition(id: "first-week", name: "First Week", subtitle: "7-day streak", symbol: "flame.fill") { $0.bestStreak >= 7 },
        BadgeDefinition(id: "marcus-medal", name: "Marcus Medal", subtitle: "10 readings", symbol: "person.crop.circle.fill") { $0.totalReads >= 10 },
        BadgeDefinition(id: "thirty-days", name: "30 Days", subtitle: "A month strong", symbol: "seal.fill") { $0.bestStreak >= 30 },
        BadgeDefinition(id: "night-reader", name: "Night Reader", subtitle: "10 late reads", symbol: "moon.stars.fill") { $0.nightReads >= 10 },
        BadgeDefinition(id: "one-hundred", name: "One Hundred", subtitle: "100 readings", symbol: "books.vertical.fill") { $0.totalReads >= 100 },
        BadgeDefinition(id: "deep-thinker", name: "Deep Thinker", subtitle: "10 reflections", symbol: "text.bubble.fill") { $0.reflections >= 10 },
        BadgeDefinition(id: "sage", name: "Sage", subtitle: "Level 5", symbol: "sparkles") { $0.level >= 5 },
    ]

    var badges: [Badge] {
        let metrics = BadgeDefinition.Metrics(
            bestStreak: bestStreak,
            totalReads: totalReads,
            nightReads: state.nightReads,
            reflections: state.reflections.count,
            level: level
        )
        return Self.badgeDefinitions.map { definition in
            Badge(
                id: definition.id,
                name: definition.name,
                subtitle: definition.subtitle,
                symbol: definition.symbol,
                earnedDate: definition.condition(metrics) ? (state.badgeDates[definition.id] ?? todayKey) : nil
            )
        }
    }

    private func evaluateBadges() {
        let metrics = BadgeDefinition.Metrics(
            bestStreak: bestStreak,
            totalReads: totalReads,
            nightReads: state.nightReads,
            reflections: state.reflections.count,
            level: level
        )
        for definition in Self.badgeDefinitions where definition.condition(metrics) {
            if state.badgeDates[definition.id] == nil {
                state.badgeDates[definition.id] = todayKey
            }
        }
    }

    // MARK: - Mutations

    /// Marks today complete and awards XP. Returns reward info, or nil if already done.
    @discardableResult
    func completeToday(now: Date = Date()) -> RewardInfo? {
        let key = Self.key(for: now)
        guard !completedSet.contains(key) else { return nil }
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now))
        let extended = yesterday.map { completedSet.contains(Self.key(for: $0)) } ?? false

        state.completedDays.append(key)
        state.xp += Self.xpPerDay
        if calendar.component(.hour, from: now) >= 22 {
            state.nightReads += 1
        }
        evaluateBadges()
        persist()

        return RewardInfo(
            id: key,
            streakAfter: streak(on: now),
            extended: extended,
            xpEarned: Self.xpPerDay,
            dayKey: key
        )
    }

    func saveReflection(_ text: String, for dayKey: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            state.reflections.removeValue(forKey: dayKey)
        } else {
            state.reflections[dayKey] = trimmed
        }
        evaluateBadges()
        persist()
    }

    func setReminder(on: Bool, hour: Int, minute: Int) {
        state.reminderOn = on
        state.reminderHour = hour
        state.reminderMinute = minute
        persist()
    }

    func resetAll() {
        state = ProgressState()
        defaults.removeObject(forKey: Self.storageKey)
    }
}
