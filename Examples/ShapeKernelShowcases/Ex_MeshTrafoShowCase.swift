// Ex_MeshTrafoShowCase.swift
// Genolanx — Port of LEAP71 ShapeKernel Ex_MeshTrafoShowCase.cs
// SPDX-License-Identifier: CC0-1.0

import Foundation
import simd

enum MeshTrafoShowCase {

    static func run(sceneManager: SceneManager) {
        sceneManager.log("MeshTrafoShowCase: Starting...")
        Sh.resetGroupCounter()

        // Step 1: Generate a simple box mesh
        let box = BaseBox(LocalFrame(position: SIMD3(0, 100, 0)), 50, 40, 30)
        let voxBox = box.voxConstruct()

        // Step 2: Apply a vertex-wise rotation transformation
        let voxTrafo = PicoGKVoxels()
        let mesh = voxBox.asMesh()
        let meshTrafo = PicoGKMesh()

        let triCount = mesh.triangleCount
        for i in 0..<triCount {
            let (a, b, c) = mesh.triangleVertices(at: i)
            let ra = fnRotate(a)
            let rb = fnRotate(b)
            let rc = fnRotate(c)
            meshTrafo.addTriangle(ra, rb, rc)
        }

        let voxTrafoResult = PicoGKVoxels(mesh: meshTrafo)

        // Step 3: Visualize both
        DispatchQueue.main.async {
            Sh.previewVoxels(voxBox, color: Cp.clrCopper, sceneManager: sceneManager)
            Sh.previewVoxels(voxTrafoResult, color: Cp.clrGold, sceneManager: sceneManager)
        }

        sceneManager.log("MeshTrafoShowCase: Done!")
    }

    /// Rotates point 45 degrees around Z axis.
    private static func fnRotate(_ pt: SIMD3<Float>) -> SIMD3<Float> {
        let axis = SIMD3<Float>(0, 0, 1)
        let dPhi = 45.0 / 180.0 * Float.pi
        return VecOp.rotateAroundAxis(point: pt, angle: dPhi, axis: axis)
    }
}
