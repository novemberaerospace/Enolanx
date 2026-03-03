// HelixHeatX.swift
// Genolanx — Port of LEAP71 HelixHeatX (helical counter-flow heat exchanger)
//
// Original: 11 C# partial class files merged into a single Swift file.
// SPDX-License-Identifier: Apache-2.0

import Foundation
import simd
import PicoGKBridge

// MARK: - Task Entry Point

enum HelixHeatXTask {
    static func run(sceneManager: SceneManager) {
        let hx = HelixHeatX(sceneManager: sceneManager)
        hx.voxConstruct()
    }
}

// MARK: - HelixHeatX

final class HelixHeatX {

    enum EFluid { case cool, hot }

    private let sceneManager: SceneManager
    private let firstInletFrame: LocalFrame
    private let secondInletFrame: LocalFrame
    private let firstOutletFrame: LocalFrame
    private let secondOutletFrame: LocalFrame
    private let centreBottomFrame: LocalFrame
    private let ioRadius: Float
    private let voxBounding: PicoGKVoxels
    private let plateThickness: Float
    private let wallThickness: Float

    init(sceneManager: SceneManager) {
        self.sceneManager = sceneManager

        let halfIOLength: Float = 75
        let halfIOWidth: Float = 26.5

        firstInletFrame = LocalFrame(
            position: SIMD3(-halfIOLength, -halfIOWidth, 50),
            localZ: SIMD3(-1, 0, 0))
        secondInletFrame = LocalFrame(
            position: SIMD3(-halfIOLength, halfIOWidth, 50),
            localZ: SIMD3(-1, 0, 0))
        firstOutletFrame = LocalFrame(
            position: SIMD3(halfIOLength, -halfIOWidth, 50),
            localZ: SIMD3(1, 0, 0))
        secondOutletFrame = LocalFrame(
            position: SIMD3(halfIOLength, halfIOWidth, 50),
            localZ: SIMD3(1, 0, 0))

        centreBottomFrame = LocalFrame(
            position: SIMD3(-50, 0, 50),
            localZ: SIMD3(1, 0, 0),
            localX: SIMD3(0, 0, 1))

        let outerBox = BaseBox(
            LocalFrame(position: SIMD3(0, 0, -4)),
            107, 2 * halfIOLength + 24, 104)
        voxBounding = outerBox.voxConstruct()

        plateThickness = 3.5
        wallThickness = 0.8
        ioRadius = 7
    }

    // MARK: - Main Construction

