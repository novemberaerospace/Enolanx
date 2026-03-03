// Ex_BaseRingShowCase.swift
// Genolanx — Port of LEAP71 ShapeKernel Ex_BaseRingShowCase.cs
// SPDX-License-Identifier: CC0-1.0

import Foundation
import simd

enum BaseRingShowCase {

    static func run(sceneManager: SceneManager) {
        sceneManager.log("BaseRingShowCase: Starting...")
        Sh.resetGroupCounter()

        // 1. Basic ring (torus)
        do {
            let frame = LocalFrame(position: SIMD3(-50, -50, 0))
            let shape = BaseRing(frame: frame, majorRadius: 30, tubeRadius: 8)
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrFrozen, sceneManager: sceneManager)
            }
            sceneManager.log("  Basic ring done.")
        }

        // 2. Modulated ring 0 (tube radius varies with phi)
        do {
            let frame = LocalFrame(position: SIMD3(-50, 50, 0))
            let shape = BaseRing(frame: frame, majorRadius: 30)
            shape.setRadius(SurfaceModulation { phi, _ in
                10.0 - 2.0 * cos(5.0 * phi)
            })
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrPitaya, sceneManager: sceneManager)
            }
            sceneManager.log("  Modulated ring 0 done.")
        }

        // 3. Modulated ring 1 (tube radius varies with alpha)
        do {
            let frame = LocalFrame(position: SIMD3(50, 50, 0))
            let shape = BaseRing(frame: frame, majorRadius: 30)
            shape.setRadius(SurfaceModulation { _, alpha in
                10.0 + 3.0 * cos(5.0 * alpha)
            })
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrWarning, sceneManager: sceneManager)
            }
            sceneManager.log("  Modulated ring 1 done.")
        }

        // 4. Modulated ring 2 (tube radius varies with phi + alpha)
        do {
            let frame = LocalFrame(position: SIMD3(50, -50, 0))
            let shape = BaseRing(frame: frame, majorRadius: 30)
            shape.setRadius(SurfaceModulation { phi, alpha in
                let p = phi + 1.0 * alpha
                return 10.0 - 2.0 * cos(5.0 * p) + 3.0 * cos(5.0 * alpha)
            })
            let vox = shape.constructVoxels()
            DispatchQueue.main.async {
                Sh.previewVoxels(vox, color: Cp.clrBlue, sceneManager: sceneManager)
            }
            sceneManager.log("  Modulated ring 2 done.")
        }

        sceneManager.log("BaseRingShowCase: Done!")
    }
}
