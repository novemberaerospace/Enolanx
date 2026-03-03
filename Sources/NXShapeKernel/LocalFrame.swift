// LocalFrame.swift
// Genolanx — Coordinate frame (port of LEAP71 ShapeKernel LocalFrame.cs)

import simd

struct LocalFrame {
    var position: SIMD3<Float>
    var localX: SIMD3<Float>
    var localY: SIMD3<Float>
    var localZ: SIMD3<Float>

    /// Default frame at origin, aligned with global axes.
    init() {
        position = .zero
        localX = SIMD3(1, 0, 0)
        localY = SIMD3(0, 1, 0)
        localZ = SIMD3(0, 0, 1)
    }

    /// Frame at position, aligned with global axes.
    init(position: SIMD3<Float>) {
        self.position = position
        localX = SIMD3(1, 0, 0)
        localY = SIMD3(0, 1, 0)
        localZ = SIMD3(0, 0, 1)
    }

    /// Frame at position with specified Z-axis. X/Y computed orthogonally.
    init(position: SIMD3<Float>, localZ: SIMD3<Float>) {
        self.position = position
        self.localZ = simd_normalize(localZ)
        self.localX = VecOp.orthogonalDir(self.localZ)
        self.localY = simd_normalize(simd_cross(self.localZ, self.localX))
    }

    /// Full frame specification. Y = cross(Z, X).
    init(position: SIMD3<Float>, localZ: SIMD3<Float>, localX: SIMD3<Float>) {
        self.position = position
        self.localZ = simd_normalize(localZ)
        self.localX = simd_normalize(localX)
        self.localY = simd_normalize(simd_cross(self.localZ, self.localX))
    }

    /// Return a translated frame (axes unchanged).
    func translated(by offset: SIMD3<Float>) -> LocalFrame {
        var f = self
        f.position = position + offset
        return f
    }

    /// Return a rotated frame (position unchanged, axes rotated around axis).
    func rotated(angle: Float, axis: SIMD3<Float>) -> LocalFrame {
        let q = simd_quatf(angle: angle, axis: simd_normalize(axis))
        var f = self
        f.localX = q.act(localX)
        f.localY = q.act(localY)
        f.localZ = q.act(localZ)
        return f
    }

    // MARK: - C# API Compatibility

    func vecGetPosition() -> SIMD3<Float> { position }
    func vecGetLocalX() -> SIMD3<Float> { localX }
    func vecGetLocalY() -> SIMD3<Float> { localY }
    func vecGetLocalZ() -> SIMD3<Float> { localZ }

    /// Translate a frame by a vector offset (static, matches C# LocalFrame.oGetTranslatedFrame).
    static func oGetTranslatedFrame(_ frame: LocalFrame, _ offset: SIMD3<Float>) -> LocalFrame {
        frame.translated(by: offset)
    }

    /// Invert frame direction. If invertX is true, flip X axis. Always flips Z.
    static func oGetInvertFrame(_ frame: LocalFrame, _ invertX: Bool, _ invertY: Bool) -> LocalFrame {
        var f = frame
        f.localZ = -f.localZ
        if invertX { f.localX = -f.localX }
        if invertY { f.localY = -f.localY }
        // Recompute Y to keep right-handed
        f.localY = simd_normalize(simd_cross(f.localZ, f.localX))
        return f
    }
}
