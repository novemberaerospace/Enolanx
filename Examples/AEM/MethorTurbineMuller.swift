// MethorTurbineMuller.swift
// Genolanx — Parametric Turbine Muller (Jante + Aimants + Pales boulonn\u{00E9}es)
//
// Jante annulaire à section rectangulaire avec:
//   1. Aimants NdFeB encastrés face extérieure (catalogue supermagnete.be)
//   2. Surfaçages rectangulaires (méplats) sur la face INTÉRIEURE pour les pales
//   3. Pales fixées par 2 encoches pentagonales (queue d'aronde) dans la jante
//
// Motifs d'aimants:
//   Standard:  N→ext / S→ext alternés (1 aimant/pôle)
//   Halbach V: 4 segments/pôle (→↑←↓) en chevron pour concentrer le flux
//
// Vue en coupe radiale (un pôle + une pale):
//
//        ← face ext (aimants)
//        ┌─────┬──────┬─────┐
//        │     │ magn │     │  ← aimant NdFeB
//        │     ├──────┤     │
//        │  ⬠ │      │ ⬠  │  ← 2× encoches pentagonales
//        └─────┤ base ├─────┘  ← méplat (surface plane, face int)
//               ╲    ╱
//                pale          ← s'étend vers le centre
//              ← face int (Ø360)
//
// Les encoches pentagonales ne traversent PAS jusqu'aux logements aimants.
// Profondeur encoche < épaisseur jante - profondeur magnet.
// Les aimants ne percent JAMAIS la jante (profondeur limitée automatiquement).

import simd
import Foundation
import PicoGKBridge

// ═══════════════════════════════════════════════════════════════
// MARK: - Magnet Catalog (supermagnete.be)
// ═══════════════════════════════════════════════════════════════

/// Un aimant du catalogue — dimensions L×W×T + grade + prix.
/// Source: supermagnete.be (février 2026)
struct MagnetCatalogEntry: Identifiable, Hashable {
    let id: String           // SKU
    let lengthMM: Float      // L (tangentiel sur jante)
    let widthMM: Float       // W (axial = hauteur jante)
    let thicknessMM: Float   // T (radial = profondeur dans jante)
    let grade: String        // ex: "N42"
    let brTesla: Float       // rémanence
    let label: String        // libellé court pour Picker

    /// Épaisseur de jante minimale pour contenir l'aimant + marge
    var minRimEpaisseur: Float { thicknessMM + 8 }
    /// Hauteur de jante minimale pour contenir l'aimant + marge
    var minRimHauteur: Float   { widthMM + 4 }
}

extension MagnetCatalogEntry {
    /// Catalogue bloc supermagnete.be — sélection pour LERF
    static let catalog: [MagnetCatalogEntry] = [
        // Micro
        MagnetCatalogEntry(id: "Q-10-05-02", lengthMM: 10, widthMM: 5,  thicknessMM: 2,  grade: "N50", brTesla: 1.43, label: "10×5×2 N50"),
        MagnetCatalogEntry(id: "Q-10-10-05", lengthMM: 10, widthMM: 10, thicknessMM: 5,  grade: "N42", brTesla: 1.29, label: "10×10×5 N42"),
        // Petit
        MagnetCatalogEntry(id: "Q-15-15-03", lengthMM: 15, widthMM: 15, thicknessMM: 3,  grade: "N45", brTesla: 1.35, label: "15×15×3 N45"),
        MagnetCatalogEntry(id: "Q-15-15-08", lengthMM: 15, widthMM: 15, thicknessMM: 8,  grade: "N42", brTesla: 1.29, label: "15×15×8 N42"),
        // Moyen
        MagnetCatalogEntry(id: "Q-20-10-05", lengthMM: 20, widthMM: 10, thicknessMM: 5,  grade: "N42", brTesla: 1.29, label: "20×10×5 N42"),
        MagnetCatalogEntry(id: "Q-20-20-05", lengthMM: 20, widthMM: 20, thicknessMM: 5,  grade: "N42", brTesla: 1.29, label: "20×20×5 N42"),
        MagnetCatalogEntry(id: "Q-20-20-10", lengthMM: 20, widthMM: 20, thicknessMM: 10, grade: "N42", brTesla: 1.29, label: "20×20×10 N42"),
        // Standard
        MagnetCatalogEntry(id: "Q-30-10-05", lengthMM: 30, widthMM: 10, thicknessMM: 5,  grade: "N42", brTesla: 1.29, label: "30×10×5 N42"),
        MagnetCatalogEntry(id: "Q-30-30-15", lengthMM: 30, widthMM: 30, thicknessMM: 15, grade: "N45", brTesla: 1.35, label: "30×30×15 N45"),
        // Large
        MagnetCatalogEntry(id: "Q-40-10-05", lengthMM: 40, widthMM: 10, thicknessMM: 5,  grade: "N42", brTesla: 1.29, label: "40×10×5 N42"),
        MagnetCatalogEntry(id: "Q-40-20-05", lengthMM: 40, widthMM: 20, thicknessMM: 5,  grade: "N42", brTesla: 1.29, label: "40×20×5 N42"),
        MagnetCatalogEntry(id: "Q-40-20-10", lengthMM: 40, widthMM: 20, thicknessMM: 10, grade: "N42", brTesla: 1.29, label: "40×20×10 N42"),
        // Puissance
        MagnetCatalogEntry(id: "Q-50-15-15", lengthMM: 50, widthMM: 15, thicknessMM: 15, grade: "N48", brTesla: 1.40, label: "50×15×15 N48"),
        MagnetCatalogEntry(id: "Q-60-30-15", lengthMM: 60, widthMM: 30, thicknessMM: 15, grade: "N40", brTesla: 1.26, label: "60×30×15 N40"),
    ]

