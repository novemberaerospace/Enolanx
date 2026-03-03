// MethorHub.swift
// Genolanx — Parametric Methor Hub (revolution solid)
//
// 3-step staircase hub + ball bearing + optional bifurcating rosace branches.
//
// Staircase cross-section (half-section, revolved around Z):
//
//   Z = hauteur ─────┐
//                     │ étage 3: tube roulement  R = roulInt + epaulement
//   Z = h2Top   ─────┼──────────┐
//                     │          │ étage 2: corps  R = roulInt + 2*epaulement
//   Z = h1Top   ─────┼──────────┼──────────────────┐
//                     │          │                   │ étage 1: flange  R = longueur
//   Z = 0       ─────┴──────────┴───────────────────┘
//
// Parameters:
//   Hub: roulementInterieur, epaulement, roulementHauteur, epaisseurFlange, hauteur, longueur
//   Branches: nBranches, branchEpaisseur, branchHauteur, rayonFork, rayonFinal

import simd
import Foundation
import PicoGKBridge

final class MethorHubTask {

    // MARK: - Hub Parameters (mm)

    let roulementInterieur: Float
    let roulementExterieur: Float  // outer radius of bearing (mm)
    let epaulement: Float
    let roulementHauteur: Float
    let epaisseurFlange: Float
    let hauteur: Float
    let longueur: Float

    // MARK: - Branch Parameters

    let nBranches: Int
    let branchEpaisseur: Float
    let branchHauteur: Float
    let rayonFork: Float       // radius where branches bifurcate
    let rayonFinal: Float      // outer radius of rosace (arm tips)
    let plotHauteur: Float     // hex plot height (independent from branch height)
    let losHalfL: Float        // losange half-length radial (0 = auto from branchEpaisseur)
    let losHalfW: Float        // losange half-width tangential (0 = auto from branchEpaisseur)
    let forkAngleFactor: Float // fraction of angular spacing for fork half-angle (0.25 = stator-aligned)

    // MARK: - Derived Geometry

    var step3Radius: Float { roulementInterieur + epaulement }
    var step2Radius: Float { roulementInterieur + 2 * epaulement }
    var step1Radius: Float { longueur }

    var step1Height: Float { epaisseurFlange }
    var step2Height: Float { hauteur - roulementHauteur - epaisseurFlange }
    var step3Height: Float { roulementHauteur }

    var step1TopZ: Float { epaisseurFlange }
    var step2TopZ: Float { hauteur - roulementHauteur }

    // MARK: - Init

    init(roulementInterieur: Float = 12.5,
         roulementExterieur: Float = 28,
         epaulement: Float = 8,
         roulementHauteur: Float = 12,
         epaisseurFlange: Float = 3,
         hauteur: Float = 35,
         longueur: Float = 50,
         nBranches: Int = 16,
         branchEpaisseur: Float = 2.0,
         branchHauteur: Float = 5.0,
         rayonFork: Float = 82,
         rayonFinal: Float = 180,
         plotHauteur: Float = 8.0,
         losHalfL: Float = 0,
         losHalfW: Float = 0,
         forkAngleFactor: Float = 0.40) {
        self.roulementInterieur = roulementInterieur
        self.roulementExterieur = roulementExterieur
        self.epaulement = epaulement
        self.roulementHauteur = roulementHauteur
        self.epaisseurFlange = epaisseurFlange
        self.hauteur = hauteur
        self.longueur = longueur
        self.nBranches = nBranches
        self.branchEpaisseur = branchEpaisseur
        self.branchHauteur = branchHauteur
        self.rayonFork = rayonFork
        self.rayonFinal = rayonFinal
        self.plotHauteur = plotHauteur
        self.losHalfL = losHalfL
        self.losHalfW = losHalfW
        self.forkAngleFactor = forkAngleFactor
    }

    // MARK: - Entry Point

