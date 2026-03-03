// Ex_BaseBoxShowCase.swift
// Genolanx — Port of LEAP71 ShapeKernel Ex_BaseBoxShowCase.cs
// SPDX-License-Identifier: CC0-1.0

import Foundation
import simd

enum BaseBoxShowCase {

    static func run(sceneManager: SceneManager) {
        sceneManager.log("BaseBoxShowCase: Starting...")
        Sh.resetGroupCounter()

        // 1. Basic box
        do {
            let frame = LocalFrame(position: SIMD3(-50, 0, 0))
            let shape = BaseBox(frame, 20, 10, 15)
            let vox = shape.voxConstruct()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrBlue, sceneManager: sceneManager)
            }
            sceneManager.log("  Basic box done.")
        }

        // 2. Modulated box (width & depth vary along length)
        do {
            let frame = LocalFrame(position: SIMD3(50, 0, 0))
            let shape = BaseBox(frame, 20)
            shape.setWidth(LineModulation { lr in
                8.0 - 1.0 * cos(40.0 * lr)
            })
            shape.setDepth(LineModulation { lr in
                10.0 - 3.0 * cos(8.0 * lr)
            })
            let vox = shape.voxConstruct()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrGreen, sceneManager: sceneManager)
            }
            sceneManager.log("  Modulated box done.")
        }

        // 3. Modulated + spline-based box
        do {
            let spine = ExampleSpline()
            let frames = Frames(points: spine.getPoints(500), upVector: SIMD3(0, 1, 0))
            let shape = BaseBox(frames)
            shape.setWidth(LineModulation { lr in
                8.0 - 1.0 * cos(40.0 * lr)
            })
            shape.setDepth(LineModulation { lr in
                10.0 - 3.0 * cos(8.0 * lr)
            })
            let vox = shape.voxConstruct()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrYellow, sceneManager: sceneManager)
            }
            sceneManager.log("  Spline box done.")
        }

        sceneManager.log("BaseBoxShowCase: Done!")
    }
}