    func voxConstruct() {
        sceneManager.log("HelixHeatX: Building turning fins...")
        let voxHotCornerFins = voxGetTurningFins(.hot)
        let voxCoolCornerFins = voxGetTurningFins(.cool)
        let voxAllCornerFins = voxHotCornerFins + voxCoolCornerFins

        sceneManager.log("HelixHeatX: Building straight fins...")
        let voxHotStraightFins = voxGetStraightFins(.hot)
        let voxCoolStraightFins = voxGetStraightFins(.cool)
        let voxAllStraightFins = voxHotStraightFins + voxCoolStraightFins

        let voxFins = voxAllCornerFins + voxAllStraightFins

        sceneManager.log("HelixHeatX: Building outer structure...")
        let voxStructure = voxGetOuterStructure()

        sceneManager.log("HelixHeatX: Building helical voids (hot)...")
        let (voxHotFluidVoidRaw, voxHotFluidSplitters) = getHelicalVoid(.hot)

        sceneManager.log("HelixHeatX: Building helical voids (cool)...")
        let (voxCoolFluidVoidRaw, voxCoolFluidSplitters) = getHelicalVoid(.cool)

        // Subtract offset of opposite fluid
        let voxHotFluidVoid = voxHotFluidVoidRaw
        let voxCoolFluidVoid = voxCoolFluidVoidRaw
        voxHotFluidVoid.boolSubtract(voxCoolFluidVoidRaw.offsetted(wallThickness))
        voxCoolFluidVoid.boolSubtract(voxHotFluidVoidRaw.offsetted(wallThickness))

        let voxInnerVolume = voxHotFluidVoid + voxCoolFluidVoid
        let voxSplitters = voxHotFluidSplitters + voxCoolFluidSplitters
        let voxOuterVolume = voxInnerVolume.offsetted(0.9)

        sceneManager.log("HelixHeatX: Building flange...")
        let (voxFlange, voxScrewHoles, _) = getFlange()
        voxFlange.fillet(5)
        voxFlange.smoothen(0.5)

        voxOuterVolume.boolAdd(voxFlange)
        voxOuterVolume.boolAdd(voxGetIOSupports())
        voxOuterVolume.fillet(5)
        voxOuterVolume.smoothen(0.5)

        sceneManager.log("HelixHeatX: Adding centre piece...")
        addCentrePiece(voxOuterVolume)

        voxOuterVolume.boolAdd(voxStructure)
        voxOuterVolume.boolSubtract(voxScrewHoles)
        voxOuterVolume.projectZSlice(startZ: 4, endZ: -4)
        voxOuterVolume.boolSubtract(voxGetPrintWeb())

        sceneManager.log("HelixHeatX: Final assembly...")
        let voxResult = voxOuterVolume - voxInnerVolume
        voxResult.boolAdd(voxFins)
        voxResult.boolAdd(voxSplitters)
        voxResult.boolIntersect(voxBounding)

        let voxThreads = voxGetIOThreads()
        voxResult.boolAdd(voxThreads)
        voxResult.boolSubtract(voxGetIOCuts())

        let sm = sceneManager
        DispatchQueue.main.async {
            sm.removeAllObjects()
            sm.addVoxels(voxResult, groupID: 0, name: "HelixHeatX")
            sm.setGroupMaterial(0, color: Cp.clrRock, metallic: 0.5, roughness: 0.4)
        }

        sceneManager.log("HelixHeatX: Exporting STL...")
        let path = NSHomeDirectory() + "/Documents/HelixHeatX.stl"
        sceneManager.exportSTL(voxels: voxResult, to: path)
        sceneManager.log("HelixHeatX: Done!")
    }

    // MARK: - Misc (vecTrafo, radii, centre piece)

    private func vecTrafo(_ pt: SIMD3<Float>) -> SIMD3<Float> {
        VecOp.translatePointOntoFrame(centreBottomFrame, point: pt)
    }

    private func fGetInnerRadius(_ phi: Float, _ lengthRatio: Float) -> Float {
        10 * Uf.superShapeRadius(phi: phi, shape: .round)
    }

    private func fGetOuterRadius(_ phi: Float, _ lengthRatio: Float) -> Float {
        50 * Uf.superShapeRadius(phi: phi, shape: .quad)
    }

    private func addCentrePiece(_ voxOuter: PicoGKVoxels) {
        let box = BaseBox(centreBottomFrame, 100, 20, 2)
        voxOuter.boolAdd(box.voxConstruct())
    }

    // MARK: - Helical Voids

