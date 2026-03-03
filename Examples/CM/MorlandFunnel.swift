// MorlandFunnel.swift
// Genolanx — Port of Leap71.MorlandFunnelProject.MorlandFunnel
//
// A funnel/diffuser with internal spiral blade cavities.
// Turbine impeller design with curved vanes inside an expanding cone,
// sitting on a cylindrical stem and flat base flange.

import simd
import Foundation

final class MorlandFunnelTask {

    // MARK: - Geometry Parameters (all in mm)

    // Base flange
    let flangeRadius: Float      = 40
    let flangeThickness: Float   = 5

    // Stem
    let stemRadius: Float        = 12
    let stemHeight: Float        = 30

    // Cone (elliptical flare)
    let coneHeight: Float        = 60
    let coneTopRadius: Float     = 45

    // Flange holes
    let flangeHoleRadius: Float  = 4
    let flangeHoleCount: UInt32  = 8
    let flangeHoleCircle: Float  = 33

    // Central bore
    let innerHoleRadius: Float   = 8

    // Wall and blade dimensions
    let wallThickness: Float     = 2
    let bladeCount: UInt32       = 9
    let bladeThickness: Float    = 2
    let bladeTwistAngle: Float   = 75  // degrees

    // MARK: - Derived Z Coordinates

    var flangeTopZ: Float  { flangeThickness }
    var coneBaseZ: Float   { flangeThickness + stemHeight }
    var coneTopZ: Float    { flangeThickness + stemHeight + coneHeight }

    // MARK: - Entry Point

    static func run(sceneManager: SceneManager) {
        sceneManager.log("Starting MorlandFunnel Task.")
        let funnel = MorlandFunnelTask()
        funnel.construct(sceneManager: sceneManager)
        sceneManager.log("Finished MorlandFunnel Task successfully.")
    }

    // MARK: - Main Assembly

    private func construct(sceneManager: SceneManager) {
        // Step 1 — Base flange
        sceneManager.log("Building flange...")
        let voxFlange = makeFlange()

        // Step 2 — Stem
        sceneManager.log("Building stem...")
        let voxStem = makeStem()

        // Step 3 — Outer cone wall
        sceneManager.log("Building outer cone...")
        let voxOuterCone = makeOuterCone()

        // Step 4 — Central bore
        sceneManager.log("Building inner hole...")
        let voxInnerHole = makeInnerHole()

        // Step 5 — Spiral blades
        sceneManager.log("Building spiral blades...")
        let voxBlades = makeSpiralBlades(sceneManager: sceneManager)

        // Step 6 — Flange bolt holes
        sceneManager.log("Building flange holes...")
        let voxFlangeHoles = makeFlangeHoles()

        // Step 7 — Boolean assembly
        sceneManager.log("Assembling...")

        // Union all solid parts
        var voxSolid = voxFlange + voxStem
        voxSolid = voxSolid + voxOuterCone

        // Subtract the central bore
        voxSolid = voxSolid - voxInnerHole

        // Subtract the flange bolt holes
        voxSolid = voxSolid - voxFlangeHoles

        // Add the spiral blades
        voxSolid = voxSolid + voxBlades

        // Smooth pass
        voxSolid = voxSolid.smoothened(0.3)

        // Final preview
        DispatchQueue.main.async {
            sceneManager.removeAllObjects()
            sceneManager.addVoxels(voxSolid, groupID: 0, name: "MorlandFunnel")
            sceneManager.setGroupMaterial(0, color: Cp.clrFrozen, metallic: 0.5, roughness: 0.4)
        }

        // Export STL
        sceneManager.log("Exporting STL...")
        let path = ShExport.exportPath(filename: "MorlandFunnel")
        sceneManager.exportSTL(voxels: voxSolid, to: path)

        sceneManager.log("Done! Exported to: \(path)")
    }

    // MARK: - Component Builders

    /// Base flange: flat circular disk at the bottom.
    private func makeFlange() -> PicoGKVoxels {
        let frame = LocalFrame(position: SIMD3(0, 0, 0))
        let flange = BaseCylinder(frame: frame, length: flangeThickness, radius: flangeRadius)
        return flange.constructVoxels()
    }

    /// Stem: solid cylinder rising from the flange center.
    private func makeStem() -> PicoGKVoxels {
        let frame = LocalFrame(position: SIMD3(0, 0, flangeTopZ))
        let stem = BaseCylinder(frame: frame, length: stemHeight, radius: stemRadius)
        return stem.constructVoxels()
    }

    /// Elliptical flare radius at a given height ratio.
    ///   r(t) = stemRadius + (coneTopRadius - stemRadius) * sqrt(1 - (1-t)^2)
    private func flareRadius(at lengthRatio: Float) -> Float {
        let t = max(0, min(1, lengthRatio))
        let ellipticFactor = sqrt(1.0 - (1.0 - t) * (1.0 - t))
        return stemRadius + (coneTopRadius - stemRadius) * ellipticFactor
    }

