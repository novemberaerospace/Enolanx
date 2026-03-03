// BaseCone.swift
// Genolanx — Parametric cone (port of LEAP71 ShapeKernel BaseCone.cs)
// Uses composition: internally wraps a BaseCylinder with linear radius modulation.

import simd

final class BaseCone: BaseShape {
    private let cylinder: BaseCylinder
    private let startRadius: Float
    private let endRadius: Float

    /// Create a cone from startRadius at bottom to endRadius at top.
    init(frame: LocalFrame, length: Float, startRadius: Float, endRadius: Float) {
        self.startRadius = startRadius
        self.endRadius = endRadius
        cylinder = BaseCylinder(frame: frame, length: length)
        super.init()

        // Set linear radius modulation
        cylinder.setRadius(SurfaceModulation { [startRadius, endRadius] _, lengthRatio in
            let t = max(0, min(1, lengthRatio))
            return startRadius + t * (endRadius - startRadius)
        })
    }

    override func constructVoxels() -> PicoGKVoxels {
        cylinder.transformation = transformation
        return cylinder.constructVoxels()
    }

    override func constructMesh() -> PicoGKMesh {
        cylinder.transformation = transformation
        return cylinder.constructMesh()
    }
}
