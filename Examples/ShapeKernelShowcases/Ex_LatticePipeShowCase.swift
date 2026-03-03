// Ex_LatticePipeShowCase.swift
// Genolanx — Port of LEAP71 ShapeKernel Ex_LatticePipeShowCase.cs
// SPDX-License-Identifier: CC0-1.0

import Foundation
import simd

enum LatticePipeShowCase {

    static func run(sceneManager: SceneManager) {
        sceneManager.log("LatticePipeShowCase: Starting...")
        Sh.resetGroupCounter()

        // 1. Basic lattice pipe
        do {
            let frame = LocalFrame(position: SIMD3(-50, 0, 0))
            let shape = LatticePipe(frame: frame, length: 60, radius: 10)
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrYellow, sceneManager: sceneManager)
            }
            sceneManager.log("  Basic lattice pipe done.")
        }

        // 2. Modulated lattice pipe (radius varies along length)
        do {
            let frame = LocalFrame(position: SIMD3(50, -50, 0))
            let shape = LatticePipe(frame: frame, length: 60)
            shape.setRadius(LineModulation { lr in
                10.0 - 3.0 * cos(8.0 * lr)
            })
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrFrozen, sceneManager: sceneManager)
            }
            sceneManager.log("  Modulated lattice pipe done.")
        }

        // 3. Spline-based lattice pipe with modulation
        do {
            let spine = ExampleSpline()
            let frames = Frames(points: spine.getPoints(500), upVector: SIMD3(0, 1, 0))
            let shape = LatticePipe(frames: frames)
            shape.setRadius(LineModulation { lr in
                10.0 - 3.0 * cos(8.0 * lr)
            })
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrRacingGreen, sceneManager: sceneManager)
            }
            sceneManager.log("  Spline lattice pipe done.")
        }

        // 4. Simple spline-based lattice pipe
        do {
            let spine = ExampleSpline()
            let pts = SplineOperations.translateList(spine.getPoints(500), by: 50 * SIMD3(1, 0, 0))
            let frames = Frames(points: pts, upVector: SIMD3(0, 1, 0))
            let shape = LatticePipe(frames: frames, radius: 5)
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrCopper, sceneManager: sceneManager)
            }
            sceneManager.log("  Simple spline lattice pipe done.")
        }

        sceneManager.log("LatticePipeShowCase: Done!")
    }
}
