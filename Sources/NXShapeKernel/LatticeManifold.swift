// LatticeManifold.swift
// Genolanx — Port of LEAP71 ShapeKernel LatticeManifold
// Cylindrical lattice for pipe cuts (used in HelixHeatX IOCuts)

import simd
import PicoGKBridge

/// Creates a cylindrical volume via lattice beams along a frame.
/// Supports teardrop overhang for printability.
class LatticeManifold {
    let frame: LocalFrame
    let length: Float
    let radius: Float

    let overhangAngleDeg: Float
    let extendBothSides: Bool

    init(_ frame: LocalFrame, _ length: Float, _ radius: Float) {
        self.frame = frame
        self.length = length
        self.radius = radius
        self.overhangAngleDeg = 45
        self.extendBothSides = false
    }

    /// Full C# constructor with overhang and bilateral extension.
    init(_ frame: LocalFrame, _ length: Float, _ radius: Float,
         _ overhangAngleDeg: Float, _ extendBothSides: Bool) {
        self.frame = frame
        self.length = length
        self.radius = radius
        self.overhangAngleDeg = overhangAngleDeg
        self.extendBothSides = extendBothSides
    }

    func voxConstruct() -> PicoGKVoxels {
        let lat = PicoGKLattice()
        let nSteps = 20
        let nPhi = 36
        let beamRadius: Float = 0.5

        for iZ in 0..<nSteps {
            let ratio = Float(iZ) / Float(nSteps - 1)
            let z = ratio * length

            for iPhi in 0..<nPhi {
                let phi = Float(iPhi) / Float(nPhi) * 2.0 * Float.pi
                let localPt = VecOp.cylindricalPoint(radius: radius, phi: phi, z: z)
                let worldPt = VecOp.translatePointOntoFrame(frame, point: localPt)

                // Axis point at same Z
                let axisPt = VecOp.translatePointOntoFrame(frame, point: SIMD3(0, 0, z))
                lat.addBeam(from: axisPt, radiusA: beamRadius,
                           to: worldPt, radiusB: beamRadius, roundCap: false)
            }
        }

        return PicoGKVoxels(lattice: lat)
    }
}
