// MorlandHub.swift
// Genolanx — Port of Leap71.MorlandHubProject.MorlandHub
//
// A hydroponic hub (bicross) designed for 3D printing.
// Features a bearing seat, shoulder, outer cylindrical wall, bottom flange
// with bolt holes, and internal spiral blades.
// Parametric for CM-130, CM-140 and other bearing sizes.

import simd
import Foundation

final class MorlandHubTask {

    // MARK: - Bearing parameters (CM-130 default)

    let bearingInnerDiam: Float
    let bearingOuterDiam: Float
    let bearingHeight: Float

    // MARK: - Derived bearing dimensions

    var bearingInnerRadius: Float  { bearingInnerDiam / 2 }
    var bearingOuterRadius: Float  { bearingOuterDiam / 2 }
    var shoulderWidth: Float       { (bearingOuterDiam - bearingInnerDiam) / 2 }

    // MARK: - Hub body parameters (mm)

    let hubTotalHeight: Float
    let wallThickness: Float

    // MARK: - Flange parameters

    let flangeExtension: Float
    let flangeThickness: Float

    // MARK: - Flange bolt holes

    let flangeHoleCount: Int
    let flangeHoleRadius: Float

    // MARK: - Central funnel (entonnoir) parameters

    let funnelExitHeight: Float
    var funnelTopRadius: Float     { bearingInnerRadius / 2 }
    let funnelBottomRadius: Float

    // MARK: - Blade parameters

    let bladeCount: Int
    let bladeThickness: Float
    let bladeTwistAngle: Float

    // MARK: - Neodymium magnet parameters

    let neodymiumCount: Int          // number of magnet sectors (14–28)
    let neodymiumThickness: Float    // magnet thickness (mm)
    let flangeHoleDist: Float        // bolt hole distance from shoulder (mm)
    let magnetInnerR: Float?         // inner radius of magnet sectors (nil = auto 10% gap)
    let magnetOuterR: Float?         // outer radius of magnet sectors (nil = auto)

    // MARK: - Init (defaults = CM-130 original values)

    init(bearingInnerDiam: Float = 130,
         bearingOuterDiam: Float = 165,
         bearingHeight: Float = 18,
         hubTotalHeight: Float = 60,
         wallThickness: Float = 4,
         flangeExtension: Float = 30,
         flangeThickness: Float = 4,
         flangeHoleCount: Int = 8,
         flangeHoleRadius: Float = 4,
         funnelExitHeight: Float = 20,
         funnelBottomRadius: Float = 8,
         bladeCount: Int = 12,
         bladeThickness: Float = 2,
         bladeTwistAngle: Float = 75,
         neodymiumCount: Int = 14,
         neodymiumThickness: Float = 4,
         flangeHoleDist: Float = 25,
         magnetInnerR: Float? = nil,
         magnetOuterR: Float? = nil) {
        self.bearingInnerDiam = bearingInnerDiam
        self.bearingOuterDiam = bearingOuterDiam
        self.bearingHeight = bearingHeight
        self.hubTotalHeight = hubTotalHeight
        self.wallThickness = wallThickness
        self.flangeExtension = flangeExtension
        self.flangeThickness = flangeThickness
        self.flangeHoleCount = flangeHoleCount
        self.flangeHoleRadius = flangeHoleRadius
        self.funnelExitHeight = funnelExitHeight
        self.funnelBottomRadius = funnelBottomRadius
        self.bladeCount = bladeCount
        self.bladeThickness = bladeThickness
        self.bladeTwistAngle = bladeTwistAngle
        self.neodymiumCount = neodymiumCount
        self.neodymiumThickness = neodymiumThickness
        self.flangeHoleDist = flangeHoleDist
        self.magnetInnerR = magnetInnerR
        self.magnetOuterR = magnetOuterR
    }

    // MARK: - Derived Z coordinates

    var flangeTopZ: Float       { flangeThickness }
    var hubBodyTopZ: Float      { flangeThickness + hubTotalHeight }
    var bearingSeatBaseZ: Float  { hubBodyTopZ - bearingHeight }

    // MARK: - Derived radii

    var outerWallRadius: Float     { bearingInnerRadius + wallThickness }      // 69
    var shoulderOuterRadius: Float { bearingInnerRadius + shoulderWidth }      // 82.5
    var flangeRadius: Float        { shoulderOuterRadius + flangeExtension }
    var flangeHoleCircle: Float    { shoulderOuterRadius + flangeHoleDist }

