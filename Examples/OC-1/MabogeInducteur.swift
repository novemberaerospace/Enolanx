// MabogeInducteur.swift
// Genolanx — Port of LEAP71 MabogeInducteur (Chartres labyrinth copper inductor)

import Foundation
import simd
import PicoGKBridge

enum MabogeInducteurTask {

    static func run(sceneManager: SceneManager) {
        let inductor = MabogeInducteur()
        inductor.build(sceneManager: sceneManager)
    }
}

final class MabogeInducteur {

    // MARK: - Parameters

    let outerDiam: Float = 240
    let innerDiam: Float = 100.75
    let nPhases: UInt = 6
    let nLevels: UInt = 6

    let traceWidth: Float = 3
    let traceHeight: Float = 2
    let levelSpacing: Float = 5

    let pinHeight: Float = 8
    let pinRadius: Float = 2
    let guideOffsetRad: Float = 0.04

    var outerRadius: Float { outerDiam / 2 }
    var innerRadius: Float { innerDiam / 2 }
    var sectorAngleRad: Float { 2 * Float.pi / Float(nPhases) }

    // MARK: - Build

    func build(sceneManager: SceneManager) {
        sceneManager.log("Building Maboge Inducteur — single sector, \(nLevels) levels...")

        let voxAll = buildSector(sectorStartAngle: 0, z: 0)
        voxAll.smoothen(0.2)

        DispatchQueue.main.async {
            sceneManager.removeAllObjects()
            sceneManager.addVoxels(voxAll, groupID: 0, name: "MabogeInducteur")
            sceneManager.setGroupMaterial(0, color: Cp.clrWarning, metallic: 0.6, roughness: 0.3)
        }

        sceneManager.log("Exporting STL...")
        let path = NSHomeDirectory() + "/Documents/MabogeInducteur.stl"
        sceneManager.exportSTL(voxels: voxAll, to: path)
        sceneManager.log("Done!")
    }

    // MARK: - Sector Builder

