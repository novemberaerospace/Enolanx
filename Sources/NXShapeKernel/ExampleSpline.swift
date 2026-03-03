// ExampleSpline.swift
// Genolanx — Port of LEAP71 ShapeKernel ExampleSpline
// SPDX-License-Identifier: CC0-1.0

import Foundation
import simd

/// Example spline used by many ShapeKernel showcase examples.
/// Generates a smooth B-spline curve from a set of control points.
final class ExampleSpline: ISpline {

    private let spline: ControlPointSpline

    init() {
        let controlPoints: [SIMD3<Float>] = [
            SIMD3(0, 0, 0),
            SIMD3(0, 40, 0),
            SIMD3(0, 50, 20),
            SIMD3(0, 60, 60),
        ]
        spline = ControlPointSpline(points: controlPoints)
    }

    func pointAt(_ ratio: Float) -> SIMD3<Float> {
        spline.pointAt(ratio)
    }

    func getPoints(_ nSamples: UInt) -> [SIMD3<Float>] {
        spline.getPoints(nSamples)
    }
}
