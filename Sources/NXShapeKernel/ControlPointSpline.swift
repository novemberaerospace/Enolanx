// ControlPointSpline.swift
// Genolanx — Port of LEAP71 ShapeKernel ControlPointSpline (B-spline)

import simd

/// Protocol for spline curves.
protocol ISpline {
    func getPoints(_ nSamples: UInt) -> [SIMD3<Float>]
    func pointAt(_ ratio: Float) -> SIMD3<Float>
}

/// B-spline with control points, open or closed ends.
class ControlPointSpline: ISpline {

    enum Ends { case open, closed }

    private let controlPoints: [SIMD3<Float>]
    private let knots: [Float]
    private let degree: Int
    private let ends: Ends

    init(points: [SIMD3<Float>], ends: Ends = .open, degree: Int = 2) {
        self.ends = ends
        self.degree = degree

        if ends == .closed {
            // Wrap control points for periodic spline
            var wrapped = points
            for i in 0..<degree {
                wrapped.append(points[i % points.count])
            }
            self.controlPoints = wrapped
        } else {
            self.controlPoints = points
        }

        // Build knot vector
        let n = self.controlPoints.count
        let k = degree + 1
        let numKnots = n + k

        var knotVec = [Float](repeating: 0, count: numKnots)

        if ends == .open {
            // Clamped knot vector: first k knots = 0, last k knots = 1
            for i in 0..<numKnots {
                if i < k {
                    knotVec[i] = 0
                } else if i >= n {
                    knotVec[i] = 1
                } else {
                    knotVec[i] = Float(i - degree) / Float(n - degree)
                }
            }
        } else {
            // Uniform knot vector for closed
            for i in 0..<numKnots {
                knotVec[i] = Float(i) / Float(numKnots - 1)
            }
        }

        self.knots = knotVec
    }

    func pointAt(_ ratio: Float) -> SIMD3<Float> {
        let t = simd_clamp(ratio, 0, 0.9999)

        // Map ratio to knot range
        let tMin = knots[degree]
        let tMax = knots[controlPoints.count]
        let u = tMin + t * (tMax - tMin)

        return deBoor(u: u)
    }

    func getPoints(_ nSamples: UInt) -> [SIMD3<Float>] {
        var result = [SIMD3<Float>]()
        result.reserveCapacity(Int(nSamples))
        for i in 0..<Int(nSamples) {
            let ratio = Float(i) / Float(nSamples - 1)
            result.append(pointAt(ratio))
        }
        return result
    }

    // MARK: - De Boor Algorithm

    private func deBoor(u: Float) -> SIMD3<Float> {
        let n = controlPoints.count
        let p = degree

        // Find knot span
        var k = p
        for i in p..<n {
            if u >= knots[i] && u < knots[i + 1] {
                k = i
                break
            }
        }

        // De Boor recursion
        var d = [SIMD3<Float>](repeating: .zero, count: p + 1)
        for j in 0...p {
            let idx = k - p + j
            if idx >= 0 && idx < n {
                d[j] = controlPoints[idx]
            }
        }

        for r in 1...p {
            for j in stride(from: p, through: r, by: -1) {
                let knotIdx = k - p + j
                let denom = knots[knotIdx + p - r + 1] - knots[knotIdx]
                let alpha: Float
                if abs(denom) < 1e-10 {
                    alpha = 0
                } else {
                    alpha = (u - knots[knotIdx]) / denom
                }
                d[j] = (1.0 - alpha) * d[j - 1] + alpha * d[j]
            }
        }

        return d[p]
    }
}
