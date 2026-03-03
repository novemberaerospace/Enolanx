// SuperShapes.swift
// Genolanx — Port of LEAP71 ShapeKernel Uf.fGetSuperShapeRadius (superformula)

import Foundation

/// Useful formulas namespace (matches C# Uf static class).
enum Uf {

    /// Named super-shape presets.
    enum ESuperShape {
        case round
        case hex
        case quad
        case tri
    }

    /// Super-shape radius for a named preset at angle phi.
    static func superShapeRadius(phi: Float, shape: ESuperShape) -> Float {
        switch shape {
        case .round:
            return 1.0
        case .hex:
            return superShapeRadius(phi: phi, m: 6, n1: 1000, n2: 1000, n3: 1000)
        case .quad:
            return superShapeRadius(phi: phi, m: 4, n1: 1000, n2: 1000, n3: 1000)
        case .tri:
            return superShapeRadius(phi: phi, m: 3, n1: 1000, n2: 1000, n3: 1000)
        }
    }

    /// Gielis superformula: r(phi) = ( |cos(m*phi/4)/a|^n2 + |sin(m*phi/4)/b|^n3 )^(-1/n1)
    /// With a=1, b=1 (standard).
    static func superShapeRadius(phi: Float, m: Float, n1: Float, n2: Float, n3: Float) -> Float {
        let a: Float = 1.0
        let b: Float = 1.0
        let angle = m * phi / 4.0
        let t1 = pow(abs(cos(angle) / a), n2)
        let t2 = pow(abs(sin(angle) / b), n3)
        let sum = t1 + t2
        guard sum > 1e-20 else { return 1.0 }
        return pow(sum, -1.0 / n1)
    }
}
