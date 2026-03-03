// BaseBox.swift
// Genolanx — Port of LEAP71 ShapeKernel BaseBox (box via implicit SDF)

import simd
import PicoGKBridge

class BaseBox {
    let frame: LocalFrame
    private(set) var length: Float  // along frame Z
    private(set) var width: Float   // along frame X
    private(set) var depth: Float   // along frame Y

    private var frames: Frames?
    private var widthModulation: LineModulation?
    private var depthModulation: LineModulation?

    init(_ frame: LocalFrame, _ length: Float, _ width: Float, _ depth: Float) {
        self.frame = frame
        self.length = length
        self.width = width
        self.depth = depth
    }

    /// Constant-size box extruded along length.
    init(_ frame: LocalFrame, _ length: Float) {
        self.frame = frame
        self.length = length
        self.width = 10
        self.depth = 10
    }

    /// Spline-based box: extruded along a frame sequence.
    init(_ frames: Frames) {
        self.frame = LocalFrame()
        self.length = 0
        self.width = 10
        self.depth = 10
        self.frames = frames
    }

    func setWidth(_ mod: LineModulation) { widthModulation = mod }
    func setDepth(_ mod: LineModulation) { depthModulation = mod }

    func voxConstruct() -> PicoGKVoxels {
        if let frames = frames {
            return constructSplinedBox(frames)
        }
        return constructBasicBox()
    }

    private func constructBasicBox() -> PicoGKVoxels {
        let halfL = length / 2.0
        let f = frame

        let wMod = widthModulation
        let dMod = depthModulation
        let baseW = width
        let baseD = depth

        // Compute bounding box in global coordinates
        let maxW = max(baseW, 20.0)
        let maxD = max(baseD, 20.0)
        let corners: [SIMD3<Float>] = [
            VecOp.translatePointOntoFrame(f, point: SIMD3(-maxW, -maxD, -halfL)),
            VecOp.translatePointOntoFrame(f, point: SIMD3( maxW, -maxD, -halfL)),
            VecOp.translatePointOntoFrame(f, point: SIMD3(-maxW,  maxD, -halfL)),
            VecOp.translatePointOntoFrame(f, point: SIMD3( maxW,  maxD, -halfL)),
            VecOp.translatePointOntoFrame(f, point: SIMD3(-maxW, -maxD,  halfL)),
            VecOp.translatePointOntoFrame(f, point: SIMD3( maxW, -maxD,  halfL)),
            VecOp.translatePointOntoFrame(f, point: SIMD3(-maxW,  maxD,  halfL)),
            VecOp.translatePointOntoFrame(f, point: SIMD3( maxW,  maxD,  halfL)),
        ]

        var bMin = corners[0]
        var bMax = corners[0]
        for c in corners {
            bMin = simd_min(bMin, c)
            bMax = simd_max(bMax, c)
        }
        let margin: Float = 2.0
        let bounds = BBox3(min: bMin - SIMD3(repeating: margin),
                           max: bMax + SIMD3(repeating: margin))

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let local = VecOp.expressPointInFrame(f, point: pt)
            let lr = (local.z + halfL) / (2.0 * halfL)
            let halfW = (wMod?.value(at: lr) ?? baseW) / 2.0
            let halfD = (dMod?.value(at: lr) ?? baseD) / 2.0
            let dx = abs(local.x) - halfW
            let dy = abs(local.y) - halfD
            let dz = abs(local.z) - halfL
            return max(dx, max(dy, dz))
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }

    private func constructSplinedBox(_ frames: Frames) -> PicoGKVoxels {
        let mesh = PicoGKMesh()
        let nLen = 200
        let wMod = widthModulation
        let dMod = depthModulation
        let baseW = width
        let baseD = depth

        // Generate grid of surface points
        var pts = [[SIMD3<Float>]](repeating: [SIMD3<Float>](repeating: .zero, count: 5), count: nLen + 1)

        for iLen in 0...nLen {
            let lr = Float(iLen) / Float(nLen)
            let localFrame = frames.frameAlongLength(lr)
            let halfW = (wMod?.value(at: lr) ?? baseW) / 2.0
            let halfD = (dMod?.value(at: lr) ?? baseD) / 2.0
            let pos = localFrame.position
            let lx = localFrame.localX
            let ly = localFrame.localY

            pts[iLen][0] = pos - halfW * lx - halfD * ly
            pts[iLen][1] = pos + halfW * lx - halfD * ly
            pts[iLen][2] = pos + halfW * lx + halfD * ly
            pts[iLen][3] = pos - halfW * lx + halfD * ly
            pts[iLen][4] = pts[iLen][0]  // close loop
        }

        // Triangulate 4 faces
        for iLen in 0..<nLen {
            for iFace in 0..<4 {
                let a = pts[iLen][iFace]
                let b = pts[iLen][iFace + 1]
                let c = pts[iLen + 1][iFace + 1]
                let d = pts[iLen + 1][iFace]
                mesh.addQuad(a, b, c, d)
            }
        }

        // End caps
        mesh.addQuad(pts[0][3], pts[0][2], pts[0][1], pts[0][0])
        mesh.addQuad(pts[nLen][0], pts[nLen][1], pts[nLen][2], pts[nLen][3])

        return PicoGKVoxels(mesh: mesh)
    }
}
