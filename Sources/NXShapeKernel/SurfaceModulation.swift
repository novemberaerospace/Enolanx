// SurfaceModulation.swift
// Genolanx — 2D parametric modulation (port of LEAP71 ShapeKernel SurfaceModulation)

import Foundation

final class SurfaceModulation {
    typealias RatioFunc = (Float, Float) -> Float

    private let func_: RatioFunc

    /// Constant value modulation.
    init(constant value: Float) {
        func_ = { _, _ in value }
    }

    /// Shorthand constant value modulation (matches C# `new SurfaceModulation(6f)`).
    init(_ value: Float) {
        func_ = { _, _ in value }
    }

    /// From LineModulation (matches C# `new SurfaceModulation(new LineModulation(...))`).
    init(_ lineMod: LineModulation) {
        func_ = { _, lengthRatio in lineMod.value(at: lengthRatio) }
    }

    /// Function-based 2D modulation: f(phi, lengthRatio) -> value.
    init(_ function: @escaping RatioFunc) {
        func_ = function
    }

    /// From LineModulation, projected onto one axis.
    /// - `.first`: value depends on phi (first parameter)
    /// - `.second`: value depends on lengthRatio (second parameter)
    init(line: LineModulation, axis: Axis = .second) {
        switch axis {
        case .first:
            func_ = { phi, _ in line.value(at: phi) }
        case .second:
            func_ = { _, lengthRatio in line.value(at: lengthRatio) }
        }
    }

    enum Axis {
        case first   // phi
        case second  // lengthRatio
    }

    /// Get modulated value at (phi, lengthRatio).
    func value(phi: Float, lengthRatio: Float) -> Float {
        func_(phi, lengthRatio)
    }

    // MARK: - Operators

    static func * (factor: Float, mod: SurfaceModulation) -> SurfaceModulation {
        SurfaceModulation { phi, lr in factor * mod.value(phi: phi, lengthRatio: lr) }
    }

    static func + (lhs: SurfaceModulation, rhs: SurfaceModulation) -> SurfaceModulation {
        SurfaceModulation { phi, lr in lhs.value(phi: phi, lengthRatio: lr) + rhs.value(phi: phi, lengthRatio: lr) }
    }

    static func - (lhs: SurfaceModulation, rhs: SurfaceModulation) -> SurfaceModulation {
        SurfaceModulation { phi, lr in lhs.value(phi: phi, lengthRatio: lr) - rhs.value(phi: phi, lengthRatio: lr) }
    }
}
