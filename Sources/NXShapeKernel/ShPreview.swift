// ShPreview.swift
// Genolanx — Preview and export helper functions (port of Sh.PreviewVoxels etc.)

import PicoGKBridge

/// Shape helper functions (mirrors C# Sh static class).
enum Sh {
    nonisolated(unsafe) private static var nextGroupID: Int = 0

    /// Preview voxels in the scene with auto-incrementing group ID.
    @MainActor
    static func previewVoxels(_ voxels: PicoGKVoxels, color: PKColorFloat,
                               sceneManager: SceneManager,
                               metallic: Float = 0.4, roughness: Float = 0.7) {
        let groupID = nextGroupID
        nextGroupID += 1
        sceneManager.addVoxels(voxels, groupID: groupID)
        sceneManager.setGroupMaterial(groupID, color: color, metallic: metallic, roughness: roughness)
    }

    /// Preview voxels with explicit metallic param (C# Sh.PreviewVoxels overload).
    @MainActor
    static func previewVoxels(_ voxels: PicoGKVoxels, color: PKColorFloat,
                               _ metallic: Float,
                               sceneManager: SceneManager) {
        previewVoxels(voxels, color: color, sceneManager: sceneManager,
                      metallic: metallic, roughness: 0.7)
    }

    /// Preview a mesh directly (no voxelization round-trip).
    @MainActor
    static func previewMesh(_ mesh: PicoGKMesh, color: PKColorFloat,
                             sceneManager: SceneManager,
                             metallic: Float = 0.4, roughness: Float = 0.7) {
        let groupID = nextGroupID
        nextGroupID += 1
        sceneManager.addMesh(mesh, groupID: groupID)
        sceneManager.setGroupMaterial(groupID, color: color, metallic: metallic, roughness: roughness)
    }

    /// Preview a lattice in the scene.
    @MainActor
    static func previewLattice(_ lattice: PicoGKLattice, color: PKColorFloat,
                                sceneManager: SceneManager,
                                metallic: Float = 0.4, roughness: Float = 0.7) {
        let vox = PicoGKVoxels(lattice: lattice)
        previewVoxels(vox, color: color, sceneManager: sceneManager,
                      metallic: metallic, roughness: roughness)
    }

    /// Create a lattice from a single beam (helper matching C# Sh.latFromBeam).
    static func latFromBeam(_ from: SIMD3<Float>, _ to: SIMD3<Float>,
                             _ radiusA: Float, _ radiusB: Float,
                             _ roundCap: Bool) -> PicoGKLattice {
        let lat = PicoGKLattice()
        lat.addBeam(from: from, radiusA: radiusA,
                    to: to, radiusB: radiusB, roundCap: roundCap)
        return lat
    }

    /// Reset the group ID counter (call before a new task).
    static func resetGroupCounter() {
        nextGroupID = 0
    }
}