    private func getHelicalVoid(_ fluid: EFluid) -> (volume: PicoGKVoxels, splitters: PicoGKVoxels) {
        let phiStart: Float = (fluid == .cool) ? 0 : Float.pi
        let beam = 0.5 * plateThickness
        let startZ: Float = 0
        let endZ: Float = 100
        let totalLength = endZ - startZ
        let interPlateThickness = wallThickness
        let nTurns = UInt(totalLength / (2 * plateThickness + 2 * interPlateThickness))
        let fTurns = Float(nTurns) - 0.5
        let fSlope = (fTurns * 2 * Float.pi) / totalLength

        let latVoid = PicoGKLattice()
        var vecFirstPt1 = SIMD3<Float>.zero
        var vecFirstPt2 = SIMD3<Float>.zero
        var vecLastPt1 = SIMD3<Float>.zero
        var vecLastPt2 = SIMD3<Float>.zero

        let nSamples = UInt(totalLength / 0.005)
        for i in 0..<Int(nSamples) {
            let ratio = Float(i) / Float(nSamples)
            let z = startZ + ratio * (endZ - startZ)
            let phi = phiStart + fSlope * (z - startZ)
            let innerR = fGetInnerRadius(phi, ratio)
            let outerR = fGetOuterRadius(phi, ratio) - beam
            var pt1 = VecOp.cylindricalPoint(radius: innerR, phi: phi, z: z)
            var pt2 = VecOp.cylindricalPoint(radius: outerR, phi: phi, z: z)
            pt1 = vecTrafo(pt1)
            pt2 = vecTrafo(pt2)
            let pt3 = pt1 + 3 * SIMD3<Float>(0, 0, 1)
            let pt4 = pt2 + 3 * SIMD3<Float>(0, 0, 1)
            latVoid.addBeam(from: pt1, radiusA: beam, to: pt2, radiusB: beam)
            latVoid.addBeam(from: pt1, radiusA: beam, to: pt3, radiusB: 0.2)
            latVoid.addBeam(from: pt2, radiusA: beam, to: pt4, radiusB: 0.2)

            if i == 0 { vecFirstPt1 = pt1; vecFirstPt2 = pt2 }
            if i == Int(nSamples) - 1 { vecLastPt1 = pt1; vecLastPt2 = pt2 }
        }

        let voxHelical = PicoGKVoxels(lattice: latVoid)
        let (voxInlet, voxInletSplitter) = getInlet(fluid, vecFirstPt1, vecFirstPt2, beam)
        let (voxOutlet, voxOutletSplitter) = getOutlet(fluid, vecLastPt1, vecLastPt2, beam)

        let volume = voxInlet + voxOutlet
        volume.boolAdd(voxHelical)
        let splitters = voxInletSplitter + voxOutletSplitter

        return (volume, splitters)
    }

    // MARK: - IO Pipes (Inlet / Outlet)

    private func getInlet(_ fluid: EFluid, _ pt1In: SIMD3<Float>, _ pt2In: SIMD3<Float>,
                          _ beam: Float) -> (voxels: PicoGKVoxels, splitter: PicoGKVoxels) {
        let vecEnd: SIMD3<Float>
        let vecEndDir: SIMD3<Float>
        let lengthDir = VecOp.safeNormalize(pt2In - pt1In)
        var normal: SIMD3<Float>
        var startDir: SIMD3<Float>

        if fluid == .hot {
            vecEnd = firstInletFrame.position
            vecEndDir = SIMD3(-1, 0, 0)
            normal = simd_cross(SIMD3(0, 0, -1), lengthDir)
            startDir = simd_cross(lengthDir, normal)
        } else {
            vecEnd = secondInletFrame.position
            vecEndDir = SIMD3(-1, 0, 0)
            normal = simd_cross(SIMD3(0, 1, 0), lengthDir)
            startDir = simd_cross(lengthDir, normal)
        }

        return buildIOTransition(pt1In, pt2In, beam, vecEnd, vecEndDir,
                                 VecOp.safeNormalize(startDir))
    }

    private func getOutlet(_ fluid: EFluid, _ pt1In: SIMD3<Float>, _ pt2In: SIMD3<Float>,
                           _ beam: Float) -> (voxels: PicoGKVoxels, splitter: PicoGKVoxels) {
        let vecEnd: SIMD3<Float>
        let vecEndDir: SIMD3<Float>
        let lengthDir = VecOp.safeNormalize(pt2In - pt1In)
        var normal: SIMD3<Float>
        var startDir: SIMD3<Float>

        if fluid == .hot {
            vecEnd = firstOutletFrame.position
            vecEndDir = SIMD3(1, 0, 0)
            normal = simd_cross(SIMD3(0, 0, 1), lengthDir)
            startDir = simd_cross(lengthDir, normal)
        } else {
            vecEnd = secondOutletFrame.position
            vecEndDir = SIMD3(1, 0, 0)
            normal = simd_cross(SIMD3(0, 1, 0), lengthDir)
            startDir = simd_cross(lengthDir, normal)
        }

        return buildIOTransition(pt1In, pt2In, beam, vecEnd, vecEndDir,
                                 VecOp.safeNormalize(startDir))
    }

