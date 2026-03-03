// Ex_BasicLattices.swift
// Genolanx — Port of LEAP71 ShapeKernel Ex_BasicLattices.cs
// SPDX-License-Identifier: CC0-1.0

import Foundation
import simd

enum BasicLatticesShowCase {

    static func run(sceneManager: SceneManager) {
        sceneManager.log("BasicLatticesShowCase: Starting...")
        Sh.resetGroupCounter()

        let lattice = PicoGKLattice()

        // Add node (sphere)
        let pt0 = SIMD3<Float>(1, 5, -10)
        let r0: Float = 5
        lattice.addSphere(center: pt0, radius: r0)

        // Add beams (smooth and linear interpolation)
        let pt1 = SIMD3<Float>(5, 3, 0)
        let r1: Float = 1
        let pt2 = SIMD3<Float>(-3, 0, 7)
        let r2: Float = 3
        lattice.addBeam(from: pt1, radiusA: r1, to: pt2, radiusB: r2, roundCap: true)
        lattice.addBeam(from: pt1, radiusA: r1, to: pt2, radiusB: r2, roundCap: false)

        DispatchQueue.main.async {
            Sh.previewLattice(lattice, color: Cp.clrBlue, sceneManager: sceneManager)
        }
        sceneManager.log("BasicLatticesShowCase: Done!")
    }
}
