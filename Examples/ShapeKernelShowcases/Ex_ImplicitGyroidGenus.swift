// Ex_ImplicitGyroidGenus.swift
// Genolanx — Port of LEAP71 ShapeKernel Ex_ImplicitGyroidGenus.cs
// SPDX-License-Identifier: CC0-1.0

import Foundation
import simd

enum ImplicitGyroidGenusShowCase {

    static func run(sceneManager: SceneManager) {
        sceneManager.log("ImplicitGyroidGenus: Starting...")
        sceneManager.log("  Note: genus shape is small. Use voxel size 0.01mm for best resolution.")
        Sh.resetGroupCounter()

        let gap: Float = 0.3
        let extent: Float = 2.5

        // Step 1: generate genus SDF
        let genus = ImplicitGenus(gap: gap)

        // Step 2: bounding box
        let bounds = BBox3(
            min: 1.2 * SIMD3(-extent, -extent, -extent + 1.5),
            max: 1.2 * SIMD3(extent, extent, extent - 1.5)
        )

        // Step 3: render genus into voxels
        let voxGenus = PicoGKVoxels()
        voxGenus.renderImplicit({ pt in genus.sdf(pt) }, bounds: bounds)

        // Step 4: intersect with gyroid pattern
        let gyroid = ImplicitGyroid(scale: 1, threshold: 0.5)
        let voxGyroidGenus = PicoGKVoxels()
        voxGyroidGenus.renderImplicit({ pt in
            max(genus.sdf(pt), gyroid.sdf(pt))
        }, bounds: bounds)

        // Step 5: visualize
        DispatchQueue.main.async {
            Sh.previewVoxels(voxGyroidGenus, color: Cp.clrGold, sceneManager: sceneManager)
            Sh.previewVoxels(voxGenus, color: Cp.clrCrystal, sceneManager: sceneManager)
        }

        sceneManager.log("ImplicitGyroidGenus: Done!")
    }
}