    static func run(sceneManager: SceneManager,
                    roulementInterieur: Float = 12.5,
                    roulementExterieur: Float = 28,
                    epaulement: Float = 8,
                    roulementHauteur: Float = 12,
                    epaisseurFlange: Float = 3,
                    hauteur: Float = 35,
                    longueur: Float = 50,
                    nBranches: Int = 16,
                    branchEpaisseur: Float = 2.0,
                    branchHauteur: Float = 5.0,
                    rayonFork: Float = 82,
                    rayonFinal: Float = 180,
                    plotHauteur: Float = 8.0,
                    losHalfL: Float = 0,
                    losHalfW: Float = 0,
                    forkAngleFactor: Float = 0.40) {
        sceneManager.log("Starting MethorHub Task.")
        sceneManager.log("  Roulement Int: \(roulementInterieur)  Ext: \(roulementExterieur)  Épaul: \(epaulement)  Roul.H: \(roulementHauteur)")
        sceneManager.log("  Ép.Flange: \(epaisseurFlange)  Hauteur: \(hauteur)  Longueur: \(longueur)")
        sceneManager.log("  Branches: \(nBranches)x  ép=\(branchEpaisseur)  H=\(branchHauteur)")
        sceneManager.log("  Fork R=\(rayonFork)  Final R=\(rayonFinal)  Plot H=\(plotHauteur)")

        let hub = MethorHubTask(
            roulementInterieur: roulementInterieur,
            roulementExterieur: roulementExterieur,
            epaulement: epaulement,
            roulementHauteur: roulementHauteur,
            epaisseurFlange: epaisseurFlange,
            hauteur: hauteur,
            longueur: longueur,
            nBranches: nBranches,
            branchEpaisseur: branchEpaisseur,
            branchHauteur: branchHauteur,
            rayonFork: rayonFork,
            rayonFinal: rayonFinal,
            plotHauteur: plotHauteur,
            losHalfL: losHalfL,
            losHalfW: losHalfW,
            forkAngleFactor: forkAngleFactor
        )

        hub.construct(sceneManager: sceneManager)
        sceneManager.log("Finished MethorHub Task successfully.")
    }

    // MARK: - Geometry Builder (reusable by MethorAssemblyTask)

    /// Build hub + bearing voxels at the given Z offset.
    /// Returns (hub staircase, ball bearing) as separate voxels.
    internal func buildGeometry(sceneManager: SceneManager, zOffset: Float = 0) -> (hub: PicoGKVoxels, bearing: PicoGKVoxels) {

        sceneManager.log("Building 3-step staircase...")
        let voxStep1 = makeStep(radius: step1Radius, fromZ: zOffset, height: step1Height)
        let voxStep2 = makeStep(radius: step2Radius, fromZ: zOffset + step1TopZ, height: step2Height)
        let voxStep3 = makeStep(radius: step3Radius, fromZ: zOffset + step2TopZ, height: step3Height)

        sceneManager.log("Cutting bore...")
        let voxBore = makeBore(zOffset: zOffset)

        var voxHub = voxStep1 + voxStep2
        voxHub = voxHub + voxStep3
        voxHub = voxHub - voxBore

        sceneManager.log("Building \(nBranches) rosace branches (fork R=\(rayonFork), final R=\(rayonFinal))...")
        let voxBranches = makeBranches(sceneManager: sceneManager, zOffset: zOffset)
        voxHub = voxHub + voxBranches

        voxHub = voxHub.smoothened(0.3)

        sceneManager.log("Building ball bearing around manchon...")
        sceneManager.log("  Bearing: inner R=\(step3Radius) (manchon)  outer R=\(roulementExterieur)  H=\(roulementHauteur)")

        let bearingTask = BallBearingTask(
            innerRadius: step3Radius,
            outerRadius: roulementExterieur,
            height: roulementHauteur
        )
        sceneManager.log("  \(bearingTask.ballCount) balls  \u{00D8}\(String(format: "%.1f", bearingTask.ballRadius * 2)) mm")

        let voxBearing = bearingTask.buildVoxels(baseZ: zOffset + step2TopZ)

        return (voxHub, voxBearing)
    }

