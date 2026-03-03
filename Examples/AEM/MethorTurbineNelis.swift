// MethorTurbineNelis.swift
// Genolanx — Parametric Turbine N\u{00E9}lis
//
// Single fused object: ogive + concave crescent blades + rectangular jante.
// Aimants NdFeB incrustés à 2/3 profondeur dans la jante (boolSubtract).
//
// Blade profile: true concave cross-section (cuillère/croissant).
//   - Extrados (top): flat/convex surface
//   - Intrados (bottom): concave hollow (sine-arc depression)
//   - Creates a "cupped hand" shape that catches air
//
// Blades start at the CENTER (r≈0) so they merge seamlessly with the ogive.
// Crescent Z-path: sinusoidal sweep from paleHauteurBegin to paleHauteurEnd.
// Tight per-blade bounding box (~1.5M voxels each) = fast renderImplicit.
//
// Magnet patterns (posés sur la face extérieure):
//   Standard:  1 aimant/pôle, aligné tangentiel (incrémenteur pair)
//   Halbach chevron V: 2 aimants/pôle à ±ANGLE dans le plan XY (vue du dessus)
//     Le V est formé près de la ligne de symétrie radiale de chaque pôle.
//
// Catalog magnets: MagnetCatalogEntry (supermagnete.be), sélection par Picker.

import simd
import Foundation
import PicoGKBridge

// MARK: - Presets

enum TurbinePreset: String, CaseIterable, Identifiable {
    case aem262 = "AEM 262"
    case aem360 = "AEM 360"

    var id: String { rawValue }

    var ogiveHauteur: Float      { 40 }
    var ogiveBaseRadius: Float   { switch self { case .aem262: return 22.4;  case .aem360: return 45.5  } }
    var nPales: Int              { switch self { case .aem262: return 5;     case .aem360: return 8     } }
    var janteDiametre: Float     { switch self { case .aem262: return 262;   case .aem360: return 364.5 } }
    var paleLargeur: Float       { switch self { case .aem262: return 75.9;  case .aem360: return 80    } }
    var paleEpaisseur: Float     { 5.2 }
    var palePitch: Float         { 25 }
    var paleHauteurBegin: Float  { 0 }
    var paleHauteurEnd: Float    { 0 }
    var janteHauteur: Float      { switch self { case .aem262: return 17.1;  case .aem360: return 26.8  } }
    var janteEpaisseur: Float    { 10.3 }
    var nPoles: Int              { switch self { case .aem262: return 10;  case .aem360: return 16    } }
    var magnetCatalogID: String  { switch self { case .aem262: return "Q-10-10-05"; case .aem360: return "Q-20-10-05" } }
    var magnetPattern: MagnetPattern { .halbachChevron }
    var chevronAngle: Float      { 25 }
    var magnetJeu: Float         { 0.15 }
}

// MARK: - TurbineTask

final class TurbineTask {

    // MARK: - Ogive Parameters (mm)

    let ogiveHauteur: Float
    let ogiveBaseRadius: Float

    // MARK: - Blade Parameters

    let nPales: Int
    let janteDiametre: Float
    let paleLargeur: Float
    let paleEpaisseur: Float
    let palePitch: Float
    let paleHauteurBegin: Float
    let paleHauteurEnd: Float

    // MARK: - Jante Parameters

    let janteHauteur: Float
    let janteEpaisseur: Float

    // MARK: - Magnet Parameters (surface extérieure, chevron Halbach)

    let nPoles: Int
    let magnetLargeur: Float      // tangentiel (catalog L)
    let magnetHauteur: Float      // axial (catalog W)
    let magnetProfondeur: Float   // radial (catalog T)
    let magnetJeu: Float
    let magnetPattern: MagnetPattern
    let magnetCatalogID: String
    let chevronAngle: Float       // angle du V en degrés

    // MARK: - Bearing Parameters (alésage bas du moyeu)

    let roulementExterieur: Float   // rayon ext. bague roulement (mm)
    let roulementHauteur: Float     // hauteur roulement (mm)
    let hubOffset: Float            // épaisseur paroi autour du roulement (mm)

    // MARK: - Derived

    private var janteRadius: Float { janteDiametre / 2.0 }
    private var janteOuterRadius: Float { janteRadius + janteEpaisseur / 2.0 }
    private var hubRadius: Float { roulementExterieur + hubOffset }

