// TangentialControlSpline.swift
// Genolanx — Port of LEAP71 ShapeKernel TangentialControlSpline

import simd

/// Spline with tangential control at start and end points.
/// Uses a ControlPointSpline internally with intermediate control points
/// derived from start/end directions and tangent strengths.
class TangentialControlSpline: ISpline {

    private let spline: ControlPointSpline

    init(start: SIMD3<Float>, end: SIMD3<Float>,
         startDir: SIMD3<Float>, endDir: SIMD3<Float>,
         tangentStrength1: Float, tangentStrength2: Float) {

        let d1 = VecOp.safeNormalize(startDir)
        let d2 = VecOp.safeNormalize(endDir)

        // Create 4 control points: start, start+tangent, end-tangent, end
        let cp1 = start + tangentStrength1 * d1
        let cp2 = end - tangentStrength2 * d2

        let points = [start, cp1, cp2, end]
        spline = ControlPointSpline(points: points, ends: .open, degree: 3)
    }

    func pointAt(_ ratio: Float) -> SIMD3<Float> {
        spline.pointAt(ratio)
    }

    func getPoints(_ nSamples: UInt) -> [SIMD3<Float>] {
        spline.getPoints(nSamples)
    }
}