    private func buildIOTransition(
        _ pt1In: SIMD3<Float>, _ pt2In: SIMD3<Float>, _ beam: Float,
        _ vecEnd: SIMD3<Float>, _ vecEndDir: SIMD3<Float>,
        _ vecStartDir: SIMD3<Float>
    ) -> (voxels: PicoGKVoxels, splitter: PicoGKVoxels) {

        let vecStart = 0.5 * (pt1In + pt2In)
        let vecStartOri = VecOp.safeNormalize(pt2In - pt1In)
        let startLength = simd_length(pt2In - vecStart)
        let spline = TangentialControlSpline(
            start: vecStart, end: vecEnd,
            startDir: vecStartDir, endDir: vecEndDir,
            tangentStrength1: 20, tangentStrength2: 10)

        let nSamples: UInt = 500
        let latPipe = PicoGKLattice()
        let latSplitter = PicoGKLattice()
        let unitZ = SIMD3<Float>(0, 0, 1)

        let points = spline.getPoints(nSamples)
        for i in 0..<points.count {
            let ratio = Float(i) / Float(points.count)
            let pt = points[i]
            let localX = vecStartOri
            let beam2 = Uf.transFixed(from: beam, to: ioRadius, ratio: ratio)
            let length2 = Uf.transFixed(from: startLength, to: 0, ratio: ratio)
            let tipExt = Uf.transFixed(from: 3, to: 10, ratio: ratio)

            let p1 = pt - length2 * localX
            let p2 = pt + length2 * localX

            if p1.z > p2.z {
                let p3 = p1 + tipExt * unitZ
                latPipe.addBeam(from: p1, radiusA: beam2, to: p3, radiusB: 0.2)

                let sp0 = p2 - 10 * unitZ
                let sp1 = p3 + beam2 * unitZ
                let sp2 = p3 + (beam2 + 5) * unitZ
                let sp3 = p3 + (beam2 + 10) * unitZ
                let topBeam = Uf.transFixed(from: 0.4, to: 1, ratio: ratio)
                latSplitter.addBeam(from: sp0, radiusA: 0.4, to: sp1, radiusB: 0.4)
                latSplitter.addBeam(from: sp1, radiusA: 0.4, to: sp2, radiusB: topBeam)
                latSplitter.addBeam(from: sp2, radiusA: topBeam, to: sp3, radiusB: topBeam)
            } else {
                let p3 = p2 + tipExt * unitZ
                latPipe.addBeam(from: p2, radiusA: beam2, to: p3, radiusB: 0.2)

                let sp0 = p1 - 10 * unitZ
                let sp1 = p3 + beam2 * unitZ
                let sp2 = p3 + (beam2 + 5) * unitZ
                let sp3 = p3 + (beam2 + 10) * unitZ
                let topBeam = Uf.transFixed(from: 0.4, to: 1, ratio: ratio)
                latSplitter.addBeam(from: sp0, radiusA: 0.4, to: sp1, radiusB: 0.4)
                latSplitter.addBeam(from: sp1, radiusA: 0.4, to: sp2, radiusB: topBeam)
                latSplitter.addBeam(from: sp2, radiusA: topBeam, to: sp3, radiusB: topBeam)
            }
            latPipe.addBeam(from: p1, radiusA: beam2, to: p2, radiusB: beam2)
        }

        let voxPipe = PicoGKVoxels(lattice: latPipe)
        var voxSplitter = PicoGKVoxels(lattice: latSplitter)
        voxSplitter.boolIntersect(voxPipe)
        return (voxPipe, voxSplitter)
    }

    // MARK: - Internal Fins (Turning)