    // MARK: - Init

    init(ogiveHauteur: Float = 40,
         ogiveBaseRadius: Float = 22.4,
         nPales: Int = 5,
         janteDiametre: Float = 262,
         paleLargeur: Float = 75.9,
         paleEpaisseur: Float = 5.2,
         palePitch: Float = 25,
         paleHauteurBegin: Float = 0,
         paleHauteurEnd: Float = 0,
         janteHauteur: Float = 17.1,
         janteEpaisseur: Float = 10.3,
         nPoles: Int = 10,
         magnetCatalogID: String = "Q-10-10-05",
         magnetPattern: MagnetPattern = .halbachChevron,
         chevronAngle: Float = 25,
         magnetJeu: Float = 0.15,
         roulementExterieur: Float = 14,
         roulementHauteur: Float = 12,
         hubOffset: Float = 5) {
        self.ogiveHauteur = ogiveHauteur
        self.ogiveBaseRadius = ogiveBaseRadius
        self.nPales = nPales
        self.janteDiametre = janteDiametre
        self.paleLargeur = paleLargeur
        self.paleEpaisseur = paleEpaisseur
        self.palePitch = palePitch
        self.paleHauteurBegin = paleHauteurBegin
        self.paleHauteurEnd = paleHauteurEnd
        self.janteHauteur = janteHauteur
        self.janteEpaisseur = janteEpaisseur
        let entry = MagnetCatalogEntry.find(id: magnetCatalogID) ?? MagnetCatalogEntry.catalog[0]
        self.nPoles = nPoles
        self.magnetLargeur = entry.lengthMM
        self.magnetHauteur = entry.widthMM
        self.magnetProfondeur = entry.thicknessMM
        self.magnetJeu = magnetJeu
        self.magnetPattern = magnetPattern
        self.magnetCatalogID = magnetCatalogID
        self.chevronAngle = chevronAngle
        self.roulementExterieur = roulementExterieur
        self.roulementHauteur = roulementHauteur
        self.hubOffset = hubOffset
    }

    // MARK: - Entry Point

    static func run(sceneManager: SceneManager,
                    ogiveHauteur: Float = 40,
                    ogiveBaseRadius: Float = 22.4,
                    nPales: Int = 5,
                    janteDiametre: Float = 262,
                    paleLargeur: Float = 75.9,
                    paleEpaisseur: Float = 5.2,
                    palePitch: Float = 25,
                    paleHauteurBegin: Float = 0,
                    paleHauteurEnd: Float = 0,
                    janteHauteur: Float = 17.1,
                    janteEpaisseur: Float = 10.3,
                    nPoles: Int = 10,
                    magnetCatalogID: String = "Q-10-10-05",
                    magnetPattern: MagnetPattern = .halbachChevron,
                    chevronAngle: Float = 25,
                    magnetJeu: Float = 0.15,
                    roulementExterieur: Float = 14,
                    roulementHauteur: Float = 12,
                    hubOffset: Float = 5) {
        sceneManager.log("Starting Turbine Task.")
        sceneManager.log("  Ogive: H=\(ogiveHauteur) mm  Base R=\(ogiveBaseRadius) mm")
        if nPales > 0 {
            sceneManager.log("  Pales: \(nPales)x  \u{00D8}Jante=\(janteDiametre) mm  Chord=\(paleLargeur) mm  pitch=\(palePitch)\u{00B0}")
            sceneManager.log("  Pale Z: begin=\(paleHauteurBegin) end=\(paleHauteurEnd) mm")
            sceneManager.log("  Jante: H=\(janteHauteur) mm  Ep=\(janteEpaisseur) mm")
            sceneManager.log("  Magnets: \(magnetPattern.label)  \(nPoles) p\u{00F4}les  catalog=\(magnetCatalogID)")
            if magnetPattern == .halbachChevron {
                sceneManager.log("    Chevron: \(nPoles) aimants  angle=\u{00B1}\(chevronAngle)\u{00B0}  pair=-/impair=+")
            } else {
                sceneManager.log("    Standard: \(nPoles / 2) aimants (incr\u{00E9}menteur pair)")
            }
            sceneManager.log("  Bearing: R ext=\(roulementExterieur) mm  H=\(roulementHauteur) mm  offset=\(hubOffset) mm  Hub R=\(roulementExterieur + hubOffset) mm")
        }

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

        turbine.construct(sceneManager: sceneManager)
        sceneManager.log("Finished Turbine Task successfully.")
    }

