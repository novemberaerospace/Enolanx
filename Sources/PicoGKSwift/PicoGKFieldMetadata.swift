// PicoGKFieldMetadata.swift
// Genolanx — Swift wrapper for PicoGK field metadata

import simd
import PicoGKBridge

final class PicoGKFieldMetadata: @unchecked Sendable {
    let handle: PKHandle

    init(fromVoxels voxelsHandle: PKHandle) {
        handle = Metadata_hFromVoxels(voxelsHandle)
        assert(handle != nil)
    }

    init(fromScalarField fieldHandle: PKHandle) {
        handle = Metadata_hFromScalarField(fieldHandle)
        assert(handle != nil)
    }

    init(fromVectorField fieldHandle: PKHandle) {
        handle = Metadata_hFromVectorField(fieldHandle)
        assert(handle != nil)
    }

    deinit {
        Metadata_Destroy(handle)
    }

    // MARK: - Count & Names

    var count: Int32 {
        Metadata_nCount(handle)
    }

    func name(at index: Int32) -> String? {
        let length = Metadata_nNameLengthAt(handle, index)
        guard length > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: Int(length) + 1)
        let ok = Metadata_bGetNameAt(handle, index, &buffer, Int32(buffer.count))
        return ok ? String(cString: buffer) : nil
    }

    // MARK: - Type Query

    /// Returns the type index for a named field.
    func type(forName name: String) -> Int32 {
        Metadata_nTypeAt(handle, name)
    }

    // MARK: - String Values

    func getString(forName name: String) -> String? {
        let length = Metadata_nStringLengthAt(handle, name)
        guard length > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: Int(length) + 1)
        let ok = Metadata_bGetStringAt(handle, name, &buffer, Int32(buffer.count))
        return ok ? String(cString: buffer) : nil
    }

    func setString(forName name: String, value: String) {
        Metadata_SetStringValue(handle, name, value)
    }

    // MARK: - Float Values

    func getFloat(forName name: String) -> Float? {
        var value: Float = 0
        let ok = Metadata_bGetFloatAt(handle, name, &value)
        return ok ? value : nil
    }

    func setFloat(forName name: String, value: Float) {
        Metadata_SetFloatValue(handle, name, value)
    }

    // MARK: - Vector Values

    func getVector(forName name: String) -> SIMD3<Float>? {
        var vec = PKVector3.zero
        let ok = Metadata_bGetVectorAt(handle, name, &vec)
        return ok ? vec.simd : nil
    }

    func setVector(forName name: String, value: SIMD3<Float>) {
        var vec = PKVector3(value)
        Metadata_SetVectorValue(handle, name, &vec)
    }

    // MARK: - Remove

    func removeValue(forName name: String) {
        // NOTE: dylib has inconsistent casing: MetaData_RemoveValue (capital D)
        MetaData_RemoveValue(handle, name)
    }
}
