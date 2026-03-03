// MethorAssembly.swift
// Genolanx — Methor Hub + Turbine N\u{00E9}lis : vue assembl\u{00E9}e
//
// Fusionne le hub (stator) et la turbine N\u{00E9}lis (rotor) dans une m\u{00EA}me sc\u{00E8}ne.
// Le hub est affich\u{00E9} en semi-transparent (50%) pour r\u{00E9}v\u{00E9}ler le roulement \u{00E0} billes
// \u{00E0} l'interface entre les deux pi\u{00E8}ces.
//
// Alignement Z:
//   - La turbine est construite \u{00E0} Z=0 (ogive vers le haut).
//   - Le hub est d\u{00E9}cal\u{00E9} en Z n\u{00E9}gatif pour que sa zone de roulement (\u{00E9}tage 3)
//     co\u{00EF}ncide avec l'al\u{00E9}sage de roulement de la turbine.
//
// Groups:
//   0: Turbine N\u{00E9}lis  (Navy, opaque)
//   1: Aimants NdFeB    (Gold, opaque)
//   2: Hub staircase    (Frozen, alpha 0.5)
//   3: Roulement billes (Yellow, opaque)
//   4: Stator MabogeSlot (Copper, opaque) — S slots (indépendant de P pôles rotor)

import simd
import Foundation
import PicoGKBridge

final class MethorAssemblyTask {

