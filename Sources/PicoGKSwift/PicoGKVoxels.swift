// PicoGKVoxels.swift
// Genolanx — Swift wrapper for PicoGK Voxels (the most extensive wrapper)

import simd
import PicoGKBridge

// MARK: - Implicit Distance Protocol

protocol ImplicitSDF {
    func signedDistance(at point: SIMD3<Float>) -> Float
}

protocol BoundedImplicitSDF: ImplicitSDF {
    var bounds: BBox3 { get }
}

// MARK: - Thread-local callback trampoline for implicit rendering

// The dylib calls PKImplicitDistanceCallback synchronously without a user-data pointer.
// We use a thread-local global to store the Swift closure — safe because the callback
// is invoked synchronously during Voxels_RenderImplicit / Voxels_IntersectImplicit.
nonisolated(unsafe) private var _implicitCallback: ((SIMD3<Float>) -> Float)?

private func _implicitTrampoline(_ pvec: UnsafePointer<PKVector3>?) -> Float {
    guard let cb = _implicitCallback, let ptr = pvec else {
        return Float.greatestFiniteMagnitude
    }
    return cb(ptr.pointee.simd)
}

// MARK: - PicoGKVoxels

final class PicoGKVoxels: @unchecked Sendable {
    let handle: PKHandle

    // MARK: - Constructors

    init() {
        handle = Voxels_hCreate()
        assert(handle != nil, "Voxels_hCreate returned nil")
        assert(Voxels_bIsValid(handle))
    }

    init(copy source: PicoGKVoxels) {
        handle = Voxels_hCreateCopy(source.handle)
        assert(handle != nil)
    }

    init(mesh: PicoGKMesh) {
        handle = Voxels_hCreate()
        assert(handle != nil)
        Voxels_RenderMesh(handle, mesh.handle)
    }

    init(lattice: PicoGKLattice) {
        handle = Voxels_hCreate()
        assert(handle != nil)
        Voxels_RenderLattice(handle, lattice.handle)
    }

    init(implicit sdf: ImplicitSDF, bounds: BBox3) {
        handle = Voxels_hCreate()
        assert(handle != nil)
        renderImplicit(sdf.signedDistance, bounds: bounds)
    }

    init(boundedImplicit sdf: BoundedImplicitSDF) {
        handle = Voxels_hCreate()
        assert(handle != nil)
        renderImplicit(sdf.signedDistance, bounds: sdf.bounds)
    }

    /// Internal init from raw handle (takes ownership).
    init(handle: PKHandle) {
        self.handle = handle
        assert(handle != nil)
    }

    deinit {
        Voxels_Destroy(handle)
    }

    // MARK: - Mesh Conversion

    func asMesh() -> PicoGKMesh {
        PicoGKMesh(fromVoxels: self)
    }

    func duplicate() -> PicoGKVoxels {
        PicoGKVoxels(copy: self)
    }

    // MARK: - Boolean Operations (mutating)

    func boolAdd(_ other: PicoGKVoxels) {
        Voxels_BoolAdd(handle, other.handle)
    }

    func boolSubtract(_ other: PicoGKVoxels) {
        Voxels_BoolSubtract(handle, other.handle)
    }

    func boolIntersect(_ other: PicoGKVoxels) {
        Voxels_BoolIntersect(handle, other.handle)
    }

    // MARK: - Boolean Operations (non-mutating, return new)

    func adding(_ other: PicoGKVoxels) -> PicoGKVoxels {
        let copy = duplicate()
        copy.boolAdd(other)
        return copy
    }

    func subtracting(_ other: PicoGKVoxels) -> PicoGKVoxels {
        let copy = duplicate()
        copy.boolSubtract(other)
        return copy
    }

    func intersecting(_ other: PicoGKVoxels) -> PicoGKVoxels {
        let copy = duplicate()
        copy.boolIntersect(other)
        return copy
    }

    /// Add all voxels from a list into this one (mutating union).
    func boolAddAll(_ list: [PicoGKVoxels]) {
        for vox in list {
            boolAdd(vox)
        }
    }

    /// Combine all voxels via union (non-mutating).
    static func combine(_ voxelsList: [PicoGKVoxels]) -> PicoGKVoxels {
        guard let first = voxelsList.first else { return PicoGKVoxels() }
        let result = first.duplicate()
        for vox in voxelsList.dropFirst() {
            result.boolAdd(vox)
        }
        return result
    }

    // MARK: - Offset & Morphological

    func offset(_ distMM: Float) {
        Voxels_Offset(handle, distMM)
    }

    func offsetted(_ distMM: Float) -> PicoGKVoxels {
        let copy = duplicate()
        copy.offset(distMM)
        return copy
    }

    func doubleOffset(_ dist1MM: Float, _ dist2MM: Float) {
        Voxels_DoubleOffset(handle, dist1MM, dist2MM)
    }

    func tripleOffset(_ distMM: Float) {
        Voxels_TripleOffset(handle, distMM)
    }

    func smoothen(_ distMM: Float) {
        tripleOffset(distMM)
    }

    func smoothened(_ distMM: Float) -> PicoGKVoxels {
        let copy = duplicate()
        copy.smoothen(distMM)
        return copy
    }

    /// Over-offset: expand by firstDist then contract back to finalDist.
    /// C# OverOffset(first, final) = DoubleOffset(first, final - first)
    func overOffset(_ firstDist: Float, _ finalDist: Float = 0) {
        doubleOffset(firstDist, finalDist - firstDist)
    }

