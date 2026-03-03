// MetalRenderer.swift
// Genolanx — Metal renderer with PBR shading, replacing PicoGK's GLFW/OpenGL viewer

import MetalKit
import simd

// MARK: - GPU Uniform Structs (must match PBRShaders.metal)

struct SceneUniforms {
    var modelMatrix: simd_float4x4
    var viewProjectionMatrix: simd_float4x4
    var eyePosition: SIMD3<Float>
    var _pad0: Float = 0
    var lightDirection: SIMD3<Float>
    var _pad1: Float = 0
}

struct MaterialUniforms {
    var baseColor: SIMD4<Float>
    var metallic: Float
    var roughness: Float
    var _pad: SIMD2<Float> = .zero
}

// MARK: - Action Queue (thread-safe scene mutations, ported from PicoGK ViewerActions)

private enum RenderAction {
    case addMesh(MeshBuffer, Int)
    case addPolyLine(PolyLineBuffer, Int)
    case removeAllObjects
    case setGroupMaterial(Int, PBRMaterial)
    case setGroupVisible(Int, Bool)
    case setGroupTransform(Int, simd_float4x4)
}

// MARK: - MetalRenderer

final class MetalRenderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let meshPipeline: MTLRenderPipelineState
    let linePipeline: MTLRenderPipelineState
    let gridPipeline: MTLRenderPipelineState
    let depthState: MTLDepthStencilState
    let gridDepthState: MTLDepthStencilState
    let transparentDepthState: MTLDepthStencilState

    let camera = OrbitCamera()

    private var groups: [Int: RenderGroup] = [:]
    private let actionQueue = DispatchQueue(label: "com.nxgenoevra.renderactions")
    private var pendingActions: [RenderAction] = []

    var showGrid = true

    init(metalView: MTKView) {
        device = metalView.device ?? MTLCreateSystemDefaultDevice()!
        commandQueue = device.makeCommandQueue()!

        metalView.colorPixelFormat = .bgra8Unorm_srgb
        metalView.depthStencilPixelFormat = .depth32Float
        metalView.clearColor = MTLClearColor(red: 0.18, green: 0.20, blue: 0.25, alpha: 1.0)
        metalView.sampleCount = 4
        metalView.preferredFramesPerSecond = 60

        let library = device.makeDefaultLibrary()!

        // --- Mesh PBR Pipeline ---
        let meshPipelineDesc = MTLRenderPipelineDescriptor()
        meshPipelineDesc.vertexFunction = library.makeFunction(name: "meshVertexShader")
        meshPipelineDesc.fragmentFunction = library.makeFunction(name: "meshFragmentShader")
        meshPipelineDesc.vertexDescriptor = MeshBuffer.vertexDescriptor
        meshPipelineDesc.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        meshPipelineDesc.depthAttachmentPixelFormat = metalView.depthStencilPixelFormat
        meshPipelineDesc.sampleCount = metalView.sampleCount
        // Alpha blending for transparent materials
        meshPipelineDesc.colorAttachments[0].isBlendingEnabled = true
        meshPipelineDesc.colorAttachments[0].rgbBlendOperation = .add
        meshPipelineDesc.colorAttachments[0].alphaBlendOperation = .add
        meshPipelineDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        meshPipelineDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        meshPipelineDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        meshPipelineDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        meshPipeline = try! device.makeRenderPipelineState(descriptor: meshPipelineDesc)

        // --- Line Pipeline ---
        let linePipelineDesc = MTLRenderPipelineDescriptor()
        linePipelineDesc.vertexFunction = library.makeFunction(name: "lineVertexShader")
        linePipelineDesc.fragmentFunction = library.makeFunction(name: "lineFragmentShader")
        linePipelineDesc.vertexDescriptor = PolyLineBuffer.vertexDescriptor
        linePipelineDesc.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        linePipelineDesc.depthAttachmentPixelFormat = metalView.depthStencilPixelFormat
        linePipelineDesc.sampleCount = metalView.sampleCount
        linePipelineDesc.colorAttachments[0].isBlendingEnabled = true
        linePipelineDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        linePipelineDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        linePipeline = try! device.makeRenderPipelineState(descriptor: linePipelineDesc)

        // --- Grid Pipeline ---
        let gridPipelineDesc = MTLRenderPipelineDescriptor()
        gridPipelineDesc.vertexFunction = library.makeFunction(name: "gridVertexShader")
        gridPipelineDesc.fragmentFunction = library.makeFunction(name: "gridFragmentShader")
        gridPipelineDesc.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        gridPipelineDesc.depthAttachmentPixelFormat = metalView.depthStencilPixelFormat
        gridPipelineDesc.sampleCount = metalView.sampleCount
        gridPipelineDesc.colorAttachments[0].isBlendingEnabled = true
        gridPipelineDesc.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        gridPipelineDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        gridPipeline = try! device.makeRenderPipelineState(descriptor: gridPipelineDesc)

        // --- Depth Stencil States ---
        let depthDesc = MTLDepthStencilDescriptor()
        depthDesc.depthCompareFunction = .less
        depthDesc.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: depthDesc)!

        let gridDepthDesc = MTLDepthStencilDescriptor()
        gridDepthDesc.depthCompareFunction = .less
        gridDepthDesc.isDepthWriteEnabled = false  // Grid doesn't write depth
        gridDepthState = device.makeDepthStencilState(descriptor: gridDepthDesc)!

        let transDepthDesc = MTLDepthStencilDescriptor()
        transDepthDesc.depthCompareFunction = .less
        transDepthDesc.isDepthWriteEnabled = false  // Transparent objects don't write depth
        transparentDepthState = device.makeDepthStencilState(descriptor: transDepthDesc)!

        super.init()
        metalView.delegate = self
    }

    // MARK: - Thread-Safe Scene Mutation

    func addMesh(_ mesh: PicoGKMesh, groupID: Int) {
        let buffer = MeshBuffer(device: device, mesh: mesh)
        enqueueAction(.addMesh(buffer, groupID))
    }

    func addPolyLine(_ polyLine: PicoGKPolyLine, groupID: Int) {
        let buffer = PolyLineBuffer(device: device, polyLine: polyLine)
        enqueueAction(.addPolyLine(buffer, groupID))
    }

    func removeAllObjects() {
        enqueueAction(.removeAllObjects)
    }

    func setGroupMaterial(_ groupID: Int, material: PBRMaterial) {
        enqueueAction(.setGroupMaterial(groupID, material))
    }

    func setGroupVisible(_ groupID: Int, visible: Bool) {
        enqueueAction(.setGroupVisible(groupID, visible))
    }

    func setGroupTransform(_ groupID: Int, transform: simd_float4x4) {
        enqueueAction(.setGroupTransform(groupID, transform))
    }

    private func enqueueAction(_ action: RenderAction) {
        actionQueue.sync {
            pendingActions.append(action)
        }
    }

    private func drainActions() {
        var actions: [RenderAction] = []
        actionQueue.sync {
            actions = pendingActions
            pendingActions.removeAll()
        }

        for action in actions {
            switch action {
            case .addMesh(let buffer, let groupID):
                let group = groups[groupID] ?? RenderGroup()
                group.meshBuffers.append(buffer)
                groups[groupID] = group
                camera.sceneBounds.include(buffer.boundingBox)

            case .addPolyLine(let buffer, let groupID):
                let group = groups[groupID] ?? RenderGroup()
                group.polyLineBuffers.append(buffer)
                groups[groupID] = group

            case .removeAllObjects:
                groups.removeAll()
                camera.sceneBounds = BBox3()

            case .setGroupMaterial(let groupID, let material):
                groups[groupID, default: RenderGroup()].material = material

            case .setGroupVisible(let groupID, let visible):
                groups[groupID]?.isVisible = visible

            case .setGroupTransform(let groupID, let transform):
                groups[groupID]?.transform = transform
            }
        }
    }

    // MARK: - MTKViewDelegate

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        drainActions()

        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        let aspect = Float(view.drawableSize.width / view.drawableSize.height)
        let vp = camera.projectionMatrix(aspectRatio: aspect) * camera.viewMatrix

        var sceneUniforms = SceneUniforms(
            modelMatrix: matrix_identity_float4x4,
            viewProjectionMatrix: vp,
            eyePosition: camera.eyePosition,
            lightDirection: simd_normalize(SIMD3(0.6, 0.4, 0.8))
        )

        // --- Draw Grid ---
        if showGrid {
            encoder.setRenderPipelineState(gridPipeline)
            encoder.setDepthStencilState(gridDepthState)
            encoder.setVertexBytes(&sceneUniforms, length: MemoryLayout<SceneUniforms>.stride, index: 1)
            var gridSize: Float = 500.0
            encoder.setVertexBytes(&gridSize, length: MemoryLayout<Float>.stride, index: 2)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }

        // --- Draw Opaque Meshes ---
        encoder.setRenderPipelineState(meshPipeline)
        encoder.setDepthStencilState(depthState)
        encoder.setFrontFacing(.counterClockwise)
        encoder.setCullMode(.back)

        for (_, group) in groups where group.isVisible && group.material.baseColor.w >= 1.0 {
            sceneUniforms.modelMatrix = group.transform
            encoder.setVertexBytes(&sceneUniforms, length: MemoryLayout<SceneUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&sceneUniforms, length: MemoryLayout<SceneUniforms>.stride, index: 1)

            var materialUniforms = MaterialUniforms(
                baseColor: group.material.baseColor,
                metallic: group.material.metallic,
                roughness: group.material.roughness
            )
            encoder.setFragmentBytes(&materialUniforms, length: MemoryLayout<MaterialUniforms>.stride, index: 0)

            for meshBuffer in group.meshBuffers {
                encoder.setVertexBuffer(meshBuffer.vertexBuffer, offset: 0, index: 0)
                encoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: meshBuffer.indexCount,
                    indexType: .uint32,
                    indexBuffer: meshBuffer.indexBuffer,
                    indexBufferOffset: 0
                )
            }
        }

        // --- Draw Transparent Meshes (no depth write, both faces visible) ---
        encoder.setDepthStencilState(transparentDepthState)
        encoder.setCullMode(.none)

        for (_, group) in groups where group.isVisible && group.material.baseColor.w < 1.0 {
            sceneUniforms.modelMatrix = group.transform
            encoder.setVertexBytes(&sceneUniforms, length: MemoryLayout<SceneUniforms>.stride, index: 1)
            encoder.setFragmentBytes(&sceneUniforms, length: MemoryLayout<SceneUniforms>.stride, index: 1)

            var materialUniforms = MaterialUniforms(
                baseColor: group.material.baseColor,
                metallic: group.material.metallic,
                roughness: group.material.roughness
            )
            encoder.setFragmentBytes(&materialUniforms, length: MemoryLayout<MaterialUniforms>.stride, index: 0)

            for meshBuffer in group.meshBuffers {
                encoder.setVertexBuffer(meshBuffer.vertexBuffer, offset: 0, index: 0)
                encoder.drawIndexedPrimitives(
                    type: .triangle,
                    indexCount: meshBuffer.indexCount,
                    indexType: .uint32,
                    indexBuffer: meshBuffer.indexBuffer,
                    indexBufferOffset: 0
                )
            }
        }

        // --- Draw PolyLines ---
        encoder.setRenderPipelineState(linePipeline)
        encoder.setCullMode(.none)

        for (_, group) in groups where group.isVisible {
            sceneUniforms.modelMatrix = group.transform
            encoder.setVertexBytes(&sceneUniforms, length: MemoryLayout<SceneUniforms>.stride, index: 1)

            for lineBuffer in group.polyLineBuffers {
                var lineColor = lineBuffer.color
                encoder.setVertexBytes(&lineColor, length: MemoryLayout<SIMD4<Float>>.stride, index: 2)
                encoder.setVertexBuffer(lineBuffer.vertexBuffer, offset: 0, index: 0)
                encoder.drawPrimitives(type: .lineStrip, vertexStart: 0, vertexCount: lineBuffer.vertexCount)
            }
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
