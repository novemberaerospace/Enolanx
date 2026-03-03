// Frames.swift
// Genolanx — Spine frame sequence (port of LEAP71 ShapeKernel Frames.cs)

import simd

final class Frames {
    private var points: [SIMD3<Float>]
    private var localXs: [SIMD3<Float>]
    private var localYs: [SIMD3<Float>]
    private var localZs: [SIMD3<Float>]

    /// Straight extrusion: frame extruded along its Z-axis for given length.
    init(length: Float, frame: LocalFrame) {
        let start = frame.position
        let end = start + length * frame.localZ

        // Minimum 2 points
        let nPoints = max(2, Int(ceil(length / 1.0))) // ~1mm spacing
        points = (0..<nPoints).map { i in
            let t = Float(i) / Float(nPoints - 1)
            return VecOp.lerp(start, end, t: t)
        }

        localXs = [SIMD3<Float>](repeating: frame.localX, count: nPoints)
        localYs = [SIMD3<Float>](repeating: frame.localY, count: nPoints)
        localZs = [SIMD3<Float>](repeating: frame.localZ, count: nPoints)
    }

    /// Spline extrusion with constant frame orientation.
    init(points: [SIMD3<Float>], frame: LocalFrame) {
        self.points = points
        let n = points.count
        localXs = [SIMD3<Float>](repeating: frame.localX, count: n)
        localYs = [SIMD3<Float>](repeating: frame.localY, count: n)
        localZs = [SIMD3<Float>](repeating: frame.localZ, count: n)
    }

    /// Spline extrusion with Frenet-like frames derived from point tangents and an up vector.
    /// Port of C# constructor: new Frames(aPoints, vecUpVector).
    init(points: [SIMD3<Float>], upVector: SIMD3<Float>) {
        self.points = points
        let n = points.count
        localXs = [SIMD3<Float>](repeating: .zero, count: n)
        localYs = [SIMD3<Float>](repeating: .zero, count: n)
        localZs = [SIMD3<Float>](repeating: .zero, count: n)

        for i in 0..<n {
            // Tangent direction (localZ)
            let tangent: SIMD3<Float>
            if i == 0 && n > 1 {
                tangent = VecOp.safeNormalize(points[1] - points[0])
            } else if i == n - 1 && n > 1 {
                tangent = VecOp.safeNormalize(points[n - 1] - points[n - 2])
            } else if n > 2 {
                tangent = VecOp.safeNormalize(points[i + 1] - points[i - 1])
            } else {
                tangent = SIMD3(0, 0, 1)
            }

            let localX = VecOp.safeNormalize(simd_cross(upVector, tangent))
            let localY = VecOp.safeNormalize(simd_cross(tangent, localX))

            localZs[i] = tangent
            localXs[i] = localX
            localYs[i] = localY
        }
    }

    // MARK: - Interpolation Along Length

    /// Get position along spine at ratio [0, 1].
    func spineAlongLength(_ ratio: Float) -> SIMD3<Float> {
        interpolate(array: points, at: ratio)
    }

    /// Get local X-axis at ratio [0, 1].
    func localXAlongLength(_ ratio: Float) -> SIMD3<Float> {
        VecOp.safeNormalize(interpolate(array: localXs, at: ratio))
    }

    /// Get local Y-axis at ratio [0, 1].
    func localYAlongLength(_ ratio: Float) -> SIMD3<Float> {
        VecOp.safeNormalize(interpolate(array: localYs, at: ratio))
    }

    /// Get local Z-axis at ratio [0, 1].
    func localZAlongLength(_ ratio: Float) -> SIMD3<Float> {
        VecOp.safeNormalize(interpolate(array: localZs, at: ratio))
    }

    /// Get full local frame at ratio [0, 1].
    func frameAlongLength(_ ratio: Float) -> LocalFrame {
        LocalFrame(
            position: spineAlongLength(ratio),
            localZ: localZAlongLength(ratio),
            localX: localXAlongLength(ratio)
        )
    }

    // MARK: - Internal

    private func interpolate(array: [SIMD3<Float>], at ratio: Float) -> SIMD3<Float> {
        let t = max(0, min(1, ratio))
        let n = array.count
        guard n > 1 else { return array.first ?? .zero }

        let fIndex = t * Float(n - 1)
        let i0 = min(Int(fIndex), n - 2)
        let i1 = i0 + 1
        let frac = fIndex - Float(i0)

        return VecOp.lerp(array[i0], array[i1], t: frac)
    }
}
