// ContentView.swift
// Genolanx — Main application layout

import SwiftUI
import PicoGKBridge

struct ContentView: View {
    @StateObject private var sceneManager = SceneManager()
    @State private var voxelSize: Float = 0.5
    @State private var showExportSheet = false

    // Spiral Inductor parameters
    @State private var spiralOuterR: Float = 100
    @State private var spiralInnerR: Float = 30
    @State private var spiralPhases: Int = 3
    @State private var spiralWireDiam: Float = 3.0

    // Ball Bearing parameters
    @State private var bearingInnerR: Float = 15
    @State private var bearingOuterR: Float = 30
    @State private var bearingHeight: Float = 12

    // Methor Hub parameters (6 params from drawing + branches)
    @State private var hubRoulInterieur: Float = 12.5
    @State private var hubRoulExterieur: Float = 28
    @State private var hubEpaulement: Float = 8
    @State private var hubRoulHauteur: Float = 12
    @State private var hubEpaisseurFlange: Float = 3
    @State private var hubHauteur: Float = 35
    @State private var hubLongueur: Float = 50
    // hubBranches supprimé — auto-dérivé de statorSlots (S)
    @State private var hubBranchEpaisseur: Float = 2.0
    @State private var hubBranchHauteur: Float = 5.0
    @State private var hubRayonFork: Float = 82
    // hubRayonFinal supprimé — auto-dérivé de stator Noir mid-R
    @State private var hubPlotHauteur: Float = 8.0

    // Turbine parameters
    @State private var turbPreset: TurbinePreset = .aem262
    @State private var turbOgiveHauteur: Float = TurbinePreset.aem262.ogiveHauteur
    @State private var turbOgiveBaseRadius: Float = TurbinePreset.aem262.ogiveBaseRadius
    @State private var turbNPales: Int = TurbinePreset.aem262.nPales
    @State private var turbJanteDiametre: Float = TurbinePreset.aem262.janteDiametre
    @State private var turbPaleLargeur: Float = TurbinePreset.aem262.paleLargeur
    @State private var turbPaleEpaisseur: Float = TurbinePreset.aem262.paleEpaisseur
    @State private var turbPalePitch: Float = TurbinePreset.aem262.palePitch
    @State private var turbPaleHBegin: Float = TurbinePreset.aem262.paleHauteurBegin
    @State private var turbPaleHEnd: Float = TurbinePreset.aem262.paleHauteurEnd
    @State private var turbJanteHauteur: Float = TurbinePreset.aem262.janteHauteur
    @State private var turbJanteEpaisseur: Float = TurbinePreset.aem262.janteEpaisseur
    @State private var turbNPoles: Int = TurbinePreset.aem262.nPoles
    @State private var turbMagnetCatalogID: String = TurbinePreset.aem262.magnetCatalogID
    @State private var turbMagnetPatternIdx: Int = TurbinePreset.aem262.magnetPattern.rawValue
    @State private var turbChevronAngle: Float = TurbinePreset.aem262.chevronAngle
    @State private var turbMagnetJeu: Float = TurbinePreset.aem262.magnetJeu
    @State private var turbHubOffset: Float = 5.0

    // MabogeSlot parameters (OC-1)
    @State private var mabSlotPoles: Int = 21
    @State private var mabSlotRInner: Float = 180         // R Inner (diam 360 / 2)
    @State private var mabSlotAirGap: Float = 3           // Air gap
    @State private var mabSlotProfA: Float = 3            // Profondeur A (Jaune)
    @State private var mabSlotProfB: Float = 20           // Profondeur B (Rouge)
    @State private var mabSlotProfC: Float = 20           // Profondeur C (Noir)
    @State private var mabSlotHautH: Float = 20           // Hauteur H
    @State private var mabSlotNarrowPct: Float = 70       // Rouge: narrow band arc %
    @State private var mabSlotFlatPct: Float = 50         // Rouge: aplatir hauteur %

    // Stator motor config
    @State private var statorSlots: Int = 21        // S (multiple de 3, 12…42)

    /// Hub↔Stator: nBranches = statorSlots (auto)
    private var hubBranchesAuto: Int { statorSlots }

    /// Hub↔Stator: rayonFinal = stator Noir mid-radius (auto)
    private var hubRayonFinalAuto: Float {
        let janteOuterR = turbJanteDiametre / 2.0 + turbJanteEpaisseur / 2.0
        return janteOuterR + mabSlotAirGap + mabSlotProfA + mabSlotProfB + mabSlotProfC / 2.0
    }

    // N\u{00E9}lis accordion section expansion states
    @State private var nelisSecRoulement = true
    @State private var nelisSecHub = false
    @State private var nelisSecPales = false
    @State private var nelisSecJante = false
    @State private var nelisSecStator = false

    // Methor Rim parameters
    @State private var rimRayonInt: Float = 180
    @State private var rimEpaisseur: Float = 15
    @State private var rimHauteur: Float = 25
    @State private var rimNPoles: Int = 24
    @State private var rimMagnetID: String = "Q-20-20-05"   // SKU from catalog
    @State private var rimMagLargeur: Float = 20
    @State private var rimMagHauteur: Float = 20
    @State private var rimMagProfondeur: Float = 5
    @State private var rimMagJeu: Float = 0.15
    @State private var rimMagnetPatternIdx: Int = 0          // 0 = Standard, 1 = Halbach
    @State private var rimNPales: Int = 3
    @State private var rimPaleLargeur: Float = 40
    @State private var rimPaleHauteur: Float = 80
    @State private var rimNacaM: Float = 2
    @State private var rimNacaP: Float = 4
    @State private var rimNacaT: Float = 12
    @State private var rimPalePitch: Float = 0
    @State private var rimPaleSweep: Float = 0

    // ME2 MorlandHub parameters
    @State private var morlBearingInnerDiam: Float = 130
    @State private var morlBearingOuterDiam: Float = 165
    @State private var morlBearingHeight: Float = 18
    @State private var morlHubTotalHeight: Float = 60
    @State private var morlWallThickness: Float = 4
    @State private var morlFlangeExtension: Float = 30
    @State private var morlFlangeThickness: Float = 4
    @State private var morlFlangeHoleCount: Int = 8
    @State private var morlFlangeHoleRadius: Float = 4
    @State private var morlFunnelExitHeight: Float = 20
    @State private var morlFunnelBottomRadius: Float = 8
    @State private var morlBladeCount: Int = 12
    @State private var morlBladeThickness: Float = 2
    @State private var morlBladeTwistAngle: Float = 75