    /// Fillet: round sharp edges by over-offsetting.
    func fillet(_ roundingMM: Float) {
        overOffset(roundingMM)
    }

    /// Create a hollow shell by offsetting inward.
    func shell(_ offsetMM: Float) -> PicoGKVoxels {
        let inner = offsetted(-abs(offsetMM))
        return subtracting(inner)
    }

    // MARK: - Filters

    func gaussian(_ sizeMM: Float) {
        Voxels_Gaussian(handle, sizeMM)
    }

    func median(_ sizeMM: Float) {
        Voxels_Median(handle, sizeMM)
    }

    func mean(_ sizeMM: Float) {
        Voxels_Mean(handle, sizeMM)
    }

    // MARK: - Rendering Into Voxels

    func renderMesh(_ mesh: PicoGKMesh) {
        Voxels_RenderMesh(handle, mesh.handle)
    }

    func renderImplicit(_ sdf: @escaping (SIMD3<Float>) -> Float, bounds: BBox3) {
        _implicitCallback = sdf
        var bbox = bounds.toPK()
        Voxels_RenderImplicit(handle, &bbox, _implicitTrampoline)
        _implicitCallback = nil
    }

    func intersectImplicit(_ sdf: @escaping (SIMD3<Float>) -> Float) {
        _implicitCallback = sdf
        Voxels_IntersectImplicit(handle, _implicitTrampoline)
        _implicitCallback = nil
    }

    func renderLattice(_ lattice: PicoGKLattice) {
        Voxels_RenderLattice(handle, lattice.handle)
    }

    // MARK: - Projection

    func projectZSlice(startZ: Float, endZ: Float) {
        Voxels_ProjectZSlice(handle, startZ, endZ)
    }

    // MARK: - Analysis & Properties

    func calculateProperties() -> (volumeCubicMM: Float, boundingBox: BBox3) {
        var volume: Float = 0
        var bbox = PKBBox3(vecMin: PKVector3.zero, vecMax: PKVector3.zero)
        Voxels_CalculateProperties(handle, &volume, &bbox)
        return (volume, BBox3(from: bbox))
    }

    var boundingBox: BBox3 {
        calculateProperties().boundingBox
    }

    // MARK: - Surface Queries

    func surfaceNormal(at point: SIMD3<Float>) -> SIMD3<Float> {
        var p = PKVector3(point)
        var n = PKVector3.zero
        Voxels_GetSurfaceNormal(handle, &p, &n)
        return n.simd
    }

    func closestPointOnSurface(to point: SIMD3<Float>) -> SIMD3<Float>? {
        var search = PKVector3(point)
        var result = PKVector3.zero
        let found = Voxels_bClosestPointOnSurface(handle, &search, &result)
        return found ? result.simd : nil
    }

    func rayCastToSurface(origin: SIMD3<Float>, direction: SIMD3<Float>) -> SIMD3<Float>? {
        var o = PKVector3(origin)
        var d = PKVector3(direction)
        var result = PKVector3.zero
        let hit = Voxels_bRayCastToSurface(handle, &o, &d, &result)
        return hit ? result.simd : nil
    }

    func isEqual(to other: PicoGKVoxels) -> Bool {
        Voxels_bIsEqual(handle, other.handle)
    }

    // MARK: - Voxel Grid Access

    struct VoxelDimensions {
        var origin: (x: Int32, y: Int32, z: Int32)
        var size: (x: Int32, y: Int32, z: Int32)
    }

    var voxelDimensions: VoxelDimensions {
        var ox: Int32 = 0, oy: Int32 = 0, oz: Int32 = 0
        var sx: Int32 = 0, sy: Int32 = 0, sz: Int32 = 0
        Voxels_GetVoxelDimensions(handle, &ox, &oy, &oz, &sx, &sy, &sz)
        return VoxelDimensions(origin: (ox, oy, oz), size: (sx, sy, sz))
    }

    /// Get a Z-slice of the voxel field.
    /// Returns a flat float array of size (xSize * ySize) and the background value.
    func getSlice(z: Int32) -> (buffer: [Float], backgroundValue: Float) {
        let dims = voxelDimensions
        let count = Int(dims.size.x * dims.size.y)
        var buffer = [Float](repeating: 0, count: max(count, 1))
        var background: Float = 0
        Voxels_GetSlice(handle, z, &buffer, &background)
        return (buffer, background)
    }

    func getInterpolatedSlice(z: Float) -> (buffer: [Float], backgroundValue: Float) {
        let dims = voxelDimensions
        let count = Int(dims.size.x * dims.size.y)
        var buffer = [Float](repeating: 0, count: max(count, 1))
        var background: Float = 0
        Voxels_GetInterpolatedSlice(handle, z, &buffer, &background)
        return (buffer, background)
    }
}

// MARK: - Operators

extension PicoGKVoxels {
    static func + (lhs: PicoGKVoxels, rhs: PicoGKVoxels) -> PicoGKVoxels {
        lhs.adding(rhs)
    }

    static func - (lhs: PicoGKVoxels, rhs: PicoGKVoxels) -> PicoGKVoxels {
        lhs.subtracting(rhs)
    }

    static func & (lhs: PicoGKVoxels, rhs: PicoGKVoxels) -> PicoGKVoxels {
        lhs.intersecting(rhs)
    }
}
