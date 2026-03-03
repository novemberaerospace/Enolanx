// PicoGKOpenVdbFile.swift
// Genolanx — Swift wrapper for PicoGK OpenVDB file I/O

import Foundation
import PicoGKBridge

final class PicoGKOpenVdbFile: @unchecked Sendable {
    let handle: PKHandle

    init() {
        handle = VdbFile_hCreate()
        assert(handle != nil)
    }

    init(fromFile path: String) {
        handle = VdbFile_hCreateFromFile(path)
        assert(handle != nil)
    }

    deinit {
        VdbFile_Destroy(handle)
    }

    // MARK: - Save

    @discardableResult
    func save(to path: String) -> Bool {
        VdbFile_bSaveToFile(handle, path)
    }

    // MARK: - Voxels

    func getVoxels(at index: Int32) -> PicoGKVoxels? {
        let h = VdbFile_hGetVoxels(handle, index)
        guard h != nil else { return nil }
        return PicoGKVoxels(handle: h!)
    }

    @discardableResult
    func addVoxels(name: String, voxels: PicoGKVoxels) -> Int32 {
        VdbFile_nAddVoxels(handle, name, voxels.handle)
    }

    // MARK: - Scalar Fields

    func getScalarField(at index: Int32) -> PicoGKScalarField? {
        let h = VdbFile_hGetScalarField(handle, index)
        guard h != nil else { return nil }
        return PicoGKScalarField(handle: h!)
    }

    @discardableResult
    func addScalarField(name: String, field: PicoGKScalarField) -> Int32 {
        VdbFile_nAddScalarField(handle, name, field.handle)
    }

    // MARK: - Vector Fields

    func getVectorField(at index: Int32) -> PicoGKVectorField? {
        let h = VdbFile_hGetVectorField(handle, index)
        guard h != nil else { return nil }
        return PicoGKVectorField(handle: h!)
    }

    @discardableResult
    func addVectorField(name: String, field: PicoGKVectorField) -> Int32 {
        VdbFile_nAddVectorField(handle, name, field.handle)
    }

    // MARK: - Field Metadata

    var fieldCount: Int32 {
        VdbFile_nFieldCount(handle)
    }

    func fieldName(at index: Int32) -> String {
        var buffer = [CChar](repeating: 0, count: 256)
        VdbFile_GetFieldName(handle, index, &buffer)
        return String(cString: buffer)
    }

    /// Field type: 0 = Voxels, 1 = ScalarField, 2 = VectorField
    func fieldType(at index: Int32) -> Int32 {
        VdbFile_nFieldType(handle, index)
    }
}