    /// Outer cone: hollow expanding wall with elliptical flare profile.
    private func makeOuterCone() -> PicoGKVoxels {
        let frame = LocalFrame(position: SIMD3(0, 0, coneBaseZ))

        let cone = BasePipe(
            frame: frame,
            length: coneHeight,
            innerRadius: stemRadius - wallThickness,
            outerRadius: coneTopRadius
        )

        let outerMod = SurfaceModulation { [self] _, lr in
            flareRadius(at: lr)
        }

        let innerMod = SurfaceModulation { [self] _, lr in
            flareRadius(at: lr) - wallThickness
        }

        cone.setRadius(inner: innerMod, outer: outerMod)
        return cone.constructVoxels()
    }

    /// Inner hole: cylinder through the entire height.
    private func makeInnerHole() -> PicoGKVoxels {
        let frame = LocalFrame(position: SIMD3(0, 0, 0))
        let hole = BaseCylinder(frame: frame, length: coneTopZ + 1, radius: innerHoleRadius)
        return hole.constructVoxels()
    }

    /// Flange holes: evenly spaced through-holes around the flange.
    private func makeFlangeHoles() -> PicoGKVoxels {
        var voxHoles: PicoGKVoxels? = nil

        for i in 0..<flangeHoleCount {
            let angle = Float(i) * 2.0 * Float.pi / Float(flangeHoleCount)
            let x = flangeHoleCircle * cos(angle)
            let y = flangeHoleCircle * sin(angle)

            let frame = LocalFrame(position: SIMD3(x, y, -0.5))
            let hole = BaseCylinder(frame: frame, length: flangeThickness + 1, radius: flangeHoleRadius)
            let voxHole = hole.constructVoxels()

            if let existing = voxHoles {
                voxHoles = existing + voxHole
            } else {
                voxHoles = voxHole
            }
        }

        return voxHoles!
    }

    /// Spiral blades inside the funnel cone.
    private func makeSpiralBlades(sceneManager: SceneManager) -> PicoGKVoxels {
        let twistRad = bladeTwistAngle * Float.pi / 180.0
        let beamRadius = 0.5 * bladeThickness

        let latBlades = PicoGKLattice()

        let heightSamples: UInt32 = 120
        let radialSamples: UInt32 = 40

        for iBlade in 0..<bladeCount {
            let phiBase = Float(iBlade) * 2.0 * Float.pi / Float(bladeCount)
            sceneManager.log("  Blade \(iBlade + 1)/\(bladeCount)...")

            for iZ in 0..<heightSamples {
                let lr = Float(iZ) / Float(heightSamples - 1)
                let z = coneBaseZ + lr * coneHeight

                let innerR = innerHoleRadius + 1.0
                let outerR = flareRadius(at: lr) - wallThickness - 0.5

                guard outerR > innerR + 1 else { continue }

                for iR in 0..<radialSamples {
                    let radialRatio = Float(iR) / Float(radialSamples - 1)
                    let phi = phiBase + twistRad * radialRatio
                    let r = innerR + radialRatio * (outerR - innerR)

                    let pt = VecOp.cylindricalPoint(radius: r, phi: phi, z: z)

                    // Connect to next radial point (along blade width)
                    if iR < radialSamples - 1 {
                        let nextRR = Float(iR + 1) / Float(radialSamples - 1)
                        let nextPhi = phiBase + twistRad * nextRR
                        let nextR = innerR + nextRR * (outerR - innerR)

                        let nextPt = VecOp.cylindricalPoint(radius: nextR, phi: nextPhi, z: z)
                        latBlades.addBeam(from: pt, radiusA: beamRadius,
                                          to: nextPt, radiusB: beamRadius, roundCap: false)
                    }

                    // Connect to next height point (along blade height)
                    if iZ < heightSamples - 1 {
                        let nextLR = Float(iZ + 1) / Float(heightSamples - 1)
                        let nextZ = coneBaseZ + nextLR * coneHeight
                        let nextOuterR = flareRadius(at: nextLR) - wallThickness - 0.5

                        if nextOuterR > innerR + 1 {
                            let nextR2 = innerR + radialRatio * (nextOuterR - innerR)
                            let nextPt = VecOp.cylindricalPoint(radius: nextR2, phi: phi, z: nextZ)
                            latBlades.addBeam(from: pt, radiusA: beamRadius,
                                              to: nextPt, radiusB: beamRadius, roundCap: false)
                        }
                    }
                }
            }
        }

        sceneManager.log("  Converting blade lattice to voxels...")
        return PicoGKVoxels(lattice: latBlades)
    }
}
