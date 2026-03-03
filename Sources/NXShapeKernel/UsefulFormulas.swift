// UsefulFormulas.swift
// Genolanx — Port of LEAP71 ShapeKernel Uf.fTransFixed / fTransSmooth

import simd

extension Uf {

    /// Smooth transition from `from` to `to` over ratio [0..1].
    /// Uses cubic Hermite smoothstep: 3t² - 2t³ (matches B-spline 4-point behaviour).
    static func transFixed(from: Float, to: Float, ratio: Float) -> Float {
        let t = simd_clamp(ratio, 0, 1)
        let s = t * t * (3.0 - 2.0 * t) // smoothstep
        return from + s * (to - from)
    }

    /// Vector version of transFixed.
    static func transFixed(from: SIMD3<Float>, to: SIMD3<Float>, ratio: Float) -> SIMD3<Float> {
        let t = simd_clamp(ratio, 0, 1)
        let s = t * t * (3.0 - 2.0 * t)
        return from + s * (to - from)
    }

    /// Smooth transition using tanh (C# fTransSmooth).
    /// Maps ratio [0..1] -> smooth [from..to] with steepness control.
    static func transSmooth(from: Float, to: Float, ratio: Float, steepness: Float = 6.0) -> Float {
        let t = simd_clamp(ratio, 0, 1)
        let x = steepness * (2.0 * t - 1.0)
        let s = (tanh(x) + 1.0) * 0.5
        return from + s * (to - from)
    }

    /// Clamp a value to [min, max].
    static func clamp(_ v: Float, _ lo: Float, _ hi: Float) -> Float {
        simd_clamp(v, lo, hi)
    }
}
