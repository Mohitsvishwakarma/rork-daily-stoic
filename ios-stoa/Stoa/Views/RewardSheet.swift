import SwiftUI

/// Celebration sheet shown when a day is completed: streak medallion,
/// XP earned, and an optional evening reflection.
struct RewardSheet: View {
    let info: RewardInfo
    let onDone: () -> Void

    @Environment(ProgressStore.self) private var progress
    @Environment(\.dismiss) private var dismiss

    @State private var reflection: String = ""
    @State private var appeared = false

    var body: some View {
        ZStack {
            MarbleBackground()
            ScrollView {
                VStack(spacing: 18) {
                    medallion
                        .padding(.top, 28)

                    VStack(spacing: 6) {
                        Text("Day complete")
                            .font(.system(size: 30, weight: .semibold, design: .serif))
                            .foregroundStyle(Theme.charcoal)
                        Text("+\(info.xpEarned) XP")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.bronze)
                        Text(info.extended ? "Streak extended" : "Streak started")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.warmGray)
                    }

                    reflectionField

                    Button {
                        progress.saveReflection(reflection, for: info.dayKey)
                        onDone()
                    } label: {
                        Text("Done")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.bronze))
                    }
                    .buttonStyle(PressableButtonStyle())
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .onAppear {
            reflection = progress.state.reflections[info.dayKey] ?? ""
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                appeared = true
            }
        }
    }

    // MARK: - Medallion

    private var medallion: some View {
        ZStack {
            Circle()
                .strokeBorder(Theme.bronze.opacity(0.35), lineWidth: 1.5)
                .frame(width: 212, height: 212)
            Circle()
                .fill(Theme.bronze)
                .frame(width: 182, height: 182)
                .shadow(color: Theme.bronzeDeep.opacity(0.35), radius: 20, x: 0, y: 12)
            Image(systemName: "laurel.leading")
                .font(.system(size: 42))
                .foregroundStyle(Theme.bronzeTint.opacity(0.9))
                .offset(x: -52)
            Image(systemName: "laurel.trailing")
                .font(.system(size: 42))
                .foregroundStyle(Theme.bronzeTint.opacity(0.9))
                .offset(x: 52)
            VStack(spacing: 0) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.bronzeTint)
                Text("\(info.streakAfter)")
                    .font(.system(size: 54, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                Text("days")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.bronzeTint)
            }
        }
        .scaleEffect(appeared ? 1 : 0.6)
        .opacity(appeared ? 1 : 0)
        .overlay { FallingLeaves().allowsHitTesting(false) }
    }

    // MARK: - Reflection

    private var reflectionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surface)

                if reflection.isEmpty {
                    Text("Tonight, ask: what did I do well today?")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.warmGray)
                        .padding(16)
                        .allowsHitTesting(false)
                }

                TextField("", text: $reflection, axis: .vertical)
                    .lineLimit(2...4)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.charcoal)
                    .tint(Theme.bronze)
                    .padding(16)
                    .accessibilityLabel("Tonight, ask: what did I do well today?")
            }
            .onSubmit {
                progress.saveReflection(reflection, for: info.dayKey)
            }
            Text("Optional. Saved to your Profile.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .padding(.horizontal, 4)
        }
    }
}

/// Gentle bronze leaves drifting down over the medallion.
private struct FallingLeaves: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                var generator = SeededRandom(seed: 13)
                for index in 0..<10 {
                    let speed = generator.next(in: 0.05...0.11)
                    let offset = generator.next()
                    let phase = (time * speed + offset).truncatingRemainder(dividingBy: 1)
                    let x = size.width * (0.08 + 0.84 * generator.next())
                        + CGFloat(sin(time * 1.4 + Double(index))) * 14
                    let y = size.height * CGFloat(phase * 0.55)
                    let side = CGFloat(generator.next(in: 6...10))
                    let rotation = Angle.degrees(generator.next(in: 0...360) + time * 40)

                    var ctx = context
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: rotation)
                    let leaf = Path(ellipseIn: CGRect(x: -side / 2, y: -side / 4, width: side, height: side / 2))
                    ctx.fill(leaf, with: .color(Theme.bronze.opacity(0.3)))
                }
            }
        }
        .frame(width: 320, height: 340)
    }
}