    static func run(sceneManager: SceneManager,
                    // ── Turbine params ──
                    ogiveHauteur: Float,
                    ogiveBaseRadius: Float,
                    nPales: Int,
                    janteDiametre: Float,
                    paleLargeur: Float,
                    paleEpaisseur: Float,
                    palePitch: Float,
                    paleHauteurBegin: Float,
                    paleHauteurEnd: Float,
                    janteHauteur: Float,
                    janteEpaisseur: Float,
                    nPoles: Int,
                    magnetCatalogID: String,
                    magnetPattern: MagnetPattern,
                    chevronAngle: Float,
                    magnetJeu: Float,
                    roulementExterieur: Float,
                    roulementHauteur: Float,
                    hubOffset: Float,
                    // ── Hub params ──
                    hubRoulInterieur: Float,
                    hubEpaulement: Float,
                    hubEpaisseurFlange: Float,
                    hubHauteur: Float,
                    hubLongueur: Float,
                    nBranches: Int,
                    branchEpaisseur: Float,
                    branchHauteur: Float,
                    rayonFork: Float,
                    rayonFinal: Float,
                    plotHauteur: Float,
                    // ── Stator MabogeSlot params ──
                    statorSlots: Int = 21,
                    statorAirGap: Float = 3,
                    statorProfA: Float = 3,
                    statorProfB: Float = 20,
                    statorProfC: Float = 20,
                    statorNarrowPct: Float = 70,
                    statorFlattenPct: Float = 50) {

        sceneManager.log("=== Methor Assembly: Hub + Turbine N\u{00E9}lis ===")

        // ────────────────────────────────────────────
        // 1. Build Turbine N\u{00E9}lis
        // ────────────────────────────────────────────

        sceneManager.log("\u{2500}\u{2500} Building Turbine N\u{00E9}lis \u{2500}\u{2500}")

        let turbine = TurbineTask(
            ogiveHauteur: ogiveHauteur,
            ogiveBaseRadius: ogiveBaseRadius,
            nPales: nPales,
            janteDiametre: janteDiametre,
            paleLargeur: paleLargeur,
            paleEpaisseur: paleEpaisseur,
            palePitch: palePitch,
            paleHauteurBegin: paleHauteurBegin,
            paleHauteurEnd: paleHauteurEnd,
            janteHauteur: janteHauteur,
            janteEpaisseur: janteEpaisseur,
            nPoles: nPoles,
            magnetCatalogID: magnetCatalogID,
            magnetPattern: magnetPattern,
            chevronAngle: chevronAngle,
            magnetJeu: magnetJeu,
            roulementExterieur: roulementExterieur,
            roulementHauteur: roulementHauteur,
            hubOffset: hubOffset
        )

        let (voxTurbine, voxMagnets) = turbine.buildGeometry(sceneManager: sceneManager)

        // ────────────────────────────────────────────
        // 2. Calculate Z offset for Hub
        // ────────────────────────────────────────────
        //
        // Turbine bore zone:
        //   bottom = cutZ = paleHauteurEnd - janteHauteur/2
        //   top    = cutZ + roulementHauteur
        //
        // Hub bearing zone (local coords):
        //   bottom = step2TopZ = hubHauteur - roulementHauteur
        //   top    = hubHauteur
        //
        // Align: hub step2TopZ  →  turbine cutZ
        //   hubZOffset = cutZ - step2TopZ

        let cutZ = paleHauteurEnd - janteHauteur / 2.0
        let hubStep2TopZ = hubHauteur - roulementHauteur
        let hubZOffset = cutZ - hubStep2TopZ

        sceneManager.log("  Turbine bore zone: Z=[\(String(format: "%.1f", cutZ)), \(String(format: "%.1f", cutZ + roulementHauteur))]")
        sceneManager.log("  Hub Z offset: \(String(format: "%.1f", hubZOffset)) mm")

        // ────────────────────────────────────────────
        // 3. Build Hub at offset
        // ────────────────────────────────────────────

        sceneManager.log("\u{2500}\u{2500} Building Methor Hub (Z offset: \(String(format: "%.1f", hubZOffset))) \u{2500}\u{2500}")

        // ── Hub↔Stator interlocking geometry ──
        // nBranches  = statorSlots (S)  → one branch per stator slot
        // rayonFinal = rNoirMid         → arm tips reach Noir losange centers
        // forkAngle  = 0.25             → arms align with stator losange φ offsets
        // losHalfL/W = 10.0 / 5.5      → match stator losange orifice dimensions
        let janteOuterR = janteDiametre / 2.0 + janteEpaisseur / 2.0
        let statorRJauneI = janteOuterR + statorAirGap
        let statorRNoirI = statorRJauneI + statorProfA + statorProfB
        let statorRNoirMid = statorRNoirI + statorProfC / 2.0

        sceneManager.log("  Hub\u{2194}Stator interlock: S=\(statorSlots) branches  R final=\(String(format: "%.1f", statorRNoirMid)) mm (Noir mid)")

        let hub = MethorHubTask(
            roulementInterieur: hubRoulInterieur,
            roulementExterieur: roulementExterieur,   // shared with turbine
            epaulement: hubEpaulement,
            roulementHauteur: roulementHauteur,       // shared with turbine
            epaisseurFlange: hubEpaisseurFlange,
            hauteur: hubHauteur,
            longueur: hubLongueur,
            nBranches: statorSlots,                   // ← auto: one branch per slot
            branchEpaisseur: branchEpaisseur,
            branchHauteur: branchHauteur,
            rayonFork: rayonFork,
            rayonFinal: statorRNoirMid,               // ← auto: arm tips at Noir mid
            plotHauteur: plotHauteur,
            losHalfL: 10.0,                           // ← match stator losange
            losHalfW: 5.5,                            // ← match stator losange
            forkAngleFactor: 0.25                     // ← match stator losange φ offset
        )

        let (voxHub, voxBearing) = hub.buildGeometry(sceneManager: sceneManager, zOffset: hubZOffset)

        // ────────────────────────────────────────────
        // 3b. Build Stator Ring (MabogeSlot) around jante
        // ────────────────────────────────────────────
        //
        // rInnerBase = jante outer radius (face extérieure de la jante)
        //            = janteDiametre/2 + janteEpaisseur/2
        // hauteur    = janteHauteur (même hauteur que la jante)
        // nPoles     = statorSlots (S, multiple de 3 — indépendant de P rotor)
        // zCenter    = paleHauteurEnd (centre de la jante en Z)

        // janteOuterR already computed above for hub↔stator interlocking
        let statorZCenter = paleHauteurEnd

        sceneManager.log("\u{2500}\u{2500} Building Stator Ring (MabogeSlot) \u{2500}\u{2500}")
        sceneManager.log("  Jante outer R=\(String(format: "%.1f", janteOuterR))  S=\(statorSlots) slots  P=\(nPoles) poles  Z=\(String(format: "%.1f", statorZCenter))")

        let voxStator = MabogeSlotTask.buildRingGeometry(
            sceneManager: sceneManager,
            nPoles: statorSlots,
            rInnerBase: janteOuterR,
            airGap: statorAirGap,
            profondeurA: statorProfA,
            profondeurB: statorProfB,
            profondeurC: statorProfC,
            hauteurH: janteHauteur,
            narrowPct: statorNarrowPct,
            flattenPct: statorFlattenPct,
            zCenter: statorZCenter
        )

        // ────────────────────────────────────────────
        // 4. Volumes
        // ────────────────────────────────────────────

        let turbProps = voxTurbine.calculateProperties()
        sceneManager.log("  Turbine: \(String(format: "%.1f", turbProps.volumeCubicMM)) mm\u{00B3}")
        if let magnets = voxMagnets {
            let magProps = magnets.calculateProperties()
            sceneManager.log("  Magnets: \(String(format: "%.1f", magProps.volumeCubicMM)) mm\u{00B3}")
        }
        let hubProps = voxHub.calculateProperties()
        let bearProps = voxBearing.calculateProperties()
        sceneManager.log("  Hub: \(String(format: "%.1f", hubProps.volumeCubicMM)) mm\u{00B3}")
        sceneManager.log("  Bearing: \(String(format: "%.1f", bearProps.volumeCubicMM)) mm\u{00B3}")
        let statorProps = voxStator.calculateProperties()
        sceneManager.log("  Stator: \(String(format: "%.1f", statorProps.volumeCubicMM)) mm\u{00B3}")

        // ────────────────────────────────────────────
        // 5. Display: 5 groups, hub semi-transparent
        // ────────────────────────────────────────────

        DispatchQueue.main.async {
            sceneManager.removeAllObjects()

            // Group 0: Turbine (Navy, opaque)
            sceneManager.addVoxels(voxTurbine, groupID: 0, name: "Turbine N\u{00E9}lis")
            sceneManager.setGroupMaterial(0, color: Cp.clrNavy, metallic: 0.7, roughness: 0.25)

            // Group 1: Magnets (Gold, opaque)
            if let magnets = voxMagnets {
                sceneManager.addVoxels(magnets, groupID: 1, name: "Aimants NdFeB")
                sceneManager.setGroupMaterial(1, color: Cp.clrGold, metallic: 0.9, roughness: 0.15)
            }

            // Group 2: Hub staircase (Frozen, 50% transparent)
            sceneManager.addVoxels(voxHub, groupID: 2, name: "Hub (transparent)")
            let hubColor = PKColorFloat(r: 0.6, g: 0.75, b: 0.85, a: 0.5)
            sceneManager.setGroupMaterial(2, color: hubColor, metallic: 0.5, roughness: 0.3)

            // Group 3: Ball bearing (Yellow, opaque)
            sceneManager.addVoxels(voxBearing, groupID: 3, name: "Roulement")
            sceneManager.setGroupMaterial(3, color: Cp.clrYellow, metallic: 0.8, roughness: 0.2)

            // Group 4: Stator MabogeSlot (Copper, opaque)
            sceneManager.addVoxels(voxStator, groupID: 4, name: "Stator MabogeSlot")
            sceneManager.setGroupMaterial(4, color: Cp.clrCopper, metallic: 0.85, roughness: 0.2)
        }

        // ────────────────────────────────────────────
        // 6. Export assembly STLs
        // ────────────────────────────────────────────

        sceneManager.log("Exporting assembly STLs...")

        let pathTurbine = ShExport.exportPath(filename: "Assembly_Turbine")
        sceneManager.exportSTL(voxels: voxTurbine, to: pathTurbine)
        sceneManager.log("  \u{2192} \(pathTurbine)")

        let pathHub = ShExport.exportPath(filename: "Assembly_Hub")
        sceneManager.exportSTL(voxels: voxHub, to: pathHub)
        sceneManager.log("  \u{2192} \(pathHub)")

        let pathBearing = ShExport.exportPath(filename: "Assembly_Bearing")
        sceneManager.exportSTL(voxels: voxBearing, to: pathBearing)
        sceneManager.log("  \u{2192} \(pathBearing)")

        if let magnets = voxMagnets {
            let pathMag = ShExport.exportPath(filename: "Assembly_Magnets")
            sceneManager.exportSTL(voxels: magnets, to: pathMag)
            sceneManager.log("  \u{2192} \(pathMag)")
        }

        let pathStator = ShExport.exportPath(filename: "Assembly_Stator")
        sceneManager.exportSTL(voxels: voxStator, to: pathStator)
        sceneManager.log("  \u{2192} \(pathStator)")

        sceneManager.log("=== Assembly done! ===")
    }
}
