// BasePipeSegment.swift
// Genolanx — Port of LEAP71 ShapeKernel BasePipeSegment
// SPDX-License-Identifier: Apache-2.0

import Foundation
import simd

final class BasePipeSegment: BaseShape {

    enum EMethod { case midRange }

    private var frames: Frames
    private var innerRadiusModulation: SurfaceModulation
    private var outerRadiusModulation: SurfaceModulation
    private var phiMidModulation: LineModulation
    private var phiRangeModulation: LineModulation
    private let method: EMethod
    private var lengthSteps: UInt32 = 200
    private var polarSteps: UInt32 = 100

    /// Frame-based pipe segment.
    init(frame: LocalFrame, length: Float = 60, innerRadius: Float = 10, outerRadius: Float = 20,
         phiMid: LineModulation, phiRange: LineModulation, method: EMethod = .midRange) {
        self.frames = Frames(length: length, frame: frame)
        self.innerRadiusModulation = SurfaceModulation(constant: innerRadius)
        self.outerRadiusModulation = SurfaceModulation(constant: outerRadius)
        self.phiMidModulation = phiMid
        self.phiRangeModulation = phiRange
        self.method = method
    }

    /// Spline-based pipe segment.
    init(frames: Frames, innerRadius: Float = 10, outerRadius: Float = 20,
         phiMid: LineModulation, phiRange: LineModulation, method: EMethod = .midRange) {
        self.frames = frames
        self.innerRadiusModulation = SurfaceModulation(constant: innerRadius)
        self.outerRadiusModulation = SurfaceModulation(constant: outerRadius)
        self.phiMidModulation = phiMid
        self.phiRangeModulation = phiRange
        self.method = method
    }

    func setRadius(inner: SurfaceModulation, outer: SurfaceModulation) {
        innerRadiusModulation = inner
        outerRadiusModulation = outer
    }

    func setLengthSteps(_ n: UInt32) { lengthSteps = n }
    func setPolarSteps(_ n: UInt32) { polarSteps = n }

    override func constructVoxels() -> PicoGKVoxels {
        // Build mesh and voxelize
        let mesh = constructMesh()
        return PicoGKVoxels(mesh: mesh)
    }

    override func constructMesh() -> PicoGKMesh {
        let mesh = PicoGKMesh()
        let nLen = Int(lengthSteps)
        let nPol = Int(polarSteps)

        // Generate surface points for outer and inner walls
        var outerPts = [[SIMD3<Float>]](repeating: [SIMD3<Float>](repeating: .zero, count: nPol + 1), count: nLen + 1)
        var innerPts = [[SIMD3<Float>]](repeating: [SIMD3<Float>](repeating: .zero, count: nPol + 1), count: nLen + 1)

        for iLen in 0...nLen {
            let lr = Float(iLen) / Float(nLen)
            let localFrame = frames.frameAlongLength(lr)
            let phiMid = phiMidModulation.value(at: lr)
            let phiRange = phiRangeModulation.value(at: lr)
            let phiStart = phiMid - phiRange / 2.0
            let phiEnd = phiMid + phiRange / 2.0

            for iPol in 0...nPol {
                let pr = Float(iPol) / Float(nPol)
                let phi = phiStart + pr * (phiEnd - phiStart)

                let outerR = outerRadiusModulation.value(phi: phi, lengthRatio: lr)
                let innerR = innerRadiusModulation.value(phi: phi, lengthRatio: lr)

                let localDir = cos(phi) * localFrame.localX + sin(phi) * localFrame.localY
                outerPts[iLen][iPol] = localFrame.position + outerR * localDir
                innerPts[iLen][iPol] = localFrame.position + innerR * localDir
            }
        }

        // Triangulate outer surface
        for iLen in 0..<nLen {
            for iPol in 0..<nPol {
                let a = outerPts[iLen][iPol]
                let b = outerPts[iLen][iPol + 1]
                let c = outerPts[iLen + 1][iPol + 1]
                let d = outerPts[iLen + 1][iPol]
                mesh.addQuad(a, b, c, d)
            }
        }

        // Triangulate inner surface (reversed winding)
        for iLen in 0..<nLen {
            for iPol in 0..<nPol {
                let a = innerPts[iLen][iPol]
                let b = innerPts[iLen][iPol + 1]
                let c = innerPts[iLen + 1][iPol + 1]
                let d = innerPts[iLen + 1][iPol]
                mesh.addQuad(d, c, b, a)
            }
        }

        // Top cap
        for iPol in 0..<nPol {
            let a = outerPts[nLen][iPol]
            let b = outerPts[nLen][iPol + 1]
            let c = innerPts[nLen][iPol + 1]
            let d = innerPts[nLen][iPol]
            mesh.addQuad(a, b, c, d)
        }

        // Bottom cap
        for iPol in 0..<nPol {
            let a = outerPts[0][iPol]
            let b = outerPts[0][iPol + 1]
            let c = innerPts[0][iPol + 1]
            let d = innerPts[0][iPol]
            mesh.addQuad(d, c, b, a)
        }

        // Side caps (start and end phi edges)
        for iLen in 0..<nLen {
            let a = outerPts[iLen][0]
            let b = innerPts[iLen][0]
            let c = innerPts[iLen + 1][0]
            let d = outerPts[iLen + 1][0]
            mesh.addQuad(a, b, c, d)

            let e = outerPts[iLen][nPol]
            let f = innerPts[iLen][nPol]
            let g = innerPts[iLen + 1][nPol]
            let h = outerPts[iLen + 1][nPol]
            mesh.addQuad(h, g, f, e)
        }

        return mesh
    }
}
