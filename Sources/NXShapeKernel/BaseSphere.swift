// BaseSphere.swift
// Genolanx — Port of LEAP71 ShapeKernel BaseSphere
// SPDX-License-Identifier: Apache-2.0

import Foundation
import simd

final class BaseSphere: BaseShape {

    private let frame: LocalFrame
    private var radiusModulation: SurfaceModulation
    private var thetaSteps: UInt32 = 100
    private var phiSteps: UInt32 = 100

    init(frame: LocalFrame, radius: Float = 40) {
        self.frame = frame
        self.radiusModulation = SurfaceModulation(constant: radius)
    }

    func setRadius(_ mod: SurfaceModulation) {
        radiusModulation = mod
    }

    func setThetaSteps(_ n: UInt32) { thetaSteps = n }
    func setPhiSteps(_ n: UInt32) { phiSteps = n }

    override func constructVoxels() -> PicoGKVoxels {
        let maxR: Float = 80
        let margin: Float = 5
        let pos = frame.position
        let bounds = BBox3(
            min: pos - SIMD3(repeating: maxR + margin),
            max: pos + SIMD3(repeating: maxR + margin)
        )

        let mod = radiusModulation
        let c = pos

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let d = pt - c
            let r = simd_length(d)
            if r < 0.0001 { return -1.0 }
            let theta = acos(max(-1, min(1, d.z / r)))
            let phi = atan2(d.y, d.x)
            let targetR = mod.value(phi: theta, lengthRatio: phi)
            return r - targetR
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }

    // MARK: - Direct Mesh (UV-sphere tessellation, bypasses PicoGK voxelization)

    override func constructMesh() -> PicoGKMesh {
        let mesh = PicoGKMesh()
        let pos = frame.position
        let nTheta = Int(thetaSteps)
        let nPhi = Int(phiSteps)

        // Surface point from spherical coordinates — same parametric space as the SDF.
        func pt(theta: Float, phi: Float) -> SIMD3<Float> {
            let r = radiusModulation.value(phi: theta, lengthRatio: phi)
            return transformation(pos + SIMD3(
                r * sin(theta) * cos(phi),
                r * sin(theta) * sin(phi),
                r * cos(theta)
            ))
        }

        // North pole (theta = 0)
        let northPole = mesh.addVertex(pt(theta: 0, phi: 0))

        // Ring vertices: theta indices 1..<nTheta
        var rings = [[Int32]]()
        rings.reserveCapacity(nTheta - 1)
        for iTheta in 1..<nTheta {
            let theta = Float(iTheta) / Float(nTheta) * .pi
            var ring = [Int32]()
            ring.reserveCapacity(nPhi)
            for iPhi in 0..<nPhi {
                let phi = Float(iPhi) / Float(nPhi) * 2.0 * .pi
                ring.append(mesh.addVertex(pt(theta: theta, phi: phi)))
            }
            rings.append(ring)
        }

        // South pole (theta = π)
        let southPole = mesh.addVertex(pt(theta: .pi, phi: 0))

        // North cap: triangles from pole to first ring
        if let first = rings.first {
            for iPhi in 0..<nPhi {
                let next = (iPhi + 1) % nPhi
                mesh.addTriangle(northPole, first[iPhi], first[next])
            }
        }

        // Middle bands: quads between consecutive rings
        for iRing in 0..<(rings.count - 1) {
            let r0 = rings[iRing]
            let r1 = rings[iRing + 1]
            for iPhi in 0..<nPhi {
                let next = (iPhi + 1) % nPhi
                mesh.addQuad(r0[iPhi], r0[next], r1[next], r1[iPhi])
            }
        }

        // South cap: triangles from last ring to pole
        if let last = rings.last {
            for iPhi in 0..<nPhi {
                let next = (iPhi + 1) % nPhi
                mesh.addTriangle(last[iPhi], southPole, last[next])
            }
        }

        return mesh
    }
}
