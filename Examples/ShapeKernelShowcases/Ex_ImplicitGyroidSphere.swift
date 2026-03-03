// Ex_ImplicitGyroidSphere.swift
// Genolanx — Port of LEAP71 ShapeKernel Ex_ImplicitGyroidSphere.cs
// SPDX-License-Identifier: CC0-1.0

import Foundation
import simd

enum ImplicitGyroidSphereShowCase {

    static func run(sceneManager: SceneManager) {
        sceneManager.log("ImplicitGyroidSphere: Starting...")
        Sh.resetGroupCounter()

        let center = SIMD3<Float>.zero
        let radius: Float = 10.0

        // SDFs
        let sphere = ImplicitSphere(center: center, radius: radius)
        let gyroid = ImplicitGyroid(scale: 3, threshold: 1)

        let bounds = BBox3(
            min: 1.2 * SIMD3(-radius, -radius, -radius),
            max: 1.2 * SIMD3(radius, radius, radius)
        )

        // Render sphere
        let voxSphere = PicoGKVoxels()
        voxSphere.renderImplicit({ pt in sphere.sdf(pt) }, bounds: bounds)

        // Intersect sphere with gyroid
        let voxGyroidSphere = PicoGKVoxels()
        voxGyroidSphere.renderImplicit({ pt in
            max(sphere.sdf(pt), gyroid.sdf(pt))
        }, bounds: bounds)

        // Visualize
        DispatchQueue.main.async {
            Sh.previewVoxels(voxGyroidSphere, color: Cp.clrGold, sceneManager: sceneManager)
            Sh.previewVoxels(voxSphere, color: Cp.clrCrystal, sceneManager: sceneManager)
        }

        sceneManager.log("ImplicitGyroidSphere: Done!")
    }
}