    private func voxGetTurningFins(_ fluid: EFluid) -> PicoGKVoxels {
        let phiStart: Float = (fluid == .cool) ? 0 : Float.pi
        let fWallThickness: Float = 0.4
        let fBeam = 0.5 * fWallThickness
        let startZ: Float = 0
        let endZ: Float = 100
        let totalLength = endZ - startZ
        let interPlate: Float = 0.8
        let nTurns = UInt(totalLength / (2 * plateThickness + 2 * interPlate))
        let fTurns = Float(nTurns) - 0.5
        let fSlope = (fTurns * 2 * Float.pi) / totalLength

        let latFins = PicoGKLattice()
        let nSamples = UInt(totalLength / 0.005)
        let unitZ = SIMD3<Float>(0, 0, 1)

        for i in 0..<Int(nSamples) {
            let ratio = Float(i) / Float(nSamples)
            let z = startZ + ratio * totalLength
            let phi = phiStart + fSlope * (z - startZ)
            var phiDeg = phi / Float.pi * 180
            phiDeg = phiDeg.truncatingRemainder(dividingBy: 360)

            let dAngle: Float = 20
            let isCorner = (phiDeg > 45 - dAngle && phiDeg < 45 + dAngle) ||
                           (phiDeg > 135 - dAngle && phiDeg < 135 + dAngle) ||
                           (phiDeg > 225 - dAngle && phiDeg < 225 + dAngle) ||
                           (phiDeg > 315 - dAngle && phiDeg < 315 + dAngle)

            if isCorner {
                let nFins = 20
                for j in 0..<nFins {
                    let phiFin = phi - 15 / 180 * Float.pi * cos(3 * (Float(j) / Float(nFins) - 0.5))
                    let innerR = fGetInnerRadius(phiFin, ratio)
                    let outerR = fGetOuterRadius(phiFin, ratio) - fBeam
                    let r = innerR + 5 + Float(j) / Float(nFins - 1) * (outerR - 10 - innerR)
                    var p1 = VecOp.cylindricalPoint(radius: r, phi: phiFin, z: z - 0.5 * plateThickness)
                    var p2 = VecOp.cylindricalPoint(radius: r, phi: phiFin, z: z + 0.5 * plateThickness)
                    p1 = vecTrafo(p1); p2 = vecTrafo(p2)
                    p1.z -= 1.5; p2.z -= 1.5
                    let p3 = 0.5 * (p1 + p2)
                    let p4 = p3 + 3 * unitZ
                    latFins.addBeam(from: p1, radiusA: fBeam, to: p4, radiusB: fBeam)
                    latFins.addBeam(from: p2, radiusA: fBeam, to: p4, radiusB: fBeam)
                }
            }
        }
        return PicoGKVoxels(lattice: latFins)
    }

    // MARK: - Internal Fins (Straight)

