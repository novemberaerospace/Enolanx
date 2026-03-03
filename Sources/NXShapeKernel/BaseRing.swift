// BaseRing.swift
// Genolanx — Port of LEAP71 ShapeKernel BaseRing (torus)
// SPDX-License-Identifier: Apache-2.0

import Foundation
import simd

final class BaseRing: BaseShape {

    private let frame: LocalFrame
    private let majorRadius: Float
    private var tubeRadiusModulation: SurfaceModulation

    /// Create a torus ring.
    /// - Parameters:
    ///   - frame: local coordinate frame
    ///   - majorRadius: distance from center to tube center
    ///   - tubeRadius: radius of the tube cross-section
    init(frame: LocalFrame, majorRadius: Float = 30, tubeRadius: Float = 8) {
        self.frame = frame
        self.majorRadius = majorRadius
        self.tubeRadiusModulation = SurfaceModulation(constant: tubeRadius)
    }

    func setRadius(_ mod: SurfaceModulation) {
        tubeRadiusModulation = mod
    }

    override func constructVoxels() -> PicoGKVoxels {
        let maxTube: Float = 20
        let margin: Float = 5
        let pos = frame.position
        let extent = majorRadius + maxTube + margin
        let bounds = BBox3(
            min: pos - SIMD3(extent, extent, maxTube + margin),
            max: pos + SIMD3(extent, extent, maxTube + margin)
        )

        let c = pos
        let R = majorRadius
        let tubeMod = tubeRadiusModulation

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let dx = pt.x - c.x
            let dy = pt.y - c.y
            let dz = pt.z - c.z

            let rXY = sqrt(dx * dx + dy * dy)
            let phi = atan2(dy, dx)

            // Distance from tube center circle
            let distFromRing = sqrt((rXY - R) * (rXY - R) + dz * dz)

            // Alpha: angle around the tube cross-section
            let alpha = atan2(dz, rXY - R)

            let tubeR = tubeMod.value(phi: phi, lengthRatio: alpha)
            return distFromRing - tubeR
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }
}
