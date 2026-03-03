// SceneManager.swift
// Genolanx — Central coordinator replacing PicoGK's Library.oViewer() and Library.Log()
//
// This is the bridge between the computation layer (PicoGK/ShapeKernel) and the
// Metal renderer + SwiftUI UI. All scene mutations flow through here.

import Foundation
import simd
import PicoGKBridge

@MainActor
final class SceneManager: ObservableObject, @unchecked Sendable {
    @Published var logMessages: [LogEntry] = []
    @Published var isRunning = false
    @Published var currentTaskName: String = ""
    @Published var groupInfos: [Int: GroupInfo] = [:]

    var renderer: MetalRenderer?
    private(set) var library: PicoGKLibrary?

    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp = Date()
        let message: String
    }

    struct GroupInfo: Identifiable {
        let id: Int
        var name: String
        var material: PBRMaterial
        var isVisible: Bool = true
        var meshCount: Int = 0
    }

    // MARK: - Library Management

    func initialize(voxelSizeMM: Float = 0.5) {
        library = PicoGKLibrary(voxelSizeMM: voxelSizeMM)
        log("PicoGK initialized: \(PicoGKLibrary.name) \(PicoGKLibrary.version)")
        log("Voxel size: \(voxelSizeMM) mm")
    }

    // MARK: - Logging

    nonisolated func log(_ message: String) {
        let entry = LogEntry(message: message)
        if Thread.isMainThread {
            MainActor.assumeIsolated {
                self.logMessages.append(entry)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.logMessages.append(entry)
            }
        }
    }

    // MARK: - Task Execution

    /// Run a geometry computation task on a background thread.
    func runTask(name: String, _ task: @escaping @Sendable (SceneManager) -> Void) {
        guard !isRunning else {
            log("Task already running — please wait.")
            return
        }

        isRunning = true
        currentTaskName = name
        log("Starting task: \(name)")

        // Capture self weakly to allow cancellation
        let manager = self
        Task.detached {
            task(manager)
            await MainActor.run {
                manager.isRunning = false
                manager.log("Completed task: \(name)")
                manager.currentTaskName = ""
            }
        }
    }

    // MARK: - Scene API (mirrors PicoGK Viewer interface)

    /// Add voxels to the scene (converts to mesh first).
    func addVoxels(_ voxels: PicoGKVoxels, groupID: Int = 0, name: String? = nil) {
        let mesh = voxels.asMesh()
        addMesh(mesh, groupID: groupID, name: name)
    }

    /// Add a mesh to the scene.
    func addMesh(_ mesh: PicoGKMesh, groupID: Int = 0, name: String? = nil) {
        renderer?.addMesh(mesh, groupID: groupID)

        let groupName = name ?? "Group \(groupID)"
        if var info = groupInfos[groupID] {
            info.meshCount += 1
            groupInfos[groupID] = info
        } else {
            groupInfos[groupID] = GroupInfo(
                id: groupID,
                name: groupName,
                material: PBRMaterial(),
                meshCount: 1
            )
        }
    }

    /// Add a polyline to the scene.
    func addPolyLine(_ polyLine: PicoGKPolyLine, groupID: Int = 0) {
        renderer?.addPolyLine(polyLine, groupID: groupID)
    }

    /// Set material properties for a group.
    func setGroupMaterial(_ groupID: Int, color: PKColorFloat,
                          metallic: Float = 0.4, roughness: Float = 0.7) {
        let material = PBRMaterial(color: color, metallic: metallic, roughness: roughness)
        renderer?.setGroupMaterial(groupID, material: material)
        groupInfos[groupID]?.material = material
    }

    /// Toggle group visibility.
    func setGroupVisible(_ groupID: Int, visible: Bool) {
        renderer?.setGroupVisible(groupID, visible: visible)
        groupInfos[groupID]?.isVisible = visible
    }

    /// Remove all objects from the scene.
    func removeAllObjects() {
        renderer?.removeAllObjects()
        groupInfos.removeAll()
    }

    // MARK: - Export

    /// Export voxels to STL file (via mesh conversion).
    nonisolated func exportSTL(voxels: PicoGKVoxels, to path: String) {
        let mesh = voxels.asMesh()
        exportSTL(mesh: mesh, to: path)
    }

    /// Export mesh to STL file.
    nonisolated func exportSTL(mesh: PicoGKMesh, to path: String) {
        log("Exporting STL to: \(path)")

        let triCount = mesh.triangleCount
        var data = Data()

        // STL binary header (80 bytes)
        var header = [UInt8](repeating: 0, count: 80)
        let headerStr = "Genolanx STL Export"
        headerStr.utf8.enumerated().forEach { i, byte in
            if i < 80 { header[i] = byte }
        }
        data.append(contentsOf: header)

        // Triangle count (4 bytes, little-endian)
        var count = UInt32(triCount)
        data.append(Data(bytes: &count, count: 4))

        // Triangles
        for i in 0..<triCount {
            let (a, b, c) = mesh.triangleVertices(at: i)
            let edge1 = b - a
            let edge2 = c - a
            var normal = simd_normalize(simd_cross(edge1, edge2))

            // Normal (12 bytes)
            data.append(Data(bytes: &normal, count: 12))
            // Vertex A (12 bytes)
            var va = a; data.append(Data(bytes: &va, count: 12))
            // Vertex B (12 bytes)
            var vb = b; data.append(Data(bytes: &vb, count: 12))
            // Vertex C (12 bytes)
            var vc = c; data.append(Data(bytes: &vc, count: 12))
            // Attribute byte count (2 bytes)
            var attr: UInt16 = 0
            data.append(Data(bytes: &attr, count: 2))
        }

        do {
            try data.write(to: URL(fileURLWithPath: path))
            log("STL exported: \(triCount) triangles, \(data.count) bytes")
        } catch {
            log("STL export failed: \(error.localizedDescription)")
        }
    }
}
