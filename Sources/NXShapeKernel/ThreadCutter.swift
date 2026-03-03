// ThreadCutter.swift
// Genolanx — Port of LEAP71 ConstructionModules ThreadCutter

import simd
import PicoGKBridge

/// Screw cutter: helical thread pattern for simulating post-production thread cuts.
class ThreadCutter {
    let frame: LocalFrame
    let length: Float
    let maxRadius: Float
    let coreRadius: Float
    let slope: Float

    init(_ frame: LocalFrame, _ length: Float, _ maxRadius: Float,
         _ coreRadius: Float, _ slope: Float) {
        self.frame = frame
        self.length = length
        self.maxRadius = maxRadius
        self.coreRadius = coreRadius
        self.slope = slope
    }

    func voxConstruct() -> PicoGKVoxels {
        // Core cylinder
        let core = BaseCylinder(frame: frame, length: length, radius: coreRadius)
        let voxCore = core.voxConstruct()

        // Bounding cylinder
        let bounding = BaseCylinder(frame: frame, length: length, radius: maxRadius)
        let voxBounding = bounding.voxConstruct()

        // Helical thread via lattice
        let turns = length / slope
        let beam1 = 0.5 * slope
        let beam2: Float = 0.1

        let lat = PicoGKLattice()
        var phi: Float = 0
        while phi <= turns * 2.0 * Float.pi {
            let dS = phi / (2.0 * Float.pi) * slope
            let relInner = VecOp.cylindricalPoint(radius: coreRadius, phi: phi, z: dS)
            let relOuter = VecOp.cylindricalPoint(radius: maxRadius, phi: phi, z: dS)
            let ptInner = VecOp.translatePointOntoFrame(frame, point: relInner)
            let ptOuter = VecOp.translatePointOntoFrame(frame, point: relOuter)
            lat.addBeam(from: ptInner, radiusA: beam1,
                       to: ptOuter, radiusB: beam2, roundCap: false)
            phi += 0.005
        }

        var voxThread = voxCore + PicoGKVoxels(lattice: lat)
        voxThread.boolIntersect(voxBounding)
        return voxThread
    }
}
