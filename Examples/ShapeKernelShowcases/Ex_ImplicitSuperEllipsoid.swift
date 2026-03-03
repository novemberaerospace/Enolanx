// Ex_ImplicitSuperEllipsoid.swift
// Genolanx — Port of LEAP71 ShapeKernel Ex_ImplicitSuperEllipsoid.cs
// SPDX-License-Identifier: CC0-1.0

import Foundation
import simd

enum ImplicitSuperEllipsoidShowCase {

    static func run(sceneManager: SceneManager) {
        sceneManager.log("ImplicitSuperEllipsoid: Starting...")
        sceneManager.log("  Note: ellipsoid shapes are small. Use voxel size 0.01mm for best resolution.")
        Sh.resetGroupCounter()

        // 1. Ellipsoid with epsilon1=3.0, epsilon2=0.25
        do {
            let center = SIMD3<Float>(0, 0, 0)
            let ax: Float = 1, ay: Float = 1, az: Float = 1
            let e1: Float = 3.0, e2: Float = 0.25

            let ellipsoid = ImplicitSuperEllipsoid(center: center, ax: ax, ay: ay, az: az,
                                                    epsilon1: e1, epsilon2: e2)
            let bounds = BBox3(
                min: SIMD3(-ax + center.x, -ay + center.y, -az + center.z),
                max: SIMD3( ax + center.x,  ay + center.y,  az + center.z)
            )

            let vox = PicoGKVoxels()
            vox.renderImplicit({ pt in ellipsoid.sdf(pt) }, bounds: bounds)
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrRed, sceneManager: sceneManager)
            }
            sceneManager.log("  Ellipsoid 1 done (e1=3.0, e2=0.25).")
        }

        // 2. Ellipsoid with epsilon1=1.5, epsilon2=1.5
        do {
            let center = SIMD3<Float>(-4, 0, 0)
            let ax: Float = 1, ay: Float = 1, az: Float = 1
            let e1: Float = 1.5, e2: Float = 1.5

            let ellipsoid = ImplicitSuperEllipsoid(center: center, ax: ax, ay: ay, az: az,
                                                    epsilon1: e1, epsilon2: e2)
            let bounds = BBox3(
                min: SIMD3(-ax + center.x, -ay + center.y, -az + center.z),
                max: SIMD3( ax + center.x,  ay + center.y,  az + center.z)
            )

            let vox = PicoGKVoxels()
            vox.renderImplicit({ pt in ellipsoid.sdf(pt) }, bounds: bounds)
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrBlue, sceneManager: sceneManager)
            }
            sceneManager.log("  Ellipsoid 2 done (e1=1.5, e2=1.5).")
        }

        // 3. Ellipsoid with epsilon1=0.25, epsilon2=0.25
        do {
            let center = SIMD3<Float>(4, 0, 0)
            let ax: Float = 1, ay: Float = 1, az: Float = 1
            let e1: Float = 0.25, e2: Float = 0.25

            let ellipsoid = ImplicitSuperEllipsoid(center: center, ax: ax, ay: ay, az: az,
                                                    epsilon1: e1, epsilon2: e2)
            let bounds = BBox3(
                min: SIMD3(-ax + center.x, -ay + center.y, -az + center.z),
                max: SIMD3( ax + center.x,  ay + center.y,  az + center.z)
            )

            let vox = PicoGKVoxels()
            vox.renderImplicit({ pt in ellipsoid.sdf(pt) }, bounds: bounds)
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrPitaya, sceneManager: sceneManager)
            }
            sceneManager.log("  Ellipsoid 3 done (e1=0.25, e2=0.25).")
        }

        sceneManager.log("ImplicitSuperEllipsoid: Done!")
    }
}