    // MARK: - Main Assembly (hub + bearing, 2 color groups)

    private func construct(sceneManager: SceneManager) {

        let (voxHub, voxBearing) = buildGeometry(sceneManager: sceneManager)

        // Volumes
        let hubProps = voxHub.calculateProperties()
        let bearingProps = voxBearing.calculateProperties()
        sceneManager.log("  Hub volume: \(String(format: "%.1f", hubProps.volumeCubicMM)) mm\u{00B3}")
        sceneManager.log("  Bearing volume: \(String(format: "%.1f", bearingProps.volumeCubicMM)) mm\u{00B3}")

        // Display: 2 color groups
        DispatchQueue.main.async {
            sceneManager.removeAllObjects()
            sceneManager.addVoxels(voxHub, groupID: 0, name: "MethorHub")
            sceneManager.setGroupMaterial(0, color: Cp.clrFrozen, metallic: 0.7, roughness: 0.25)
            sceneManager.addVoxels(voxBearing, groupID: 1, name: "Roulement")
            sceneManager.setGroupMaterial(1, color: Cp.clrYellow, metallic: 0.8, roughness: 0.2)
        }

        // Export
        sceneManager.log("Exporting STLs...")

        let pathHub = ShExport.exportPath(filename: "MethorHub_Hub")
        sceneManager.exportSTL(voxels: voxHub, to: pathHub)
        sceneManager.log("  \u{2192} \(pathHub)")

        let pathBearing = ShExport.exportPath(filename: "MethorHub_Roulement")
        sceneManager.exportSTL(voxels: voxBearing, to: pathBearing)
        sceneManager.log("  \u{2192} \(pathBearing)")

        let voxFull = voxHub + voxBearing
        let pathFull = ShExport.exportPath(filename: "MethorHub_Full")
        sceneManager.exportSTL(voxels: voxFull, to: pathFull)
        sceneManager.log("  \u{2192} \(pathFull)")

        sceneManager.log("Done! STLs exported.")
    }

    // MARK: - Component Builders

    private func makeStep(radius: Float, fromZ: Float, height: Float) -> PicoGKVoxels {
        let frame = LocalFrame(position: SIMD3(0, 0, fromZ))
        return BaseCylinder(frame: frame, length: height, radius: radius).constructVoxels()
    }

    private func makeBore(zOffset: Float = 0) -> PicoGKVoxels {
        let frame = LocalFrame(position: SIMD3(0, 0, zOffset - 0.5))
        return BaseCylinder(frame: frame, length: hauteur + 1.0, radius: roulementInterieur).constructVoxels()
    }

    // MARK: - Rosace Branches

