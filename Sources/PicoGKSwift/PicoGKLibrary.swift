// PicoGKLibrary.swift
// Genolanx — Swift wrapper for PicoGK Library initialization

import Foundation
import PicoGKBridge

final class PicoGKLibrary: @unchecked Sendable {
    static let stringBufferLength = 255

    let voxelSizeMM: Float
    private var isInitialized = false

    init(voxelSizeMM: Float) {
        self.voxelSizeMM = voxelSizeMM
        Library_Init(voxelSizeMM)
        isInitialized = true
    }

    deinit {
        if isInitialized {
            Library_Destroy()
        }
    }

    static var name: String {
        var buffer = [CChar](repeating: 0, count: stringBufferLength + 1)
        Library_GetName(&buffer)
        return String(cString: buffer)
    }

    static var version: String {
        var buffer = [CChar](repeating: 0, count: stringBufferLength + 1)
        Library_GetVersion(&buffer)
        return String(cString: buffer)
    }

    static var buildInfo: String {
        var buffer = [CChar](repeating: 0, count: stringBufferLength + 1)
        Library_GetBuildInfo(&buffer)
        return String(cString: buffer)
    }

    /// Convert voxel coordinates to millimeters.
    static func voxelsToMm(_ voxelCoord: SIMD3<Float>) -> SIMD3<Float> {
        var input = PKVector3(voxelCoord)
        var output = PKVector3.zero
        Library_VoxelsToMm(&input, &output)
        return output.simd
    }

    /// Convert millimeters to voxel coordinates.
    static func mmToVoxels(_ mmCoord: SIMD3<Float>) -> SIMD3<Float> {
        var input = PKVector3(mmCoord)
        var output = PKVector3.zero
        Library_MmToVoxels(&input, &output)
        return output.simd
    }
}
