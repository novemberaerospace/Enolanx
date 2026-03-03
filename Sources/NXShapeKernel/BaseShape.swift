// BaseShape.swift
// Genolanx — Base shape protocol and shared utilities

import simd

/// A shape that can be converted to voxels.
protocol VoxelConstructible {
    func constructVoxels() -> PicoGKVoxels
}

/// A shape that can be converted to a mesh.
protocol MeshConstructible {
    func constructMesh() -> PicoGKMesh
}

/// Base class for parametric shapes with optional vertex transformation.
class BaseShape: VoxelConstructible, MeshConstructible {
    typealias VertexTransformation = (SIMD3<Float>) -> SIMD3<Float>

    var transformation: VertexTransformation = { $0 }

    func constructVoxels() -> PicoGKVoxels {
        PicoGKVoxels(mesh: constructMesh())
    }

    /// Alias matching C# convention.
    func voxConstruct() -> PicoGKVoxels {
        constructVoxels()
    }

    func constructMesh() -> PicoGKMesh {
        fatalError("Subclass must override constructMesh()")
    }
}