    private func voxGetStraightFins(_ fluid: EFluid) -> PicoGKVoxels {
        let phiStart: Float = (fluid == .cool) ? 0 : Float.pi
        let fWallThickness: Float = 0.4
        let fBeam = 0.5 * fWallThickness
        let startZ: Float = 0
        let endZ: Float = 100
        let totalLength = endZ - startZ
        let interPlate: Float = 0.8
        let nTurns = UInt(totalLength / (2 * plateThickness + 2 * interPlate))
        let fTurns = Float(nTurns) - 0.5
        let fSlope = (fTurns * 2 * Float.pi) / totalLength

        let latFins = PicoGKLattice()
        let nSamples = UInt(totalLength / 0.005)
        let unitZ = SIMD3<Float>(0, 0, 1)

        for i in 0..<Int(nSamples) {
            let ratio = Float(i) / Float(nSamples)
            let z = startZ + ratio * totalLength
            let phi = phiStart + fSlope * (z - startZ)
            var phiDeg = phi / Float.pi * 180
            phiDeg = phiDeg.truncatingRemainder(dividingBy: 360)

            let dAngle: Float = 15

            let isStraight = (phiDeg > 0 - dAngle && phiDeg < 0 + dAngle) ||
                             (phiDeg > 360 - dAngle && phiDeg < 360 + dAngle) ||
                             (phiDeg > 180 - dAngle && phiDeg < 180 + dAngle)

            let is90 = phiDeg > 90 - dAngle && phiDeg < 90 + dAngle
            let is270 = phiDeg > 270 - dAngle && phiDeg < 270 + dAngle

            if isStraight || is90 || is270 {
                let nFins = 8
                for j in 0..<nFins {
                    let phiFin = phi - 15 / 180 * Float.pi * cos(3 * (Float(j) / Float(nFins) - 0.5))
                    let innerR = fGetInnerRadius(phiFin, ratio)
                    let outerR = fGetOuterRadius(phiFin, ratio) - fBeam
                    let r = innerR + 5 + Float(j) / Float(nFins - 1) * (outerR - 10 - innerR)
                    var p1 = VecOp.cylindricalPoint(radius: r, phi: phiFin, z: z - 0.5 * plateThickness)
                    var p2 = VecOp.cylindricalPoint(radius: r, phi: phiFin, z: z + 0.5 * plateThickness)
                    p1 = vecTrafo(p1); p2 = vecTrafo(p2)
                    p1.z -= 1.5; p2.z -= 1.5

                    let p3 = 0.5 * (p1 + p2)

                    if is90 || is270 {
                        let dTurnPhi = (phiDeg - 270 + dAngle) / (2 * dAngle) * 2 * Float.pi
                        let rp1 = VecOp.rotateAroundZ(point: p1, angle: dTurnPhi, origin: p3)
                        let rp2 = VecOp.rotateAroundZ(point: p2, angle: dTurnPhi, origin: p3)
                        let p4 = p3 + 3 * unitZ
                        latFins.addBeam(from: rp1, radiusA: fBeam, to: p4, radiusB: fBeam)
                        latFins.addBeam(from: rp2, radiusA: fBeam, to: p4, radiusB: fBeam)
                    } else {
                        let p4 = p3 + 3 * unitZ
                        latFins.addBeam(from: p1, radiusA: fBeam, to: p4, radiusB: fBeam)
                        latFins.addBeam(from: p2, radiusA: fBeam, to: p4, radiusB: fBeam)
                    }
                }
            }
        }
        return PicoGKVoxels(lattice: latFins)
    }

    // MARK: - Outer Structure

    private func voxGetOuterStructure() -> PicoGKVoxels {
        let totalLength: Float = 100
        let fBeam: Float = 1
        let lat = PicoGKLattice()
        let sidePhis: [Float] = [0, 0.5 * Float.pi, Float.pi, 1.5 * Float.pi]

        var z: Float = 0
        while z < totalLength {
            for sidePhi in sidePhis {
                for sign: Float in [1, -1] {
                    let ratio = z / totalLength
                    let phi = sidePhi + sign * 0.25 * Float.pi * cos(2 * 2 * Float.pi / totalLength * z)
                    let innerR = fGetOuterRadius(phi, ratio) - 15
                    let outerR = fGetOuterRadius(phi, ratio) + 15
                    var p1 = VecOp.cylindricalPoint(radius: innerR, phi: phi, z: z)
                    var p2 = VecOp.cylindricalPoint(radius: outerR, phi: phi, z: z)
                    p1 = vecTrafo(p1); p2 = vecTrafo(p2)
                    lat.addBeam(from: p1, radiusA: fBeam, to: p2, radiusB: fBeam)
                }
            }
            z += 0.3
        }

        let voxStructure = PicoGKVoxels(lattice: lat)
        voxStructure.overOffset(5, 0.5)
        voxStructure.smoothen(1)
        voxStructure.boolIntersect(voxBounding)
        return voxStructure
    }

    // MARK: - Flange