    // Neodymium magnet radii — sectors sit between shoulder and bolt holes
    // Default: 10% of flangeExtension as gap from shoulder
    var magnetInnerRadius: Float   { magnetInnerR ?? (shoulderOuterRadius + 0.10 * flangeExtension) }
    var magnetOuterRadius: Float   { magnetOuterR ?? (flangeHoleCircle - flangeHoleRadius - 2) }

    // MARK: - Entry Point

    static func run(sceneManager: SceneManager,
                    bearingInnerDiam: Float = 130,
                    bearingOuterDiam: Float = 165,
                    bearingHeight: Float = 18,
                    hubTotalHeight: Float = 60,
                    wallThickness: Float = 4,
                    flangeExtension: Float = 30,
                    flangeThickness: Float = 4,
                    flangeHoleCount: Int = 8,
                    flangeHoleRadius: Float = 4,
                    funnelExitHeight: Float = 20,
                    funnelBottomRadius: Float = 8,
                    bladeCount: Int = 12,
                    bladeThickness: Float = 2,
                    bladeTwistAngle: Float = 75,
                    neodymiumCount: Int = 14,
                    neodymiumThickness: Float = 4,
                    flangeHoleDist: Float = 25,
                    magnetInnerR: Float? = nil,
                    magnetOuterR: Float? = nil) {
        sceneManager.log("Starting MorlandHub Task.")
        sceneManager.log("  Bearing: \(bearingInnerDiam)/\(bearingOuterDiam) x H\(bearingHeight)")
        sceneManager.log("  Hub: H=\(hubTotalHeight)  Wall=\(wallThickness)")
        sceneManager.log("  Flange: ext=\(flangeExtension)  ep=\(flangeThickness)  \(flangeHoleCount) holes")
        sceneManager.log("  Blades: \(bladeCount)x  ep=\(bladeThickness)  twist=\(bladeTwistAngle)")
        sceneManager.log("  Neodymium: \(neodymiumCount) sectors  ep=\(neodymiumThickness)  holeDist=\(flangeHoleDist)")

        let hub = MorlandHubTask(
            bearingInnerDiam: bearingInnerDiam,
            bearingOuterDiam: bearingOuterDiam,
            bearingHeight: bearingHeight,
            hubTotalHeight: hubTotalHeight,
            wallThickness: wallThickness,
            flangeExtension: flangeExtension,
            flangeThickness: flangeThickness,
            flangeHoleCount: flangeHoleCount,
            flangeHoleRadius: flangeHoleRadius,
            funnelExitHeight: funnelExitHeight,
            funnelBottomRadius: funnelBottomRadius,
            bladeCount: bladeCount,
            bladeThickness: bladeThickness,
            bladeTwistAngle: bladeTwistAngle,
            neodymiumCount: neodymiumCount,
            neodymiumThickness: neodymiumThickness,
            flangeHoleDist: flangeHoleDist,
            magnetInnerR: magnetInnerR,
            magnetOuterR: magnetOuterR)
        hub.construct(sceneManager: sceneManager)
        sceneManager.log("Finished MorlandHub Task successfully.")
    }

    // MARK: - Mirror helper

    /// For a BasePipe at startZ with length L:
    /// normal → frame at startZ;  mirror → frame at -(startZ + L)
    private func pipeZ(_ startZ: Float, _ length: Float, mirror: Bool) -> Float {
        mirror ? -(startZ + length) : startZ
    }

    // MARK: - Build one half (top or mirrored bottom)

