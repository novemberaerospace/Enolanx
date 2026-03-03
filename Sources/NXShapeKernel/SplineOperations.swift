// SplineOperations.swift
// Genolanx — Port of LEAP71 ShapeKernel SplineOperations
// SPDX-License-Identifier: Apache-2.0

import Foundation
import simd

enum SplineOperations {

    /// Translate all points in a list by a given offset vector.
    static func translateList(_ points: [SIMD3<Float>], by offset: SIMD3<Float>) -> [SIMD3<Float>] {
        points.map { $0 + offset }
    }
}
