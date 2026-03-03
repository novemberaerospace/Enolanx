// PicoGKVectorField.swift
// Genolanx — Swift wrapper for PicoGK VectorField

import simd
import PicoGKBridge

// Thread-local callback trampoline for vector field traversal
nonisolated(unsafe) private var _vectorTraverseCallback: ((SIMD3<Float>, SIMD3<Float>) -> Void)?

private func _vectorTraverseTrampoline(_ pvec: UnsafePointer<PKVector3>?,
                                        _ pval: UnsafePointer<PKVector3>?) {
    guard let cb = _vectorTraverseCallback, let pv = pvec, let pp = pval else { return }
    cb(pv.pointee.simd, pp.pointee.simd)
}

final class PicoGKVectorField: @unchecked Sendable {
    let handle: PKHandle

    init() {
        handle = VectorField_hCreate()
        assert(handle != nil)
    }

    init(copy source: PicoGKVectorField) {
        handle = VectorField_hCreateCopy(source.handle)
        assert(handle != nil)
    }

    init(fromVoxels voxels: PicoGKVoxels) {
        handle = VectorField_hCreateFromVoxels(voxels.handle)
        assert(handle != nil)
    }

    init(fromVoxels voxels: PicoGKVoxels, value: SIMD3<Float>, sdThreshold: Float) {
        var v = PKVector3(value)
        handle = VectorField_hBuildFromVoxels(voxels.handle, &v, sdThreshold)
        assert(handle != nil)
    }

    init(handle: PKHandle) {
        self.handle = handle
        assert(handle != nil)
    }

    deinit {
        VectorField_Destroy(handle)
    }

    // MARK: - Value Operations

    func setValue(at position: SIMD3<Float>, value: SIMD3<Float>) {
        var pos = PKVector3(position)
        var val = PKVector3(value)
        VectorField_SetValue(handle, &pos, &val)
    }

    func getValue(at position: SIMD3<Float>) -> SIMD3<Float>? {
        var pos = PKVector3(position)
        var val = PKVector3.zero
        let found = VectorField_bGetValue(handle, &pos, &val)
        return found ? val.simd : nil
    }

    func removeValue(at position: SIMD3<Float>) {
        var pos = PKVector3(position)
        VectorField_RemoveValue(handle, &pos)
    }

    // MARK: - Traversal

    func traverseActive(_ callback: @escaping (SIMD3<Float>, SIMD3<Float>) -> Void) {
        _vectorTraverseCallback = callback
        VectorField_TraverseActive(handle, _vectorTraverseTrampoline)
        _vectorTraverseCallback = nil
    }
}
