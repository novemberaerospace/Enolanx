// RenderGroup.swift
// Genolanx — Render group for scene organization (mirrors PicoGK Viewer group system)

import simd
import PicoGKBridge

struct PBRMaterial {
    var baseColor: SIMD4<Float>
    var metallic: Float
    var roughness: Float

    init(color: PKColorFloat = PKColorFloat(r: 0.8, g: 0.8, b: 0.8, a: 1.0),
         metallic: Float = 0.4,
         roughness: Float = 0.7) {
        self.baseColor = SIMD4(color.r, color.g, color.b, color.a)
        self.metallic = metallic
        self.roughness = roughness
    }
}

final class RenderGroup {
    var meshBuffers: [MeshBuffer] = []
    var polyLineBuffers: [PolyLineBuffer] = []
    var material = PBRMaterial()
    var isVisible = true
    var isStatic = false
    var transform = matrix_identity_float4x4

    var boundingBox: BBox3 {
        var bbox = BBox3()
        for mb in meshBuffers {
            bbox.include(mb.boundingBox)
        }
        return bbox
    }
}
