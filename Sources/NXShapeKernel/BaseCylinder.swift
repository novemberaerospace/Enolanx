// BaseCylinder.swift
// Genolanx — Parametric cylinder (port of LEAP71 ShapeKernel BaseCylinder.cs)

import simd

final class BaseCylinder: BaseShape {
    var lengthSteps: UInt32 = 5
    var polarSteps: UInt32 = 360
    var radialSteps: UInt32 = 5
    var radiusModulation: SurfaceModulation
    let frames: Frames

    /// Simple cylinder: straight extrusion from frame.
    init(frame: LocalFrame, length: Float = 20, radius: Float = 10) {
        frames = Frames(length: length, frame: frame)
        radiusModulation = SurfaceModulation(constant: radius)
        super.init()
    }

    /// Spline-based cylinder along provided frames.
    init(frames: Frames, radius: Float = 10) {
        self.frames = frames
        radiusModulation = SurfaceModulation(constant: radius)
        lengthSteps = 500
        super.init()
    }

    // MARK: - Settings

    func setRadius(_ mod: SurfaceModulation) {
        radiusModulation = mod
    }

    func setLengthSteps(_ n: UInt32) { lengthSteps = max(5, n) }
    func setPolarSteps(_ n: UInt32) { polarSteps = max(5, n) }
    func setRadialSteps(_ n: UInt32) { radialSteps = max(5, n) }

    // MARK: - Surface Point

    /// Compute a surface point given parametric coordinates.
    /// - lengthRatio: [0, 1] along spine
    /// - phiRatio: [0, 1] around circumference (0 = 0°, 1 = 360°)
    /// - radiusRatio: [0, 1] from axis to surface (0 = center, 1 = surface)
    func surfacePoint(lengthRatio: Float, phiRatio: Float, radiusRatio: Float) -> SIMD3<Float> {
        let phi = 2.0 * Float.pi * phiRatio
        let spinePos = frames.spineAlongLength(lengthRatio)
        let lx = frames.localXAlongLength(lengthRatio)
        let ly = frames.localYAlongLength(lengthRatio)

        let fullRadius = radiusModulation.value(phi: phi, lengthRatio: lengthRatio)
        let r = radiusRatio * fullRadius

        let pt = spinePos + r * cos(phi) * lx + r * sin(phi) * ly
        return transformation(pt)
    }

    // MARK: - Mesh Construction

    override func constructMesh() -> PicoGKMesh {
        let mesh = PicoGKMesh()
        addTopSurface(mesh: mesh, flipped: false)
        addOuterMantle(mesh: mesh, flipped: false)
        addBottomSurface(mesh: mesh, flipped: true)
        return mesh
    }

    private func addTopSurface(mesh: PicoGKMesh, flipped: Bool) {
        let lr: Float = 1.0
        for iPhi in 1..<polarSteps {
            for iR in 1..<radialSteps {
                let pr0 = Float(iPhi - 1) / Float(polarSteps - 1)
                let pr1 = Float(iPhi) / Float(polarSteps - 1)
                let rr0 = Float(iR - 1) / Float(radialSteps - 1)
                let rr1 = Float(iR) / Float(radialSteps - 1)

                let v0 = surfacePoint(lengthRatio: lr, phiRatio: pr0, radiusRatio: rr0)
                let v1 = surfacePoint(lengthRatio: lr, phiRatio: pr1, radiusRatio: rr0)
                let v2 = surfacePoint(lengthRatio: lr, phiRatio: pr1, radiusRatio: rr1)
                let v3 = surfacePoint(lengthRatio: lr, phiRatio: pr0, radiusRatio: rr1)

                let n0 = mesh.addVertex(v0)
                let n1 = mesh.addVertex(v1)
                let n2 = mesh.addVertex(v2)
                let n3 = mesh.addVertex(v3)
                mesh.addQuad(n0, n1, n2, n3, flipped: flipped)
            }
        }
    }

    private func addBottomSurface(mesh: PicoGKMesh, flipped: Bool) {
        let lr: Float = 0.0
        for iPhi in 1..<polarSteps {
            for iR in 1..<radialSteps {
                let pr0 = Float(iPhi - 1) / Float(polarSteps - 1)
                let pr1 = Float(iPhi) / Float(polarSteps - 1)
                let rr0 = Float(iR - 1) / Float(radialSteps - 1)
                let rr1 = Float(iR) / Float(radialSteps - 1)

                let v0 = surfacePoint(lengthRatio: lr, phiRatio: pr0, radiusRatio: rr0)
                let v1 = surfacePoint(lengthRatio: lr, phiRatio: pr1, radiusRatio: rr0)
                let v2 = surfacePoint(lengthRatio: lr, phiRatio: pr1, radiusRatio: rr1)
                let v3 = surfacePoint(lengthRatio: lr, phiRatio: pr0, radiusRatio: rr1)

                let n0 = mesh.addVertex(v0)
                let n1 = mesh.addVertex(v1)
                let n2 = mesh.addVertex(v2)
                let n3 = mesh.addVertex(v3)
                mesh.addQuad(n0, n1, n2, n3, flipped: flipped)
            }
        }
    }

    private func addOuterMantle(mesh: PicoGKMesh, flipped: Bool) {
        let rr: Float = 1.0
        for iPhi in 1..<polarSteps {
            for iL in 1..<lengthSteps {
                let pr0 = Float(iPhi - 1) / Float(polarSteps - 1)
                let pr1 = Float(iPhi) / Float(polarSteps - 1)
                let lr0 = Float(iL - 1) / Float(lengthSteps - 1)
                let lr1 = Float(iL) / Float(lengthSteps - 1)

                let v0 = surfacePoint(lengthRatio: lr0, phiRatio: pr0, radiusRatio: rr)
                let v1 = surfacePoint(lengthRatio: lr0, phiRatio: pr1, radiusRatio: rr)
                let v2 = surfacePoint(lengthRatio: lr1, phiRatio: pr1, radiusRatio: rr)
                let v3 = surfacePoint(lengthRatio: lr1, phiRatio: pr0, radiusRatio: rr)

                let n0 = mesh.addVertex(v0)
                let n1 = mesh.addVertex(v1)
                let n2 = mesh.addVertex(v2)
                let n3 = mesh.addVertex(v3)
                mesh.addQuad(n0, n1, n2, n3, flipped: flipped)
            }
        }
    }
}
