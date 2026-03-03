// LineModulation.swift
// Genolanx — 1D parametric modulation (port of LEAP71 ShapeKernel LineModulation)

import Foundation

final class LineModulation {
    typealias RatioFunc = (Float) -> Float

    private let func_: RatioFunc

    /// Constant value modulation.
    init(constant value: Float) {
        func_ = { _ in value }
    }

    /// Shorthand constant value (matches C# `new LineModulation(MathF.PI)`).
    init(_ value: Float) {
        func_ = { _ in value }
    }

    /// Function-based modulation.
    init(_ function: @escaping RatioFunc) {
        func_ = function
    }

    /// Discrete points with linear interpolation.
    /// Points are (x, y) pairs where x is the ratio [0,1] and y is the value.
    init(points: [(x: Float, y: Float)]) {
        // Sort and filter: keep only strictly increasing x values
        var filtered: [(x: Float, y: Float)] = []
        var lastX: Float = -Float.greatestFiniteMagnitude
        for p in points.sorted(by: { $0.x < $1.x }) {
            if p.x > lastX {
                filtered.append(p)
                lastX = p.x
            }
        }

        // Ensure coverage at 0.0 and 1.0
        if filtered.isEmpty {
            func_ = { _ in 0 }
            return
        }
        if filtered.first!.x > 0 {
            filtered.insert((x: 0, y: filtered.first!.y), at: 0)
        }
        if filtered.last!.x < 1.0 {
            filtered.append((x: 1.0, y: filtered.last!.y))
        }

        let xValues = filtered.map { $0.x }
        let yValues = filtered.map { $0.y }

        func_ = { ratio in
            let r = max(0, min(1, ratio))

            // Find interval
            for i in 1..<xValues.count {
                if r <= xValues[i] {
                    let span = xValues[i] - xValues[i - 1]
                    if span < 1e-10 { return yValues[i] }
                    let t = (r - xValues[i - 1]) / span
                    return yValues[i - 1] + t * (yValues[i] - yValues[i - 1])
                }
            }
            return yValues.last ?? 0
        }
    }

    /// Get modulated value at ratio [0, 1].
    func value(at ratio: Float) -> Float {
        func_(ratio)
    }

    // MARK: - Operators

    static func * (factor: Float, mod: LineModulation) -> LineModulation {
        LineModulation { ratio in factor * mod.value(at: ratio) }
    }

    static func + (lhs: LineModulation, rhs: LineModulation) -> LineModulation {
        LineModulation { ratio in lhs.value(at: ratio) + rhs.value(at: ratio) }
    }

    static func - (lhs: LineModulation, rhs: LineModulation) -> LineModulation {
        LineModulation { ratio in lhs.value(at: ratio) - rhs.value(at: ratio) }
    }
}
