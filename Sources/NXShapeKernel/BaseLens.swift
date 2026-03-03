// BaseLens.swift
// Genolanx — Port of LEAP71 ShapeKernel BaseLens
// SPDX-License-Identifier: Apache-2.0

import Foundation
import simd

final class BaseLens: BaseShape {

    private let frame: LocalFrame
    private let topHeight: Float
    private let bottomHeight: Float
    private let radius: Float
    private var topModulation: SurfaceModulation
    private var bottomModulation: SurfaceModulation

    /// Create a lens with top/bottom heights and outer radius.
    /// - Parameters:
    ///   - frame: local coordinate frame
    ///   - topHeight: height above center plane
    ///   - bottomHeight: height below center plane (positive value)
    ///   - radius: outer radius of the lens
    init(frame: LocalFrame, topHeight: Float = 10, bottomHeight: Float = 10, radius: Float = 40) {
        self.frame = frame
        self.topHeight = topHeight
        self.bottomHeight = bottomHeight
        self.radius = radius
        self.topModulation = SurfaceModulation(constant: topHeight)
        self.bottomModulation = SurfaceModulation(constant: bottomHeight)
    }

    func setHeight(top: SurfaceModulation, bottom: SurfaceModulation) {
        topModulation = top
        bottomModulation = bottom
    }

    override func constructVoxels() -> PicoGKVoxels {
        let margin: Float = 5
        let pos = frame.position
        let maxH = max(topHeight, bottomHeight) + 20
        let bounds = BBox3(
            min: pos - SIMD3(radius + margin, radius + margin, maxH + margin),
            max: pos + SIMD3(radius + margin, radius + margin, maxH + margin)
        )

        let c = pos
        let r = radius
        let topMod = topModulation
        let botMod = bottomModulation

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let dx = pt.x - c.x
            let dy = pt.y - c.y
            let dz = pt.z - c.z
            let rXY = sqrt(dx * dx + dy * dy)
            let phi = atan2(dy, dx)
            let radiusRatio = min(rXY / r, 1.0)

            // Outside radius
            if rXY > r { return rXY - r }

            // Elliptic profile: z limits scale with sqrt(1 - (r/R)^2)
            let elliptic = sqrt(max(0, 1.0 - radiusRatio * radiusRatio))
            let hTop = topMod.value(phi: phi, lengthRatio: radiusRatio) * elliptic
            let hBot = botMod.value(phi: phi, lengthRatio: radiusRatio) * elliptic

            if dz > hTop { return dz - hTop }
            if dz < -hBot { return -hBot - dz }
            return max(rXY - r, max(dz - hTop, -hBot - dz))
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }
}
