// ScrewHole.swift
// Genolanx — Port of LEAP71 ConstructionModules ScrewHole

import simd
import PicoGKBridge

/// Dummy screw shape for cutting material where screws will be placed.
class ScrewHole {
    let frame: LocalFrame
    let length: Float
    let coreRadius: Float
    let headLength: Float
    let headRadius: Float

    init(_ frame: LocalFrame, _ length: Float, _ coreRadius: Float,
         _ headLength: Float, _ headRadius: Float) {
        self.frame = frame
        self.length = length
        self.coreRadius = coreRadius
        self.headLength = headLength
        self.headRadius = headRadius
    }

    func voxConstruct() -> PicoGKVoxels {
        let lat = PicoGKLattice()
        let dir = frame.localZ

        // Head
        let pt1 = frame.position
        let pt0 = pt1 + dir * headLength

        // Thread
        let pt2 = frame.position - dir * length
        let pt3 = pt2 - dir * (2.0 * coreRadius)

        lat.addBeam(from: pt0, radiusA: headRadius,
                    to: pt1, radiusB: headRadius, roundCap: false)
        lat.addBeam(from: pt2, radiusA: coreRadius,
                    to: pt1, radiusB: coreRadius, roundCap: false)
        lat.addBeam(from: pt2, radiusA: coreRadius,
                    to: pt3, radiusB: 0.1, roundCap: true)

        return PicoGKVoxels(lattice: lat)
    }
}