    /// Bifurcating rosace: tronc from hub body (step2Radius) to rayonFork,
    /// then 2 arms diverge to rayonFinal with hex plots.
    /// Trunk starts inside the hub so it is physically fused ("collé") to it.
    /// Fork angle is ~half the angular spacing → arms interlace with neighbours.
    private func makeBranches(sceneManager: SceneManager, zOffset: Float = 0) -> PicoGKVoxels {
        var voxAll: PicoGKVoxels?

        let rStart = step2Radius             // branches start inside the hub body (collé au hub)
        let rFork  = rayonFork               // bifurcation point
        let rEnd   = rayonFinal              // arm tips

        let trunkLen = rFork - rStart
        let upDir = SIMD3<Float>(0, 0, 1)
        let zC = zOffset + branchHauteur / 2.0         // box center Z with offset

        // Fork half-angle: fraction of angular spacing between branches
        // 0.40 = default (interlace), 0.25 = stator-aligned (losange interlock)
        let angularSpacing = 2.0 * Float.pi / Float(nBranches)
        let forkHalfAngle = angularSpacing * forkAngleFactor

        // Losange dimensions: auto from branchEpaisseur, or explicit (stator interlock)
        let losHL: Float = (losHalfL > 0) ? losHalfL : branchEpaisseur * 2.2
        let losHW: Float = (losHalfW > 0) ? losHalfW : branchEpaisseur * 1.2
        let losH: Float = plotHauteur
        let losZC = zOffset + plotHauteur / 2.0     // losange center Z with offset

        for i in 0..<nBranches {
            let phi = Float(i) / Float(nBranches) * 2.0 * Float.pi

            let dirR = SIMD3<Float>(cos(phi), sin(phi), 0)
            let dirT = SIMD3<Float>(-sin(phi), cos(phi), 0)

            // ── Tronc: hub body → fork (passes through flange, fuses with hub) ──
            let trunkCenter = dirR * (rStart + trunkLen / 2.0) + upDir * zC
            let trunkFrame = LocalFrame(position: trunkCenter, localZ: dirR, localX: dirT)
            let voxTrunk = BaseBox(trunkFrame, trunkLen, branchEpaisseur, branchHauteur).voxConstruct()

            // Fork point
            let forkPt = dirR * rFork

            // ── Two arms: fork → end ──
            for sign: Float in [-1.0, 1.0] {
                let armPhi = phi + sign * forkHalfAngle

                // Arm endpoint at rayonFinal
                let armEnd = SIMD3<Float>(cos(armPhi), sin(armPhi), 0) * rEnd

                // Arm vector & length
                let armVec = armEnd - forkPt
                let armActualLen = simd_length(armVec)
                let armDirFwd = simd_normalize(armVec)
                let armDirSide = SIMD3<Float>(-armDirFwd.y, armDirFwd.x, 0)

                // Arm center
                let armCenter = (forkPt + armEnd) * 0.5 + upDir * zC

                let armFrame = LocalFrame(position: armCenter, localZ: armDirFwd, localX: armDirSide)
                let voxArm = BaseBox(armFrame, armActualLen, branchEpaisseur, branchHauteur).voxConstruct()

                // Losange plot at tip (oriented radially, independent height)
                let voxLos = makeLosangePlot(center: armEnd + upDir * losZC,
                                             armPhi: armPhi,
                                             halfL: losHL, halfW: losHW,
                                             height: losH)

                if let existing = voxAll {
                    voxAll = existing + voxArm + voxLos
                } else {
                    voxAll = voxArm + voxLos
                }
            }

            // Add trunk
            if let existing = voxAll {
                voxAll = existing + voxTrunk
            } else {
                voxAll = voxTrunk
            }

            if (i + 1) % 4 == 0 {
                sceneManager.log("  Branch \(i + 1)/\(nBranches) done")
            }
        }

        return voxAll ?? PicoGKVoxels()
    }

    /// Losange (diamond) prism at position, oriented along the arm radial direction.
    /// |dr|/halfL + |dt|/halfW <= 1  (radial × tangential), extruded along Z.
    private func makeLosangePlot(center: SIMD3<Float>, armPhi: Float,
                                  halfL: Float, halfW: Float, height: Float) -> PicoGKVoxels {
        let halfH = height / 2.0
        let maxR = max(halfL, halfW)
        let margin: Float = 2.0
        let bounds = BBox3(
            min: center - SIMD3(maxR + margin, maxR + margin, halfH + margin),
            max: center + SIMD3(maxR + margin, maxR + margin, halfH + margin)
        )

        let c = center
        let cA = cos(armPhi)
        let sA = sin(armPhi)
        let hL = halfL
        let hW = halfW

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let dx = pt.x - c.x
            let dy = pt.y - c.y
            let dz = abs(pt.z - c.z)
            // Project onto radial (arm direction) and tangential axes
            let dr = abs(dx * cA + dy * sA)
            let dt = abs(-dx * sA + dy * cA)
            let losDist = (dr / hL + dt / hW - 1.0) * min(hL, hW)
            return max(losDist, dz - halfH)
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }
}
