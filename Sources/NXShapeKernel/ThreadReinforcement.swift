// ThreadReinforcement.swift
// Genolanx — Port of LEAP71 ConstructionModules ThreadReinforcement

import simd
import PicoGKBridge

/// Thread reinforcement: adds material where screw holes will be drilled.
/// Pipe shape with tapered outer radius near the end.
class ThreadReinforcement {
    let frame: LocalFrame
    let length: Float
    let innerRadius: Float
    let outerRadius: Float

    init(_ frame: LocalFrame, _ length: Float, _ innerRadius: Float, _ outerRadius: Float) {
        self.frame = frame
        self.length = length
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
    }

    func voxConstruct() -> PicoGKVoxels {
        let pipe = BasePipe(frame: frame, length: length,
                           innerRadius: innerRadius, outerRadius: outerRadius)
        let innerR = innerRadius
        let outerR = outerRadius

        pipe.setRadius(
            inner: SurfaceModulation { [innerR] _, _ in innerR },
            outer: SurfaceModulation { [outerR, innerR] _, lengthRatio in
                var r = outerR
                if lengthRatio > 0.75 {
                    r = outerR - (outerR - innerR + 1.0) * (lengthRatio - 0.75)
                }
                return r
            }
        )
        return pipe.voxConstruct()
    }
}
