// ImplicitShapes.swift
// Genolanx — Port of LEAP71 ShapeKernel implicit SDF shapes
// SPDX-License-Identifier: Apache-2.0

import Foundation
import simd

// MARK: - ImplicitSphere

/// Implicit sphere SDF: negative inside, positive outside.
struct ImplicitSphere {
    let center: SIMD3<Float>
    let radius: Float

    init(center: SIMD3<Float> = .zero, radius: Float = 10) {
        self.center = center
        self.radius = radius
    }

    func sdf(_ pt: SIMD3<Float>) -> Float {
        simd_length(pt - center) - radius
    }
}

// MARK: - ImplicitGyroid

/// Implicit gyroid TPMS pattern.
/// f(x,y,z) = sin(sx) * cos(sy) + sin(sy) * cos(sz) + sin(sz) * cos(sx) - threshold
struct ImplicitGyroid {
    let scale: Float
    let threshold: Float

    init(scale: Float = 3, threshold: Float = 1) {
        self.scale = scale
        self.threshold = threshold
    }

    func sdf(_ pt: SIMD3<Float>) -> Float {
        let s = scale
        let x = pt.x * s
        let y = pt.y * s
        let z = pt.z * s
        let val = sin(x) * cos(y) + sin(y) * cos(z) + sin(z) * cos(x)
        return abs(val) - threshold
    }
}

// MARK: - ImplicitGenus

/// Implicit genus surface (surface with holes).
/// f(x,y,z) = 2y(y^2 - 3x^2)(1-z^2) + (x^2+y^2)^2 - (9z^2-1)(1-z^2) - gap
struct ImplicitGenus {
    let gap: Float

    init(gap: Float = 0.3) {
        self.gap = gap
    }

    func sdf(_ pt: SIMD3<Float>) -> Float {
        let x = pt.x
        let y = pt.y
        let z = pt.z
        let x2 = x * x
        let y2 = y * y
        let z2 = z * z
        let val = 2.0 * y * (y2 - 3.0 * x2) * (1.0 - z2) + (x2 + y2) * (x2 + y2) - (9.0 * z2 - 1.0) * (1.0 - z2)
        return val - gap
    }
}

// MARK: - ImplicitSuperEllipsoid

/// Implicit super-ellipsoid shape.
/// See: https://en.wikipedia.org/wiki/Superellipsoid
struct ImplicitSuperEllipsoid {
    let center: SIMD3<Float>
    let ax: Float
    let ay: Float
    let az: Float
    let epsilon1: Float
    let epsilon2: Float

    init(center: SIMD3<Float>, ax: Float, ay: Float, az: Float,
         epsilon1: Float, epsilon2: Float) {
        self.center = center
        self.ax = ax
        self.ay = ay
        self.az = az
        self.epsilon1 = epsilon1
        self.epsilon2 = epsilon2
    }

    func sdf(_ pt: SIMD3<Float>) -> Float {
        let d = pt - center
        let xn = abs(d.x / ax)
        let yn = abs(d.y / ay)
        let zn = abs(d.z / az)

        let e1 = 2.0 / epsilon1
        let e2 = 2.0 / epsilon2

        let inner = pow(xn, e2) + pow(yn, e2)
        let outer = pow(inner, e1 / e2) + pow(zn, e1)
        return pow(outer, 1.0 / e1) - 1.0
    }
}
