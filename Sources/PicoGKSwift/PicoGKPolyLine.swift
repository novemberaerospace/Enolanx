// PicoGKPolyLine.swift
// Genolanx — Swift wrapper for PicoGK PolyLine

import simd
import PicoGKBridge

final class PicoGKPolyLine: @unchecked Sendable {
    let handle: PKHandle

    init(color: PKColorFloat) {
        var clr = color
        handle = PolyLine_hCreate(&clr)
        assert(handle != nil)
        assert(PolyLine_bIsValid(handle))
    }

    deinit {
        PolyLine_Destroy(handle)
    }

    // MARK: - Vertices

    @discardableResult
    func addVertex(_ v: SIMD3<Float>) -> Int32 {
        var pv = PKVector3(v)
        return PolyLine_nAddVertex(handle, &pv)
    }

    func addVertices(_ vertices: [SIMD3<Float>]) {
        for v in vertices {
            addVertex(v)
        }
    }

    var vertexCount: Int32 {
        PolyLine_nVertexCount(handle)
    }

    func vertex(at index: Int32) -> SIMD3<Float> {
        var v = PKVector3.zero
        PolyLine_GetVertex(handle, index, &v)
        return v.simd
    }

    // MARK: - Color

    var color: PKColorFloat {
        var clr = PKColorFloat(r: 0, g: 0, b: 0, a: 1)
        PolyLine_GetColor(handle, &clr)
        return clr
    }
}