    private func buildHalf(mirror: Bool, sceneManager: SceneManager)
        -> (solid: PicoGKVoxels, races: PicoGKVoxels, balls: PicoGKVoxels, magnets: PicoGKVoxels)
    {
        let side = mirror ? "bottom" : "top"
        let s: Float = mirror ? -1 : 1

        sceneManager.log("  [\(side)] Flange...")
        let voxFlange = makeFlange(mirror: mirror)

        sceneManager.log("  [\(side)] Hub wall...")
        let voxWall = makeHubWall(mirror: mirror)

        sceneManager.log("  [\(side)] Shoulder...")
        let voxShoulder = makeBearingShoulder(mirror: mirror)

        sceneManager.log("  [\(side)] Spiral blades...")
        let voxBlades = makeSpiralBlades(mirror: mirror, sceneManager: sceneManager)

        sceneManager.log("  [\(side)] Funnel...")
        let voxFunnel = makeCentralFunnel(mirror: mirror)

        sceneManager.log("  [\(side)] Holes...")
        let voxHoles = makeFlangeHoles(mirror: mirror)

        // Boolean assembly
        var voxSolid = voxFlange + voxWall
        voxSolid = voxSolid + voxShoulder
        voxSolid = voxSolid + voxBlades
        voxSolid = voxSolid - voxFunnel
        voxSolid = voxSolid - voxHoles
        voxSolid = voxSolid.smoothened(0.3)

        // Bearing
        sceneManager.log("  [\(side)] Bearing...")
        let bearing = BallBearingTask(
            innerRadius: outerWallRadius,
            outerRadius: bearingOuterRadius,
            height: bearingHeight)
        let bearingBaseZ = mirror ? -(bearingSeatBaseZ + bearingHeight) : bearingSeatBaseZ
        let (races, balls) = bearing.buildSeparateVoxels(baseZ: bearingBaseZ)

        // Magnets
        sceneManager.log("  [\(side)] Magnets...")
        let magnets = makeNeodymiumMagnets(mirror: mirror)

        return (voxSolid, races, balls, magnets)
    }

    // MARK: - Main Assembly

    private func construct(sceneManager: SceneManager) {

        // ===== TOP HALF =====
        sceneManager.log("Building top half...")
        let top = buildHalf(mirror: false, sceneManager: sceneManager)

        // ===== BOTTOM HALF (mirror Z) =====
        sceneManager.log("Building bottom half (mirror)...")
        let bot = buildHalf(mirror: true, sceneManager: sceneManager)

        // Final preview — all objects separate (no fusion)
        DispatchQueue.main.async {
            sceneManager.removeAllObjects()
            // Hub bodies
            sceneManager.addVoxels(top.solid, groupID: 0, name: "Hub Top")
            sceneManager.setGroupMaterial(0, color: Cp.clrFrozen, metallic: 0.5, roughness: 0.4)
            sceneManager.addVoxels(bot.solid, groupID: 1, name: "Hub Bottom")
            sceneManager.setGroupMaterial(1, color: Cp.clrFrozen, metallic: 0.5, roughness: 0.4)
            // Bearing races — black
            sceneManager.addVoxels(top.races, groupID: 2, name: "Races Top")
            sceneManager.setGroupMaterial(2, color: Cp.clrBlack, metallic: 0.8, roughness: 0.2)
            sceneManager.addVoxels(bot.races, groupID: 3, name: "Races Bot")
            sceneManager.setGroupMaterial(3, color: Cp.clrBlack, metallic: 0.8, roughness: 0.2)
            // Bearing balls — silver
            sceneManager.addVoxels(top.balls, groupID: 4, name: "Balls Top")
            sceneManager.setGroupMaterial(4, color: Cp.clrSilver, metallic: 0.9, roughness: 0.1)
            sceneManager.addVoxels(bot.balls, groupID: 5, name: "Balls Bot")
            sceneManager.setGroupMaterial(5, color: Cp.clrSilver, metallic: 0.9, roughness: 0.1)
            // Neodymium magnets — silver
            sceneManager.addVoxels(top.magnets, groupID: 6, name: "Magnets Top")
            sceneManager.setGroupMaterial(6, color: Cp.clrSilver, metallic: 0.85, roughness: 0.15)
            sceneManager.addVoxels(bot.magnets, groupID: 7, name: "Magnets Bot")
            sceneManager.setGroupMaterial(7, color: Cp.clrSilver, metallic: 0.85, roughness: 0.15)
        }

        // Export STL (top half only)
        sceneManager.log("Exporting STL...")
        let path = ShExport.exportPath(filename: "MorlandHub")
        sceneManager.exportSTL(voxels: top.solid, to: path)

        sceneManager.log("Done! Exported to: \(path)")
    }

    // MARK: - Component Builders