    static func find(id: String) -> MagnetCatalogEntry? {
        catalog.first { $0.id == id }
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Magnet Pattern
// ═══════════════════════════════════════════════════════════════

/// Motif d'arrangement des aimants sur la jante.
enum MagnetPattern: Int, CaseIterable {
    /// Standard: tous les aimants orientés radialement (N→ext, S→ext alternés)
    case standard = 0
    /// Halbach chevron (V): aimants en V pour concentrer le flux côté entrefer
    /// Pattern: →↑←↓ (4 aimants/pôle, orientés à 90° successifs)
    case halbachChevron = 1

    var label: String {
        switch self {
        case .standard:       return "Standard (radial)"
        case .halbachChevron: return "Halbach chevron (V)"
        }
    }
}

// ═══════════════════════════════════════════════════════════════

final class MethorRimTask {

    // MARK: - Jante Parameters (mm)

    let rayonInterieur: Float    // rayon intérieur de la jante (180 mm = Ø360)
    let epaisseur: Float         // épaisseur radiale de la jante
    let hauteur: Float           // hauteur axiale de la jante

    // MARK: - Magnet Parameters

    let nPoles: Int              // nombre de pôles magnétiques
    let magnetLargeur: Float     // largeur tangentielle (face plate)
    let magnetHauteur: Float     // hauteur axiale (face plate)
    let magnetProfondeur: Float  // profondeur radiale (encastrement)
    let magnetJeu: Float         // jeu d'assemblage
    let magnetPattern: MagnetPattern // motif d'arrangement

    // MARK: - Pale Parameters

    let nPales: Int              // nombre de pales
    let paleLargeur: Float       // largeur tangentielle de la base de pale
    let paleHauteurRadiale: Float // hauteur radiale de la pale (extension vers ext)
    let paleBaseEpaisseur: Float // épaisseur de la base de fixation
    let meplatProfondeur: Float  // profondeur du surfaçage (méplat)

    // MARK: - NACA Airfoil Parameters

    let nacaM: Float             // cambrure max (en % corde) — NACA 2412 → 2
    let nacaP: Float             // position cambrure max (en dixièmes) — NACA 2412 → 4
    let nacaT: Float             // épaisseur max (en % corde) — NACA 2412 → 12

    // MARK: - Blade Angle Parameters

    let palePitch: Float         // inclinaison axiale en degrés (+ = pointe monte, - = descend)
    let paleSweep: Float         // balayage tangentiel en degrés (+ = horaire, - = anti-horaire) ±20°

    // MARK: - Encoche Parameters (pentagonale)

    let encocheLargeur: Float    // largeur de l'encoche (tangentiel) au fond
    let encocheLargeurHaut: Float // largeur de l'encoche en haut (côté face int) → trapèze
    let encocheProfondeur: Float // profondeur radiale de l'encoche dans la jante
    let encochePropHauteur: Float // proportion de la hauteur de jante occupée par l'encoche
    let encocheEntraxe: Float    // entraxe entre les 2 encoches
    let encocheJeu: Float        // jeu d'assemblage pour la languette

    // MARK: - Derived

    var rayonExterieur: Float   { rayonInterieur + epaisseur }
    var rayonMoyen: Float       { rayonInterieur + epaisseur / 2 }

    // MARK: - Init

    init(rayonInterieur: Float = 180,
         epaisseur: Float = 15,
         hauteur: Float = 25,
         nPoles: Int = 24,
         magnetLargeur: Float = 20,
         magnetHauteur: Float = 10,
         magnetProfondeur: Float = 5,
         magnetJeu: Float = 0.15,
         magnetPattern: MagnetPattern = .standard,
         nPales: Int = 3,
         paleLargeur: Float = 40,
         paleHauteurRadiale: Float = 80,
         paleBaseEpaisseur: Float = 6,
         meplatProfondeur: Float = 2,
         nacaM: Float = 2,
         nacaP: Float = 4,
         nacaT: Float = 12,
         palePitch: Float = 0,
         paleSweep: Float = 0,
         encocheLargeur: Float = 8,
         encocheLargeurHaut: Float = 12,
         encocheProfondeur: Float = 7,
         encochePropHauteur: Float = 0.6,
         encocheEntraxe: Float = 24,
         encocheJeu: Float = 0.15) {
        self.rayonInterieur = rayonInterieur
        self.epaisseur = epaisseur
        self.hauteur = hauteur
        self.nPoles = nPoles
        self.magnetLargeur = magnetLargeur
        self.magnetHauteur = magnetHauteur
        self.magnetProfondeur = magnetProfondeur
        self.magnetJeu = magnetJeu
        self.magnetPattern = magnetPattern
        self.nPales = nPales
        self.paleLargeur = paleLargeur
        self.paleHauteurRadiale = paleHauteurRadiale
        self.paleBaseEpaisseur = paleBaseEpaisseur
        self.meplatProfondeur = meplatProfondeur
        self.nacaM = nacaM
        self.nacaP = nacaP
        self.nacaT = nacaT
        self.palePitch = palePitch
        self.paleSweep = paleSweep
        self.encocheLargeur = encocheLargeur
        self.encocheLargeurHaut = encocheLargeurHaut
        self.encocheProfondeur = encocheProfondeur
        self.encochePropHauteur = encochePropHauteur
        self.encocheEntraxe = encocheEntraxe
        self.encocheJeu = encocheJeu
    }

    // MARK: - Entry Point

    static func run(sceneManager: SceneManager,
                    rayonInterieur: Float = 180,
                    epaisseur: Float = 15,
                    hauteur: Float = 25,
                    nPoles: Int = 24,
                    magnetLargeur: Float = 20,
                    magnetHauteur: Float = 10,
                    magnetProfondeur: Float = 5,
                    magnetJeu: Float = 0.15,
                    magnetPattern: MagnetPattern = .standard,
                    nPales: Int = 3,
                    paleLargeur: Float = 40,
                    paleHauteurRadiale: Float = 80,
                    nacaM: Float = 2,
                    nacaP: Float = 4,
                    nacaT: Float = 12,
                    palePitch: Float = 0,
                    paleSweep: Float = 0) {
        let nacaName = String(format: "NACA %01.0f%01.0f%02.0f", nacaM, nacaP, nacaT)
        let chord = sqrt(paleLargeur * paleLargeur + hauteur * hauteur)
        sceneManager.log("Starting MethorRim Task.")
        sceneManager.log("  Jante: Ø int=\(rayonInterieur * 2) mm  ép=\(epaisseur) mm  H=\(hauteur) mm")
        sceneManager.log("  Poles: \(nPoles)  (\(nPoles / 2) paires)")
        sceneManager.log("  Magnet: \(magnetLargeur)×\(magnetHauteur)×\(magnetProfondeur) mm  jeu=\(magnetJeu) mm")
        sceneManager.log("  Pattern: \(magnetPattern.label)")
        if magnetPattern == .halbachChevron {
            sceneManager.log("    Halbach: \(nPoles * 4) segments (4 par pôle, rotation 90°)")
        }
        sceneManager.log("  Pales: \(nPales)x  profil \(nacaName)  corde=\(String(format: "%.1f", chord)) mm (auto-fit)")
        sceneManager.log("    envergure=\(paleHauteurRadiale) mm  pitch=\(palePitch)°  sweep=\(paleSweep)°")
        sceneManager.log("  Fixation: 2× encoches pentagonales  entraxe=24 mm")

        let rim = MethorRimTask(
            rayonInterieur: rayonInterieur,
            epaisseur: epaisseur,
            hauteur: hauteur,
            nPoles: nPoles,
            magnetLargeur: magnetLargeur,
            magnetHauteur: magnetHauteur,
            magnetProfondeur: magnetProfondeur,
            magnetJeu: magnetJeu,
            magnetPattern: magnetPattern,
            nPales: nPales,
            paleLargeur: paleLargeur,
            paleHauteurRadiale: paleHauteurRadiale,
            nacaM: nacaM,
            nacaP: nacaP,
            nacaT: nacaT,
            palePitch: palePitch,
            paleSweep: paleSweep
        )

        rim.construct(sceneManager: sceneManager)
        sceneManager.log("Finished MethorRim Task successfully.")
    }

    // MARK: - Main Assembly

    private func construct(sceneManager: SceneManager) {

        // 1. Jante annulaire (section rectangulaire)
        sceneManager.log("Building jante rectangulaire...")
        let voxJante = makeJante()

        // 2. Logements magnets (poches face ext)
        let pocketDesc = magnetPattern == .halbachChevron ? "\(nPoles)×4 Halbach" : "\(nPoles) standard"
        sceneManager.log("Cutting \(pocketDesc) magnet pockets...")
        let voxMagnetPockets = makeMagnetPockets(sceneManager: sceneManager)

        // 3. Surfaçages rectangulaires (méplats pour pales)
        sceneManager.log("Cutting \(nPales) méplats...")
        let voxMeplats = makeMeplats()

        // 4. Encoches pentagonales dans la jante (2 par pale)
        sceneManager.log("Cutting \(nPales * 2) pentagonal notches in rim...")
        let voxEncoches = makeEncochesJante()

        // 5. Boolean: jante - magnets - méplats - encoches
        var voxRim = voxJante - voxMagnetPockets
        voxRim = voxRim - voxMeplats
        voxRim = voxRim - voxEncoches
        voxRim = voxRim.smoothened(0.2)

        // 6. Magnets (visualisation)
        let magDesc = magnetPattern == .halbachChevron ? "\(nPoles)×4 Halbach" : "\(nPoles) standard"
        sceneManager.log("Building \(magDesc) magnets...")
        let voxMagnets = makeMagnets(sceneManager: sceneManager)

        // 7. Pales (avec base + languettes pentagonales)
        sceneManager.log("Building \(nPales) pales...")
        let voxPales = makePales(sceneManager: sceneManager)

        // 8. Volume
        let rimProps = voxRim.calculateProperties()
        let magProps = voxMagnets.calculateProperties()
        let paleProps = voxPales.calculateProperties()
        sceneManager.log("  Rim volume: \(String(format: "%.1f", rimProps.volumeCubicMM)) mm³")
        sceneManager.log("  Magnets volume: \(String(format: "%.1f", magProps.volumeCubicMM)) mm³")
        sceneManager.log("  Pales volume: \(String(format: "%.1f", paleProps.volumeCubicMM)) mm³")

        // 9. Display: 3 groups
        DispatchQueue.main.async {
            sceneManager.removeAllObjects()

            // Group 0: Jante → Silver
            sceneManager.addVoxels(voxRim, groupID: 0, name: "MethorRim")
            sceneManager.setGroupMaterial(0, color: Cp.clrSilver, metallic: 0.8, roughness: 0.2)

            // Group 1: Magnets → Gold (NdFeB)
            sceneManager.addVoxels(voxMagnets, groupID: 1, name: "Magnets NdFeB")
            sceneManager.setGroupMaterial(1, color: Cp.clrGold, metallic: 0.9, roughness: 0.15)

            // Group 2: Pales → Navy
            sceneManager.addVoxels(voxPales, groupID: 2, name: "Pales")
            sceneManager.setGroupMaterial(2, color: Cp.clrNavy, metallic: 0.6, roughness: 0.3)
        }

        // 10. Export
        sceneManager.log("Exporting STLs...")

        let pathRim = ShExport.exportPath(filename: "MethorRim_Jante")
        sceneManager.exportSTL(voxels: voxRim, to: pathRim)
        sceneManager.log("  → \(pathRim)")

        let pathMagnets = ShExport.exportPath(filename: "MethorRim_Magnets")
        sceneManager.exportSTL(voxels: voxMagnets, to: pathMagnets)
        sceneManager.log("  → \(pathMagnets)")

        let pathPales = ShExport.exportPath(filename: "MethorRim_Pales")
        sceneManager.exportSTL(voxels: voxPales, to: pathPales)
        sceneManager.log("  → \(pathPales)")

        sceneManager.log("Done!")
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: - Jante
    // ═══════════════════════════════════════════════════════════════

    private func makeJante() -> PicoGKVoxels {
        let rCenter = rayonMoyen
        let halfE = epaisseur / 2
        let halfH = hauteur / 2
        let rOuter = rayonExterieur

        let margin: Float = 2
        let bounds = BBox3(
            min: SIMD3(-(rOuter + margin), -(rOuter + margin), -(halfH + margin)),
            max: SIMD3( (rOuter + margin),  (rOuter + margin),  (halfH + margin))
        )

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let r = sqrt(pt.x * pt.x + pt.y * pt.y)
            let dz = abs(pt.z) - halfH
            let dr = abs(r - rCenter) - halfE
            return max(dz, dr)
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: - Méplats (surfaçages rectangulaires)
    // ═══════════════════════════════════════════════════════════════

    /// Coupe plane sur la face INTÉRIEURE de la jante à chaque position de pale.
    /// Le méplat est un bloc qui coupe la courbure intérieure pour créer
    /// une surface plane où la base de pale vient se plaquer.
    private func makeMeplats() -> PicoGKVoxels {
        var voxAll: PicoGKVoxels?

        for i in 0..<nPales {
            let phi = Float(i) / Float(nPales) * 2 * Float.pi
            let vox = makeSingleMeplat(phi: phi)
            if let existing = voxAll {
                voxAll = existing + vox
            } else {
                voxAll = vox
            }
        }

        return voxAll ?? PicoGKVoxels()
    }

    /// Un méplat: bloc qui coupe la face intérieure de la jante.
    /// Le plan tangent passe à meplatProfondeur au-dessus du rayon intérieur.
    /// Largeur = paleLargeur, Hauteur = hauteur de jante.
    private func makeSingleMeplat(phi: Float) -> PicoGKVoxels {
        let dirR = SIMD3<Float>(cos(phi), sin(phi), 0)
        let dirT = SIMD3<Float>(-sin(phi), cos(phi), 0)

        // Le méplat coupe depuis en dessous de rInt jusqu'à rInt + prof
        let rCut = rayonInterieur + meplatProfondeur
        let depth: Float = meplatProfondeur + 2  // dépasse en dessous de rInt
        let rCenter = rCut - depth / 2

        let center = dirR * rCenter
        let halfL = paleLargeur / 2
        let halfH = hauteur / 2 + 0.5
        let halfP = depth / 2

        let corners = boxCorners(center: center, dirT: dirT, dirR: dirR,
                                  halfL: halfL, halfH: halfH, halfP: halfP)
        let bounds = boundsFromCorners(corners, margin: 2)

        let ctr = center
        let dR = dirR
        let dT = dirT
        let hL = halfL
        let hHt = halfH
        let hP = halfP

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let v = pt - ctr
            let projT = simd_dot(v, dT)
            let projZ = v.z
            let projR = simd_dot(v, dR)
            return max(abs(projT) - hL, max(abs(projZ) - hHt, abs(projR) - hP))
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: - Encoches pentagonales (dans la jante)
    // ═══════════════════════════════════════════════════════════════

    /// 2 encoches pentagonales par pale, creusées depuis la face intérieure
    /// de la jante. Forme trapézoïdale: plus large côté face int (entrée),
    /// plus étroite au fond → verrouillage mécanique.
    /// La profondeur est limitée pour ne PAS atteindre les logements aimants.
    private func makeEncochesJante() -> PicoGKVoxels {
        var voxAll: PicoGKVoxels?

        // Sécurité: la profondeur d'encoche ne doit pas toucher les magnets
        let maxProf = epaisseur - magnetProfondeur - magnetJeu - 1.0
        let profEffective = min(encocheProfondeur, maxProf)

        for i in 0..<nPales {
            let phi = Float(i) / Float(nPales) * 2 * Float.pi
            let dirR = SIMD3<Float>(cos(phi), sin(phi), 0)
            let dirT = SIMD3<Float>(-sin(phi), cos(phi), 0)

            // 2 encoches espacées de encocheEntraxe le long de la tangente
            for sign: Float in [-1, 1] {
                let offset = dirT * (sign * encocheEntraxe / 2)
                let vox = makeSingleEncoche(dirR: dirR, dirT: dirT,
                                             tangentOffset: offset,
                                             profondeur: profEffective)
                if let existing = voxAll {
                    voxAll = existing + vox
                } else {
                    voxAll = vox
                }
            }
        }

        return voxAll ?? PicoGKVoxels()
    }

    /// Une encoche pentagonale (trapèze en coupe tangentielle × hauteur axiale).
    ///
    /// Vue en coupe tangentielle (perpendiculaire au rayon):
    ///
    ///     face int (entrée)
    ///     ┌────────────┐  largeurHaut (plus large)
    ///     │            │
    ///      ╲          ╱
    ///       └────────┘    largeur (plus étroit, au fond)
    ///     face ext (fond)
    ///
    /// L'encoche s'étend radialement depuis la face int vers l'ext,
    /// sur une profondeur limitée (ne touche pas les aimants).
    /// Hauteur axiale = encochePropHauteur × hauteur de jante.
    private func makeSingleEncoche(dirR: SIMD3<Float>, dirT: SIMD3<Float>,
                                    tangentOffset: SIMD3<Float>,
                                    profondeur: Float) -> PicoGKVoxels {

        // Centre de l'encoche: radialement au milieu de la profondeur,
        // partant de la face intérieure
        let rStart = rayonInterieur              // face int (entrée)
        let rEnd = rayonInterieur + profondeur   // fond (vers ext)
        let rCenter = (rStart + rEnd) / 2

        let center = dirR * rCenter + tangentOffset
        let encH = hauteur * encochePropHauteur  // hauteur axiale de l'encoche
        let halfH = encH / 2
        let halfP = profondeur / 2

        // Largeurs: interpolation linéaire entre haut (face int) et fond
        let wHaut = encocheLargeurHaut / 2  // demi-largeur côté face int
        let wFond = encocheLargeur / 2      // demi-largeur au fond

        // Bounding box
        let maxW = max(wHaut, wFond) + 2
        let corners = boxCorners(center: center, dirT: dirT, dirR: dirR,
                                  halfL: maxW, halfH: halfH + 1, halfP: halfP + 1)
        let bounds = boundsFromCorners(corners, margin: 2)

        // Captures pour la closure SDF
        let ctr = center
        let dR = dirR
        let dT = dirT
        let hH = halfH
        let hP = halfP
        let wH = wHaut
        let wF = wFond

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let v = pt - ctr
            let projR = simd_dot(v, dR)   // radial: -halfP = face int, +halfP = fond
            let projT = simd_dot(v, dT)   // tangentiel
            let projZ = v.z               // axial

            // Distance radiale (profondeur)
            let dR_dist = abs(projR) - hP

            // Distance axiale (hauteur)
            let dZ = abs(projZ) - hH

            // Largeur tangentielle variable: interpole entre face int et fond
            // t = 0 à la face int (projR = -halfP), t = 1 au fond (projR = +halfP)
            let t = (projR + hP) / (2 * hP)
            let tClamped = max(0, min(1, t))
            let localHalfW = wH + (wF - wH) * tClamped  // wH à l'entrée, wF au fond

            let dT_dist = abs(projT) - localHalfW

            // Intersection des 3 contraintes
            return max(dR_dist, max(dZ, dT_dist))
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: - NACA 4-Digit Airfoil
    // ═══════════════════════════════════════════════════════════════

    /// Calcule la demi-épaisseur NACA à une position x/c normalisée [0,1].
    /// Formule standard NACA 4-digit (épaisseur symétrique).
    /// Retourne la demi-épaisseur en fraction de corde.
    private static func nacaThickness(x: Float, t: Float) -> Float {
        let tc = t / 100.0  // épaisseur en fraction (12% → 0.12)
        let sqrtX = sqrt(max(0, x))
        return (tc / 0.2) * (
            0.2969 * sqrtX
          - 0.1260 * x
          - 0.3516 * x * x
          + 0.2843 * x * x * x
          - 0.1015 * x * x * x * x   // bord de fuite fermé
        )
    }

    /// Calcule la ligne de cambrure NACA à une position x/c normalisée [0,1].
    /// Retourne le décalage de cambrure en fraction de corde.
    private static func nacaCamber(x: Float, m: Float, p: Float) -> Float {
        let mc = m / 100.0  // cambrure max en fraction (2% → 0.02)
        let pc = p / 10.0   // position en fraction de corde (4 → 0.4)
        guard mc > 0 && pc > 0 && pc < 1 else { return 0 }

        if x < pc {
            return mc / (pc * pc) * (2 * pc * x - x * x)
        } else {
            let omp = 1 - pc
            return mc / (omp * omp) * ((1 - 2 * pc) + 2 * pc * x - x * x)
        }
    }

    /// SDF distance d'un point 2D (xNorm, yNorm) au profil NACA.
    /// xNorm, yNorm sont en coordonnées normalisées [0,1] × [-0.5, 0.5].
    /// Retourne une distance approximée (négatif = à l'intérieur du profil).
    ///
    /// Pour chaque x ∈ [0,1], on connaît:
    ///   - yc(x) = cambrure
    ///   - yt(x) = demi-épaisseur
    /// Le profil va de yc - yt (intrados) à yc + yt (extrados).
    private static func nacaSDF(xNorm: Float, yNorm: Float,
                                 m: Float, p: Float, t: Float) -> Float {
        // Clamp x pour rester dans [0, 1]
        let xc = max(0, min(1, xNorm))

        let yc = nacaCamber(x: xc, m: m, p: p)
        let yt = nacaThickness(x: xc, t: t)

        // Distance par rapport au profil en y
        let yRel = yNorm - yc      // position relative à la cambrure
        let dY = abs(yRel) - yt    // négatif si à l'intérieur

        // Distance en x (si hors [0,1])
        let dX: Float
        if xNorm < 0 {
            dX = -xNorm
        } else if xNorm > 1 {
            dX = xNorm - 1
        } else {
            dX = -min(xNorm, 1 - xNorm)  // négatif à l'intérieur
        }

        // Combinaison: si les deux sont négatifs, on est à l'intérieur
        if dX < 0 && dY < 0 {
            return max(dX, dY)  // le plus grand négatif = le plus proche de la surface
        } else if dX < 0 {
            return dY
        } else if dY < 0 {
            return dX
        } else {
            return sqrt(dX * dX + dY * dY)  // coin: distance euclidienne
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: - Pales (profil NACA)
    // ═══════════════════════════════════════════════════════════════

    /// Génère toutes les pales.
    private func makePales(sceneManager: SceneManager) -> PicoGKVoxels {
        var voxAll: PicoGKVoxels?

        for i in 0..<nPales {
            let phi = Float(i) / Float(nPales) * 2 * Float.pi
            sceneManager.log("  Pale \(i + 1)/\(nPales)...")
            let voxPale = makeSinglePale(phi: phi)
            if let existing = voxAll {
                voxAll = existing + voxPale
            } else {
                voxAll = voxPale
            }
        }

        return voxAll ?? PicoGKVoxels()
    }

    /// Une pale = base de fixation rectangulaire + aile NACA vers l'intérieur
    ///          + 2 languettes pentagonales qui s'insèrent dans les encoches.
    ///
    /// La corde NACA est auto-calculée = diagonale du rectangle (paleLargeur × hauteur)
    /// pour remplir tout l'espace disponible. Le profil est orienté en diagonale
    /// dans le plan (tangentiel T × axial Z).
    ///
    /// Angles de pale (progressifs du pied à la pointe):
    ///   - palePitch: rotation autour de l'axe tangentiel (pointe monte/descend)
    ///   - paleSweep: rotation autour de l'axe radial (balayage horaire/anti-horaire)
    ///
    /// Les languettes pentagonales dépassent vers l'extérieur (non affectées par les angles).
    private func makeSinglePale(phi: Float) -> PicoGKVoxels {
        let dirR = SIMD3<Float>(cos(phi), sin(phi), 0)
        let dirT = SIMD3<Float>(-sin(phi), cos(phi), 0)

        let rInt = rayonInterieur

        // ── Base de fixation ──
        let halfBL = paleLargeur / 2
        let halfBH = hauteur / 2

        // ── Corde NACA auto-fit: diagonale du rectangle base ──
        let chord = sqrt(paleLargeur * paleLargeur + hauteur * hauteur)
        // Angle d'orientation de la corde dans le plan (T, Z):
        // la corde va d'un coin à l'autre du rectangle
        let chordAngle = atan2(hauteur, paleLargeur)  // angle par rapport à T

        // ── Aile NACA ──
        let rWingStart = rInt - paleBaseEpaisseur
        let rWingEnd = rWingStart - paleHauteurRadiale

        // ── Angles en radians ──
        let pitchRad = palePitch * Float.pi / 180.0
        let sweepRad = paleSweep * Float.pi / 180.0

        // ── Languettes ──
        let maxProf = epaisseur - magnetProfondeur - magnetJeu - 1.0
        let profLang = min(encocheProfondeur - encocheJeu, maxProf - encocheJeu)
        let langH = hauteur * encochePropHauteur
        let langWHaut = (encocheLargeurHaut - 2 * encocheJeu) / 2
        let langWFond = (encocheLargeur - 2 * encocheJeu) / 2

        // ── Bounding box (élargie pour couvrir les angles) ──
        let rMax = rInt + profLang + 2
        let rMin = max(0, rWingEnd - paleHauteurRadiale * abs(sin(pitchRad)) - 2)
        let tangMax = halfBL + paleHauteurRadiale * abs(sin(sweepRad)) + 2
        let zMax = halfBH + paleHauteurRadiale * abs(sin(pitchRad)) + 2

        var bbMin = SIMD3<Float>(repeating: Float.greatestFiniteMagnitude)
        var bbMax = SIMD3<Float>(repeating: -Float.greatestFiniteMagnitude)

        for rr in [rMin, rMax] {
            for ts: Float in [-1, 1] {
                for zs: Float in [-1, 1] {
                    let pt = dirR * rr + dirT * (ts * tangMax) + SIMD3(0, 0, zs * zMax)
                    bbMin = simd_min(bbMin, pt)
                    bbMax = simd_max(bbMax, pt)
                }
            }
        }

        let bounds = BBox3(min: bbMin, max: bbMax)

        // ── Captures SDF ──
        let dR = dirR
        let dT = dirT
        let bE = paleBaseEpaisseur
        let hBL = halfBL
        let hBH = halfBH
        let rWS = rWingStart
        let pHR = paleHauteurRadiale
        let crd = chord
        let cAngle = chordAngle
        let nM = nacaM
        let nPr = nacaP
        let nT = nacaT
        let pPitch = pitchRad
        let pSweep = sweepRad

        // Languettes
        let lProfEff = profLang
        let lHalfH = langH / 2
        let lWH = langWHaut
        let lWF = langWFond
        let lEntraxe = encocheEntraxe

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let projR = simd_dot(pt, dR)
            let projT = simd_dot(pt, dT)
            let projZ = pt.z

            // ── Base de fixation: box plaquée face intérieure ──
            let baseR = rInt - projR
            let dBaseR: Float
            if baseR < 0 {
                dBaseR = -baseR
            } else if baseR > bE {
                dBaseR = baseR - bE
            } else {
                dBaseR = -min(baseR, bE - baseR)
            }
            let dBaseT = abs(projT) - hBL
            let dBaseZ = abs(projZ) - hBH
            let dBase = max(dBaseR, max(dBaseT, dBaseZ))

            // ── Aile NACA avec pitch + sweep ──
            // span = distance depuis le pied vers la pointe (0 = pied, pHR = pointe)
            // On travaille en coordonnées locales relatives au pied de l'aile

            // Position relative au pied (face intérieure - épaisseur base)
            let localR = rWS - projR   // positif vers la pointe (centre)
            let localT = projT         // tangentiel (inchangé au pied)
            let localZ = projZ         // axial (inchangé au pied)

            // Appliquer pitch et sweep progressivement le long du span
            // Au pied (localR=0): pas de rotation. À la pointe (localR=pHR): rotation complète
            let spanFrac = max(0, min(1, localR / pHR))

            // Pitch: rotation autour de l'axe T → déplace la pointe en Z
            // Le décalage Z augmente linéairement avec le span
            let zOffset = localR * sin(pPitch * spanFrac)
            let rCorrPitch = localR * cos(pPitch * spanFrac)

            // Sweep: rotation autour de l'axe R → déplace la pointe en T
            // Le décalage T augmente linéairement avec le span
            let tOffset = localR * sin(pSweep * spanFrac)
            let rCorrSweep = rCorrPitch * cos(pSweep * spanFrac)

            // Coordonnées corrigées de l'aile
            let wingR = rCorrSweep          // span effectif après rotations
            let wingT = localT - tOffset    // tangentiel corrigé du sweep
            let wingZ = localZ - zOffset    // axial corrigé du pitch

            // Distance radiale (envergure)
            let dSpan = max(-wingR, wingR - pHR)

            // ── Profil NACA dans le plan (T, Z) orienté en diagonale ──
            // La corde suit la diagonale du rectangle:
            // Direction de la corde: angle cAngle dans le plan (T, Z)
            let cosCA = cos(cAngle)
            let sinCA = sin(cAngle)

            // Taper: réduction de corde du pied à la pointe (100% → 60%)
            let taper = max(0, min(1, wingR / pHR))
            let scaleFactor: Float = 1.0 - 0.4 * taper
            let localChord = crd * scaleFactor
            guard localChord > 0.1 else {
                return min(dBase, Float.greatestFiniteMagnitude)
            }

            // Projeter wingT, wingZ sur les axes corde et épaisseur
            // Axe corde = (cosCA, sinCA) dans le plan (T, Z)
            // Axe épaisseur = (-sinCA, cosCA) perpendiculaire
            let projCorde = wingT * cosCA + wingZ * sinCA
            let projEpais = -wingT * sinCA + wingZ * cosCA

            // Normaliser par la corde locale
            let halfLC = localChord / 2
            let xNaca = (projCorde + halfLC) / localChord    // [0, 1]
            let yNaca = projEpais / localChord                // normalisé

            // SDF 2D du profil NACA
            let d2D = MethorRimTask.nacaSDF(xNorm: xNaca, yNorm: yNaca,
                                             m: nM, p: nPr, t: nT) * localChord

            // Combinaison envergure × profil
            let dWing: Float
            if dSpan < 0 && d2D < 0 {
                dWing = max(dSpan, d2D)
            } else if dSpan < 0 {
                dWing = d2D
            } else if d2D < 0 {
                dWing = dSpan
            } else {
                dWing = sqrt(dSpan * dSpan + d2D * d2D)
            }

            // ── 2 Languettes pentagonales (pas affectées par pitch/sweep) ──
            var dLangBest: Float = Float.greatestFiniteMagnitude
            for s: Float in [-1, 1] {
                let langCenterT = s * lEntraxe / 2
                let langLocalT = projT - langCenterT

                let langR = projR - rInt
                let dLangR = max(-langR, langR - lProfEff)
                let dLangZ = abs(projZ) - lHalfH

                let tLang = max(0, min(1, langR / max(lProfEff, 0.001)))
                let localHalfW = lWH + (lWF - lWH) * tLang
                let dLangT = abs(langLocalT) - localHalfW

                let dLang = max(dLangR, max(dLangZ, dLangT))
                dLangBest = min(dLangBest, dLang)
            }

            // Union: base + aile NACA + languettes
            return min(dBase, min(dWing, dLangBest))
        }

        let voxPale = PicoGKVoxels()
        voxPale.renderImplicit(sdf, bounds: bounds)

        return voxPale
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: - Magnet Pockets (face extérieure)
    // ═══════════════════════════════════════════════════════════════

    /// Crée les poches pour les aimants.
    /// Standard: 1 poche rectangulaire par pôle.
    /// Halbach chevron: 4 poches par pôle (segments à 90° successifs).
    private func makeMagnetPockets(sceneManager: SceneManager) -> PicoGKVoxels {
        switch magnetPattern {
        case .standard:
            return makeStandardMagnetPockets(sceneManager: sceneManager)
        case .halbachChevron:
            return makeHalbachMagnetPockets(sceneManager: sceneManager, isPocket: true)
        }
    }

    /// Poches standard: 1 rectangulaire par pôle sur la face extérieure.
    private func makeStandardMagnetPockets(sceneManager: SceneManager) -> PicoGKVoxels {
        var voxAll: PicoGKVoxels?

        let pocketLargeur = magnetLargeur + 2 * magnetJeu
        let pocketHauteur = magnetHauteur + 2 * magnetJeu
        let pocketProfondeur = magnetProfondeur + magnetJeu

        for i in 0..<nPoles {
            let phi = Float(i) / Float(nPoles) * 2 * Float.pi

            let voxPocket = makeFlatRectBlock(
                phi: phi,
                largeur: pocketLargeur,
                hauteur: pocketHauteur,
                profondeur: pocketProfondeur,
                isPocket: true
            )

            if let existing = voxAll {
                voxAll = existing + voxPocket
            } else {
                voxAll = voxPocket
            }

            if (i + 1) % 6 == 0 {
                sceneManager.log("  Pocket \(i + 1)/\(nPoles)")
            }
        }

        return voxAll ?? PicoGKVoxels()
    }

    /// Halbach chevron: 4 segments d'aimant par pôle, orientés en V.
    ///
    /// Pour chaque pôle i, 4 segments disposés en chevron (V):
    ///   Segment 0: radial outward  (N→ext)
    ///   Segment 1: tangentiel CW   (N→CW)
    ///   Segment 2: radial inward   (N→int)
    ///   Segment 3: tangentiel CCW  (N→CCW)
    ///
    /// Les segments sont plus petits que le standard: L/4 en tangentiel,
    /// même hauteur axiale, même profondeur radiale.
    /// Profondeur limitée pour ne JAMAIS percer la face intérieure.
    ///
    /// Disposition chevron (vue de dessus, un pôle):
    ///
    ///        ╱ seg1 ╲
    ///       ╱        ╲
    ///  seg0           seg2
    ///       ╲        ╱
    ///        ╲ seg3 ╱
    ///
    private func makeHalbachMagnetPockets(sceneManager: SceneManager, isPocket: Bool) -> PicoGKVoxels {
        var voxAll: PicoGKVoxels?

        // Taille d'un segment Halbach: chaque pôle est divisé en 4 segments
        // La largeur tangentielle d'un segment = polePitch / 4
        let polePitchDeg = 360.0 / Float(nPoles)
        let polePitchMM = polePitchDeg / 360.0 * 2 * Float.pi * rayonExterieur

        // Largeur tangentielle d'un segment (avec jeu si poche)
        let segLargeur = min(magnetLargeur, polePitchMM / 4 - 1.0)
        let segHauteur = magnetHauteur
        let segProfondeur = magnetProfondeur

        // Sécurité: la profondeur max ne doit PAS percer la jante
        let maxProf = epaisseur - 2.0  // 2mm de paroi minimum
        let profEffective = min(segProfondeur, maxProf)

        let jeu: Float = isPocket ? magnetJeu : 0

        let totalSegments = nPoles * 4
        sceneManager.log("  Halbach: \(totalSegments) segments (\(nPoles) pôles × 4)")
        sceneManager.log("  Segment: \(String(format: "%.1f", segLargeur))×\(String(format: "%.1f", segHauteur))×\(String(format: "%.1f", profEffective)) mm")

        for i in 0..<nPoles {
            let phiPole = Float(i) / Float(nPoles) * 2 * Float.pi

            // 4 segments par pôle, décalés angulairement en chevron
            for seg in 0..<4 {
                // Position angulaire du segment dans le pôle
                // Chevron: segments 0,2 au centre, 1,3 décalés latéralement
                let segOffsetFrac = (Float(seg) - 1.5) / 4.0  // -0.375, -0.125, +0.125, +0.375
                let segPhi = phiPole + segOffsetFrac * polePitchDeg * Float.pi / 180.0

                // Orientation du segment (rotation de 90° × seg par rapport au radial)
                // seg 0: radial (standard) — profondeur = épaisseur radiale
                // seg 1: tangentiel CW — aimant tourné 90° CW, encastré dans la jante
                // seg 2: radial inversé — profondeur radiale, polarité inversée
                // seg 3: tangentiel CCW — aimant tourné 90° CCW

                // Pour Halbach, chaque segment est un bloc orienté radialement
                // (même géométrie de poche), mais l'aimant physique est tourné.
                // La poche reste rectangulaire — seul le magnétisme change.
                // Le chevron V est réalisé par le décalage angulaire.

                let voxSeg = makeHalbachSegment(
                    phi: segPhi,
                    largeur: segLargeur + 2 * jeu,
                    hauteur: segHauteur + 2 * jeu,
                    profondeur: profEffective + (isPocket ? jeu : 0),
                    isPocket: isPocket,
                    segmentIndex: seg
                )

                if let existing = voxAll {
                    voxAll = existing + voxSeg
                } else {
                    voxAll = voxSeg
                }
            }

            if (i + 1) % 6 == 0 {
                sceneManager.log("  Pole \(i + 1)/\(nPoles) done")
            }
        }

        return voxAll ?? PicoGKVoxels()
    }

    /// Un segment Halbach: bloc rectangulaire encastré sur la face extérieure.
    ///
    /// Segments 0 et 2 (radial): profondeur classique.
    /// Segments 1 et 3 (tangentiel): décalés axialement en V (chevron).
    ///   - Segment 1: décalé vers +Z (moitié haute)
    ///   - Segment 3: décalé vers -Z (moitié basse)
    /// Cela forme le motif en V (chevron).
    private func makeHalbachSegment(phi: Float,
                                     largeur: Float,
                                     hauteur: Float,
                                     profondeur: Float,
                                     isPocket: Bool,
                                     segmentIndex: Int) -> PicoGKVoxels {
        let dirR = SIMD3<Float>(cos(phi), sin(phi), 0)
        let dirT = SIMD3<Float>(-sin(phi), cos(phi), 0)

        let overcut: Float = isPocket ? 1.0 : 0.0
        let totalDepth = profondeur + overcut
        let rCenter = rayonExterieur - profondeur / 2 + overcut / 2

        // Chevron V: segments tangentiels décalés axialement
        let chevronOffset: Float
        switch segmentIndex {
        case 1:  chevronOffset = hauteur * 0.25   // segment tangentiel → décalé +Z
        case 3:  chevronOffset = -hauteur * 0.25  // segment tangentiel → décalé -Z
        default: chevronOffset = 0                  // segments radiaux → centrés
        }

        let center = dirR * rCenter + SIMD3<Float>(0, 0, chevronOffset)

        let halfL = largeur / 2
        let halfH = hauteur / 2
        let halfP = totalDepth / 2

        let corners = boxCorners(center: center, dirT: dirT, dirR: dirR,
                                  halfL: halfL, halfH: halfH, halfP: halfP)
        let bounds = boundsFromCorners(corners, margin: 2)

        let ctr = center
        let dR = dirR
        let dT = dirT
        let hL = halfL
        let hHt = halfH
        let hP = halfP
        // Clip axial: ne pas dépasser la hauteur de jante
        let janteHalfH = self.hauteur / 2

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let v = pt - ctr
            let projT = simd_dot(v, dT)
            let projZ = v.z
            let projR = simd_dot(v, dR)

            // Box SDF du segment
            let dBox = max(abs(projT) - hL, max(abs(projZ) - hHt, abs(projR) - hP))

            // Clip: le segment ne doit pas sortir de la jante axialement
            let dClipZ = abs(pt.z) - janteHalfH
            return max(dBox, dClipZ)
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }

    // MARK: - Magnets (Visualization)

    /// Crée les aimants pour visualisation.
    private func makeMagnets(sceneManager: SceneManager) -> PicoGKVoxels {
        switch magnetPattern {
        case .standard:
            return makeStandardMagnets(sceneManager: sceneManager)
        case .halbachChevron:
            return makeHalbachMagnetPockets(sceneManager: sceneManager, isPocket: false)
        }
    }

    /// Aimants standard: 1 bloc par pôle.
    private func makeStandardMagnets(sceneManager: SceneManager) -> PicoGKVoxels {
        var voxAll: PicoGKVoxels?

        for i in 0..<nPoles {
            let phi = Float(i) / Float(nPoles) * 2 * Float.pi

            let voxMag = makeFlatRectBlock(
                phi: phi,
                largeur: magnetLargeur,
                hauteur: magnetHauteur,
                profondeur: magnetProfondeur,
                isPocket: false
            )

            if let existing = voxAll {
                voxAll = existing + voxMag
            } else {
                voxAll = voxMag
            }
        }

        return voxAll ?? PicoGKVoxels()
    }

    // MARK: - Flat Rectangular Block (magnet / pocket — standard pattern)

    private func makeFlatRectBlock(phi: Float,
                                    largeur: Float,
                                    hauteur: Float,
                                    profondeur: Float,
                                    isPocket: Bool) -> PicoGKVoxels {
        let dirR = SIMD3<Float>(cos(phi), sin(phi), 0)
        let dirT = SIMD3<Float>(-sin(phi), cos(phi), 0)

        let overcut: Float = isPocket ? 1.0 : 0.0
        let totalDepth = profondeur + overcut
        let rCenter = rayonExterieur - profondeur / 2 + overcut / 2

        let center = dirR * rCenter

        let halfL = largeur / 2
        let halfH = hauteur / 2
        let halfP = totalDepth / 2

        let corners = boxCorners(center: center, dirT: dirT, dirR: dirR,
                                  halfL: halfL, halfH: halfH, halfP: halfP)
        let bounds = boundsFromCorners(corners, margin: 2)

        let ctr = center
        let dR = dirR
        let dT = dirT
        let hL = halfL
        let hHt = halfH
        let hP = halfP

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let v = pt - ctr
            let projT = simd_dot(v, dT)
            let projZ = v.z
            let projR = simd_dot(v, dR)
            return max(abs(projT) - hL, max(abs(projZ) - hHt, abs(projR) - hP))
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: - Geometry Helpers
    // ═══════════════════════════════════════════════════════════════

    private func boxCorners(center: SIMD3<Float>,
                             dirT: SIMD3<Float>, dirR: SIMD3<Float>,
                             halfL: Float, halfH: Float, halfP: Float) -> [SIMD3<Float>] {
        var result: [SIMD3<Float>] = []
        for ts: Float in [-1, 1] {
            for zs: Float in [-1, 1] {
                for rs: Float in [-1, 1] {
                    result.append(center + dirT * (ts * halfL)
                                        + SIMD3(0, 0, zs * halfH)
                                        + dirR * (rs * halfP))
                }
            }
        }
        return result
    }

    private func boundsFromCorners(_ corners: [SIMD3<Float>], margin: Float) -> BBox3 {
        var bbMin = SIMD3<Float>(repeating: Float.greatestFiniteMagnitude)
        var bbMax = SIMD3<Float>(repeating: -Float.greatestFiniteMagnitude)
        for c in corners {
            bbMin = simd_min(bbMin, c)
            bbMax = simd_max(bbMax, c)
        }
        bbMin -= SIMD3(repeating: margin)
        bbMax += SIMD3(repeating: margin)
        return BBox3(min: bbMin, max: bbMax)
    }
}
