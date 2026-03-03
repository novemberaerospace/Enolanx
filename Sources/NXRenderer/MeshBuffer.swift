// MeshBuffer.swift
// Genolanx — Convert PicoGK meshes into Metal GPU buffers

import Metal
import simd

struct MetalVertex {
    var position: SIMD3<Float>   // 12 bytes
    var normal: SIMD3<Float>     // 12 bytes
    // Total: 24 bytes per vertex (no padding needed for Metal)
}

final class MeshBuffer {
    let vertexBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
    let indexCount: Int
    let boundingBox: BBox3

    /// Create Metal buffers from a PicoGK mesh.
    /// Computes smooth per-vertex normals by accumulating face normals.
    init(device: MTLDevice, mesh: PicoGKMesh) {
        let vertCount = Int(mesh.vertexCount)
        let triCount = Int(mesh.triangleCount)

        // Extract all vertices
        var positions = [SIMD3<Float>](repeating: .zero, count: vertCount)
        for i in 0..<Int32(vertCount) {
            positions[Int(i)] = mesh.vertex(at: i)
        }

        // Accumulate face normals per vertex
        var normals = [SIMD3<Float>](repeating: .zero, count: vertCount)
        var indices = [UInt32]()
        indices.reserveCapacity(triCount * 3)

        var bbox = BBox3()

        for i in 0..<Int32(triCount) {
            let tri = mesh.triangle(at: i)
            let a = Int(tri.a), b = Int(tri.b), c = Int(tri.c)

            indices.append(UInt32(a))
            indices.append(UInt32(b))
            indices.append(UInt32(c))

            let pa = positions[a]
            let pb = positions[b]
            let pc = positions[c]

            // Face normal (cross product)
            let edge1 = pb - pa
            let edge2 = pc - pa
            let faceNormal = simd_cross(edge1, edge2)
            // Weight by area (magnitude of cross product) — gives better results
            // for meshes with varying triangle sizes

            normals[a] += faceNormal
            normals[b] += faceNormal
            normals[c] += faceNormal

            bbox.include(pa)
            bbox.include(pb)
            bbox.include(pc)
        }

        // Normalize accumulated normals
        var vertices = [MetalVertex]()
        vertices.reserveCapacity(vertCount)
        for i in 0..<vertCount {
            let n = normals[i]
            let len = simd_length(n)
            let normalizedNormal = len > 0 ? n / len : SIMD3(0, 0, 1)
            vertices.append(MetalVertex(position: positions[i], normal: normalizedNormal))
        }

        vertexBuffer = device.makeBuffer(
            bytes: vertices,
            length: MemoryLayout<MetalVertex>.stride * vertices.count,
            options: .storageModeShared
        )!
        vertexBuffer.label = "MeshVertexBuffer"

        indexBuffer = device.makeBuffer(
            bytes: indices,
            length: MemoryLayout<UInt32>.stride * indices.count,
            options: .storageModeShared
        )!
        indexBuffer.label = "MeshIndexBuffer"

        indexCount = indices.count
        boundingBox = bbox
    }

    /// Vertex descriptor for Metal pipeline.
    static var vertexDescriptor: MTLVertexDescriptor {
        let desc = MTLVertexDescriptor()

        // Attribute 0: position (float3 at offset 0)
        desc.attributes[0].format = .float3
        desc.attributes[0].offset = 0
        desc.attributes[0].bufferIndex = 0

        // Attribute 1: normal (float3 at offset 12)
        desc.attributes[1].format = .float3
        desc.attributes[1].offset = MemoryLayout<SIMD3<Float>>.stride
        desc.attributes[1].bufferIndex = 0

        // Layout: stride of MetalVertex
        desc.layouts[0].stride = MemoryLayout<MetalVertex>.stride
        desc.layouts[0].stepRate = 1
        desc.layouts[0].stepFunction = .perVertex

        return desc
    }
}