    // MARK: - Geometry Builder (reusable by MethorAssemblyTask)

    internal func buildGeometry(sceneManager: SceneManager) -> (turbine: PicoGKVoxels, magnets: PicoGKVoxels?) {

        let baseZ: Float = 0.0
        var voxMagnets: PicoGKVoxels?

        sceneManager.log("Building ogive...")
        let voxTurbine = makeOgive(baseZ: baseZ, baseRadius: ogiveBaseRadius, height: ogiveHauteur)

        if nPales > 0 {
            let bladeStartR: Float = 2.0

            for i in 0..<nPales {
                let phiBase = Float(i) / Float(nPales) * 2.0 * Float.pi
                sceneManager.log("  Blade \(i + 1)/\(nPales)...")
                let voxBlade = makeCrescentBlade(
                    phiBase: phiBase,
                    startRadius: bladeStartR,
                    baseZ: baseZ
                )
                voxTurbine.boolAdd(voxBlade)
            }

            sceneManager.log("Building rectangular jante...")
            let voxJante = makeRectangularJante(baseZ: baseZ)
            voxTurbine.boolAdd(voxJante)

            if nPoles > 0 {
                sceneManager.log("Building magnets (\(magnetPattern.label)) \u{2014} incrust\u{00E9}s 2/3...")
                let (magnets, pockets) = makeMagnets(sceneManager: sceneManager, baseZ: baseZ)
                sceneManager.log("Subtracting magnet pockets (jeu=\(magnetJeu) mm)...")
                voxTurbine.boolSubtract(pockets)
                voxMagnets = magnets
            }

            let janteBottomZ = baseZ + paleHauteurEnd - janteHauteur / 2.0
            if janteBottomZ < baseZ {
                sceneManager.log("Building central hub: R=\(String(format: "%.1f", hubRadius)) mm...")
                let voxHub = makeCentralHub(topZ: baseZ, bottomZ: janteBottomZ, radius: hubRadius)
                voxTurbine.boolAdd(voxHub)
            }

            if roulementExterieur > 0 && roulementHauteur > 0 {
                let boreBottomZ = janteBottomZ
                sceneManager.log("Boring bearing pocket: R=\(String(format: "%.1f", roulementExterieur)) mm  H=\(String(format: "%.1f", roulementHauteur)) mm...")
                let voxBore = makeBearingBore(bottomZ: boreBottomZ, radius: roulementExterieur, depth: roulementHauteur)
                voxTurbine.boolSubtract(voxBore)
            }
        }

        let cutZ = baseZ + paleHauteurEnd - janteHauteur / 2.0
        sceneManager.log("Applying cutting plane at Z=\(String(format: "%.1f", cutZ)) mm...")
        voxTurbine.intersectImplicit { pt in cutZ - pt.z }

        return (voxTurbine, voxMagnets)
    }

    // MARK: - Main Assembly

    private func construct(sceneManager: SceneManager) {

        let (voxTurbine, voxMagnets) = buildGeometry(sceneManager: sceneManager)

        // Volume
        let turbineProps = voxTurbine.calculateProperties()
        sceneManager.log("  Turbine volume: \(String(format: "%.1f", turbineProps.volumeCubicMM)) mm\u{00B3}")
        if let magnets = voxMagnets {
            let magProps = magnets.calculateProperties()
            sceneManager.log("  Magnets volume: \(String(format: "%.1f", magProps.volumeCubicMM)) mm\u{00B3}")
        }

        // Display: Turbine (Navy) + Magnets (Gold)
        DispatchQueue.main.async {
            sceneManager.removeAllObjects()
            sceneManager.addVoxels(voxTurbine, groupID: 0, name: "Turbine")
            sceneManager.setGroupMaterial(0, color: Cp.clrNavy, metallic: 0.7, roughness: 0.25)
            if let magnets = voxMagnets {
                sceneManager.addVoxels(magnets, groupID: 1, name: "Magnets NdFeB")
                sceneManager.setGroupMaterial(1, color: Cp.clrGold, metallic: 0.9, roughness: 0.15)
            }
        }

        // Export
        sceneManager.log("Exporting STLs...")
        let pathTurbine = ShExport.exportPath(filename: "Turbine")
        sceneManager.exportSTL(voxels: voxTurbine, to: pathTurbine)
        sceneManager.log("  \u{2192} \(pathTurbine)")

        if let magnets = voxMagnets {
            let pathMagnets = ShExport.exportPath(filename: "Turbine_Magnets")
            sceneManager.exportSTL(voxels: magnets, to: pathMagnets)
            sceneManager.log("  \u{2192} \(pathMagnets)")
        }

        sceneManager.log("Done!")
    }

