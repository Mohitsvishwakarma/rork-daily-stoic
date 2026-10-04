import SwiftUI
import RevenueCat

/// Profile: level, daily reminder settings, stats, reflections, and about.
struct ProfileView: View {
    @Environment(ContentStore.self) private var content
    @Environment(ProgressStore.self) private var progress
    @Environment(LifetimeStore.self) private var store

    @State private var reminderDate = defaultReminderDate
    @State private var showResetConfirmation = false
    @State private var showPaywall = false
    @State private var legalDocument: LegalView.Document?

    private static var defaultReminderDate: Date {
        Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    }

    var body: some View {
        ZStack {
            MarbleBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    levelCard
                    trialCard
                    reminderCard
                    statsCard
                    if !progress.sortedReflections.isEmpty {
                        reflectionsCard
                    }
                    aboutCard
                    resetButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .confirmationDialog(
            "Reset all progress? This cannot be undone.",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset everything", role: .destructive) {
                progress.resetAll()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showPaywall) {
            LifetimePaywallView(store: store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $legalDocument) { document in
            LegalView(document: document)
                .presentationDetents([.medium, .large])
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Trial & Lifetime

    /// Shows the free trial countdown while it runs, then the lifetime purchase
    /// option, then a quiet confirmation once unlocked.
    private var trialCard: some View {
        Group {
            if store.isLifetime {
                HStack(spacing: 14) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.bronze)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Theme.bronzeTint.opacity(0.7)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lifetime unlocked")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.charcoal)
                        Text("Every day of Unshaken is yours forever.")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.warmGray)
                    }
                    Spacer()
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface(cornerRadius: 24)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Free Trial")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.charcoal)
                        Spacer()
                        Text("\(daysLeft) day\(daysLeft == 1 ? "" : "s") left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(daysLeft <= 2 ? Theme.bronzeDeep : Theme.warmGray)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.sand)
                            Capsule()
                                .fill(Theme.bronze)
                                .frame(width: max(0, geo.size.width * CGFloat(progress.totalReads) / CGFloat(ProgressStore.freeTrialDays)))
                                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress.totalReads)
                        }
                    }
                    .frame(height: 8)

                    Text("\(progress.totalReads) of \(ProgressStore.freeTrialDays) free days used.")
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.warmGray)

                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Lifetime deal · \(priceText) once")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.bronze))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardSurface(cornerRadius: 24)
            }
        }
    }

    private var daysLeft: Int {
        max(0, ProgressStore.freeTrialDays - progress.totalReads)
    }

    private var priceText: String {
        store.lifetimePackage?.localizedPriceString ?? "$19.99"
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Profile")
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .foregroundStyle(Theme.charcoal)
            Text("Your practice, at a glance.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.warmGray)
        }
    }

    // MARK: - Level

    private var levelCard: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .strokeBorder(Theme.sand, lineWidth: 9)
                Circle()
                    .trim(from: 0, to: CGFloat(progress.xpIntoLevel) / CGFloat(progress.xpForNextLevel))
                    .stroke(Theme.bronze, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress.xpIntoLevel)
                VStack(spacing: 0) {
                    Text("LVL")
                        .font(.system(size: 11, weight: .bold))
                        .kerning(1)
                        .foregroundStyle(Theme.warmGray)
                    Text("\(progress.level)")
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundStyle(Theme.charcoal)
                }
            }
            .frame(width: 76, height: 76)

            VStack(alignment: .leading, spacing: 6) {
                Text(progress.tierName)
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(Theme.charcoal)
                Text("\(progress.xp) XP total · \(progress.xpForNextLevel - progress.xpIntoLevel) XP to next level")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.warmGray)
                Text("Read daily to rise from Seeker to Sage.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.muted)
            }
            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: 24)
    }

    // MARK: - Reminder

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Daily Reminder")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.charcoal)

            Toggle(isOn: Binding(
                get: { progress.state.reminderOn },
                set: { newValue in
                    progress.setReminder(on: newValue, hour: hour, minute: minute)
                    Task {
                        if newValue {
                            await ReminderScheduler.schedule(progress: progress, content: content)
                        } else {
                            ReminderScheduler.cancelAll()
                        }
                    }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Each morning")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.charcoal)
                    Text("A notification with the day's actual quote")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.warmGray)
                }
            }
            .tint(Theme.bronze)

            if progress.state.reminderOn {
                DatePicker(
                    "Time",
                    selection: $reminderDate,
                    displayedComponents: .hourAndMinute
                )
                .font(.system(size: 15))
                .tint(Theme.bronze)
                .onChange(of: reminderDate) { _, newValue in
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                    let hour = comps.hour ?? 8
                    let minute = comps.minute ?? 0
                    progress.setReminder(on: true, hour: hour, minute: minute)
                    Task {
                        await ReminderScheduler.schedule(progress: progress, content: content)
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: 24)
        .onAppear {
            reminderDate = Calendar.current.date(from: DateComponents(hour: progress.state.reminderHour, minute: progress.state.reminderMinute)) ?? Self.defaultReminderDate
        }
    }

    private var hour: Int { Calendar.current.dateComponents([.hour], from: reminderDate).hour ?? 8 }
    private var minute: Int { Calendar.current.dateComponents([.minute], from: reminderDate).minute ?? 0 }

    // MARK: - Stats

    private var statsCard: some View {
        VStack(spacing: 0) {
            statRow(symbol: "flame.fill", label: "Current streak", value: "\(progress.streak()) days")
            Divider().overlay(Theme.sand)
            statRow(symbol: "crown.fill", label: "Best streak", value: "\(progress.bestStreak) days")
            Divider().overlay(Theme.sand)
            statRow(symbol: "book.fill", label: "Entries read", value: "\(progress.totalReads)")
            Divider().overlay(Theme.sand)
            statRow(symbol: "text.bubble.fill", label: "Reflections", value: "\(progress.state.reflections.count)")
        }
        .padding(.vertical, 6)
        .cardSurface(cornerRadius: 24)
    }

    private func statRow(symbol: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.bronze)
                .frame(width: 30)
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(Theme.charcoal)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.warmGray)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    // MARK: - Reflections

    private var reflectionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reflections")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.charcoal)
            ForEach(progress.sortedReflections.prefix(8), id: \.key) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(displayDate(forKey: item.key))
                        .font(.system(size: 12, weight: .medium))
                        .kerning(0.5)
                        .foregroundStyle(Theme.muted)
                    Text(item.text)
                        .font(.system(size: 14, design: .serif))
                        .lineSpacing(4)
                        .foregroundStyle(Theme.charcoal)
                }
                .padding(.vertical, 4)
                if item.key != progress.sortedReflections.prefix(8).last?.key {
                    Divider().overlay(Theme.sand)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: 24)
    }

    private func displayDate(forKey key: String) -> String {
        guard let date = ProgressStore.date(fromKey: key) else { return key }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }

    // MARK: - About & Reset

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About Unshaken")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.charcoal)
            Text("One original reflection for every day of the year, each paired with a classical quote from Marcus Aurelius, Seneca, Epictetus and other Stoics in public-domain translations. Written to be read in two minutes and carried for a day.")
                .font(.system(size: 14))
                .lineSpacing(5)
                .foregroundStyle(Theme.warmGray)

            HStack(spacing: 20) {
                Button {
                    legalDocument = .terms
                } label: {
                    Text("Terms of Use")
                        .font(.system(size: 13, weight: .semibold))
                }
                Button {
                    legalDocument = .privacy
                } label: {
                    Text("Privacy Policy")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
            .tint(Theme.bronze)
            .padding(.top, 2)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface(cornerRadius: 24)
    }

    private var resetButton: some View {
        Button {
            showResetConfirmation = true
        } label: {
            Text("Reset all progress")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.bronzeDeep)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.bronzeTint.opacity(0.6)))
        }
        .buttonStyle(PressableButtonStyle())
    }
}
