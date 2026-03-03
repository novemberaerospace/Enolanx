// PicoGKScalarField.swift
// Genolanx — Swift wrapper for PicoGK ScalarField

import simd
import PicoGKBridge

// Thread-local callback trampoline for scalar field traversal
nonisolated(unsafe) private var _scalarTraverseCallback: ((SIMD3<Float>, Float) -> Void)?

private func _scalarTraverseTrampoline(_ pvec: UnsafePointer<PKVector3>?,
                                        _ fValue: Float) {
    guard let cb = _scalarTraverseCallback, let ptr = pvec else { return }
    cb(ptr.pointee.simd, fValue)
}

final class PicoGKScalarField: ImplicitSDF, @unchecked Sendable {
    let handle: PKHandle

    init() {
        handle = ScalarField_hCreate()
        assert(handle != nil)
    }

    init(copy source: PicoGKScalarField) {
        handle = ScalarField_hCreateCopy(source.handle)
        assert(handle != nil)
    }

    init(fromVoxels voxels: PicoGKVoxels) {
        handle = ScalarField_hCreateFromVoxels(voxels.handle)
        assert(handle != nil)
    }

    init(fromVoxels voxels: PicoGKVoxels, value: Float, sdThreshold: Float) {
        handle = ScalarField_hBuildFromVoxels(voxels.handle, value, sdThreshold)
        assert(handle != nil)
    }

    init(handle: PKHandle) {
        self.handle = handle
        assert(handle != nil)
    }

    deinit {
        ScalarField_Destroy(handle)
    }

    // MARK: - Value Operations

    func setValue(at position: SIMD3<Float>, value: Float) {
        var pos = PKVector3(position)
        ScalarField_SetValue(handle, &pos, value)
    }

    func getValue(at position: SIMD3<Float>) -> Float? {
        var pos = PKVector3(position)
        var value: Float = 0
        let found = ScalarField_bGetValue(handle, &pos, &value)
        return found ? value : nil
    }

    func removeValue(at position: SIMD3<Float>) {
        var pos = PKVector3(position)
        ScalarField_RemoveValue(handle, &pos)
    }

    // MARK: - Grid Access

    var voxelDimensions: PicoGKVoxels.VoxelDimensions {
        var ox: Int32 = 0, oy: Int32 = 0, oz: Int32 = 0
        var sx: Int32 = 0, sy: Int32 = 0, sz: Int32 = 0
        ScalarField_GetVoxelDimensions(handle, &ox, &oy, &oz, &sx, &sy, &sz)
        return .init(origin: (ox, oy, oz), size: (sx, sy, sz))
    }

    func getSlice(z: Int32) -> [Float] {
        let dims = voxelDimensions
        let count = Int(dims.size.x * dims.size.y)
        var buffer = [Float](repeating: 0, count: max(count, 1))
        ScalarField_GetSlice(handle, z, &buffer)
        return buffer
    }

    // MARK: - Traversal

    func traverseActive(_ callback: @escaping (SIMD3<Float>, Float) -> Void) {
        _scalarTraverseCallback = callback
        ScalarField_TraverseActive(handle, _scalarTraverseTrampoline)
        _scalarTraverseCallback = nil
    }

    // MARK: - ImplicitSDF Conformance

    func signedDistance(at point: SIMD3<Float>) -> Float {
        getValue(at: point) ?? Float.greatestFiniteMagnitude
    }
}
