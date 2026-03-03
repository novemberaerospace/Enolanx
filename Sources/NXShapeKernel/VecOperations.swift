// VecOperations.swift
// Genolanx — Vector operation utilities (port of LEAP71 ShapeKernel VecOperations.cs)

import simd
import Foundation

enum VecOp {

    // MARK: - Cylindrical Coordinates

    /// Create a point from cylindrical coordinates (r, phi, z).
    static func cylindricalPoint(radius: Float, phi: Float, z: Float) -> SIMD3<Float> {
        SIMD3(radius * cos(phi), radius * sin(phi), z)
    }

    /// Get planar radius sqrt(x^2 + y^2).
    static func planarRadius(_ p: SIMD3<Float>) -> Float {
        sqrt(p.x * p.x + p.y * p.y)
    }

    /// Get azimuthal angle atan2(y, x).
    static func phi(_ p: SIMD3<Float>) -> Float {
        atan2(p.y, p.x)
    }

    // MARK: - Spherical Coordinates

    /// Create a point from spherical coordinates.
    static func sphericalPoint(radius: Float, phi: Float, theta: Float) -> SIMD3<Float> {
        let cosTheta = cos(theta)
        return SIMD3(
            radius * cos(phi) * cosTheta,
            radius * sin(phi) * cosTheta,
            radius * sin(theta)
        )
    }

    /// Get elevation angle (theta).
    static func theta(_ p: SIMD3<Float>) -> Float {
        atan2(p.z, planarRadius(p))
    }

    // MARK: - Normalization

    /// Safe normalization — returns zero if length < epsilon.
    static func safeNormalize(_ v: SIMD3<Float>) -> SIMD3<Float> {
        let len = simd_length(v)
        return len > 1e-10 ? v / len : .zero
    }

    /// Get an arbitrary orthogonal direction to a given direction.
    static func orthogonalDir(_ dir: SIMD3<Float>) -> SIMD3<Float> {
        let d = safeNormalize(dir)
        let ref: SIMD3<Float> = abs(simd_dot(d, SIMD3(1, 0, 0))) > 0.95
            ? SIMD3(0, 1, 0)
            : SIMD3(1, 0, 0)
        return safeNormalize(simd_cross(d, ref))
    }

    // MARK: - Rotation

    /// Rotate a point around an arbitrary axis by angle phi (radians).
    static func rotateAroundAxis(
        point: SIMD3<Float>,
        angle: Float,
        axis: SIMD3<Float>,
        origin: SIMD3<Float> = .zero
    ) -> SIMD3<Float> {
        let p = point - origin
        let q = simd_quatf(angle: angle, axis: safeNormalize(axis))
        return q.act(p) + origin
    }

    /// Rotate around Z axis.
    static func rotateAroundZ(point: SIMD3<Float>, angle: Float,
                               origin: SIMD3<Float> = .zero) -> SIMD3<Float> {
        rotateAroundAxis(point: point, angle: angle, axis: SIMD3(0, 0, 1), origin: origin)
    }

    // MARK: - Angles

    /// Unsigned angle between two vectors (radians).
    static func angleBetween(_ a: SIMD3<Float>, _ b: SIMD3<Float>) -> Float {
        let na = safeNormalize(a)
        let nb = safeNormalize(b)
        let d = simd_clamp(simd_dot(na, nb), -1.0, 1.0)
        return acos(d)
    }

    // MARK: - Frame Transformations

    /// Map a point from local frame coordinates to global.
    static func translatePointOntoFrame(_ frame: LocalFrame, point: SIMD3<Float>) -> SIMD3<Float> {
        frame.position
            + point.x * frame.localX
            + point.y * frame.localY
            + point.z * frame.localZ
    }

    /// Express a global point in frame-local coordinates.
    static func expressPointInFrame(_ frame: LocalFrame, point: SIMD3<Float>) -> SIMD3<Float> {
        let delta = point - frame.position
        return SIMD3(
            simd_dot(delta, frame.localX),
            simd_dot(delta, frame.localY),
            simd_dot(delta, frame.localZ)
        )
    }

    // MARK: - Interpolation

    /// Linear interpolation between two points.
    static func lerp(_ a: SIMD3<Float>, _ b: SIMD3<Float>, t: Float) -> SIMD3<Float> {
        a + t * (b - a)
    }

    // MARK: - Direction Alignment

    /// Return v or -v, whichever better aligns with target.
    static func flipForAlignment(_ v: SIMD3<Float>, target: SIMD3<Float>) -> SIMD3<Float> {
        simd_dot(v, target) >= 0 ? v : -v
    }
}
