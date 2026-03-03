// Camera.swift
// Genolanx — Orbit camera ported from PicoGK_Viewer.cs (lines 505-546)

import simd
import Combine

final class OrbitCamera: ObservableObject {
    @Published var orbitAngle: Float = 45.0       // degrees, around Z axis
    @Published var elevationAngle: Float = 30.0   // degrees, above XY plane
    @Published var zoom: Float = 1.0
    @Published var fov: Float = 45.0              // degrees
    @Published var isPerspective: Bool = true

    var sceneBounds: BBox3 = BBox3() {
        didSet { objectWillChange.send() }
    }

    // MARK: - Computed Camera State

    var eyePosition: SIMD3<Float> {
        let center = sceneBounds.isEmpty ? SIMD3<Float>.zero : sceneBounds.center
        let r: Float
        if sceneBounds.isEmpty {
            r = 50.0 * zoom
        } else {
            r = sceneBounds.radius * 3.0 * zoom
        }

        let elevRad = elevationAngle * .pi / 180.0
        let orbitRad = orbitAngle * .pi / 180.0
        let rElev = cos(elevRad) * r

        return center + SIMD3(
            cos(orbitRad) * rElev,
            sin(orbitRad) * rElev,
            sin(elevRad) * r
        )
    }

    var target: SIMD3<Float> {
        sceneBounds.isEmpty ? .zero : sceneBounds.center
    }

    var viewMatrix: simd_float4x4 {
        simd_float4x4(lookAt: eyePosition, target: target, up: SIMD3(0, 0, 1))
    }

    func projectionMatrix(aspectRatio: Float) -> simd_float4x4 {
        let dist = simd_length(eyePosition - target)
        let near = max(dist * 0.01, 0.01)
        let far = dist * 4.0

        if isPerspective {
            return simd_float4x4(
                perspectiveFovRadians: fov * .pi / 180.0,
                aspectRatio: aspectRatio,
                near: near,
                far: far
            )
        } else {
            let height = sceneBounds.isEmpty ? 100.0 : sceneBounds.size.z * zoom * 2.0
            let width = height * aspectRatio
            return simd_float4x4(
                orthographicWidth: width,
                height: height,
                near: near,
                far: far
            )
        }
    }

    var viewProjectionMatrix: simd_float4x4 {
        // Default 1:1 aspect ratio — actual aspect set during draw
        projectionMatrix(aspectRatio: 1.0) * viewMatrix
    }

    // MARK: - Input Handling

    /// Handle mouse drag for orbit control.
    func handleDrag(delta: SIMD2<Float>) {
        orbitAngle -= delta.x * 0.5
        elevationAngle += delta.y * 0.5
        elevationAngle = max(-89, min(89, elevationAngle))

        if orbitAngle > 360 { orbitAngle -= 360 }
        if orbitAngle < 0 { orbitAngle += 360 }
    }

    /// Handle scroll wheel for zoom.
    func handleScroll(delta: Float) {
        zoom -= delta / 50.0
        zoom = max(0.1, zoom)
    }

    /// Handle trackpad magnification for zoom.
    func handleMagnify(magnification: Float) {
        zoom /= (1.0 + magnification)
        zoom = max(0.1, zoom)
    }

    /// Snap to nearest round angle (arrow key behavior from PicoGK).
    func snapToNearest(horizontal: Bool, direction: Int) {
        let step: Float = 45.0
        if horizontal {
            let current = orbitAngle
            if direction > 0 {
                orbitAngle = ceil(current / step) * step
                if orbitAngle == current { orbitAngle += step }
            } else {
                orbitAngle = floor(current / step) * step
                if orbitAngle == current { orbitAngle -= step }
            }
        } else {
            let current = elevationAngle
            if direction > 0 {
                elevationAngle = min(89, ceil(current / step) * step)
                if elevationAngle == current { elevationAngle = min(89, elevationAngle + step) }
            } else {
                elevationAngle = max(-89, floor(current / step) * step)
                if elevationAngle == current { elevationAngle = max(-89, elevationAngle - step) }
            }
        }
    }

    /// Reset to default view.
    func reset() {
        orbitAngle = 45.0
        elevationAngle = 30.0
        zoom = 1.0
    }
}
