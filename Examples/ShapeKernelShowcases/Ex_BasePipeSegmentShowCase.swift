// Ex_BasePipeSegmentShowCase.swift
// Genolanx — Port of LEAP71 ShapeKernel Ex_BasePipeSegmentShowCase.cs
// SPDX-License-Identifier: CC0-1.0

import Foundation
import simd

enum BasePipeSegmentShowCase {

    static func run(sceneManager: SceneManager) {
        sceneManager.log("BasePipeSegmentShowCase: Starting...")
        Sh.resetGroupCounter()

        // 1. Basic pipe segment
        do {
            let frame = LocalFrame(position: SIMD3(-50, 0, 0))
            let shape = BasePipeSegment(
                frame: frame, length: 60, innerRadius: 20, outerRadius: 40,
                phiMid: LineModulation(Float.pi),
                phiRange: LineModulation(0.5 * Float.pi))
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrBlue, sceneManager: sceneManager)
            }
            sceneManager.log("  Basic pipe segment done.")
        }

        // 2. Modulated phi range
        do {
            let frame = LocalFrame(position: SIMD3(-50, 50, 0))
            let shape = BasePipeSegment(
                frame: frame, length: 60, innerRadius: 2, outerRadius: 40,
                phiMid: LineModulation(Float.pi),
                phiRange: LineModulation { lr in
                    0.5 * Float.pi + 0.25 * Float.pi * cos(40.0 * lr)
                })
            shape.setLengthSteps(500)
            shape.setRadius(
                inner: SurfaceModulation(6.0),
                outer: SurfaceModulation(LineModulation { lr in
                    10.0 - 3.0 * cos(8.0 * lr)
                })
            )
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrCrystal, sceneManager: sceneManager)
            }
            sceneManager.log("  Modulated segment 0 done.")
        }

        // 3. Surface-modulated radii
        do {
            let frame = LocalFrame(position: SIMD3(0, -50, 0))
            let shape = BasePipeSegment(
                frame: frame, length: 60, innerRadius: 2, outerRadius: 40,
                phiMid: LineModulation(Float.pi),
                phiRange: LineModulation { lr in
                    0.5 * Float.pi + 0.25 * Float.pi * cos(8.0 * lr)
                })
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
            sceneManager.log("  Modulated segment 1 done.")
        }

        // 4. Rotating phi mid
        do {
            let frame = LocalFrame(position: SIMD3(50, -50, 0))
            let shape = BasePipeSegment(
                frame: frame, length: 60, innerRadius: 2, outerRadius: 40,
                phiMid: LineModulation { lr in
                    -1.0 * Float.pi * lr
                },
                phiRange: LineModulation(1.75 * Float.pi))
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
            sceneManager.log("  Modulated segment 2 done.")
        }

        // 5. Spline-based pipe segment
        do {
            let spine = ExampleSpline()
            let frames = Frames(points: spine.getPoints(500), upVector: SIMD3(0, 1, 0))
            let shape = BasePipeSegment(
                frames: frames, innerRadius: 2, outerRadius: 40,
                phiMid: LineModulation { lr in
                    4.0 * Float.pi * lr
                },
                phiRange: LineModulation(1.5 * Float.pi))
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
                Sh.previewVoxels(vox, color: Cp.clrRacingGreen, sceneManager: sceneManager)
            }
            sceneManager.log("  Spline segment done.")
        }

        // 6. Simple spline segment
        do {
            let spine = ExampleSpline()
            let pts = SplineOperations.translateList(spine.getPoints(500), by: 50 * SIMD3(1, 0, 0))
            let frames = Frames(points: pts, upVector: SIMD3(0, 1, 0))
            let shape = BasePipeSegment(
                frames: frames, innerRadius: 10, outerRadius: 12,
                phiMid: LineModulation { lr in
                    -1.0 * Float.pi * lr
                },
                phiRange: LineModulation(1.0 * Float.pi))
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrGray, sceneManager: sceneManager)
            }
            sceneManager.log("  Simple spline segment done.")
        }

        sceneManager.log("BasePipeSegmentShowCase: Done!")
    }
}
