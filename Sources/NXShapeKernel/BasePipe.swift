// BasePipe.swift
// Genolanx — Parametric hollow pipe (port of LEAP71 ShapeKernel BasePipe.cs)

import simd

final class BasePipe: BaseShape {
    var lengthSteps: UInt32 = 5
    var polarSteps: UInt32 = 360
    var radialSteps: UInt32 = 5
    var outerRadiusModulation: SurfaceModulation
    var innerRadiusModulation: SurfaceModulation
    let frames: Frames

    /// Simple pipe: straight extrusion from frame.
    init(frame: LocalFrame, length: Float = 20,
         innerRadius: Float = 10, outerRadius: Float = 20) {
        frames = Frames(length: length, frame: frame)
        innerRadiusModulation = SurfaceModulation(constant: innerRadius)
        outerRadiusModulation = SurfaceModulation(constant: outerRadius)
        super.init()
    }

    /// Spline-based pipe along provided frames.
    init(frames: Frames, innerRadius: Float = 10, outerRadius: Float = 20) {
        self.frames = frames
        innerRadiusModulation = SurfaceModulation(constant: innerRadius)
        outerRadiusModulation = SurfaceModulation(constant: outerRadius)
        lengthSteps = 500
        super.init()
    }

    // MARK: - Settings

    func setRadius(inner: SurfaceModulation, outer: SurfaceModulation) {
        innerRadiusModulation = inner
        outerRadiusModulation = outer
    }

    func setLengthSteps(_ n: UInt32) { lengthSteps = max(5, n) }
    func setPolarSteps(_ n: UInt32) { polarSteps = max(5, n) }
    func setRadialSteps(_ n: UInt32) { radialSteps = max(5, n) }

    // MARK: - Surface Point

    /// Compute a surface point.
    /// - radiusRatio: 0 = inner surface, 1 = outer surface
    func surfacePoint(lengthRatio: Float, phiRatio: Float, radiusRatio: Float) -> SIMD3<Float> {
        let phi = 2.0 * Float.pi * phiRatio
        let spinePos = frames.spineAlongLength(lengthRatio)
        let lx = frames.localXAlongLength(lengthRatio)
        let ly = frames.localYAlongLength(lengthRatio)

        let outerR = outerRadiusModulation.value(phi: phi, lengthRatio: lengthRatio)
        let innerR = innerRadiusModulation.value(phi: phi, lengthRatio: lengthRatio)
        let r = innerR + radiusRatio * (outerR - innerR)

        let pt = spinePos + r * cos(phi) * lx + r * sin(phi) * ly
        return transformation(pt)
    }

    // MARK: - Mesh Construction

    override func constructMesh() -> PicoGKMesh {
        let mesh = PicoGKMesh()
        addSurface(mesh: mesh, lengthRatio: 1.0, flipped: false)   // Top cap
        addSurface(mesh: mesh, lengthRatio: 0.0, flipped: true)    // Bottom cap
        addMantle(mesh: mesh, radiusRatio: 0.0, flipped: false)    // Inner wall
        addMantle(mesh: mesh, radiusRatio: 1.0, flipped: true)     // Outer wall
        return mesh
    }

    private func addSurface(mesh: PicoGKMesh, lengthRatio: Float, flipped: Bool) {
        for iPhi in 1..<polarSteps {
            for iR in 1..<radialSteps {
                let pr0 = Float(iPhi - 1) / Float(polarSteps - 1)
                let pr1 = Float(iPhi) / Float(polarSteps - 1)
                let rr0 = Float(iR - 1) / Float(radialSteps - 1)
                let rr1 = Float(iR) / Float(radialSteps - 1)

                let v0 = surfacePoint(lengthRatio: lengthRatio, phiRatio: pr0, radiusRatio: rr0)
                let v1 = surfacePoint(lengthRatio: lengthRatio, phiRatio: pr1, radiusRatio: rr0)
                let v2 = surfacePoint(lengthRatio: lengthRatio, phiRatio: pr1, radiusRatio: rr1)
                let v3 = surfacePoint(lengthRatio: lengthRatio, phiRatio: pr0, radiusRatio: rr1)

                let n0 = mesh.addVertex(v0)
                let n1 = mesh.addVertex(v1)
                let n2 = mesh.addVertex(v2)
                let n3 = mesh.addVertex(v3)
                mesh.addQuad(n0, n1, n2, n3, flipped: flipped)
            }
        }
    }

    private func addMantle(mesh: PicoGKMesh, radiusRatio: Float, flipped: Bool) {
        for iPhi in 1..<polarSteps {
            for iL in 1..<lengthSteps {
                let pr0 = Float(iPhi - 1) / Float(polarSteps - 1)
                let pr1 = Float(iPhi) / Float(polarSteps - 1)
                let lr0 = Float(iL - 1) / Float(lengthSteps - 1)
                let lr1 = Float(iL) / Float(lengthSteps - 1)

                let v0 = surfacePoint(lengthRatio: lr0, phiRatio: pr0, radiusRatio: radiusRatio)
                let v1 = surfacePoint(lengthRatio: lr0, phiRatio: pr1, radiusRatio: radiusRatio)
                let v2 = surfacePoint(lengthRatio: lr1, phiRatio: pr1, radiusRatio: radiusRatio)
                let v3 = surfacePoint(lengthRatio: lr1, phiRatio: pr0, radiusRatio: radiusRatio)

                let n0 = mesh.addVertex(v0)
                let n1 = mesh.addVertex(v1)
                let n2 = mesh.addVertex(v2)
                let n3 = mesh.addVertex(v3)
                mesh.addQuad(n0, n1, n2, n3, flipped: flipped)
            }
        }
    }
}