    func buildSector(sectorStartAngle: Float, z: Float) -> PicoGKVoxels {
        let lat = PicoGKLattice()
        let halfTrace = traceWidth / 2

        let baseLeftAngle = sectorStartAngle
        let baseRightAngle = sectorStartAngle + sectorAngleRad
        let centerLine = sectorStartAngle + sectorAngleRad / 2

        let linearSpacing = levelSpacing
        let guideLeftAngle = centerLine - guideOffsetRad
        let guideRightAngle = centerLine + guideOffsetRad

        // Nested closed-contour circuits with parallel edges
        for iLevel in 0..<Int(nLevels) {
            let offset = Float(iLevel) * linearSpacing

            let fOuterR = outerRadius - offset
            let fInnerR = innerRadius + offset

            if fInnerR >= fOuterR { break }

            let leftOffsetOuter = asin(min(offset / fOuterR, 1))
            let rightOffsetOuter = leftOffsetOuter
            let leftOffsetInner = asin(min(offset / fInnerR, 1))
            let rightOffsetInner = leftOffsetInner

            let leftAngleOuter = baseLeftAngle + leftOffsetOuter
            let rightAngleOuter = baseRightAngle - rightOffsetOuter
            let leftAngleInner = baseLeftAngle + leftOffsetInner
            let rightAngleInner = baseRightAngle - rightOffsetInner

            if leftAngleOuter >= rightAngleOuter { break }

            // 1. Outer arc — split at guides
            addArc(lat, radius: fOuterR, from: leftAngleOuter, to: guideLeftAngle,
                   beamRadius: halfTrace, z: z)
            addArc(lat, radius: fOuterR, from: guideRightAngle, to: rightAngleOuter,
                   beamRadius: halfTrace, z: z)

            // 2. Right radial edge
            addParallelEdge(lat, r1: fOuterR, a1: rightAngleOuter,
                            r2: fInnerR, a2: rightAngleInner, beamRadius: halfTrace, z: z)

            // 3. Inner arc — split at guides (reverse)
            addArc(lat, radius: fInnerR, from: rightAngleInner, to: guideRightAngle,
                   beamRadius: halfTrace, z: z)
            addArc(lat, radius: fInnerR, from: guideLeftAngle, to: leftAngleInner,
                   beamRadius: halfTrace, z: z)

            // 4. Left radial edge
            addParallelEdge(lat, r1: fInnerR, a1: leftAngleInner,
                            r2: fOuterR, a2: leftAngleOuter, beamRadius: halfTrace, z: z)
        }

        // Guide segments (top — staircase pattern)
        let nActualLevels = Int(nLevels)
        for iLevel in 0..<(nActualLevels - 1) {
            let rThis = outerRadius - Float(iLevel) * levelSpacing
            let rNext = outerRadius - Float(iLevel + 1) * levelSpacing
            let isEven = (iLevel % 2 == 0)

            if !isEven {
                // ODD: draw guide segment
                addRadialSegment(lat, r1: rThis, r2: rNext,
                                 angle: guideLeftAngle, beamRadius: halfTrace, z: z)
                addRadialSegment(lat, r1: rThis, r2: rNext,
                                 angle: guideRightAngle, beamRadius: halfTrace, z: z)
            }
        }

        // Bottom inner guides — inverse pattern
        for iLevel in 0..<(nActualLevels - 1) {
            let rThis = innerRadius + Float(iLevel) * levelSpacing
            let rNext = innerRadius + Float(iLevel + 1) * levelSpacing
            let isEven = (iLevel % 2 == 0)

            if isEven {
                addRadialSegment(lat, r1: rThis, r2: rNext,
                                 angle: guideLeftAngle, beamRadius: halfTrace, z: z)
                addRadialSegment(lat, r1: rThis, r2: rNext,
                                 angle: guideRightAngle, beamRadius: halfTrace, z: z)
            }
        }

        // Jonction at innermost level
        let jonctionR = outerRadius - Float(nActualLevels - 1) * levelSpacing
        addArc(lat, radius: jonctionR, from: guideLeftAngle, to: guideRightAngle,
               beamRadius: halfTrace, z: z, steps: 10)

        // Terminal pins
        let pin1Base = VecOp.cylindricalPoint(radius: outerRadius, phi: guideLeftAngle, z: z)
        let pin1Top = VecOp.cylindricalPoint(radius: outerRadius, phi: guideLeftAngle, z: z + pinHeight)
        lat.addBeam(from: pin1Base, radiusA: pinRadius, to: pin1Top, radiusB: pinRadius)

        let pin2Base = VecOp.cylindricalPoint(radius: outerRadius, phi: guideRightAngle, z: z)
        let pin2Top = VecOp.cylindricalPoint(radius: outerRadius, phi: guideRightAngle, z: z + pinHeight)
        lat.addBeam(from: pin2Base, radiusA: pinRadius, to: pin2Top, radiusB: pinRadius)

        return PicoGKVoxels(lattice: lat)
    }

    // MARK: - Geometry Helpers

    private func addArc(_ lat: PicoGKLattice, radius: Float,
                         from startAngle: Float, to endAngle: Float,
                         beamRadius: Float, z: Float, steps: Int = 40) {
        for j in 0..<steps {
            let t0 = Float(j) / Float(steps)
            let t1 = Float(j + 1) / Float(steps)
            let phi0 = startAngle + t0 * (endAngle - startAngle)
            let phi1 = startAngle + t1 * (endAngle - startAngle)
            let a = VecOp.cylindricalPoint(radius: radius, phi: phi0, z: z)
            let b = VecOp.cylindricalPoint(radius: radius, phi: phi1, z: z)
            lat.addBeam(from: a, radiusA: beamRadius, to: b, radiusB: beamRadius)
        }
    }

    private func addRadialSegment(_ lat: PicoGKLattice, r1: Float, r2: Float,
                                   angle: Float, beamRadius: Float, z: Float) {
        let from = VecOp.cylindricalPoint(radius: r1, phi: angle, z: z)
        let to = VecOp.cylindricalPoint(radius: r2, phi: angle, z: z)
        lat.addBeam(from: from, radiusA: beamRadius, to: to, radiusB: beamRadius)
    }

    private func addParallelEdge(_ lat: PicoGKLattice, r1: Float, a1: Float,
                                  r2: Float, a2: Float, beamRadius: Float, z: Float) {
        let from = VecOp.cylindricalPoint(radius: r1, phi: a1, z: z)
        let to = VecOp.cylindricalPoint(radius: r2, phi: a2, z: z)
        lat.addBeam(from: from, radiusA: beamRadius, to: to, radiusB: beamRadius)
    }
}
