// SpiralInductor.swift
// Genolanx — Parametric inductor: serpentine in sector
//
// Serpentine inductor in a sector: nested U-shapes with LEFT radial,
// connected on the RIGHT side between consecutive levels.
//
// Parameters: outerRadius, innerRadius, nPhases, wireDiameter.
//
// SPDX-License-Identifier: Apache-2.0

import Foundation
import simd
import PicoGKBridge

// MARK: - Task Entry Point

enum SpiralInductorTask {

    static func run(sceneManager: SceneManager,
                    outerRadius: Float = 100,
                    innerRadius: Float = 30,
                    nPhases: Int = 3,
                    wireDiameter: Float = 3.0,
                    wireHeight: Float = 2.0,
                    gapFactor: Float = 1.0,
                    pivotAngleDeg: Float = 15) {
        let inductor = SectorInductor(
            outerRadius: outerRadius,
            innerRadius: innerRadius,
            nPhases: nPhases,
            wireDiameter: wireDiameter,
            wireHeight: wireHeight,
            gapFactor: gapFactor
        )
        inductor.build(sceneManager: sceneManager)
    }
}

// MARK: - SectorInductor

final class SectorInductor {

    let outerRadius: Float
    let innerRadius: Float
    let nPhases: Int
    let wireDiameter: Float
    let wireHeight: Float
    let gapFactor: Float

    var beamRadius: Float { wireDiameter / 2 }
    var pitch: Float { wireDiameter * (1 + gapFactor) }
    var sectorAngle: Float { 2 * Float.pi / Float(nPhases) }

    init(outerRadius: Float, innerRadius: Float, nPhases: Int,
         wireDiameter: Float, wireHeight: Float, gapFactor: Float) {
        self.outerRadius = outerRadius
        self.innerRadius = max(wireDiameter * 2, innerRadius)
        self.nPhases = max(1, nPhases)
        self.wireDiameter = max(0.5, wireDiameter)
        self.wireHeight = wireHeight
        self.gapFactor = max(0.2, gapFactor)
    }

    // MARK: - Build

    func build(sceneManager: SceneManager) {
        sceneManager.log("Sector base — outerR=\(outerRadius) innerR=\(innerRadius) phases=\(nPhases)")
        sceneManager.log("  pitch=\(String(format: "%.2f", pitch)) mm, 4 nested levels")

        let lat = PicoGKLattice()
        let z: Float = 0
        let br = beamRadius

        // Base sector starting at angle 0.
        let aLeft: Float = 0
        let aRight: Float = sectorAngle

        // Serpentine: each level is an open-U with LEFT radial.
        // Levels connected on the RIGHT side: inner[i] → outer[i+1].
        //
        // Path: outerArc(R→L) → leftRadial(outer→inner) → innerArc(L→R)
        //       → connector(inner R → outer R next) → repeat
        let nLevels = 4

        for i in 0..<nLevels {
            let offset = Float(i) * pitch

            let rOuter = outerRadius - offset
            let rInner = innerRadius + offset

            if rInner >= rOuter { break }

            let angOffsetOuter = (offset > 0) ? asin(min(offset / rOuter, 0.99)) : Float(0)
            let angOffsetInner = (offset > 0) ? asin(min(offset / rInner, 0.99)) : Float(0)

            let leftOuter  = aLeft  + angOffsetOuter
            let rightOuter = aRight - angOffsetOuter
            let leftInner  = aLeft  + angOffsetInner
            let rightInner = aRight - angOffsetInner

            if leftOuter >= rightOuter { break }

            // --- Outer arc (full, right → left) ---
            addArc(lat, radius: rOuter, from: rightOuter, to: leftOuter, br: br, z: z)

            // --- Left radial (outer → inner) ---
            let topLeft = VecOp.cylindricalPoint(radius: rOuter, phi: leftOuter, z: z)
            let botLeft = VecOp.cylindricalPoint(radius: rInner, phi: leftInner, z: z)
            lat.addBeam(from: topLeft, radiusA: br, to: botLeft, radiusB: br)

            // --- Inner arc (full, left → right) ---
            addArc(lat, radius: rInner, from: leftInner, to: rightInner, br: br, z: z)
        }

        // --- Right-side connectors: inner[i] → outer[i+1] (points 4→5, 8→9, ...) ---
        for i in 0..<(nLevels - 1) {
            let offsetA = Float(i) * pitch
            let offsetB = Float(i + 1) * pitch

            let rInnerA = innerRadius + offsetA
            let rOuterB = outerRadius - offsetB

            if rInnerA >= rOuterB { break }

            let angOffA = (offsetA > 0) ? asin(min(offsetA / rInnerA, 0.99)) : Float(0)
            let angOffB = (offsetB > 0) ? asin(min(offsetB / rOuterB, 0.99)) : Float(0)

            let rightInnerA = aRight - angOffA
            let rightOuterB = aRight - angOffB

            let pt4 = VecOp.cylindricalPoint(radius: rInnerA, phi: rightInnerA, z: z)
            let pt5 = VecOp.cylindricalPoint(radius: rOuterB, phi: rightOuterB, z: z)
            lat.addBeam(from: pt4, radiusA: br, to: pt5, radiusB: br)
        }

        sceneManager.log("Voxelizing...")
        let vox = PicoGKVoxels(lattice: lat)
        vox.smoothen(0.15)

        let sm = sceneManager
        DispatchQueue.main.async {
            sm.removeAllObjects()
            sm.addVoxels(vox, groupID: 0, name: "SpiralInductor")
            sm.setGroupMaterial(0, color: Cp.clrCopper, metallic: 0.8, roughness: 0.25)
        }

        sceneManager.log("Exporting STL...")
        let path = NSHomeDirectory() + "/Documents/SpiralInductor.stl"
        sceneManager.exportSTL(voxels: vox, to: path)
        sceneManager.log("Done!")
    }

    // MARK: - Geometry Helpers

    private func addArc(_ lat: PicoGKLattice, radius: Float,
                         from a0: Float, to a1: Float,
                         br: Float, z: Float, steps: Int = 40) {
        for j in 0..<steps {
            let t0 = Float(j) / Float(steps)
            let t1 = Float(j + 1) / Float(steps)
            let phi0 = a0 + t0 * (a1 - a0)
            let phi1 = a0 + t1 * (a1 - a0)
            let p0 = VecOp.cylindricalPoint(radius: radius, phi: phi0, z: z)
            let p1 = VecOp.cylindricalPoint(radius: radius, phi: phi1, z: z)
            lat.addBeam(from: p0, radiusA: br, to: p1, radiusB: br)
        }
    }
}
