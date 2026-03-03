// InspectorView.swift
// Genolanx — Right panel showing group properties and scene info

import SwiftUI

struct InspectorView: View {
    @ObservedObject var sceneManager: SceneManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Inspector")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Divider()

            if sceneManager.groupInfos.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("No objects in scene")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Run a task to generate geometry")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(sceneManager.groupInfos.values).sorted(by: { $0.id < $1.id })) { info in
                            GroupInfoCard(info: info, sceneManager: sceneManager)
                        }
                    }
                    .padding(12)
                }
            }

            Spacer()

            Divider()

            // Scene stats
            VStack(alignment: .leading, spacing: 4) {
                let totalMeshes = sceneManager.groupInfos.values.reduce(0) { $0 + $1.meshCount }
                let totalGroups = sceneManager.groupInfos.count

                Text("Groups: \(totalGroups)")
                    .font(.system(.caption2, design: .monospaced))
                Text("Meshes: \(totalMeshes)")
                    .font(.system(.caption2, design: .monospaced))
            }
            .foregroundColor(.secondary)
            .padding(12)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
}

struct GroupInfoCard: View {
    let info: SceneManager.GroupInfo
    @ObservedObject var sceneManager: SceneManager

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(Color(
                        red: Double(info.material.baseColor.x),
                        green: Double(info.material.baseColor.y),
                        blue: Double(info.material.baseColor.z)
                    ))
                    .frame(width: 12, height: 12)

                Text(info.name)
                    .font(.caption.bold())

                Spacer()

                Button(action: {
                    sceneManager.setGroupVisible(info.id, visible: !info.isVisible)
                }) {
                    Image(systemName: info.isVisible ? "eye" : "eye.slash")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading) {
                    Text("Metallic")
                        .font(.caption2).foregroundColor(.secondary)
                    Text(String(format: "%.2f", info.material.metallic))
                        .font(.system(.caption2, design: .monospaced))
                }
                VStack(alignment: .leading) {
                    Text("Roughness")
                        .font(.caption2).foregroundColor(.secondary)
                    Text(String(format: "%.2f", info.material.roughness))
                        .font(.system(.caption2, design: .monospaced))
                }
                VStack(alignment: .leading) {
                    Text("Meshes")
                        .font(.caption2).foregroundColor(.secondary)
                    Text("\(info.meshCount)")
                        .font(.system(.caption2, design: .monospaced))
                }
            }
        }
        .padding(8)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(6)
    }
}
