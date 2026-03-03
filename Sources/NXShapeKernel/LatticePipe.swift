// LatticePipe.swift
// Genolanx — Port of LEAP71 ShapeKernel LatticePipe
// SPDX-License-Identifier: Apache-2.0

import Foundation
import simd

final class LatticePipe: BaseShape {

    private var frames: Frames
    private var radiusModulation: LineModulation
    private var lengthSteps: UInt32 = 200

    init(frame: LocalFrame, length: Float = 60, radius: Float = 10) {
        self.frames = Frames(length: length, frame: frame)
        self.radiusModulation = LineModulation(constant: radius)
    }

    init(frames: Frames, radius: Float = 5) {
        self.frames = frames
        self.radiusModulation = LineModulation(constant: radius)
    }

    func setRadius(_ mod: LineModulation) {
        radiusModulation = mod
    }

    func setLengthSteps(_ n: UInt32) { lengthSteps = n }

    override func constructVoxels() -> PicoGKVoxels {
        let lat = PicoGKLattice()
        let n = Int(lengthSteps)

        for i in 0..<n {
            let lr0 = Float(i) / Float(n)
            let lr1 = Float(i + 1) / Float(n)
            let pt0 = frames.spineAlongLength(lr0)
            let pt1 = frames.spineAlongLength(lr1)
            let r0 = radiusModulation.value(at: lr0)
            let r1 = radiusModulation.value(at: lr1)
            lat.addBeam(from: pt0, radiusA: r0, to: pt1, radiusB: r1)
        }

        return PicoGKVoxels(lattice: lat)
    }
}
