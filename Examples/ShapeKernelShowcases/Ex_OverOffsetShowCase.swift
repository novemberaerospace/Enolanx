// Ex_OverOffsetShowCase.swift
// Genolanx — Port of LEAP71 ShapeKernel Ex_OverOffsetShowCase.cs
// SPDX-License-Identifier: CC0-1.0

import Foundation
import simd

enum OverOffsetShowCase {

    static func run(sceneManager: SceneManager) {
        sceneManager.log("OverOffsetShowCase: Starting...")
        Sh.resetGroupCounter()

        // Step 1: Generate two intersecting boxes
        let box1 = BaseBox(LocalFrame(), 10, 40, 30)
        let box2 = BaseBox(LocalFrame(), 40, 40, 10)
        let voxBox = box1.voxConstruct() + box2.voxConstruct()

        // Step 2: Apply fillet
        let voxFillet = voxBox.smoothened(3.0)

        // Step 3: Visualize
        DispatchQueue.main.async {
            Sh.previewVoxels(voxFillet, color: Cp.clrPitaya, sceneManager: sceneManager)
        }

        sceneManager.log("OverOffsetShowCase: Done!")
    }
}
