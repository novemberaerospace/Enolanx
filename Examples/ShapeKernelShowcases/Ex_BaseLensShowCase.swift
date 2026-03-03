// Ex_BaseLensShowCase.swift
// Genolanx — Port of LEAP71 ShapeKernel Ex_BaseLensShowCase.cs
// SPDX-License-Identifier: CC0-1.0

import Foundation
import simd

enum BaseLensShowCase {

    static func run(sceneManager: SceneManager) {
        sceneManager.log("BaseLensShowCase: Starting...")
        Sh.resetGroupCounter()

        // 1. Basic lens
        do {
            let frame = LocalFrame(position: SIMD3(-50, -50, 0))
            let shape = BaseLens(frame: frame, topHeight: 10, bottomHeight: 10, radius: 40)
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrFrozen, sceneManager: sceneManager)
            }
            sceneManager.log("  Basic lens done.")
        }

        // 2. Modulated lens 0
        do {
            let frame = LocalFrame(position: SIMD3(50, 50, 0))
            let shape = BaseLens(frame: frame, topHeight: 10, bottomHeight: 10, radius: 40)
            shape.setHeight(
                top: SurfaceModulation { phi, radiusRatio in
                    5.0 - (12.0 + 3.0 * cos(5.0 * phi))
                },
                bottom: SurfaceModulation { phi, radiusRatio in
                    5.0 + (12.0 + 3.0 * cos(5.0 * phi))
                }
            )
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrPitaya, sceneManager: sceneManager)
            }
            sceneManager.log("  Modulated lens 0 done.")
        }

        // 3. Modulated lens 1
        do {
            let frame = LocalFrame(position: SIMD3(-50, 50, 0))
            let shape = BaseLens(frame: frame, topHeight: 10, bottomHeight: 10, radius: 40)
            shape.setHeight(
                top: SurfaceModulation { phi, radiusRatio in
                    5.0 - (12.0 + 3.0 * cos(5.0 * phi))
                },
                bottom: SurfaceModulation { phi, radiusRatio in
                    var p = phi + 0.3 * Float.pi * radiusRatio
                    return 5.0 + 1.0 * cos(6.0 * p) + 3.0 * cos(20.0 * radiusRatio)
                }
            )
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrWarning, sceneManager: sceneManager)
            }
            sceneManager.log("  Modulated lens 1 done.")
        }

        sceneManager.log("BaseLensShowCase: Done!")
    }
}
