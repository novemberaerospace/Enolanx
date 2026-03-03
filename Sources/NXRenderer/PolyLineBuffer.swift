// PolyLineBuffer.swift
// Genolanx — Convert PicoGK polylines into Metal GPU buffers

import Metal
import simd

final class PolyLineBuffer {
    let vertexBuffer: MTLBuffer
    let vertexCount: Int
    let color: SIMD4<Float>

    init(device: MTLDevice, polyLine: PicoGKPolyLine) {
        let count = Int(polyLine.vertexCount)

        var positions = [SIMD3<Float>]()
        positions.reserveCapacity(count)
        for i in 0..<Int32(count) {
            positions.append(polyLine.vertex(at: i))
        }

        vertexBuffer = device.makeBuffer(
            bytes: positions,
            length: MemoryLayout<SIMD3<Float>>.stride * positions.count,
            options: .storageModeShared
        )!
        vertexBuffer.label = "PolyLineVertexBuffer"

        vertexCount = count

        let clr = polyLine.color
        color = SIMD4(clr.r, clr.g, clr.b, clr.a)
    }

    static var vertexDescriptor: MTLVertexDescriptor {
        let desc = MTLVertexDescriptor()
        desc.attributes[0].format = .float3
        desc.attributes[0].offset = 0
        desc.attributes[0].bufferIndex = 0
        desc.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        desc.layouts[0].stepRate = 1
        desc.layouts[0].stepFunction = .perVertex
        return desc
    }
}
