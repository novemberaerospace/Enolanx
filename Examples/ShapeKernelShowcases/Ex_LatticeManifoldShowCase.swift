// Ex_LatticeManifoldShowCase.swift
// Genolanx — Port of LEAP71 ShapeKernel Ex_LatticeManifoldShowCase.cs
// SPDX-License-Identifier: CC0-1.0

import Foundation
import simd

enum LatticeManifoldShowCase {

    static func run(sceneManager: SceneManager) {
        sceneManager.log("LatticeManifoldShowCase: Starting...")
        Sh.resetGroupCounter()

        // 1. 45-degree overhang, single-sided
        do {
            let frame = LocalFrame(position: SIMD3(-50, 0, 0), localZ: SIMD3(0, 1, 0))
            let shape = LatticeManifold(frame, 50, 5, 45, false)
            let vox = shape.voxConstruct()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrYellow, sceneManager: sceneManager)
            }
            sceneManager.log("  Manifold 1 done (45 deg, one-sided).")
        }

        // 2. 30-degree overhang, both sides
        do {
            let frame = LocalFrame(position: SIMD3(0, 0, 0), localZ: SIMD3(0, 1, 0))
            let shape = LatticeManifold(frame, 50, 10, 30, true)
            let vox = shape.voxConstruct()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrCrystal, sceneManager: sceneManager)
            }
            sceneManager.log("  Manifold 2 done (30 deg, both-sided).")
        }

        // 3. 60-degree overhang, both sides
        do {
            let frame = LocalFrame(position: SIMD3(50, 0, 0), localZ: SIMD3(0, 1, 0))
            let shape = LatticeManifold(frame, 50, 5, 60, true)
            let vox = shape.voxConstruct()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrGreen, sceneManager: sceneManager)
            }
            sceneManager.log("  Manifold 3 done (60 deg, both-sided).")
        }

        sceneManager.log("LatticeManifoldShowCase: Done!")
    }
}
