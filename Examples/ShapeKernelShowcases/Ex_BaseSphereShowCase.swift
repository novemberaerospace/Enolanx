// Ex_BaseSphereShowCase.swift
// Genolanx — Port of LEAP71 ShapeKernel Ex_BaseSphereShowCase.cs
// SPDX-License-Identifier: CC0-1.0

import Foundation
import simd

enum BaseSphereShowCase {

    static func run(sceneManager: SceneManager) {
        sceneManager.log("BaseSphereShowCase: Starting...")
        Sh.resetGroupCounter()

        // 1. Basic sphere — direct mesh (no voxelization)
        do {
            let frame = LocalFrame(position: SIMD3(-100, 0, 0))
            let shape = BaseSphere(frame: frame, radius: 40)
            let mesh = shape.constructMesh()
            DispatchQueue.main.async {
                Sh.previewMesh(mesh, color: Cp.clrFrozen, sceneManager: sceneManager)
            }
            sceneManager.log("  Basic sphere done (direct mesh).")
        }

        // 2. Modulated sphere 0 (radius varies with phi) — direct mesh
        do {
            let frame = LocalFrame(position: SIMD3(0, 0, 0))
            let shape = BaseSphere(frame: frame)
            shape.setRadius(SurfaceModulation { theta, phi in
                40.0 - 10.0 * cos(6.0 * phi)
            })
            let mesh = shape.constructMesh()
            DispatchQueue.main.async {
                Sh.previewMesh(mesh, color: Cp.clrPitaya, sceneManager: sceneManager)
            }
            sceneManager.log("  Modulated sphere 0 done (direct mesh).")
        }

        // 3. Modulated sphere 1 (radius varies with theta + phi) — direct mesh + STL export
        do {
            let frame = LocalFrame(position: SIMD3(150, 0, 0))
            let shape = BaseSphere(frame: frame)
            shape.setRadius(SurfaceModulation { theta, phi in
                40.0 - 10.0 * cos(6.0 * phi) + 30.0 * cos(2.0 * theta)
            })
            let mesh = shape.constructMesh()
            DispatchQueue.main.async {
                Sh.previewMesh(mesh, color: Cp.clrWarning, sceneManager: sceneManager)
            }

            // Fast STL export: mesh direct, zero voxelization
            let path = ShExport.exportPath(filename: "BaseSphere_DirectMesh")
            sceneManager.exportSTL(mesh: mesh, to: path)
            sceneManager.log("  Modulated sphere 1 done (direct mesh + STL).")
        }

        sceneManager.log("BaseSphereShowCase: Done!")
    }
}
