// BallBearing.swift
// Genolanx — Parametric ball bearing with inner/outer races and balls.
//
// A radial deep-groove ball bearing built from boolean assembly:
//   1. Outer race (annular ring)
//   2. Inner race (annular ring)
//   3. Ball grooves (toroidal channels cut into each race)
//   4. Balls (spheres distributed around circumference)
//
// All geometry is parametric: inner radius, outer radius, and height
// control the full shape. Race thickness, ball size, ball count,
// and groove depth are derived automatically.

import simd
import Foundation

final class BallBearingTask {

    // MARK: - Configurable Parameters (all in mm)

    let innerRadius: Float       // Bore radius of the bearing
    let outerRadius: Float       // Outer race outside radius
    let height: Float            // Bearing width (axial)

    // MARK: - Derived Geometry

    /// Race wall thickness (~20% of radial depth).
    var raceThickness: Float {
        let radialDepth = outerRadius - innerRadius
        return max(1.5, radialDepth * 0.20)
    }

    /// Outer surface of inner race.
    var innerRaceOuterR: Float { innerRadius + raceThickness }

    /// Inner surface of outer race.
    var outerRaceInnerR: Float { outerRadius - raceThickness }

    /// Radial center where balls sit.
    var ballCenterRadius: Float { (innerRaceOuterR + outerRaceInnerR) / 2.0 }

    /// Maximum ball radius that fits between races (with clearance).
    var ballRadius: Float {
        let gapRadial = (outerRaceInnerR - innerRaceOuterR) / 2.0
        let gapAxial  = height / 2.0
        let rMax = min(gapRadial, gapAxial) * 0.85   // 85% fill
        return max(0.5, rMax)
    }

    /// Groove radius — slightly larger than ball for smooth rolling.
    var grooveRadius: Float { ballRadius * 1.05 }

    /// Number of balls that fit around the pitch circle with spacing.
    var ballCount: Int {
        let circumference = 2.0 * Float.pi * ballCenterRadius
        let ballDiameter  = 2.0 * ballRadius
        let spacing        = ballDiameter * 1.15      // 15% gap between balls
        return max(3, Int(floor(circumference / spacing)))
    }

    /// Mid-height Z coordinate (balls sit here).
    var midZ: Float { height / 2.0 }

    // MARK: - Init

    init(innerRadius: Float = 15,
         outerRadius: Float = 30,
         height: Float = 12) {
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
        self.height = height
    }

    // MARK: - Entry Point

    static func run(sceneManager: SceneManager,
                    innerRadius: Float = 15,
                    outerRadius: Float = 30,
                    height: Float = 12) {
        sceneManager.log("Starting BallBearing Task.")
        sceneManager.log("  Inner R: \(innerRadius) mm")
        sceneManager.log("  Outer R: \(outerRadius) mm")
        sceneManager.log("  Height:  \(height) mm")

        let bearing = BallBearingTask(
            innerRadius: innerRadius,
            outerRadius: outerRadius,
            height: height
        )

        sceneManager.log("  Race thickness: \(String(format: "%.1f", bearing.raceThickness)) mm")
        sceneManager.log("  Ball radius: \(String(format: "%.1f", bearing.ballRadius)) mm")
        sceneManager.log("  Ball count: \(bearing.ballCount)")

        bearing.construct(sceneManager: sceneManager)
        sceneManager.log("Finished BallBearing Task successfully.")
    }

    // MARK: - Main Assembly

    private func construct(sceneManager: SceneManager) {

        sceneManager.log("Building races, grooves, balls...")
        let voxBearing = buildVoxels()

        // Display
        DispatchQueue.main.async {
            sceneManager.removeAllObjects()
            sceneManager.addVoxels(voxBearing, groupID: 0, name: "BallBearing")
            sceneManager.setGroupMaterial(
                0,
                color: Cp.clrFrozen,
                metallic: 0.85,
                roughness: 0.15
            )
        }

        // Export STL
        sceneManager.log("Exporting STL...")
        let path = ShExport.exportPath(filename: "BallBearing")
        sceneManager.exportSTL(voxels: voxBearing, to: path)
        sceneManager.log("Done! Exported to: \(path)")
    }

    // MARK: - Public Builder (for embedding in other assemblies)