    private func getFlange() -> (flange: PicoGKVoxels, screwHoles: PicoGKVoxels, cutters: PicoGKVoxels) {
        let coreRadius: Float = 5
        let maxRadius: Float = 6
        let cutLength: Float = 24
        let screwThreadRadius: Float = 3.5
        let screwThreadLength: Float = 2
        let screwHeadRadius: Float = 7
        let screwHeadLength: Float = 10

        let xValues: [Float] = [-60, 60]
        let yValues: [Float] = [-38, 0, 38]
        let unitZ = SIMD3<Float>(0, 0, 1)

        var flangeList = [PicoGKVoxels]()
        var cutterList = [PicoGKVoxels]()
        var screwList = [PicoGKVoxels]()

        for x in xValues {
            for y in yValues {
                let pt = SIMD3<Float>(x, y, 0)

                let screw = ScrewHole(
                    LocalFrame(position: pt + 6 * unitZ),
                    screwThreadLength, screwThreadRadius,
                    screwHeadLength, screwHeadRadius)
                screwList.append(screw.voxConstruct())

                let cyl = BaseCylinder(frame: LocalFrame(position: pt), length: 8, radius: screwHeadRadius + 5)
                flangeList.append(cyl.voxConstruct())

                let cutter = ThreadCutter(
                    LocalFrame(position: pt - 10 * unitZ),
                    cutLength, maxRadius, coreRadius, 1.3)
                cutterList.append(cutter.voxConstruct())
            }
        }

        return (PicoGKVoxels.combine(flangeList),
                PicoGKVoxels.combine(screwList),
                PicoGKVoxels.combine(cutterList))
    }

    // MARK: - IO Supports

    private func voxGetIOSupports() -> PicoGKVoxels {
        let minBeam: Float = 1
        let lat = PicoGKLattice()
        let frames = [firstInletFrame, firstOutletFrame, secondInletFrame, secondOutletFrame]
        let unitX = SIMD3<Float>(1, 0, 0)
        let unitY = SIMD3<Float>(0, 1, 0)
        let unitZ = SIMD3<Float>(0, 0, -1)

        for frame in frames {
            var backAngle1: Float = -50 / 180 * Float.pi
            if frame.position.x > 0 { backAngle1 = -backAngle1 }

            var backAngle2: Float = -20 / 180 * Float.pi
            if frame.position.x > 0 { backAngle2 = -backAngle2 }

            var inwardAngle: Float = 15 / 180 * Float.pi
            if frame.position.y > 0 { inwardAngle = -inwardAngle }

            var dir1 = VecOp.rotateAroundAxis(point: unitZ, angle: backAngle1,
                                               axis: SIMD3(0, 1, 0))
            dir1 = VecOp.rotateAroundAxis(point: dir1, angle: inwardAngle,
                                            axis: unitX)

            var dir2 = VecOp.rotateAroundAxis(point: unitZ, angle: backAngle2,
                                               axis: SIMD3(0, 1, 0))
            dir2 = VecOp.rotateAroundAxis(point: dir2, angle: inwardAngle,
                                            axis: unitX)

            for dSi in 0..<30 {
                let dS = Float(dSi)
                let lr = dS / 30
                let maxBeam = Uf.transFixed(from: ioRadius + 6, to: ioRadius + 2, ratio: lr)
                let dH = (maxBeam - minBeam) / tan(30 / 180 * Float.pi)

                let pt1 = frame.position + (10 - dS) * frame.localZ
                let kink = pt1 + dH * dir2
                let pt2 = kink - (kink.z / dir1.z) * dir1

                lat.addBeam(from: pt1, radiusA: maxBeam, to: kink, radiusB: minBeam)
                lat.addBeam(from: kink, radiusA: minBeam, to: pt2, radiusB: minBeam)
            }
        }
        return PicoGKVoxels(lattice: lat)
    }

    // MARK: - IO Cuts