    // MARK: - Ogive

    /// Power series ogive: r(z) = R * (1 - z/L)^0.75
    private func makeOgive(baseZ: Float, baseRadius: Float, height: Float) -> PicoGKVoxels {
        let R = baseRadius
        let L = height

        let margin: Float = 2.0
        let tipZ = baseZ + L
        let bounds = BBox3(
            min: SIMD3(-R - margin, -R - margin, baseZ - margin),
            max: SIMD3( R + margin,  R + margin, tipZ + margin)
        )

        let bZ = baseZ
        let sdf: (SIMD3<Float>) -> Float = { pt in
            let z = pt.z - bZ
            let r = sqrt(pt.x * pt.x + pt.y * pt.y)

            if z < 0 { return max(-z, r - R) }
            if z > L { return max(z - L, r) }

            let ratio = z / L
            let rOgive = R * pow(1.0 - ratio, 0.75)
            return r - rOgive
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }

    // MARK: - Concave Crescent Blade (SDF)

    /// Build a single blade with true concave (cuillère) cross-section.
    ///
    /// Cross-section at any radial station:
    ///
    ///   extrados (top):    flat surface at +halfThick
    ///   intrados (bottom): concave arc  at -halfThick + concavity*sin(π*xNorm)
    ///
    /// The concavity dips the intrados inward, creating the "cupped hand" shape.
    /// Pitch rotates tehe entire cross-section around the radial axis.
    /// Crescent Z-path: sinusoidal sweep from paleHauteurBegin to paleHauteurEnd.
    private func makeCrescentBlade(phiBase: Float, startRadius: Float,
                                    baseZ: Float) -> PicoGKVoxels {

        let tipRadius = janteRadius
        let bladeSpan = tipRadius - startRadius
        let chord = paleLargeur
        let pitchRad = palePitch * Float.pi / 180.0

        let angularSpacing = 2.0 * Float.pi / Float(nPales)
        let camberArc = angularSpacing * 0.25

        // Crescent Z-path parameters
        let zBegin = paleHauteurBegin
        let zEnd = paleHauteurEnd
        let crescentDepth = abs(zBegin - zEnd) * 0.3

        let margin: Float = chord * 0.5

        // ── Tight bounding box (angular wedge) ──
        let phiMargin = (chord + margin) / max(startRadius, 5.0)
        let phiMin = phiBase - phiMargin
        let phiMax = phiBase + camberArc + phiMargin
        let rMin = max(0, startRadius - margin)
        let rMax = tipRadius + margin

        var bMin = SIMD3<Float>(repeating: Float.greatestFiniteMagnitude)
        var bMax = SIMD3<Float>(repeating: -Float.greatestFiniteMagnitude)
        for phi in stride(from: phiMin, through: phiMax, by: 0.1) {
            for r in [rMin, rMax] {
                let x = r * cos(phi)
                let y = r * sin(phi)
                bMin = simd_min(bMin, SIMD3(x, y, 0))
                bMax = simd_max(bMax, SIMD3(x, y, 0))
            }
        }

        // Z extent: from min Z to max Z of the crescent path + thickness
        let zLow = baseZ + min(zBegin, zEnd) - crescentDepth - paleEpaisseur * 3.0
        let zHigh = baseZ + max(zBegin, zEnd) + paleEpaisseur * 3.0

        let bounds = BBox3(
            min: SIMD3(bMin.x - margin, bMin.y - margin, zLow),
            max: SIMD3(bMax.x + margin, bMax.y + margin, zHigh)
        )

        // ── Capture locals for SDF closure ──
        let sR = startRadius
        let bS = bladeSpan
        let ch = chord
        let pR = pitchRad
        let cA = camberArc
        let bZ = baseZ
        let pE = paleEpaisseur
        let phB = phiBase
        let zB = zBegin
        let zE = zEnd
        let cD = crescentDepth

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let r = sqrt(pt.x * pt.x + pt.y * pt.y)
            let phi = atan2(pt.y, pt.x)

            // Angle relative to blade base
            var dPhi = phi - phB
            while dPhi > Float.pi { dPhi -= 2.0 * Float.pi }
            while dPhi < -Float.pi { dPhi += 2.0 * Float.pi }

            // Span ratio: 0 = root, 1 = tip
            let spanRatio = (r - sR) / bS

            // Outside blade span → distance
            if spanRatio < -0.05 || spanRatio > 1.05 {
                let dR = spanRatio < 0 ? (sR - r) : (r - sR - bS)
                return max(dR, 0.5)
            }

            let t = max(0, min(1, spanRatio))

            // Camber arc: blade sweeps in tangential direction
            let phiOnCurve = cA * t
            let dPhiFromCurve = dPhi - phiOnCurve

            // Tangential distance from blade centerline (mm)
            let tangDist = r * dPhiFromCurve

            // Chord taper: 100% at root → 60% at tip
            let localChord = ch * (1.0 - 0.4 * t)
            let halfC = localChord / 2.0

            // Thickness taper: 100% at root → 70% at tip
            let localThick = pE * (1.0 - 0.3 * t)
            let halfThick = localThick

            // Crescent Z-path: sinusoidal sweep
            let zLinear = zB + (zE - zB) * t
            let zCenter = bZ + zLinear - cD * sin(Float.pi * t)

            // Pitch rotation: rotate (tangDist, z-zCenter) by pitch angle
            let zLocal = pt.z - zCenter
            let chordDir = tangDist * cos(pR) + zLocal * sin(pR)
            let thickDir = -tangDist * sin(pR) + zLocal * cos(pR)

            // Normalized chord position: 0 = leading edge, 1 = trailing edge
            let xNorm = (chordDir + halfC) / localChord

            // Outside chord → distance to edge
            if xNorm < -0.02 || xNorm > 1.02 {
                let dChord = xNorm < 0 ? (-chordDir - halfC) : (chordDir - halfC)
                return max(dChord, abs(thickDir) - halfThick)
            }

            let xC = max(0.0, min(1.0, xNorm))

            // ── SHARP CONCAVE PROFILE ──
            let edgeFactor = pow(sin(Float.pi * xC), 0.3)
            let smoothEdge = max(edgeFactor, 0.08)

            let extrados = halfThick * smoothEdge
            let concavity = localThick * 1.5 * sin(Float.pi * xC)
            let intrados = -halfThick * smoothEdge + concavity

            let profileDist: Float
            if thickDir > extrados {
                profileDist = thickDir - extrados
            } else if thickDir < intrados {
                profileDist = intrados - thickDir
            } else {
                profileDist = -min(thickDir - intrados, extrados - thickDir)
            }

            let dSpanIn = (r - sR) * 0.5
            let dSpanOut = (sR + bS - r) * 0.5
            let spanDist = -min(dSpanIn, dSpanOut)

            return max(profileDist, spanDist)
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: - Magnet System (incrustés 2/3 + boolSubtract)
    // ═══════════════════════════════════════════════════════════════

    /// Crée les aimants incrustés à 2/3 profondeur + poches (aimant + jeu).
    /// Retourne (magnets: pour affichage, pockets: pour boolSubtract).
    private func makeMagnets(sceneManager: SceneManager, baseZ: Float) -> (magnets: PicoGKVoxels, pockets: PicoGKVoxels) {
        switch magnetPattern {
        case .standard:
            return makeStandardMagnets(sceneManager: sceneManager, baseZ: baseZ)
        case .halbachChevron:
            return makeChevronMagnets(sceneManager: sceneManager, baseZ: baseZ)
        }
    }

    /// Standard: 1 aimant tangentiel par pôle, incrémenteur pair (stride 2).
    private func makeStandardMagnets(sceneManager: SceneManager, baseZ: Float) -> (magnets: PicoGKVoxels, pockets: PicoGKVoxels) {
        var voxMag: PicoGKVoxels?
        var voxPock: PicoGKVoxels?

        let step = 2  // incrémenteur par nombre paire
        let nPlaced = nPoles / step

        for i in stride(from: 0, to: nPoles, by: step) {
            let phi = Float(i) / Float(nPoles) * 2.0 * Float.pi
            let mag = makeSurfaceMagnet(phi: phi, tiltAngle: 0, baseZ: baseZ)
            let pock = makeSurfaceMagnet(phi: phi, tiltAngle: 0, baseZ: baseZ, oversize: magnetJeu)

            voxMag = (voxMag != nil) ? voxMag! + mag : mag
            voxPock = (voxPock != nil) ? voxPock! + pock : pock

            if (i / step + 1) % 4 == 0 {
                sceneManager.log("  Magnet \(i / step + 1)/\(nPlaced)")
            }
        }

        return (voxMag ?? PicoGKVoxels(), voxPock ?? PicoGKVoxels())
    }

    /// Halbach chevron: 1 aimant par position, alternance pair/impair.
    ///
    /// Vue du dessus (plan XY, développé):
    ///
    ///    /  \  /  \  /  \      ← zigzag sur la jante
    ///
    /// Chaque aimant est disposé radialement sur la surface extérieure.
    /// Positions paires  (i%2==0) → tilt = -chevronAngle
    /// Positions impaires (i%2==1) → tilt = +chevronAngle
    ///
    /// Total = nPoles aimants, même hauteur Z, même rayon.
    private func makeChevronMagnets(sceneManager: SceneManager, baseZ: Float) -> (magnets: PicoGKVoxels, pockets: PicoGKVoxels) {
        var voxMag: PicoGKVoxels?
        var voxPock: PicoGKVoxels?

        let angleRad = chevronAngle * Float.pi / 180.0

        sceneManager.log("  Chevron: \(nPoles) aimants  angle=\u{00B1}\(chevronAngle)\u{00B0}  pair=-/impair=+")

        for i in 0..<nPoles {
            let phi = Float(i) / Float(nPoles) * 2.0 * Float.pi
            let tilt = (i % 2 == 0) ? -angleRad : +angleRad

            let mag = makeSurfaceMagnet(phi: phi, tiltAngle: tilt, baseZ: baseZ)
            let pock = makeSurfaceMagnet(phi: phi, tiltAngle: tilt, baseZ: baseZ, oversize: magnetJeu)

            voxMag = (voxMag != nil) ? voxMag! + mag : mag
            voxPock = (voxPock != nil) ? voxPock! + pock : pock

            if (i + 1) % 4 == 0 {
                sceneManager.log("  Magnet \(i + 1)/\(nPoles)")
            }
        }

        return (voxMag ?? PicoGKVoxels(), voxPock ?? PicoGKVoxels())
    }

    /// Un aimant rectangulaire incrusté à 2/3 de profondeur dans la jante.
    ///
    /// tiltAngle: rotation dans le plan XY (tangent × radial) — vue du dessus.
    ///   0 = tangentiel pur (standard)
    ///   ±angle = chevron pair/impair
    ///
    /// Incrustation: 2/3 dedans, 1/3 dehors.
    ///   Centre radial = janteOuterRadius - depth/6
    ///
    /// oversize: marge ajoutée à chaque demi-dimension (pour la poche = jeu).
    private func makeSurfaceMagnet(phi: Float, tiltAngle: Float, baseZ: Float,
                                    zOffset: Float = 0, oversize: Float = 0) -> PicoGKVoxels {
        let dirR = SIMD3<Float>(cos(phi), sin(phi), 0)
        let dirT = SIMD3<Float>(-sin(phi), cos(phi), 0)
        let dirZ = SIMD3<Float>(0, 0, 1)

        // Incrusté à 2/3: 2/3 dedans, 1/3 dehors
        // Face ext = janteOuterRadius + depth/3
        // Centre   = janteOuterRadius - depth/6
        let depth = magnetProfondeur
        let rCenter = janteOuterRadius - depth / 6.0
        let zCenter = baseZ + paleHauteurEnd + zOffset

        let center = dirR * rCenter + SIMD3<Float>(0, 0, zCenter)

        // Axes de l'aimant: rotation dans le plan XY (tangent × radial)
        let cosA = cos(tiltAngle)
        let sinA = sin(tiltAngle)
        let lengthDir = dirT * cosA + dirR * sinA     // longueur (L) — tilté dans XY
        let widthDir  = dirZ                           // largeur (W) — axiale
        let depthDir  = dirR * cosA - dirT * sinA      // profondeur (T) — ~radial

        let halfL = magnetLargeur / 2.0 + oversize
        let halfW = magnetHauteur / 2.0 + oversize
        let halfD = depth / 2.0 + oversize

        // Bounding box (conservatif)
        let extent = halfL + halfW + halfD + 2.0
        let bounds = BBox3(
            min: SIMD3(center.x - extent, center.y - extent, center.z - extent),
            max: SIMD3(center.x + extent, center.y + extent, center.z + extent)
        )

        // Captures pour closure SDF
        let ctr = center
        let lD = lengthDir
        let wD = widthDir
        let dD = depthDir
        let hL = halfL
        let hW = halfW
        let hDp = halfD

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let v = pt - ctr
            let projL = simd_dot(v, lD)   // longueur
            let projW = simd_dot(v, wD)   // largeur
            let projD = simd_dot(v, dD)   // profondeur (radial)
            return max(abs(projL) - hL, max(abs(projW) - hW, abs(projD) - hDp))
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }

    // MARK: - Rectangular Jante

    /// Rectangular cross-section annular ring at janteRadius.
    private func makeRectangularJante(baseZ: Float) -> PicoGKVoxels {
        let rCenter = janteRadius
        let halfH = janteHauteur / 2.0
        let halfE = janteEpaisseur / 2.0

        let zCenter = baseZ + paleHauteurEnd

        let margin: Float = 2.0
        let bounds = BBox3(
            min: SIMD3(-(rCenter + halfE + margin), -(rCenter + halfE + margin), zCenter - halfH - margin),
            max: SIMD3( (rCenter + halfE + margin),  (rCenter + halfE + margin), zCenter + halfH + margin)
        )

        let rC = rCenter
        let hH = halfH
        let hE = halfE
        let zC = zCenter

        let sdf: (SIMD3<Float>) -> Float = { pt in
            let r = sqrt(pt.x * pt.x + pt.y * pt.y)
            let dz = abs(pt.z - zC) - hH
            let dr = abs(r - rC) - hE
            return max(dz, dr)
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }

    // MARK: - Al\u{00E9}sage roulement (bearing bore)

    /// Cylindre creux soustrait du bas du moyeu pour loger le roulement.
    /// bottomZ = face inf\u{00E9}rieure du hub, depth = hauteur du roulement.
    /// Le cylindre monte de bottomZ \u{00E0} bottomZ + depth.
    private func makeBearingBore(bottomZ: Float, radius: Float, depth: Float) -> PicoGKVoxels {
        let R = radius
        let topZ = bottomZ + depth
        let margin: Float = 2.0
        let bounds = BBox3(
            min: SIMD3(-R - margin, -R - margin, bottomZ - margin),
            max: SIMD3( R + margin,  R + margin, topZ + margin)
        )

        let bZ = bottomZ
        let tZ = topZ
        let sdf: (SIMD3<Float>) -> Float = { pt in
            let r = sqrt(pt.x * pt.x + pt.y * pt.y)
            let dr = r - R
            let dzBot = bZ - pt.z
            let dzTop = pt.z - tZ
            let dz = max(dzBot, dzTop)
            return max(dr, dz)
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }

    // MARK: - Moyeu central (extension vers bas jante)

    /// Cylindre plein au centre, de topZ à bottomZ, pour mettre le hub
    /// à fleur avec le bas de la jante. Élimine le gap entre ogive et jante.
    private func makeCentralHub(topZ: Float, bottomZ: Float, radius: Float) -> PicoGKVoxels {
        let R = radius
        let margin: Float = 2.0
        let bounds = BBox3(
            min: SIMD3(-R - margin, -R - margin, bottomZ - margin),
            max: SIMD3( R + margin,  R + margin, topZ + margin)
        )

        let bZ = bottomZ
        let tZ = topZ
        let sdf: (SIMD3<Float>) -> Float = { pt in
            let r = sqrt(pt.x * pt.x + pt.y * pt.y)
            let dr = r - R
            let dzBot = bZ - pt.z   // > 0 if below bottom
            let dzTop = pt.z - tZ   // > 0 if above top
            let dz = max(dzBot, dzTop)
            return max(dr, dz)
        }

        let vox = PicoGKVoxels()
        vox.renderImplicit(sdf, bounds: bounds)
        return vox
    }
}