    /// Flange: anneau (ring) at Z=0, NOT a solid disk.
    /// Inner radius = outerWallRadius (flush with the hub wall exterior)
    /// Outer radius = flangeRadius
    /// Water flows through the open interior.
    private func makeFlange(mirror: Bool = false) -> PicoGKVoxels {
        let z = pipeZ(0, flangeThickness, mirror: mirror)
        let frame = LocalFrame(position: SIMD3(0, 0, z))
        let flange = BasePipe(
            frame: frame,
            length: flangeThickness,
            innerRadius: outerWallRadius,
            outerRadius: flangeRadius)
        return flange.constructVoxels()
    }

    /// Hub body wall: hollow cylinder from flange top to hub top.
    private func makeHubWall(mirror: Bool = false) -> PicoGKVoxels {
        let z = pipeZ(flangeTopZ, hubTotalHeight, mirror: mirror)
        let frame = LocalFrame(position: SIMD3(0, 0, z))
        let wall = BasePipe(
            frame: frame,
            length: hubTotalHeight,
            innerRadius: bearingInnerRadius,
            outerRadius: outerWallRadius)
        return wall.constructVoxels()
    }

    /// Bearing shoulder: wider ring flush with the flange.
    private func makeBearingShoulder(mirror: Bool = false) -> PicoGKVoxels {
        let shoulderLen = bearingSeatBaseZ - flangeTopZ
        let z = pipeZ(flangeTopZ, shoulderLen, mirror: mirror)
        let frame = LocalFrame(position: SIMD3(0, 0, z))
        let shoulderMidRadius = (outerWallRadius + bearingOuterRadius) / 2
        let shoulder = BasePipe(
            frame: frame,
            length: shoulderLen,
            innerRadius: outerWallRadius - 0.1,
            outerRadius: shoulderMidRadius)
        return shoulder.constructVoxels()
    }

    /// Central funnel (entonnoir): a solid spline-profiled funnel used
    /// as a subtraction volume to carve out the hub interior.
    /// Wide at top (inside hub), narrow at bottom (exit below flange).
    private func makeCentralFunnel(mirror: Bool = false) -> PicoGKVoxels {
        let s: Float = mirror ? -1 : 1
        // Funnel spans from top of hub interior down to below the flange
        let topZ = bearingSeatBaseZ * s
        let bottomZ = -funnelExitHeight * s

        // Spline control points along Z axis (top to bottom)
        let splinePoints: [SIMD3<Float>] = [
            SIMD3(0, 0, topZ),
            SIMD3(0, 0, topZ * 0.75),
            SIMD3(0, 0, topZ * 0.5),
            SIMD3(0, 0, topZ * 0.25),
            SIMD3(0, 0, 0),
            SIMD3(0, 0, bottomZ * 0.5),
            SIMD3(0, 0, bottomZ),
        ]

        let spine = ControlPointSpline(points: splinePoints, degree: 2)
        let pathPoints = spine.getPoints(100)

        // Build frames along the spline path
        let refFrame = LocalFrame(position: SIMD3(0, 0, 0))
        let frames = Frames(points: pathPoints, frame: refFrame)

        // Solid cylinder (subtraction volume)
        let funnel = BaseCylinder(frames: frames, radius: funnelTopRadius)

        // Radius modulation: wide at top (lr=0), narrow at bottom (lr=1)
        // Smooth bell/funnel curve using cosine interpolation
        let topR = funnelTopRadius
        let bottomR = funnelBottomRadius
        let radiusMod = SurfaceModulation { _, lr in
            let t = 0.5 * (1.0 - cos(lr * Float.pi))
            return topR + t * (bottomR - topR)
        }

        funnel.setRadius(radiusMod)
        return funnel.constructVoxels()
    }

