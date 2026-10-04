//
//  UnshakenDailyStoicismApp.swift
//  UnshakenDailyStoicism
//

import SwiftUI
import RevenueCat

@main
struct UnshakenDailyStoicismApp: App {
    @State private var content = ContentStore()
    @State private var progress = ProgressStore()
    @State private var store = LifetimeStore()

    init() {
        #if DEBUG
        let apiKey = Config.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY
        #else
        let apiKey = Config.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY
        #endif
        guard !apiKey.isEmpty else { return }
        Purchases.configure(withAPIKey: apiKey)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(content)
                .environment(progress)
                .environment(store)
                .tint(Theme.bronze)
                .task {
                    await ReminderScheduler.syncIfNeeded(progress: progress, content: content)
                }
        }
    }
}
