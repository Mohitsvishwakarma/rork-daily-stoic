//
//  ContentView.swift
//  UnshakenDailyStoicism
//

import SwiftUI

/// Root of the app: four tabs, the full-screen reader, and the reward sheet.
struct ContentView: View {
    @Environment(ContentStore.self) private var content
    @Environment(ProgressStore.self) private var progress
    @Environment(LifetimeStore.self) private var store

    @State private var selectedTab: AppTab = .today
    @State private var readerEntry: DailyEntry?
    @State private var reward: RewardInfo?
    @State private var showPaywall = false

    enum AppTab: Hashable {
        case today, journey, library, profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(onOpenEntry: { entry in
                readerEntry = entry
            })
            .tabItem { Label("Today", systemImage: "sun.max.fill") }
            .tag(AppTab.today)

            JourneyView()
                .tabItem { Label("Journey", systemImage: "chart.bar.fill") }
                .tag(AppTab.journey)

            LibraryView(onOpenEntry: { entry in
                readerEntry = entry
            })
            .tabItem { Label("Library", systemImage: "book.fill") }
            .tag(AppTab.library)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(AppTab.profile)
        }
        .tint(Theme.bronze)
        .task {
            await store.checkStatus()
            if lifetimeShouldAsk() { showPaywall = true }
        }
        .fullScreenCover(item: $readerEntry) { entry in
            ReaderView(
                entry: entry,
                canComplete: isToday(entry),
                onComplete: { rewardInfo in
                    if let rewardInfo {
                        reward = rewardInfo
                    } else {
                        readerEntry = nil
                    }
                }
            )
        }
        .sheet(item: $reward) { info in
            RewardSheet(info: info, onDone: {
                reward = nil
                readerEntry = nil
                if lifetimeShouldAsk() { showPaywall = true }
            })
            .presentationDetents([.medium, .large])
            .presentationContentInteraction(.scrolls)
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaywall) {
            LifetimePaywallView(store: store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    /// Ask for the lifetime unlock once the trial is over (7 completed days, streak not
    /// required), the user hasn't purchased, and we haven't nudged today yet.
    private func lifetimeShouldAsk() -> Bool {
        guard !store.isLifetime,
              progress.isTrialOver,
              progress.shouldNudgePaywall else { return false }
        progress.markPaywallShown()
        return true
    }

    private func isToday(_ entry: DailyEntry) -> Bool {
        content.entry(for: Date())?.id == entry.id
    }
}

#Preview {
    ContentView()
        .environment(ContentStore())
        .environment(ProgressStore())
        .environment(LifetimeStore())
}