    /// Flange rivet holes: two bands at 15% and 85% of flange disk,
    /// clamped to avoid overlapping the neodymium magnets.
    private func makeFlangeHoles(mirror: Bool = false) -> PicoGKVoxels {
        // Two rivet bands at 15% and 85% of flange radial range
        var innerCircle = shoulderOuterRadius + 0.15 * flangeExtension
        var outerCircle = shoulderOuterRadius + 0.85 * flangeExtension

        // Clamp to avoid overlapping neodymium sectors
        if innerCircle + flangeHoleRadius > magnetInnerRadius {
            innerCircle = magnetInnerRadius - flangeHoleRadius - 1
        }
        if outerCircle - flangeHoleRadius < magnetOuterRadius {
            outerCircle = magnetOuterRadius + flangeHoleRadius + 1
        }

        var voxHoles: PicoGKVoxels? = nil

        // Inner rivet band
        for i in 0..<flangeHoleCount {
            let angle = Float(i) * 2.0 * Float.pi / Float(flangeHoleCount)
            let x = innerCircle * cos(angle)
            let y = innerCircle * sin(angle)

            let holeZ: Float = mirror ? -(flangeThickness + 0.5) : -0.5
            let frame = LocalFrame(position: SIMD3(x, y, holeZ))
            let hole = BaseCylinder(
                frame: frame,
                length: flangeThickness + 1,
                radius: flangeHoleRadius)
            let voxHole = hole.constructVoxels()

            if let existing = voxHoles {
                voxHoles = existing + voxHole
            } else {
                voxHoles = voxHole
            }
        }

        // Outer rivet band
        for i in 0..<flangeHoleCount {
            let angle = Float(i) * 2.0 * Float.pi / Float(flangeHoleCount)
            let x = outerCircle * cos(angle)
            let y = outerCircle * sin(angle)

            let holeZ: Float = mirror ? -(flangeThickness + 0.5) : -0.5
            let frame = LocalFrame(position: SIMD3(x, y, holeZ))
            let hole = BaseCylinder(
                frame: frame,
                length: flangeThickness + 1,
                radius: flangeHoleRadius)
            let voxHole = hole.constructVoxels()

            if let existing = voxHoles {
                voxHoles = existing + voxHole
            } else {
                voxHoles = voxHole
            }
        }

        return voxHoles!
    }

    /// Neodymium magnet sectors embedded halfway into the flange from above.
    /// Arc-shaped sectors distributed evenly around the flange plate.
    /// Half the magnet sits inside the flange, half protrudes above.
    private func makeNeodymiumMagnets(mirror: Bool = false) -> PicoGKVoxels {
        let lat = PicoGKLattice()
        let beamR: Float = 1.0
        let s: Float = mirror ? -1 : 1

        // Magnet Z range: embedded halfway from top of flange
        let zBase: Float = s * (flangeTopZ - (neodymiumThickness / 2))
        let zTop: Float = s * (flangeTopZ + (neodymiumThickness / 2))

        // Angular span per sector with gap
        let angularGap: Float = 0.04   // small gap between sectors
        let sectorAngle = (2.0 * Float.pi / Float(neodymiumCount)) - angularGap

        let rSteps = 20
        let phiSteps = 30
        let zSteps = 6

        for iMag in 0..<neodymiumCount {
            let phiStart = Float(iMag) * 2.0 * Float.pi / Float(neodymiumCount)

            for iR in 0..<rSteps {
                let rRatio = Float(iR) / Float(rSteps - 1)
                let r = magnetInnerRadius + rRatio * (magnetOuterRadius - magnetInnerRadius)

                for iPhi in 0..<phiSteps {
                    let phiRatio = Float(iPhi) / Float(phiSteps - 1)
                    let phi = phiStart + phiRatio * sectorAngle

                    for iZ in 0..<zSteps {
                        let zRatio = Float(iZ) / Float(zSteps - 1)
                        let z = zBase + zRatio * (zTop - zBase)

                        let pt = VecOp.cylindricalPoint(radius: r, phi: phi, z: z)

                        // Connect along phi (arc direction)
                        if iPhi < phiSteps - 1 {
                            let nextPhiRatio = Float(iPhi + 1) / Float(phiSteps - 1)
                            let nextPhi = phiStart + nextPhiRatio * sectorAngle
                            let nextPt = VecOp.cylindricalPoint(radius: r, phi: nextPhi, z: z)
                            lat.addBeam(from: pt, radiusA: beamR,
                                        to: nextPt, radiusB: beamR, roundCap: false)
                        }

                        // Connect along radius
                        if iR < rSteps - 1 {
                            let nextRRatio = Float(iR + 1) / Float(rSteps - 1)
                            let nextR = magnetInnerRadius + nextRRatio * (magnetOuterRadius - magnetInnerRadius)
                            let nextPt = VecOp.cylindricalPoint(radius: nextR, phi: phi, z: z)
                            lat.addBeam(from: pt, radiusA: beamR,
                                        to: nextPt, radiusB: beamR, roundCap: false)
                        }

                        // Connect along Z (thickness)
                        if iZ < zSteps - 1 {
                            let nextZRatio = Float(iZ + 1) / Float(zSteps - 1)
                            let nextZ = zBase + nextZRatio * (zTop - zBase)
                            let nextPt = VecOp.cylindricalPoint(radius: r, phi: phi, z: nextZ)
                            lat.addBeam(from: pt, radiusA: beamR,
                                        to: nextPt, radiusB: beamR, roundCap: false)
                        }
                    }
                }
            }
        }

        return PicoGKVoxels(lattice: lat)
    }