    // ME2 Neodymium parameters
    @State private var morlNeodymiumCount: Int = 14
    @State private var morlNeodymiumThickness: Float = 4
    @State private var morlFlangeHoleDist: Float = 25
    @State private var morlMagnetInnerR: Float = 85.5
    @State private var morlMagnetOuterR: Float = 101.5

    var body: some View {
        HSplitView {
            // Left sidebar: Controls + Log
            sidebar
                .frame(minWidth: 250, idealWidth: 300, maxWidth: 380)

            // Center: 3D Viewport
            ViewportView(sceneManager: sceneManager)
                .frame(minWidth: 500, minHeight: 400)

            // Right: Inspector
            InspectorView(sceneManager: sceneManager)
                .frame(minWidth: 200, idealWidth: 240, maxWidth: 300)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                if sceneManager.isRunning {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text(sceneManager.currentTaskName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Reset Camera") {
                    sceneManager.renderer?.camera.reset()
                }

                Button("Clear Scene") {
                    sceneManager.removeAllObjects()
                }
            }
        }
        .onAppear {
            sceneManager.initialize(voxelSizeMM: voxelSize)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Genolanx")
                    .font(.headline)
                Text("Computational Engineering")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            // Settings + Tasks — scrollable
            ScrollView {
                Form {
                    Section("Library") {
                        HStack {
                            Text("Voxel Size")
                            Spacer()
                            TextField("mm", value: $voxelSize, format: .number)
                                .frame(width: 60)
                                .textFieldStyle(.roundedBorder)
                            Text("mm")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Section("AEM : Turbine N\u{00E9}lis") {
                        nelisAccordion

                        Divider()

                        rimParameterControls

                        Button("Generate Rim") {
                            let ri = rimRayonInt
                            let ep = rimEpaisseur
                            let ht = rimHauteur
                            let np = rimNPoles
                            let ml = rimMagLargeur
                            let mh = rimMagHauteur
                            let mp = rimMagProfondeur
                            let mj = rimMagJeu
                            let mPat = MagnetPattern(rawValue: rimMagnetPatternIdx) ?? .standard
                            let nP = rimNPales
                            let pL = rimPaleLargeur
                            let pH = rimPaleHauteur
                            let nM = rimNacaM
                            let nPa = rimNacaP
                            let nT = rimNacaT
                            let pPitch = rimPalePitch
                            let pSweep = rimPaleSweep
                            sceneManager.runTask(name: "Methor Rim") { manager in
                                MethorRimTask.run(
                                    sceneManager: manager,
                                    rayonInterieur: ri,
                                    epaisseur: ep,
                                    hauteur: ht,
                                    nPoles: np,
                                    magnetLargeur: ml,
                                    magnetHauteur: mh,
                                    magnetProfondeur: mp,
                                    magnetJeu: mj,
                                    magnetPattern: mPat,
                                    nPales: nP,
                                    paleLargeur: pL,
                                    paleHauteurRadiale: pH,
                                    nacaM: nM,
                                    nacaP: nPa,
                                    nacaT: nT,
                                    palePitch: pPitch,
                                    paleSweep: pSweep)
                            }
                        }
                        .disabled(sceneManager.isRunning)
                        .buttonStyle(.borderedProminent)

                        let patLabel = rimMagnetPatternIdx == 1 ? "Halbach" : "Std"
                        Text("\(rimNPoles)p \(patLabel)  |  \u{00D8}int=\(String(format: "%.0f", rimRayonInt * 2))  \u{00D8}ext=\(String(format: "%.0f", (rimRayonInt + rimEpaisseur) * 2)) mm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Section("ME2 : Turbine Morland") {
                        morlandDataTable

                        Divider()

                        // Valeurs auto
                        let shoulderR = morlBearingOuterDiam / 2
                        let flangeR = shoulderR + morlFlangeExtension
                        Text("\u{00D8} Platine: \(String(format: "%.0f", flangeR * 2)) mm  |  Roul. \(String(format: "%.0f", morlBearingInnerDiam))/\(String(format: "%.0f", morlBearingOuterDiam))")
                            .font(.caption2).foregroundColor(.orange)

                        Button("Generate MorlandHub") {
                            let bi = morlBearingInnerDiam, bo = morlBearingOuterDiam
                            let bh = morlBearingHeight
                            let ht = morlHubTotalHeight, wt = morlWallThickness
                            let fe = morlFlangeExtension, ft = morlFlangeThickness
                            let fhc = morlFlangeHoleCount, fhr = morlFlangeHoleRadius
                            let feh = morlFunnelExitHeight, fbr = morlFunnelBottomRadius
                            let bc = morlBladeCount, bt = morlBladeThickness
                            let bta = morlBladeTwistAngle
                            let nc = morlNeodymiumCount, nt = morlNeodymiumThickness
                            let fhd = morlFlangeHoleDist
                            let mir = morlMagnetInnerR, mor = morlMagnetOuterR
                            sceneManager.runTask(name: "MorlandHub") { manager in
                                MorlandHubTask.run(
                                    sceneManager: manager,
                                    bearingInnerDiam: bi, bearingOuterDiam: bo,
                                    bearingHeight: bh,
                                    hubTotalHeight: ht, wallThickness: wt,
                                    flangeExtension: fe, flangeThickness: ft,
                                    flangeHoleCount: fhc, flangeHoleRadius: fhr,
                                    funnelExitHeight: feh, funnelBottomRadius: fbr,
                                    bladeCount: bc, bladeThickness: bt,
                                    bladeTwistAngle: bta,
                                    neodymiumCount: nc, neodymiumThickness: nt,
                                    flangeHoleDist: fhd,
                                    magnetInnerR: mir, magnetOuterR: mor)
                            }
                        }
                        .disabled(sceneManager.isRunning)
                        .buttonStyle(.borderedProminent)

                        Text("Roulement Noir + Billes Blanches")
                            .font(.caption2).foregroundColor(.secondary)

                        Divider()

                        Button("MorlandFunnel") {
                            sceneManager.runTask(name: "MorlandFunnel") { manager in
                                MorlandFunnelTask.run(sceneManager: manager)
                            }
                        }
                        .disabled(sceneManager.isRunning)
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }

                    Section("OC-1 : Inducteurs") {
                        spiralParameterControls

                        Button("Generate Spiral") {
                            let outerR = spiralOuterR
                            let innerR = spiralInnerR
                            let phases = spiralPhases
                            let wireDiam = spiralWireDiam
                            sceneManager.runTask(name: "Spiral Inductor") { manager in
                                SpiralInductorTask.run(
                                    sceneManager: manager,
                                    outerRadius: outerR,
                                    innerRadius: innerR,
                                    nPhases: phases,
                                    wireDiameter: wireDiam)
                            }
                        }
                        .disabled(sceneManager.isRunning)
                        .buttonStyle(.borderedProminent)

                        let pitch = spiralWireDiam * (1 + 1.0)
                        let nTurns = max(1, Int(floor((spiralOuterR - spiralInnerR - spiralWireDiam) / (2 * pitch))))
                        Text("\(nTurns) turns  |  pitch \(String(format: "%.1f", pitch)) mm")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Divider()

                        Button("MabogeInducteur") {
                            sceneManager.runTask(name: "MabogeInducteur") { manager in
                                MabogeInducteurTask.run(sceneManager: manager)
                            }
                        }
                        .disabled(sceneManager.isRunning)

                        Button("HelixHeatX") {
                            sceneManager.runTask(name: "HelixHeatX") { manager in
                                HelixHeatXTask.run(sceneManager: manager)
                            }
                        }
                        .disabled(sceneManager.isRunning)

                        Divider()

                        mabogeSlotParameterControls

                        Button("Generate Maboge Slot") {
                            let np = mabSlotPoles
                            let ri = mabSlotRInner
                            let ag = mabSlotAirGap
                            let pa = mabSlotProfA
                            let pb = mabSlotProfB
                            let pc = mabSlotProfC
                            let hh = mabSlotHautH
                            let nw = mabSlotNarrowPct
                            let fl = mabSlotFlatPct
                            sceneManager.runTask(name: "Maboge Slot") { manager in
                                MabogeSlotTask.run(
                                    sceneManager: manager,
                                    nPoles: np,
                                    rInnerBase: ri,
                                    airGap: ag,
                                    profondeurA: pa,
                                    profondeurB: pb,
                                    profondeurC: pc,
                                    hauteurH: hh,
                                    narrowPct: nw,
                                    flattenPct: fl)
                            }
                        }
                        .disabled(sceneManager.isRunning)
                        .buttonStyle(.borderedProminent)

                        let arcDeg = 360.0 / Float(mabSlotPoles)
                        Text("\(mabSlotPoles)p  arc=\(String(format: "%.1f", arcDeg))°  Ri=\(String(format: "%.0f", mabSlotRInner))mm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // MARK: - Ball Bearing Section
                    Section("Ball Bearing") {
                        bearingParameterControls

                        Button("Generate Bearing") {
                            let innerR = bearingInnerR
                            let outerR = bearingOuterR
                            let h = bearingHeight
                            sceneManager.runTask(name: "Ball Bearing") { manager in
                                BallBearingTask.run(
                                    sceneManager: manager,
                                    innerRadius: innerR,
                                    outerRadius: outerR,
                                    height: h)
                            }
                        }
                        .disabled(sceneManager.isRunning)
                        .buttonStyle(.borderedProminent)

                        // Info readout
                        let radialDepth = bearingOuterR - bearingInnerR
                        let raceT = max(1.5, radialDepth * 0.20)
                        let gapR = ((bearingOuterR - raceT) - (bearingInnerR + raceT)) / 2.0
                        let gapA = bearingHeight / 2.0
                        let ballR = max(0.5, min(gapR, gapA) * 0.85)
                        let pitchR = ((bearingInnerR + raceT) + (bearingOuterR - raceT)) / 2.0
                        let nBalls = max(3, Int(floor(2.0 * .pi * pitchR / (2.0 * ballR * 1.15))))
                        Text("\(nBalls) balls  |  ball \(String(format: "%.1f", ballR * 2)) mm dia")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // MARK: - Tests
                    Section("Tests") {
                        Button("Test Sphere") {
                            sceneManager.runTask(name: "Test Sphere") { manager in
                                TestTasks.sphere(sceneManager: manager)
                            }
                        }
                        .disabled(sceneManager.isRunning)

                        Button("Test Boolean") {
                            sceneManager.runTask(name: "Test Boolean") { manager in
                                TestTasks.booleanOps(sceneManager: manager)
                            }
                        }
                        .disabled(sceneManager.isRunning)
                    }
                }
                .formStyle(.grouped)
            }

            Divider()

            // Log
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Log")
                        .font(.caption.bold())
                    Spacer()
                    Button("Clear") {
                        sceneManager.logMessages.removeAll()
                    }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(sceneManager.logMessages) { entry in
                                Text(entry.message)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .textSelection(.enabled)
                                    .id(entry.id)
                            }
                        }
                        .padding(.horizontal, 12)
                    }
                    .onChange(of: sceneManager.logMessages.count) {
                        if let last = sceneManager.logMessages.last {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            .frame(minHeight: 120)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - Spiral Parameter Controls

    @ViewBuilder
    private var spiralParameterControls: some View {
        VStack(spacing: 6) {
            parameterRow("Outer R", value: $spiralOuterR, range: 20...200, unit: "mm")
            parameterRow("Inner R", value: $spiralInnerR, range: 5...100, unit: "mm")
            phaseStepper
            parameterRow("Wire Dia", value: $spiralWireDiam, range: 0.5...10, unit: "mm")
        }
    }

    // MARK: - Bearing Parameter Controls

    @ViewBuilder
    private var bearingParameterControls: some View {
        VStack(spacing: 6) {
            parameterRow("Inner R", value: $bearingInnerR, range: 5...50, unit: "mm")
            parameterRow("Outer R", value: $bearingOuterR, range: 15...80, unit: "mm")
            parameterRow("Height", value: $bearingHeight, range: 3...30, unit: "mm")
        }
    }

    // MARK: - N\u{00E9}lis Accordion Sub-sections

    @ViewBuilder
    private var nelisRoulementControls: some View {
        VStack(spacing: 6) {
            parameterRow("R Int.", value: $hubRoulInterieur, range: 5...30, unit: "mm")
            parameterRow("R Ext.", value: $hubRoulExterieur, range: 15...60, unit: "mm")
            parameterRow("Hauteur", value: $hubRoulHauteur, range: 3...25, unit: "mm")
        }
    }

    @ViewBuilder
    private var nelisHubControls: some View {
        VStack(spacing: 6) {
            parameterRow("Épaul.", value: $hubEpaulement, range: 2...20, unit: "mm")
            parameterRow("Ép. Flange", value: $hubEpaisseurFlange, range: 1...15, unit: "mm")
            parameterRow("Hauteur", value: $hubHauteur, range: 10...80, unit: "mm")
            parameterRow("Longueur", value: $hubLongueur, range: 20...100, unit: "mm")
            parameterRow("Offset", value: $turbHubOffset, range: 1...15, unit: "mm")

            Divider()

            // Branches (auto-dées au hub)
            HStack {
                Text("Branches").font(.caption).frame(width: 55, alignment: .leading)
                Spacer()
                Text("\(hubBranchesAuto) (= S slots)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.orange)
            }
            parameterRow("Épaisseur", value: $hubBranchEpaisseur, range: 0.5...10, unit: "mm")
            parameterRow("Hauteur", value: $hubBranchHauteur, range: 1...20, unit: "mm")
            parameterRow("H Plot", value: $hubPlotHauteur, range: 1...25, unit: "mm")
            parameterRow("R Fork", value: $hubRayonFork, range: 55...150, unit: "mm")
            HStack {
                Text("R Final").font(.caption).frame(width: 55, alignment: .leading)
                Spacer()
                Text("\(String(format: "%.0f", hubRayonFinalAuto)) mm (Noir mid)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.orange)
            }
        }
    }

    // MARK: - Turbine Preset Helpers

    private func applyTurbinePreset(_ preset: TurbinePreset) {
        turbOgiveHauteur = preset.ogiveHauteur
        turbOgiveBaseRadius = preset.ogiveBaseRadius
        turbNPales = preset.nPales
        turbJanteDiametre = preset.janteDiametre
        turbPaleLargeur = preset.paleLargeur
        turbPaleEpaisseur = preset.paleEpaisseur
        turbPalePitch = preset.palePitch
        turbPaleHBegin = preset.paleHauteurBegin
        turbPaleHEnd = preset.paleHauteurEnd
        turbJanteHauteur = preset.janteHauteur
        turbJanteEpaisseur = preset.janteEpaisseur
        turbNPoles = preset.nPoles
        turbMagnetCatalogID = preset.magnetCatalogID
        turbMagnetPatternIdx = preset.magnetPattern.rawValue
        turbChevronAngle = preset.chevronAngle
        turbMagnetJeu = preset.magnetJeu
        adaptTurbJanteForMagnet()
    }

    /// Auto-adapte H Jante et Ep Jante au minimum requis par l'aimant sélectionné.
    private func adaptTurbJanteForMagnet() {
        guard let mag = MagnetCatalogEntry.find(id: turbMagnetCatalogID) else { return }
        if turbJanteHauteur < mag.minRimHauteur {
            turbJanteHauteur = mag.minRimHauteur
        }
        if turbJanteEpaisseur < mag.minRimEpaisseur {
            turbJanteEpaisseur = mag.minRimEpaisseur
        }
    }

    @ViewBuilder
    private var nelisPalesControls: some View {
        VStack(spacing: 6) {
            parameterRow("H Ogive", value: $turbOgiveHauteur, range: 10...120, unit: "mm")
            parameterRow("Base R", value: $turbOgiveBaseRadius, range: 10...100, unit: "mm")

            Divider()

            HStack {
                Text("Pales")
                    .font(.caption)
                    .frame(width: 55, alignment: .leading)
                Stepper(value: $turbNPales, in: 0...12) {
                    Text("\(turbNPales)")
                        .font(.system(.caption, design: .monospaced))
                }
            }
            if turbNPales > 0 {
                parameterRow("Largeur", value: $turbPaleLargeur, range: 5...120, unit: "mm")
                parameterRow("Épaisseur", value: $turbPaleEpaisseur, range: 1...10, unit: "mm")
                parameterRow("Pitch", value: $turbPalePitch, range: 0...45, unit: "°")
                parameterRow("H Begin", value: $turbPaleHBegin, range: -20...40, unit: "mm")
                parameterRow("H End", value: $turbPaleHEnd, range: -30...30, unit: "mm")
            }
        }
    }

    @ViewBuilder
    private var nelisJanteAimantsControls: some View {
        VStack(spacing: 6) {
            parameterRow("\u{00D8} Jante", value: $turbJanteDiametre, range: 100...1200, unit: "mm")
            parameterRow("H Jante", value: $turbJanteHauteur, range: 2...60, unit: "mm")
            parameterRow("Ep Jante", value: $turbJanteEpaisseur, range: 1...40, unit: "mm")

            Divider()

            Text("Aimant (supermagnete.be)").font(.caption).foregroundColor(.secondary)
            Picker("Aimant", selection: Binding(
                get: { turbMagnetCatalogID },
                set: { newID in
                    turbMagnetCatalogID = newID
                    adaptTurbJanteForMagnet()
                }
            )) {
                ForEach(MagnetCatalogEntry.catalog) { entry in
                    Text(entry.label).tag(entry.id)
                }
            }
            .labelsHidden()

            if let mag = MagnetCatalogEntry.find(id: turbMagnetCatalogID) {
                Text("\(mag.grade)  Br=\(String(format: "%.2f", mag.brTesla))T  \(String(format: "%.0f", mag.lengthMM))\u{00D7}\(String(format: "%.0f", mag.widthMM))\u{00D7}\(String(format: "%.0f", mag.thicknessMM)) mm")
                    .font(.caption2).foregroundColor(.secondary)
                Text("\u{00C9}p. min=\(String(format: "%.0f", mag.minRimEpaisseur))  H min=\(String(format: "%.0f", mag.minRimHauteur)) mm")
                    .font(.caption2).foregroundColor(.orange)
            }

            parameterRow("Jeu", value: $turbMagnetJeu, range: 0.05...1.0, unit: "mm")

            Divider()

            Text("Motif aimants").font(.caption).foregroundColor(.secondary)
            Picker("Pattern", selection: Binding(
                get: { turbMagnetPatternIdx },
                set: { newIdx in
                    turbMagnetPatternIdx = newIdx
                    adaptTurbJanteForMagnet()
                }
            )) {
                ForEach(MagnetPattern.allCases, id: \.rawValue) { pat in
                    Text(pat.label).tag(pat.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Divider()

            HStack {
                Text("P\u{00F4}les")
                    .font(.caption)
                    .frame(width: 55, alignment: .leading)
                Stepper(value: $turbNPoles, in: 4...64, step: 2) {
                    Text("\(turbNPoles)")
                        .font(.system(.caption, design: .monospaced))
                }
            }

            if turbMagnetPatternIdx == 1 {
                parameterRow("Angle V", value: $turbChevronAngle, range: 5...45, unit: "\u{00B0}")
                Text("Chevron: \(turbNPoles) aimants  /\\/\\/\\")
                    .font(.caption2).foregroundColor(.orange)
            } else {
                Text("Standard: \(turbNPoles / 2) aimants (pair)")
                    .font(.caption2).foregroundColor(.orange)
            }
        }
    }

    @ViewBuilder
    private var nelisStatorControls: some View {
        VStack(spacing: 6) {
            // ── Slots stator (multiple de 3) ──
            HStack {
                Text("Slots (S)")
                    .font(.caption)
                    .frame(width: 55, alignment: .leading)
                Stepper(value: $statorSlots, in: 12...42, step: 3) {
                    Text("\(statorSlots)")
                        .font(.system(.caption, design: .monospaced))
                }
            }

            // ── Configurations de p\u{00F4}les recommand\u{00E9}es ──
            let candidates = MotorConfig.topBalanced(forSlots: statorSlots, count: 4)

            if !candidates.isEmpty {
                Text("P\u{00F4}les rotor (P) \u{2014} \u{00E9}quilibr\u{00E9}s").font(.caption).foregroundColor(.secondary)

                Picker("P\u{00F4}les", selection: Binding(
                    get: { turbNPoles },
                    set: { newP in turbNPoles = newP }
                )) {
                    ForEach(candidates) { c in
                        Text("\(c.poles)p").tag(c.poles)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                // D\u{00E9}tail de la config s\u{00E9}lectionn\u{00E9}e
                if let sel = candidates.first(where: { $0.poles == turbNPoles }) {
                    let fHz = MotorConfig.electricalFrequency(poles: sel.poles, rpm: 3000)
                    HStack(spacing: 4) {
                        Text("q=\(String(format: "%.2f", sel.q))")
                        Text("kw\u{2081}=\(String(format: "%.3f", sel.kw1))")
                        Text("f=\(String(format: "%.0f", fHz))Hz")
                    }
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.orange)

                    HStack(spacing: 4) {
                        Text("GCD=\(sel.gcdSP)")
                        Text("LCM=\(sel.lcmSP)")
                        Text("Cogging: \(sel.coggingLabel)")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                } else {
                    // turbNPoles pas dans les candidats \u{2014} auto-s\u{00E9}lectionner le meilleur
                    Text("\u{26A0} P=\(turbNPoles) non recommand\u{00E9} pour S=\(statorSlots)")
                        .font(.caption2).foregroundColor(.red)
                }
            }

            Divider()

            // ── R Inner auto (depuis jante) ──
            let autoR = turbJanteDiametre / 2.0 + turbJanteEpaisseur / 2.0
            Text("R Inner auto: \(String(format: "%.0f", autoR)) mm  (jante ext.)")
                .font(.caption2).foregroundColor(.orange)

            Divider()

            // ── Param\u{00E8}tres g\u{00E9}om\u{00E9}triques slot ──
            parameterRow("Air Gap", value: $mabSlotAirGap, range: 0.5...10, unit: "mm")
            parameterRow("Prof. A", value: $mabSlotProfA, range: 2...6, unit: "mm")
            parameterRow("Prof. B", value: $mabSlotProfB, range: 1...50, unit: "mm")
            parameterRow("Prof. C", value: $mabSlotProfC, range: 1...50, unit: "mm")
            parameterRow("Narrow", value: $mabSlotNarrowPct, range: 10...100, unit: "%")
            parameterRow("Aplatir", value: $mabSlotFlatPct, range: 10...100, unit: "%")
        }
    }

    // MARK: - N\u{00E9}lis Accordion Layout

    @ViewBuilder
    private var nelisAccordion: some View {
        // ── Preset (toujours visible) ──
        Picker("Preset", selection: Binding(
            get: { turbPreset },
            set: { newPreset in
                turbPreset = newPreset
                applyTurbinePreset(newPreset)
            }
        )) {
            ForEach(TurbinePreset.allCases) { preset in
                Text(preset.rawValue).tag(preset)
            }
        }
        .pickerStyle(.segmented)

        // ── 1. Roulement ──
        DisclosureGroup(isExpanded: $nelisSecRoulement) {
            nelisRoulementControls
        } label: {
            HStack {
                Text("1. Roulement").font(.caption.bold())
                Spacer()
                Text("Ri=\(String(format: "%.0f", hubRoulInterieur))  Re=\(String(format: "%.0f", hubRoulExterieur))  H=\(String(format: "%.0f", hubRoulHauteur))")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }

        // ── 2. Hub ──
        DisclosureGroup(isExpanded: $nelisSecHub) {
            nelisHubControls
        } label: {
            HStack {
                Text("2. Hub").font(.caption.bold())
                Spacer()
                Text("3 \u{00E9}tages  \(hubBranchesAuto) branches (auto)")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }

        // ── 3. Pales & Ogive ──
        DisclosureGroup(isExpanded: $nelisSecPales) {
            nelisPalesControls
        } label: {
            HStack {
                Text("3. Pales & Ogive").font(.caption.bold())
                Spacer()
                Text("\(turbNPales)p  Pitch=\(String(format: "%.0f", turbPalePitch))\u{00B0}  Ogive H=\(String(format: "%.0f", turbOgiveHauteur))")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }

        // ── 4. Jante & Aimants ──
        DisclosureGroup(isExpanded: $nelisSecJante) {
            nelisJanteAimantsControls
        } label: {
            HStack {
                Text("4. Jante & Aimants").font(.caption.bold())
                Spacer()
                let patL = turbMagnetPatternIdx == 1 ? "Halbach" : "Std"
                Text("\u{00D8}\(String(format: "%.0f", turbJanteDiametre))  \(turbNPoles)p \(patL)")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }

        // ── 5. Stator MabogeSlot ──
        DisclosureGroup(isExpanded: $nelisSecStator) {
            nelisStatorControls
        } label: {
            HStack {
                Text("5. Stator").font(.caption.bold())
                Spacer()
                Text("S=\(statorSlots)  P=\(turbNPoles)  Gap=\(String(format: "%.0f", mabSlotAirGap))")
                    .font(.caption2).foregroundColor(.secondary)
            }
        }

        Divider()

        // ── Bouton principal Assembly ──
        Button("Generate Assembly") {
            let oH = turbOgiveHauteur, oR = turbOgiveBaseRadius
            let np = turbNPales, jD = turbJanteDiametre
            let pL = turbPaleLargeur, pE = turbPaleEpaisseur
            let pP = turbPalePitch, hB = turbPaleHBegin, hE = turbPaleHEnd
            let jH = turbJanteHauteur, jE = turbJanteEpaisseur
            let nP = turbNPoles
            let mID = turbMagnetCatalogID
            let mPat = MagnetPattern(rawValue: turbMagnetPatternIdx) ?? .standard
            let chA = turbChevronAngle, mJeu = turbMagnetJeu
            let rExt = hubRoulExterieur, rHaut = hubRoulHauteur
            let hOff = turbHubOffset
            let ri = hubRoulInterieur, ep = hubEpaulement
            let ef = hubEpaisseurFlange, ht = hubHauteur
            let lg = hubLongueur
            let nb = hubBranchesAuto
            let bEp = hubBranchEpaisseur, bH = hubBranchHauteur
            let rF = hubRayonFork, rFin = hubRayonFinalAuto, pH = hubPlotHauteur
            let sS = statorSlots
            let sAG = mabSlotAirGap, sPA = mabSlotProfA
            let sPB = mabSlotProfB, sPC = mabSlotProfC
            let sNW = mabSlotNarrowPct, sFL = mabSlotFlatPct
            sceneManager.runTask(name: "Assembly") { manager in
                MethorAssemblyTask.run(
                    sceneManager: manager,
                    ogiveHauteur: oH, ogiveBaseRadius: oR,
                    nPales: np, janteDiametre: jD,
                    paleLargeur: pL, paleEpaisseur: pE,
                    palePitch: pP, paleHauteurBegin: hB,
                    paleHauteurEnd: hE, janteHauteur: jH,
                    janteEpaisseur: jE, nPoles: nP,
                    magnetCatalogID: mID, magnetPattern: mPat,
                    chevronAngle: chA, magnetJeu: mJeu,
                    roulementExterieur: rExt, roulementHauteur: rHaut,
                    hubOffset: hOff,
                    hubRoulInterieur: ri, hubEpaulement: ep,
                    hubEpaisseurFlange: ef, hubHauteur: ht,
                    hubLongueur: lg, nBranches: nb,
                    branchEpaisseur: bEp, branchHauteur: bH,
                    rayonFork: rF, rayonFinal: rFin,
                    plotHauteur: pH,
                    statorSlots: sS,
                    statorAirGap: sAG, statorProfA: sPA,
                    statorProfB: sPB, statorProfC: sPC,
                    statorNarrowPct: sNW, statorFlattenPct: sFL)
            }
        }
        .disabled(sceneManager.isRunning)
        .buttonStyle(.borderedProminent)
        .tint(.purple)

        Text("Hub 50% + roulement + stator MabogeSlot")
            .font(.caption2)
            .foregroundColor(.purple)

        // ── Boutons secondaires ──
        HStack(spacing: 8) {
            Button("Turbine seule") {
                let oH = turbOgiveHauteur, oR = turbOgiveBaseRadius
                let np = turbNPales, jD = turbJanteDiametre
                let pL = turbPaleLargeur, pE = turbPaleEpaisseur
                let pP = turbPalePitch, hB = turbPaleHBegin, hE = turbPaleHEnd
                let jH = turbJanteHauteur, jE = turbJanteEpaisseur
                let nP = turbNPoles, mID = turbMagnetCatalogID
                let mPat = MagnetPattern(rawValue: turbMagnetPatternIdx) ?? .standard
                let chA = turbChevronAngle, mJeu = turbMagnetJeu
                let rExt = hubRoulExterieur, rHaut = hubRoulHauteur
                let hOff = turbHubOffset
                sceneManager.runTask(name: "Turbine") { manager in
                    TurbineTask.run(
                        sceneManager: manager,
                        ogiveHauteur: oH, ogiveBaseRadius: oR,
                        nPales: np, janteDiametre: jD,
                        paleLargeur: pL, paleEpaisseur: pE,
                        palePitch: pP, paleHauteurBegin: hB,
                        paleHauteurEnd: hE, janteHauteur: jH,
                        janteEpaisseur: jE, nPoles: nP,
                        magnetCatalogID: mID, magnetPattern: mPat,
                        chevronAngle: chA, magnetJeu: mJeu,
                        roulementExterieur: rExt, roulementHauteur: rHaut,
                        hubOffset: hOff)
                }
            }
            .disabled(sceneManager.isRunning)
            .buttonStyle(.bordered)
            .font(.caption)

            Button("Hub seul") {
                let ri = hubRoulInterieur, re = hubRoulExterieur
                let ep = hubEpaulement, rh = hubRoulHauteur
                let ef = hubEpaisseurFlange, ht = hubHauteur
                let lg = hubLongueur
                let nb = hubBranchesAuto
                let bEp = hubBranchEpaisseur, bH = hubBranchHauteur
                let rF = hubRayonFork, rFin = hubRayonFinalAuto, pH = hubPlotHauteur
                sceneManager.runTask(name: "Methor Hub") { manager in
                    MethorHubTask.run(
                        sceneManager: manager,
                        roulementInterieur: ri, roulementExterieur: re,
                        epaulement: ep, roulementHauteur: rh,
                        epaisseurFlange: ef, hauteur: ht,
                        longueur: lg, nBranches: nb,
                        branchEpaisseur: bEp, branchHauteur: bH,
                        rayonFork: rF, rayonFinal: rFin,
                        plotHauteur: pH,
                        losHalfL: 10.0, losHalfW: 5.5,
                        forkAngleFactor: 0.25)
                }
            }
            .disabled(sceneManager.isRunning)
            .buttonStyle(.bordered)
            .font(.caption)
        }
    }

    // MARK: - Rim Parameter Controls

    @ViewBuilder
    private var rimParameterControls: some View {
        VStack(spacing: 6) {
            parameterRow("R Int.", value: $rimRayonInt, range: 50...300, unit: "mm")
            parameterRow("\u{00C9}paisseur", value: $rimEpaisseur, range: 5...40, unit: "mm")
            parameterRow("Hauteur", value: $rimHauteur, range: 8...60, unit: "mm")

            Divider()

            // ── Magnet catalog picker ──
            Text("Aimant (supermagnete.be)").font(.caption).foregroundColor(.secondary)
            Picker("Aimant", selection: $rimMagnetID) {
                ForEach(MagnetCatalogEntry.catalog) { entry in
                    Text(entry.label).tag(entry.id)
                }
            }
            .labelsHidden()
            .onChange(of: rimMagnetID) {
                if let mag = MagnetCatalogEntry.find(id: rimMagnetID) {
                    rimMagLargeur = mag.lengthMM
                    rimMagHauteur = mag.widthMM
                    rimMagProfondeur = mag.thicknessMM
                    // Auto-resize rim to fit the magnet
                    if rimEpaisseur < mag.minRimEpaisseur {
                        rimEpaisseur = mag.minRimEpaisseur
                    }
                    if rimHauteur < mag.minRimHauteur {
                        rimHauteur = mag.minRimHauteur
                    }
                }
            }

            if let mag = MagnetCatalogEntry.find(id: rimMagnetID) {
                Text("\(mag.grade)  Br=\(String(format: "%.2f", mag.brTesla))T  \(String(format: "%.0f", mag.lengthMM))\u{00D7}\(String(format: "%.0f", mag.widthMM))\u{00D7}\(String(format: "%.0f", mag.thicknessMM)) mm")
                    .font(.caption2).foregroundColor(.secondary)
                Text("\u{00C9}p. min=\(String(format: "%.0f", mag.minRimEpaisseur))  H min=\(String(format: "%.0f", mag.minRimHauteur)) mm")
                    .font(.caption2).foregroundColor(.orange)
            }

            parameterRow("Jeu", value: $rimMagJeu, range: 0.05...1.0, unit: "mm")

            Divider()

            // ── Magnet pattern radio ──
            Text("Motif aimants").font(.caption).foregroundColor(.secondary)
            Picker("Pattern", selection: $rimMagnetPatternIdx) {
                ForEach(MagnetPattern.allCases, id: \.rawValue) { pat in
                    Text(pat.label).tag(pat.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Divider()

            HStack {
                Text("P\u{00F4}les")
                    .font(.caption)
                    .frame(width: 55, alignment: .leading)
                Stepper(value: $rimNPoles, in: 4...64, step: 2) {
                    Text("\(rimNPoles)")
                        .font(.system(.caption, design: .monospaced))
                }
            }

            if rimMagnetPatternIdx == 1 {
                Text("Halbach: \(rimNPoles * 4) segments")
                    .font(.caption2).foregroundColor(.orange)
            }

            Divider()

            HStack {
                Text("Pales")
                    .font(.caption)
                    .frame(width: 55, alignment: .leading)
                Stepper(value: $rimNPales, in: 0...12) {
                    Text("\(rimNPales)")
                        .font(.system(.caption, design: .monospaced))
                }
            }

            if rimNPales > 0 {
                parameterRow("Base L", value: $rimPaleLargeur, range: 15...80, unit: "mm")
                parameterRow("Enverg.", value: $rimPaleHauteur, range: 20...200, unit: "mm")

                let autoChord = sqrt(rimPaleLargeur * rimPaleLargeur + rimHauteur * rimHauteur)
                Text("Corde auto: \(String(format: "%.1f", autoChord)) mm (diagonale)")
                    .font(.caption).foregroundColor(.secondary)

                Text("NACA \(String(format: "%01.0f%01.0f%02.0f", rimNacaM, rimNacaP, rimNacaT))")
                    .font(.caption).foregroundColor(.secondary)
                parameterRow("Cambrure", value: $rimNacaM, range: 0...9, unit: "%")
                parameterRow("Pos. camb.", value: $rimNacaP, range: 1...9, unit: "/10")
                parameterRow("\u{00C9}paisseur", value: $rimNacaT, range: 6...24, unit: "%")

                Divider()
                Text("Angles de pale").font(.caption).foregroundColor(.secondary)
                parameterRow("Pitch", value: $rimPalePitch, range: -30...30, unit: "\u{00B0}")
                parameterRow("Sweep", value: $rimPaleSweep, range: -20...20, unit: "\u{00B0}")
            }
        }
    }

    // MARK: - MabogeSlot Parameter Controls (OC-1)

    @ViewBuilder
    private var mabogeSlotParameterControls: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Pôles (p)")
                    .font(.caption)
                    .frame(width: 70, alignment: .leading)
                Stepper(value: $mabSlotPoles, in: 3...33) {
                    Text("\(mabSlotPoles)")
                        .font(.system(.caption, design: .monospaced))
                }
            }

            parameterRow("R Inner", value: $mabSlotRInner, range: 50...300, unit: "mm")
            parameterRow("Air Gap", value: $mabSlotAirGap, range: 0.5...10, unit: "mm")
            parameterRow("Prof. A", value: $mabSlotProfA, range: 2...6, unit: "mm")
            parameterRow("Prof. B", value: $mabSlotProfB, range: 1...50, unit: "mm")
            parameterRow("Prof. C", value: $mabSlotProfC, range: 1...50, unit: "mm")
            parameterRow("Haut. H", value: $mabSlotHautH, range: 5...60, unit: "mm")
            parameterRow("Narrow", value: $mabSlotNarrowPct, range: 10...100, unit: "%")
            parameterRow("Aplatir", value: $mabSlotFlatPct, range: 10...100, unit: "%")
        }
    }

    private func parameterRow(_ label: String, value: Binding<Float>,
                               range: ClosedRange<Float>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label)
                    .font(.caption)
                    .frame(width: 55, alignment: .leading)
                Slider(value: value, in: range)
                Text(String(format: "%.1f", value.wrappedValue))
                    .font(.system(.caption, design: .monospaced))
                    .frame(width: 40, alignment: .trailing)
                Text(unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
            }
        }
    }

    private var phaseStepper: some View {
        HStack {
            Text("Phases")
                .font(.caption)
                .frame(width: 55, alignment: .leading)
            Stepper(value: $spiralPhases, in: 1...12) {
                Text("\(spiralPhases)")
                    .font(.system(.caption, design: .monospaced))
            }
        }
    }

    // MARK: - ME2 Morland Data-Table

    @ViewBuilder
    private var morlandDataTable: some View {
        VStack(spacing: 0) {
            // En-tête colonnes
            HStack(spacing: 0) {
                Text("Param.")
                    .frame(width: 70, alignment: .leading)
                Text("Valeur")
                    .frame(width: 50, alignment: .trailing)
                Spacer()
                Text("Unit")
                    .frame(width: 28, alignment: .trailing)
            }
            .font(.caption2.bold())
            .padding(.vertical, 3)
            .padding(.horizontal, 4)
            .background(Color.gray.opacity(0.15))

            // Section Roulement
            dataTableSection("Roulement", color: .primary) {
                dataRow("RI", value: $morlBearingInnerDiam, range: 20...200, unit: "mm")
                dataRow("RE", value: $morlBearingOuterDiam, range: 30...300, unit: "mm")
                dataRow("H", value: $morlBearingHeight, range: 5...50, unit: "mm")
            }

            // Section Hub Body
            dataTableSection("Hub Body", color: .blue) {
                dataRow("Hauteur", value: $morlHubTotalHeight, range: 20...120, unit: "mm")
                dataRow("Paroi", value: $morlWallThickness, range: 1...15, unit: "mm")
            }

            // Section Platine
            dataTableSection("Platine", color: .orange) {
                dataRow("Extension", value: $morlFlangeExtension, range: 10...100, unit: "mm")
                dataRow("Épaisseur", value: $morlFlangeThickness, range: 2...15, unit: "mm")
                dataRowInt("Trous", count: $morlFlangeHoleCount, range: 4...16)
                dataRow("Ø Trou", value: $morlFlangeHoleRadius, range: 2...10, unit: "mm")
            }

            // Section Hélices
            dataTableSection("Hélices", color: .green) {
                dataRowInt("Nombre", count: $morlBladeCount, range: 3...24)
                dataRow("Épaisseur", value: $morlBladeThickness, range: 0.5...8, unit: "mm")
                dataRow("Twist", value: $morlBladeTwistAngle, range: 0...180, unit: "°")
            }

            // Section Entonnoir
            dataTableSection("Entonnoir", color: .purple) {
                dataRow("H Sortie", value: $morlFunnelExitHeight, range: 5...60, unit: "mm")
                dataRow("R Sortie", value: $morlFunnelBottomRadius, range: 2...30, unit: "mm")
            }

            // Section Néodyme
            dataTableSection("Néodyme", color: .gray) {
                dataRowInt("Secteurs", count: $morlNeodymiumCount, range: 14...28)
                dataRow("Épaisseur", value: $morlNeodymiumThickness, range: 1...10, unit: "mm")
                dataRow("Dist. Trou", value: $morlFlangeHoleDist, range: 10...50, unit: "mm")
                dataRow("R Interne", value: $morlMagnetInnerR, range: 50...150, unit: "mm")
                dataRow("R Externe", value: $morlMagnetOuterR, range: 60...150, unit: "mm")
            }
        }
    }

    /// Ligne de grille pour Float : label | slider | valeur monospaced | unité
    private func dataRow(_ label: String, value: Binding<Float>,
                         range: ClosedRange<Float>, unit: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .frame(width: 70, alignment: .leading)
                .lineLimit(1)
            Slider(value: value, in: range)
                .controlSize(.mini)
            Text(String(format: "%.1f", value.wrappedValue))
                .font(.system(.caption2, design: .monospaced))
                .frame(width: 40, alignment: .trailing)
            Text(unit)
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 28, alignment: .trailing)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
    }

    /// Ligne de grille pour Int : label | stepper inline | valeur
    private func dataRowInt(_ label: String, count: Binding<Int>,
                            range: ClosedRange<Int>) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .frame(width: 70, alignment: .leading)
                .lineLimit(1)
            Stepper(value: count, in: range) {
                Text("\(count.wrappedValue)")
                    .font(.system(.caption2, design: .monospaced))
            }
            .controlSize(.mini)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
    }

    /// En-tête de section coloré pour la data-table
    private func dataTableSection<Content: View>(
        _ title: String, color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(title)
                    .font(.caption2.bold())
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .background(color.opacity(0.08))

            content()
        }
    }
}

// MARK: - Test Tasks (for validation before ShapeKernel is ported)

enum TestTasks {
    static func sphere(sceneManager: SceneManager) {
        sceneManager.log("Creating test sphere...")

        let lat = PicoGKLattice()
        lat.addSphere(center: SIMD3(0, 0, 0), radius: 15.0)

        let vox = PicoGKVoxels(lattice: lat)
        let props = vox.calculateProperties()
        sceneManager.log("Sphere volume: \(String(format: "%.1f", props.volumeCubicMM)) mm3")

        DispatchQueue.main.async {
            sceneManager.addVoxels(vox, groupID: 0, name: "Sphere")
            sceneManager.setGroupMaterial(0, color: PKColorFloat(r: 0.3, g: 0.6, b: 0.9, a: 1.0),
                                          metallic: 0.3, roughness: 0.5)
        }
    }

    static func booleanOps(sceneManager: SceneManager) {
        sceneManager.log("Creating boolean test...")

        // Sphere A
        let latA = PicoGKLattice()
        latA.addSphere(center: SIMD3(0, 0, 0), radius: 15.0)
        let voxA = PicoGKVoxels(lattice: latA)

        // Sphere B (offset)
        let latB = PicoGKLattice()
        latB.addSphere(center: SIMD3(10, 0, 0), radius: 12.0)
        let voxB = PicoGKVoxels(lattice: latB)

        // Union
        let voxUnion = voxA + voxB
        sceneManager.log("Union created")

        // Cylinder to subtract (via lattice beam)
        let latHole = PicoGKLattice()
        latHole.addBeam(from: SIMD3(0, 0, -25), radiusA: 5.0,
                        to: SIMD3(0, 0, 25), radiusB: 5.0, roundCap: false)
        let voxHole = PicoGKVoxels(lattice: latHole)

        let result = voxUnion - voxHole
        result.smoothen(1.0)
        sceneManager.log("Subtraction + smoothing done")

        let props = result.calculateProperties()
        sceneManager.log("Result volume: \(String(format: "%.1f", props.volumeCubicMM)) mm3")

        DispatchQueue.main.async {
            sceneManager.removeAllObjects()
            sceneManager.addVoxels(result, groupID: 0, name: "Boolean Result")
            sceneManager.setGroupMaterial(0, color: PKColorFloat(r: 0.9, g: 0.4, b: 0.2, a: 1.0),
                                          metallic: 0.6, roughness: 0.3)
        }
    }
}
