// MabogeSlot.swift
// Genolanx — OC-1 Maboge Slot
//
// 3 couches concentriques — Drapeau Allemand (int → ext):
//   Jaune : rInnerBase + airGap → + profA  (2–6mm)  arc 100%  H 100%
//   Rouge : par dessus jaune    → + profB           arc narrow%  H flatten%
//   Noir  : par dessus rouge    → + profC           arc 100%  H 100%
//         + 2 losanges perforés en miroir sur l'axe central
//   arc = 360°/p, hauteur = H

import Foundation
import simd
import PicoGKBridge

// ═══════════════════════════════════════════════════════════════
// MARK: - Slot Mode (réservé pour plus tard)
// ═══════════════════════════════════════════════════════════════

enum MabogeSlotMode: Int, CaseIterable {
    case cavity = 0
    case slot   = 1

    var label: String {
        switch self {
        case .cavity: return "C (Cavity)"
        case .slot:   return "S (Slot)"
        }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Task Entry Point
// ═══════════════════════════════════════════════════════════════

enum MabogeSlotTask {

    static func run(sceneManager: SceneManager,
                    nPoles: Int,
                    rInnerBase: Float,
                    airGap: Float,
                    profondeurA: Float,
                    profondeurB: Float,
                    profondeurC: Float,
                    hauteurH: Float,
                    narrowPct: Float,
                    flattenPct: Float) {

        let phaseArc = (2.0 * Float.pi) / Float(nPoles)
        let halfH = hauteurH / 2.0
        let halfArc = phaseArc / 2.0

        // Couches (intérieur → extérieur)
        let rJauneI = rInnerBase + airGap
        let rJauneO = rJauneI + profondeurA

        let rRougeI = rJauneO
        let rRougeO = rRougeI + profondeurB

        let rNoirI = rRougeO
        let rNoirO = rNoirI + profondeurC

        // Rouge: narrow band + aplatir
        let rougeHalfArc = halfArc * (narrowPct / 100.0)
        let rougeHalfH = halfH * (flattenPct / 100.0)

        sceneManager.log("MabogeSlot — Drapeau Allemand")
        sceneManager.log("  p=\(nPoles)  arc=\(String(format: "%.2f", phaseArc * 180 / Float.pi))°  H=\(hauteurH)mm")
        sceneManager.log("  Jaune [\(String(format: "%.1f", rJauneI))…\(String(format: "%.1f", rJauneO))]  A=\(profondeurA)mm")
        sceneManager.log("  Rouge [\(String(format: "%.1f", rRougeI))…\(String(format: "%.1f", rRougeO))]  B=\(profondeurB)mm  narrow=\(String(format: "%.0f", narrowPct))%  flat=\(String(format: "%.0f", flattenPct))%")
        sceneManager.log("  Noir  [\(String(format: "%.1f", rNoirI))…\(String(format: "%.1f", rNoirO))]  C=\(profondeurC)mm + 2 losanges")

        // ── 3 secteurs ──
        let vJaune = renderSector(rI: rJauneI, rO: rJauneO, halfH: halfH,      halfArc: halfArc)
        let vRouge = renderSector(rI: rRougeI, rO: rRougeO, halfH: rougeHalfH, halfArc: rougeHalfArc)

        // Noir avec losanges perforés (vue du dessus, traversent toute la hauteur)
        let rNoirMid = (rNoirI + rNoirO) / 2.0
        let losangePhiOffset = halfArc * 0.5   // à mi-chemin entre centre et bord
        let vNoir = renderNoirWithLosanges(
            rI: rNoirI, rO: rNoirO,
            halfH: halfH, halfArc: halfArc,
            rLosCenter: rNoirMid,
            losPhiOffset: losangePhiOffset,
            losHalfL: 10.0,   // demi-longueur radiale (20/2)
            losHalfW: 5.5     // demi-largeur tangentielle (11/2)
        )

        sceneManager.log("  Jaune: \(String(format: "%.0f", vJaune.calculateProperties().volumeCubicMM)) mm³")
        sceneManager.log("  Rouge: \(String(format: "%.0f", vRouge.calculateProperties().volumeCubicMM)) mm³")
        sceneManager.log("  Noir:  \(String(format: "%.0f", vNoir.calculateProperties().volumeCubicMM)) mm³")

        // ── Affichage 3 couleurs ──
        DispatchQueue.main.async {
            sceneManager.removeAllObjects()

            sceneManager.addVoxels(vJaune, groupID: 0, name: "Jaune (A)")
            sceneManager.setGroupMaterial(0, color: Cp.clrYellow, metallic: 0.3, roughness: 0.5)

            sceneManager.addVoxels(vRouge, groupID: 1, name: "Rouge (B)")
            sceneManager.setGroupMaterial(1, color: Cp.clrRed, metallic: 0.5, roughness: 0.4)

            sceneManager.addVoxels(vNoir, groupID: 2, name: "Noir (C)")
            sceneManager.setGroupMaterial(2, color: Cp.clrBlack, metallic: 0.7, roughness: 0.25)
        }

        let vAll = vJaune + vRouge + vNoir
        let path = ShExport.exportPath(filename: "MabogeSlot_Allemand")
        sceneManager.exportSTL(voxels: vAll, to: path)
        sceneManager.log("STL → \(path)")
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: - Full Ring Geometry (reusable by MethorAssemblyTask)
    // ═══════════════════════════════════════════════════════════════

    /// Build a full 360° ring of nPoles sectors (Jaune + Rouge + Noir combined).
    /// Uses modular-angle SDF: one implicit per layer covers the entire ring.
    /// zCenter shifts the ring along Z for assembly positioning.
    static func buildRingGeometry(
        sceneManager: SceneManager,
        nPoles: Int,
        rInnerBase: Float,
        airGap: Float,
        profondeurA: Float,
        profondeurB: Float,
        profondeurC: Float,
        hauteurH: Float,
        narrowPct: Float,
        flattenPct: Float,
        zCenter: Float = 0
    ) -> PicoGKVoxels {

        let phaseArc = (2.0 * Float.pi) / Float(nPoles)
        let halfH = hauteurH / 2.0
        let halfArc = phaseArc / 2.0

        let rJauneI = rInnerBase + airGap
        let rJauneO = rJauneI + profondeurA
        let rRougeI = rJauneO
        let rRougeO = rRougeI + profondeurB
        let rNoirI = rRougeO
        let rNoirO = rNoirI + profondeurC

        let rougeHalfArc = halfArc * (narrowPct / 100.0)
        let rougeHalfH = halfH * (flattenPct / 100.0)

        let rNoirMid = (rNoirI + rNoirO) / 2.0
        let losPhiOffset = halfArc * 0.5

        sceneManager.log("MabogeSlot Ring — \(nPoles) p\u{00F4}les  Z=\(String(format: "%.1f", zCenter))")
        sceneManager.log("  Jaune [\(String(format: "%.1f", rJauneI))\u{2026}\(String(format: "%.1f", rJauneO))]")
        sceneManager.log("  Rouge [\(String(format: "%.1f", rRougeI))\u{2026}\(String(format: "%.1f", rRougeO))]  narrow=\(String(format: "%.0f", narrowPct))%")
        sceneManager.log("  Noir  [\(String(format: "%.1f", rNoirI))\u{2026}\(String(format: "%.1f", rNoirO))]  + losanges")

        // ── Jaune ring ──
        let vJaune = renderFullRingSector(nPoles: nPoles,
                                          rI: rJauneI, rO: rJauneO,
                                          halfH: halfH, halfArc: halfArc, zCenter: zCenter)
        // ── Rouge ring ──
        let vRouge = renderFullRingSector(nPoles: nPoles,
                                          rI: rRougeI, rO: rRougeO,
                                          halfH: rougeHalfH, halfArc: rougeHalfArc, zCenter: zCenter)
        // ── Noir ring with losanges ──
        let vNoir = renderFullRingNoirWithLosanges(
            nPoles: nPoles,
            rI: rNoirI, rO: rNoirO,
            halfH: halfH, halfArc: halfArc,
            rLosCenter: rNoirMid, losPhiOffset: losPhiOffset,
            losHalfL: 10.0, losHalfW: 5.5, zCenter: zCenter)

        let vAll = vJaune + vRouge + vNoir

        let props = vAll.calculateProperties()
        sceneManager.log("  Stator ring: \(String(format: "%.0f", props.volumeCubicMM)) mm\u{00B3}")

        return vAll
    }

    // ── Full-ring SDF: annular sectors using modular angle ──
    private static func renderFullRingSector(
        nPoles: Int, rI: Float, rO: Float,
        halfH: Float, halfArc: Float, zCenter: Float
    ) -> PicoGKVoxels {
        let rMid = (rO + rI) / 2.0
        let rHalf = (rO - rI) / 2.0
        let phaseArc = 2.0 * Float.pi / Float(nPoles)

        let margin: Float = 2.0
        let bounds = BBox3(
            min: SIMD3(-(rO + margin), -(rO + margin), zCenter - halfH - margin),
            max: SIMD3( (rO + margin),  (rO + margin), zCenter + halfH + margin)
        )

        let zC = zCenter
        let hA = halfArc
        let pA = phaseArc

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let r = sqrt(pt.x * pt.x + pt.y * pt.y)
            let phi = atan2(pt.y, pt.x)
            let z = pt.z - zC

            // Map to local sector: phi ∈ [-halfArc, halfArc]
            var phi2 = phi
            if phi2 < 0 { phi2 += 2.0 * Float.pi }
            var localPhi = phi2.truncatingRemainder(dividingBy: pA)
            if localPhi > hA { localPhi -= pA }

            let dR = abs(r - rMid) - rHalf
            let dZ = abs(z) - halfH
            let dT = (abs(localPhi) - hA) * r
            return max(dR, max(dZ, dT))
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }

    // ── Full-ring Noir with losanges using modular angle ──
    private static func renderFullRingNoirWithLosanges(
        nPoles: Int, rI: Float, rO: Float,
        halfH: Float, halfArc: Float,
        rLosCenter: Float, losPhiOffset: Float,
        losHalfL: Float, losHalfW: Float, zCenter: Float
    ) -> PicoGKVoxels {
        let rMid = (rO + rI) / 2.0
        let rHalf = (rO - rI) / 2.0
        let phaseArc = 2.0 * Float.pi / Float(nPoles)

        let margin: Float = 2.0
        let bounds = BBox3(
            min: SIMD3(-(rO + margin), -(rO + margin), zCenter - halfH - margin),
            max: SIMD3( (rO + margin),  (rO + margin), zCenter + halfH + margin)
        )

        let zC = zCenter
        let hA = halfArc
        let pA = phaseArc
        let rLC = rLosCenter
        let lPO = losPhiOffset
        let lHL = losHalfL
        let lHW = losHalfW

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let r = sqrt(pt.x * pt.x + pt.y * pt.y)
            let phi = atan2(pt.y, pt.x)
            let z = pt.z - zC

            var phi2 = phi
            if phi2 < 0 { phi2 += 2.0 * Float.pi }
            var localPhi = phi2.truncatingRemainder(dividingBy: pA)
            if localPhi > hA { localPhi -= pA }

            let dR = abs(r - rMid) - rHalf
            let dZ = abs(z) - halfH
            let dT = (abs(localPhi) - hA) * r
            var dNoir = max(dR, max(dZ, dT))

            // Losanges in local sector coordinates
            let tangDist = localPhi * rLC

            let tC1 = lPO * rLC
            let dr1 = abs(r - rLC)
            let dt1 = abs(tangDist - tC1)
            let los1 = (dr1 / lHL + dt1 / lHW - 1.0) * min(lHL, lHW)

            let tC2 = -lPO * rLC
            let dt2 = abs(tangDist - tC2)
            let los2 = (dr1 / lHL + dt2 / lHW - 1.0) * min(lHL, lHW)

            if los1 < 0 { dNoir = max(dNoir, -los1) }
            if los2 < 0 { dNoir = max(dNoir, -los2) }

            return dNoir
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }

    // ── SDF : 1 secteur d'anneau (standalone) ──
    private static func renderSector(rI: Float, rO: Float,
                                     halfH: Float, halfArc: Float) -> PicoGKVoxels {
        let rMid = (rO + rI) / 2.0
        let rHalf = (rO - rI) / 2.0

        let m: Float = 2.0
        let xMin = max(0, (rI - m) * cos(halfArc))
        let yExt = (rO + m) * sin(halfArc)
        let bounds = BBox3(
            min: SIMD3(xMin, -yExt, -(halfH + m)),
            max: SIMD3(rO + m, yExt, halfH + m)
        )

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let x = pt.x, y = pt.y, z = pt.z
            let r = sqrt(x * x + y * y)
            let dR = abs(r - rMid) - rHalf
            let dZ = abs(z) - halfH
            let phi = atan2(y, x)
            let dT = (abs(phi) - halfArc) * r
            return max(dR, max(dZ, dT))
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }

    // ── Noir avec 2 losanges perforés en miroir (vue du dessus) ──
    // Losange dans le plan XY (r, tangent) : |dr|/halfL + |dt|/halfW <= 1
    // Traverse toute la hauteur Z
    // 2 losanges symétriques à ±losPhiOffset de l'axe central (phi=0)
    private static func renderNoirWithLosanges(
        rI: Float, rO: Float,
        halfH: Float, halfArc: Float,
        rLosCenter: Float,        // rayon au centre des losanges
        losPhiOffset: Float,      // offset angulaire depuis l'axe central
        losHalfL: Float,          // demi-longueur radiale du losange (mm)
        losHalfW: Float           // demi-largeur tangentielle du losange (mm)
    ) -> PicoGKVoxels {

        let rMid = (rO + rI) / 2.0
        let rHalf = (rO - rI) / 2.0

        let m: Float = 2.0
        let xMin = max(0, (rI - m) * cos(halfArc))
        let yExt = (rO + m) * sin(halfArc)
        let bounds = BBox3(
            min: SIMD3(xMin, -yExt, -(halfH + m)),
            max: SIMD3(rO + m, yExt, halfH + m)
        )

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let x = pt.x, y = pt.y, z = pt.z
            let r = sqrt(x * x + y * y)

            // Secteur d'anneau noir
            let dR = abs(r - rMid) - rHalf
            let dZ = abs(z) - halfH
            let phi = atan2(y, x)
            let dT = (abs(phi) - halfArc) * r
            var dNoir = max(dR, max(dZ, dT))

            // Distance tangentielle en mm à ce rayon
            let tangDist = phi * rLosCenter

            // Losange 1 : à +losPhiOffset
            let tC1 = losPhiOffset * rLosCenter
            let dr1 = abs(r - rLosCenter)
            let dt1 = abs(tangDist - tC1)
            let los1 = (dr1 / losHalfL + dt1 / losHalfW - 1.0) * min(losHalfL, losHalfW)

            // Losange 2 : à -losPhiOffset (miroir)
            let tC2 = -losPhiOffset * rLosCenter
            let dt2 = abs(tangDist - tC2)
            let los2 = (dr1 / losHalfL + dt2 / losHalfW - 1.0) * min(losHalfL, losHalfW)

            // Soustraction CSG
            if los1 < 0 { dNoir = max(dNoir, -los1) }
            if los2 < 0 { dNoir = max(dNoir, -los2) }

            return dNoir
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }
}
