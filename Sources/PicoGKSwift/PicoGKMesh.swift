// PicoGKMesh.swift
// Genolanx — Swift wrapper for PicoGK Mesh

import simd
import PicoGKBridge

final class PicoGKMesh: @unchecked Sendable {
    let handle: PKHandle

    init() {
        handle = Mesh_hCreate()
        assert(handle != nil, "Mesh_hCreate returned nil")
        assert(Mesh_bIsValid(handle), "Mesh handle is not valid")
    }

    init(fromVoxels voxels: PicoGKVoxels) {
        handle = Mesh_hCreateFromVoxels(voxels.handle)
        assert(handle != nil, "Mesh_hCreateFromVoxels returned nil")
    }

    /// Internal init from raw handle (takes ownership).
    init(handle: PKHandle) {
        self.handle = handle
        assert(handle != nil)
    }

    deinit {
        Mesh_Destroy(handle)
    }

    // MARK: - Vertices

    @discardableResult
    func addVertex(_ v: SIMD3<Float>) -> Int32 {
        var pv = PKVector3(v)
        return Mesh_nAddVertex(handle, &pv)
    }

    var vertexCount: Int32 {
        Mesh_nVertexCount(handle)
    }

    func vertex(at index: Int32) -> SIMD3<Float> {
        var v = PKVector3.zero
        Mesh_GetVertex(handle, index, &v)
        return v.simd
    }

    // MARK: - Triangles

    @discardableResult
    func addTriangle(_ tri: PKTriangle) -> Int32 {
        var t = tri
        return Mesh_nAddTriangle(handle, &t)
    }

    @discardableResult
    func addTriangle(_ a: Int32, _ b: Int32, _ c: Int32) -> Int32 {
        var t = PKTriangle(a: a, b: b, c: c)
        return Mesh_nAddTriangle(handle, &t)
    }

    @discardableResult
    func addTriangle(_ vecA: SIMD3<Float>, _ vecB: SIMD3<Float>, _ vecC: SIMD3<Float>) -> Int32 {
        let a = addVertex(vecA)
        let b = addVertex(vecB)
        let c = addVertex(vecC)
        return addTriangle(a, b, c)
    }

    var triangleCount: Int32 {
        Mesh_nTriangleCount(handle)
    }

    func triangle(at index: Int32) -> PKTriangle {
        var t = PKTriangle(a: 0, b: 0, c: 0)
        Mesh_GetTriangle(handle, index, &t)
        return t
    }

    func triangleVertices(at index: Int32) -> (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>) {
        var a = PKVector3.zero, b = PKVector3.zero, c = PKVector3.zero
        Mesh_GetTriangleV(handle, index, &a, &b, &c)
        return (a.simd, b.simd, c.simd)
    }

    // MARK: - Quads

    func addQuad(_ n0: Int32, _ n1: Int32, _ n2: Int32, _ n3: Int32, flipped: Bool = false) {
        if flipped {
            addTriangle(n0, n2, n1)
            addTriangle(n0, n3, n2)
        } else {
            addTriangle(n0, n1, n2)
            addTriangle(n0, n2, n3)
        }
    }

    /// Convenience: add a quad from four vertex positions (adds vertices automatically).
    func addQuad(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>, _ d: SIMD3<Float>) {
        let n0 = addVertex(a)
        let n1 = addVertex(b)
        let n2 = addVertex(c)
        let n3 = addVertex(d)
        addQuad(n0, n1, n2, n3)
    }

    // MARK: - Bounding Box

    var boundingBox: BBox3 {
        var bbox = PKBBox3(
            vecMin: PKVector3(x: Float.greatestFiniteMagnitude,
                              y: Float.greatestFiniteMagnitude,
                              z: Float.greatestFiniteMagnitude),
            vecMax: PKVector3(x: -Float.greatestFiniteMagnitude,
                              y: -Float.greatestFiniteMagnitude,
                              z: -Float.greatestFiniteMagnitude)
        )
        Mesh_GetBoundingBox(handle, &bbox)
        return BBox3(from: bbox)
    }
}
