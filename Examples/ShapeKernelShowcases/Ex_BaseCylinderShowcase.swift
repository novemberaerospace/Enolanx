// Ex_BaseCylinderShowcase.swift
// Genolanx — Port of LEAP71 ShapeKernel Ex_BaseCylinderShowcase.cs
// SPDX-License-Identifier: CC0-1.0

import Foundation
import simd

enum BaseCylinderShowCase {

    static func run(sceneManager: SceneManager) {
        sceneManager.log("BaseCylinderShowCase: Starting...")
        Sh.resetGroupCounter()

        // 1. Basic cylinder
        do {
            let frame = LocalFrame(position: SIMD3(-50, 0, 0))
            let shape = BaseCylinder(frame: frame, length: 60, radius: 40)
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrBlue, sceneManager: sceneManager)
            }
            sceneManager.log("  Basic cylinder done.")
        }

        // 2. Modulated cylinder (radius varies along length)
        do {
            let frame = LocalFrame(position: SIMD3(50, 0, 0))
            let shape = BaseCylinder(frame: frame, length: 60, radius: 12)
            shape.setLengthSteps(500)
            shape.setRadius(SurfaceModulation(LineModulation { lr in
                10.0 - 3.0 * cos(8.0 * lr)
            }))
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrGreen, sceneManager: sceneManager)
            }
            sceneManager.log("  Modulated cylinder done.")
        }

        // 3. Modulated + spline-based cylinder
        do {
            let spine = ExampleSpline()
            let frames = Frames(points: spine.getPoints(500), upVector: SIMD3(0, 1, 0))
            let shape = BaseCylinder(frames: frames, radius: 12)
            shape.setRadius(SurfaceModulation { phi, _ in
                12.0 + 3.0 * cos(5.0 * phi)
            })
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrYellow, sceneManager: sceneManager)
            }
            sceneManager.log("  Spline cylinder done.")
        }

        sceneManager.log("BaseCylinderShowCase: Done!")
    }
}
