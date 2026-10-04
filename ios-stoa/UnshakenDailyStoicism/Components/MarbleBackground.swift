import SwiftUI

/// Warm ivory canvas with faint blurred marble veining, drawn procedurally
/// with a fixed seed so it is stable across renders.
struct MarbleBackground: View {
    var body: some View {
        Canvas { context, size in
            var generator = SeededRandom(seed: 20260928)
            var ctx = context
            ctx.addFilter(.blur(radius: 16))
            for _ in 0..<11 {
                let startX = generator.next(in: -size.width * 0.4...size.width * 1.4)
                let startY = generator.next(in: -40...size.height)
                let endX = startX + generator.next(in: -size.width * 0.5...size.width * 0.9)
                let endY = startY + generator.next(in: size.height * 0.2...size.height * 0.8)
                let c1 = CGPoint(x: startX + generator.next(in: -200...200), y: startY + generator.next(in: -200...200))
                let c2 = CGPoint(x: endX + generator.next(in: -200...200), y: endY + generator.next(in: -200...200))

                var path = Path()
                path.move(to: CGPoint(x: startX, y: startY))
                path.addCurve(to: CGPoint(x: endX, y: endY), control1: c1, control2: c2)
                let width = generator.next(in: 10...26)
                ctx.stroke(
                    path,
                    with: .color(Theme.warmGray.opacity(0.055)),
                    style: StrokeStyle(lineWidth: width, lineCap: .round)
                )
            }
        }
        .background(Theme.canvas)
        .ignoresSafeArea()
    }
}

/// Small deterministic random source for stable procedural drawing.
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed &* 6364136223846793005 &+ 1442695040888963407
    }

    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(UInt64.max >> 11)
    }

    mutating func next(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + next() * (range.upperBound - range.lowerBound)
    }
}
