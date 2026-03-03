// Ex_BasePipeShowCase.swift
// Genolanx — Port of LEAP71 ShapeKernel Ex_BasePipeShowCase.cs
// SPDX-License-Identifier: CC0-1.0

import Foundation
import simd

enum BasePipeShowCase {

    static func run(sceneManager: SceneManager) {
        sceneManager.log("BasePipeShowCase: Starting...")
        Sh.resetGroupCounter()

        // 1. Basic pipe
        do {
            let frame = LocalFrame(position: SIMD3(-50, 0, 0))
            let shape = BasePipe(frame: frame, length: 60, innerRadius: 10, outerRadius: 20)
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrBlue, sceneManager: sceneManager)
            }
            sceneManager.log("  Basic pipe done.")
        }

        // 2. Modulated pipe 0 (inner constant, outer varies along length)
        do {
            let frame = LocalFrame(position: SIMD3(50, -50, 0))
            let shape = BasePipe(frame: frame, length: 60, innerRadius: 2, outerRadius: 40)
            shape.setLengthSteps(500)
            shape.setRadius(
                inner: SurfaceModulation(6.0),
                outer: SurfaceModulation(LineModulation { lr in
                    10.0 - 3.0 * cos(8.0 * lr)
                })
            )
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrGreen, sceneManager: sceneManager)
            }
            sceneManager.log("  Modulated pipe 0 done.")
        }

        // 3. Modulated pipe 1 (both radii vary with phi)
        do {
            let frame = LocalFrame(position: SIMD3(-50, -50, 0))
            let shape = BasePipe(frame: frame, length: 60, innerRadius: 2, outerRadius: 40)
            shape.setLengthSteps(500)
            shape.setRadius(
                inner: SurfaceModulation { phi, _ in
                    8.0 + 5.0 * cos(5.0 * phi)
                },
                outer: SurfaceModulation { phi, _ in
                    12.0 + 3.0 * cos(5.0 * phi)
                }
            )
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrYellow, sceneManager: sceneManager)
            }
            sceneManager.log("  Modulated pipe 1 done.")
        }

        // 4. Modulated pipe 2 (radii vary with phi + length)
        do {
            let frame = LocalFrame(position: SIMD3(0, -50, 0))
            let shape = BasePipe(frame: frame, length: 60, innerRadius: 2, outerRadius: 40)
            shape.setLengthSteps(500)
            shape.setRadius(
                inner: SurfaceModulation { phi, lr in
                    var p = phi + 1.0 * Float.pi * lr
                    return 9.0 - 1.0 * cos(3.0 * p) + 7.0 * lr
                },
                outer: SurfaceModulation { phi, lr in
                    var p = phi + 1.0 * Float.pi * lr
                    return 10.0 - 2.0 * cos(3.0 * p) + 9.0 * lr
                }
            )
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrRed, sceneManager: sceneManager)
            }
            sceneManager.log("  Modulated pipe 2 done.")
        }

        // 5. Spline-based pipe with modulation
        do {
            let spine = ExampleSpline()
            let frames = Frames(points: spine.getPoints(500), upVector: SIMD3(0, 1, 0))
            let shape = BasePipe(frames: frames, innerRadius: 2, outerRadius: 40)
            shape.setRadius(
                inner: SurfaceModulation { phi, _ in
                    8.0 + 5.0 * cos(5.0 * phi)
                },
                outer: SurfaceModulation { phi, _ in
                    12.0 + 3.0 * cos(5.0 * phi)
                }
            )
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrCopper, sceneManager: sceneManager)
            }
            sceneManager.log("  Spline pipe done.")
        }

        // 6. Simple spline-based pipe
        do {
            let spine = ExampleSpline()
            let pts = SplineOperations.translateList(spine.getPoints(500), by: 50 * SIMD3(1, 0, 0))
            let frames = Frames(points: pts, upVector: SIMD3(0, 1, 0))
            let shape = BasePipe(frames: frames, innerRadius: 10, outerRadius: 12)
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrToothpaste, sceneManager: sceneManager)
            }
            sceneManager.log("  Simple spline pipe done.")
        }

        sceneManager.log("BasePipeShowCase: Done!")
    }
}