    private func voxGetIOCuts() -> PicoGKVoxels {
        var list = [PicoGKVoxels]()
        let cutRadius: Float = 2.5
        let cutLength: Float = 12

        let cut1 = LatticeManifold(firstInletFrame, cutLength, cutRadius)
        let cut2 = LatticeManifold(secondInletFrame, cutLength, cutRadius)
        let cut3 = LatticeManifold(firstOutletFrame, cutLength, cutRadius)
        let cut4 = LatticeManifold(secondOutletFrame, cutLength, cutRadius)
        list.append(cut1.voxConstruct())
        list.append(cut2.voxConstruct())
        list.append(cut3.voxConstruct())
        list.append(cut4.voxConstruct())

        let f1 = LocalFrame.oGetTranslatedFrame(firstInletFrame,
                                                  (cutLength + 2) * firstInletFrame.localZ)
        let f2 = LocalFrame.oGetTranslatedFrame(secondInletFrame,
                                                  (cutLength + 2) * secondInletFrame.localZ)
        let f3 = LocalFrame.oGetTranslatedFrame(firstOutletFrame,
                                                  (cutLength + 2) * firstOutletFrame.localZ)
        let f4 = LocalFrame.oGetTranslatedFrame(secondOutletFrame,
                                                  (cutLength + 2) * secondOutletFrame.localZ)

        for f in [f1, f2, f3, f4] {
            let from = f.position
            let to = from - 4 * f.localZ
            list.append(PicoGKVoxels(lattice:
                Sh.latFromBeam(from, to, 7, 2, false)))
        }

        return PicoGKVoxels.combine(list)
    }

    // MARK: - IO Threads

    private func voxGetIOThreads() -> PicoGKVoxels {
        var list = [PicoGKVoxels]()
        let outerR: Float = 14
        let length: Float = 12
        let shift = SIMD3<Float>(0, 0, 1)

        var f1 = LocalFrame.oGetTranslatedFrame(firstInletFrame, shift)
        var f2 = LocalFrame.oGetTranslatedFrame(secondInletFrame, shift)
        var f3 = LocalFrame.oGetTranslatedFrame(firstOutletFrame, shift)
        var f4 = LocalFrame.oGetTranslatedFrame(secondOutletFrame, shift)

        f1 = LocalFrame.oGetInvertFrame(f1, true, false)
        f2 = LocalFrame.oGetInvertFrame(f2, true, false)
        f3 = LocalFrame.oGetInvertFrame(f3, true, false)
        f4 = LocalFrame.oGetInvertFrame(f4, true, false)

        f1 = LocalFrame.oGetTranslatedFrame(f1, -length * f1.localZ)
        f2 = LocalFrame.oGetTranslatedFrame(f2, -length * f2.localZ)
        f3 = LocalFrame.oGetTranslatedFrame(f3, -length * f3.localZ)
        f4 = LocalFrame.oGetTranslatedFrame(f4, -length * f4.localZ)

        list.append(ThreadReinforcement(f1, length, ioRadius, outerR).voxConstruct())
        list.append(ThreadReinforcement(f2, length, ioRadius, outerR).voxConstruct())
        list.append(ThreadReinforcement(f3, length, ioRadius, outerR).voxConstruct())
        list.append(ThreadReinforcement(f4, length, ioRadius, outerR).voxConstruct())

        return PicoGKVoxels.combine(list)
    }

    // MARK: - Print Web

    private func voxGetPrintWeb() -> PicoGKVoxels {
        let z: Float = -4
        let fBeam: Float = 0.8
        let dX: Float = 10
        let fY: Float = 70
        let lat = PicoGKLattice()

        var x: Float = 0
        while x <= 60 {
            lat.addBeam(from: SIMD3(x, -fY, z), radiusA: fBeam,
                       to: SIMD3(x, fY, z), radiusB: fBeam)
            lat.addBeam(from: SIMD3(-x, -fY, z), radiusA: fBeam,
                       to: SIMD3(-x, fY, z), radiusB: fBeam)
            x += dX
        }

        return PicoGKVoxels(lattice: lat)
    }
}