    /// Generates the internal spiral blades inside the hub body.
    /// Each blade sweeps radially from the inner bore to the outer wall,
    /// with a twist angle that creates a spiral/vane pattern.
    /// Blades span the full hub height (from flange top to bearing seat base).
    private func makeSpiralBlades(mirror: Bool = false, sceneManager: SceneManager) -> PicoGKVoxels {
        let s: Float = mirror ? -1 : 1
        let radialTwistRad = bladeTwistAngle * Float.pi / 180
        let helicalTwistRad: Float = 30 * Float.pi / 180   // 30 deg helical twist along Z
        let beamRadius = 0.5 * bladeThickness

        let latBlades = PicoGKLattice()

        // Blades span from just above the flange to the bearing seat
        let bladeBaseZ = flangeTopZ + 1
        let bladeTopZ = bearingSeatBaseZ - 1
        let bladeHeight = bladeTopZ - bladeBaseZ

        guard bladeHeight > 0 else {
            sceneManager.log("  Warning: no room for blades, skipping.")
            return PicoGKVoxels(lattice: latBlades)
        }

        // Radial limits: blades span from near center to the hub wall
        let innerR: Float = 2.0
        let outerR = bearingInnerRadius - 1.0

        let heightSamples = 100
        let radialSamples = 60

        for iBlade in 0..<bladeCount {
            let phiBase = Float(iBlade) * 2.0 * Float.pi / Float(bladeCount)
            sceneManager.log("  Blade \(iBlade + 1)/\(bladeCount)...")

            for iZ in 0..<heightSamples {
                let heightRatio = Float(iZ) / Float(heightSamples - 1)
                let z = bladeBaseZ + heightRatio * bladeHeight

                // Helical twist: blade rotates as it rises along Z
                let helicalOffset = helicalTwistRad * heightRatio

                for iR in 0..<radialSamples {
                    let radialRatio = Float(iR) / Float(radialSamples - 1)
                    // Combined: radial twist + helical twist along height
                    let phi = phiBase
                            + radialTwistRad * radialRatio
                            + helicalOffset
                    let r = innerR + radialRatio * (outerR - innerR)

                    let pt = VecOp.cylindricalPoint(radius: r, phi: phi, z: z * s)

                    // Connect to next radial point (along blade width)
                    if iR < radialSamples - 1 {
                        let nextRR = Float(iR + 1) / Float(radialSamples - 1)
                        let nextPhi = phiBase
                                    + radialTwistRad * nextRR
                                    + helicalOffset
                        let nextR = innerR + nextRR * (outerR - innerR)

                        let nextPt = VecOp.cylindricalPoint(radius: nextR, phi: nextPhi, z: z * s)
                        latBlades.addBeam(from: pt, radiusA: beamRadius,
                                          to: nextPt, radiusB: beamRadius, roundCap: false)
                    }

                    // Connect to next height point (along blade height)
                    if iZ < heightSamples - 1 {
                        let nextHR = Float(iZ + 1) / Float(heightSamples - 1)
                        let nextZ = bladeBaseZ + nextHR * bladeHeight
                        let nextHelical = helicalTwistRad * nextHR
                        let nextPhi = phiBase
                                    + radialTwistRad * radialRatio
                                    + nextHelical

                        let nextPt = VecOp.cylindricalPoint(radius: r, phi: nextPhi, z: nextZ * s)
                        latBlades.addBeam(from: pt, radiusA: beamRadius,
                                          to: nextPt, radiusB: beamRadius, roundCap: false)
                    }
                }
            }
        }

        sceneManager.log("  Converting blade lattice to voxels...")
        return PicoGKVoxels(lattice: latBlades)
    }
}