    /// Build the complete bearing voxels at a given Z offset.
    /// Used by MethorHub to place the bearing on the manchon.
    func buildVoxels(baseZ: Float = 0) -> PicoGKVoxels {
        let voxOuterRace = makeOuterRace(baseZ: baseZ)
        let voxInnerRace = makeInnerRace(baseZ: baseZ)
        let voxGrooveOuter = makeGroove(atRadius: outerRaceInnerR, facingInward: true, baseZ: baseZ)
        let voxGrooveInner = makeGroove(atRadius: innerRaceOuterR, facingInward: false, baseZ: baseZ)
        let voxBalls = makeBalls(baseZ: baseZ)

        var voxRaces = voxOuterRace + voxInnerRace
        voxRaces = voxRaces - voxGrooveOuter
        voxRaces = voxRaces - voxGrooveInner
        voxRaces = voxRaces.smoothened(0.3)

        return voxRaces + voxBalls
    }

    /// Build races and balls as separate voxels for multi-color rendering.
    /// Used by MorlandHub (races in black, balls in white).
    func buildSeparateVoxels(baseZ: Float = 0) -> (races: PicoGKVoxels, balls: PicoGKVoxels) {
        let voxOuterRace = makeOuterRace(baseZ: baseZ)
        let voxInnerRace = makeInnerRace(baseZ: baseZ)
        let voxGrooveOuter = makeGroove(atRadius: outerRaceInnerR, facingInward: true, baseZ: baseZ)
        let voxGrooveInner = makeGroove(atRadius: innerRaceOuterR, facingInward: false, baseZ: baseZ)
        let voxBalls = makeBalls(baseZ: baseZ)

        var voxRaces = voxOuterRace + voxInnerRace
        voxRaces = voxRaces - voxGrooveOuter
        voxRaces = voxRaces - voxGrooveInner
        voxRaces = voxRaces.smoothened(0.3)

        return (voxRaces, voxBalls)
    }

    // MARK: - Component Builders

    /// Outer race: hollow annular ring spanning the full height.
    private func makeOuterRace(baseZ: Float = 0) -> PicoGKVoxels {
        let frame = LocalFrame(position: SIMD3(0, 0, baseZ))
        let race = BasePipe(
            frame: frame,
            length: height,
            innerRadius: outerRaceInnerR,
            outerRadius: outerRadius
        )
        return race.constructVoxels()
    }

    /// Inner race: hollow annular ring spanning the full height.
    private func makeInnerRace(baseZ: Float = 0) -> PicoGKVoxels {
        let frame = LocalFrame(position: SIMD3(0, 0, baseZ))
        let race = BasePipe(
            frame: frame,
            length: height,
            innerRadius: innerRadius,
            outerRadius: innerRaceOuterR
        )
        return race.constructVoxels()
    }

    /// Toroidal groove cut at mid-height around the specified radius.
    ///
    /// Built by sweeping a sphere-sized beam around a full circle
    /// at the ball pitch radius and mid-height Z.
    ///
    /// - Parameters:
    ///   - atRadius: radial position of the groove center
    ///   - facingInward: true for outer race groove, false for inner race
    private func makeGroove(atRadius: Float, facingInward: Bool, baseZ: Float = 0) -> PicoGKVoxels {
        let lat = PicoGKLattice()
        let steps: UInt32 = 360
        let z = midZ + baseZ
        let r = facingInward
            ? atRadius - grooveRadius * 0.5   // Groove digs into inner surface of outer race
            : atRadius + grooveRadius * 0.5   // Groove digs into outer surface of inner race

        for i in 0..<steps {
            let phi0 = Float(i) * 2.0 * Float.pi / Float(steps)
            let phi1 = Float(i + 1) * 2.0 * Float.pi / Float(steps)

            let pt0 = VecOp.cylindricalPoint(radius: r, phi: phi0, z: z)
            let pt1 = VecOp.cylindricalPoint(radius: r, phi: phi1, z: z)

            lat.addBeam(
                from: pt0, radiusA: grooveRadius,
                to: pt1, radiusB: grooveRadius,
                roundCap: false
            )
        }

        return PicoGKVoxels(lattice: lat)
    }

    /// Balls: spheres evenly distributed around the pitch circle at mid-height.
    private func makeBalls(baseZ: Float = 0) -> PicoGKVoxels {
        let lat = PicoGKLattice()

        for i in 0..<ballCount {
            let phi = Float(i) * 2.0 * Float.pi / Float(ballCount)
            let center = VecOp.cylindricalPoint(
                radius: ballCenterRadius,
                phi: phi,
                z: midZ + baseZ
            )
            lat.addSphere(center: center, radius: ballRadius)
        }

        return PicoGKVoxels(lattice: lat)
    }
}
