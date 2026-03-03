// PicoGKTypes.swift
// Genolanx — Swift type extensions for PicoGK bridge structs
//
// CRITICAL: SIMD3<Float> is 16 bytes (4-float aligned) but the dylib expects
// 12-byte Vector3 (3 contiguous floats). All bridge calls MUST use PKVector3
// and convert to/from SIMD3<Float> at the Swift wrapper layer.

import simd
import PicoGKBridge

// MARK: - PKVector3 ↔ SIMD3<Float>

extension PKVector3 {
    @inlinable var simd: SIMD3<Float> { SIMD3(x, y, z) }
    @inlinable init(_ v: SIMD3<Float>) { self.init(x: v.x, y: v.y, z: v.z) }
    static let zero = PKVector3(x: 0, y: 0, z: 0)
}

// MARK: - PKVector2 ↔ SIMD2<Float>

extension PKVector2 {
    @inlinable var simd: SIMD2<Float> { SIMD2(x, y) }
    @inlinable init(_ v: SIMD2<Float>) { self.init(x: v.x, y: v.y) }
    static let zero = PKVector2(x: 0, y: 0)
}

// MARK: - PKColorFloat Extensions

extension PKColorFloat {
    @inlinable var simd4: SIMD4<Float> { SIMD4(r, g, b, a) }

    init(gray: Float, alpha: Float = 1.0) {
        self.init(r: gray, g: gray, b: gray, a: alpha)
    }

    init(hex: UInt32, alpha: Float = 1.0) {
        let r = Float((hex >> 16) & 0xFF) / 255.0
        let g = Float((hex >> 8) & 0xFF) / 255.0
        let b = Float(hex & 0xFF) / 255.0
        self.init(r: r, g: g, b: b, a: alpha)
    }

    static let white    = PKColorFloat(r: 1, g: 1, b: 1, a: 1)
    static let black    = PKColorFloat(r: 0, g: 0, b: 0, a: 1)
    static let gray     = PKColorFloat(gray: 0.5)
    static let red      = PKColorFloat(r: 1, g: 0, b: 0, a: 1)
    static let green    = PKColorFloat(r: 0, g: 1, b: 0, a: 1)
    static let blue     = PKColorFloat(r: 0, g: 0, b: 1, a: 1)
}

// MARK: - PKMatrix4x4 ↔ simd_float4x4

extension PKMatrix4x4 {
    /// Convert from PicoGK row-major matrix to Metal column-major simd_float4x4.
    var simdColumnMajor: simd_float4x4 {
        // PicoGK (System.Numerics) stores: M11,M12,M13,M14, M21,M22,...
        // That's row-major: row 0 = [m[0],m[1],m[2],m[3]]
        // simd_float4x4 is column-major: column 0 = [m[0],m[4],m[8],m[12]]
        simd_float4x4(columns: (
            SIMD4(m.0, m.4, m.8,  m.12),
            SIMD4(m.1, m.5, m.9,  m.13),
            SIMD4(m.2, m.6, m.10, m.14),
            SIMD4(m.3, m.7, m.11, m.15)
        ))
    }

    /// Create from Metal column-major simd_float4x4 to PicoGK row-major.
    init(simd mat: simd_float4x4) {
        self.init(m: (
            mat.columns.0.x, mat.columns.1.x, mat.columns.2.x, mat.columns.3.x,
            mat.columns.0.y, mat.columns.1.y, mat.columns.2.y, mat.columns.3.y,
            mat.columns.0.z, mat.columns.1.z, mat.columns.2.z, mat.columns.3.z,
            mat.columns.0.w, mat.columns.1.w, mat.columns.2.w, mat.columns.3.w
        ))
    }

    static let identity = PKMatrix4x4(m: (
        1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1
    ))
}

// MARK: - BBox3 (Swift-native bounding box)

struct BBox3 {
    var vecMin: SIMD3<Float>
    var vecMax: SIMD3<Float>

    init() {
        vecMin = SIMD3(repeating:  Float.greatestFiniteMagnitude)
        vecMax = SIMD3(repeating: -Float.greatestFiniteMagnitude)
    }

    init(min: SIMD3<Float>, max: SIMD3<Float>) {
        vecMin = min
        vecMax = max
    }

    init(from pk: PKBBox3) {
        vecMin = pk.vecMin.simd
        vecMax = pk.vecMax.simd
    }

    func toPK() -> PKBBox3 {
        PKBBox3(vecMin: PKVector3(vecMin), vecMax: PKVector3(vecMax))
    }

    var isEmpty: Bool {
        vecMin.x > vecMax.x || vecMin.y > vecMax.y || vecMin.z > vecMax.z
    }

    var center: SIMD3<Float> { (vecMin + vecMax) * 0.5 }
    var size: SIMD3<Float> { vecMax - vecMin }

    var radius: Float {
        simd_length(size) * 0.5
    }

    mutating func include(_ point: SIMD3<Float>) {
        vecMin = simd_min(vecMin, point)
        vecMax = simd_max(vecMax, point)
    }

    mutating func include(_ other: BBox3) {
        guard !other.isEmpty else { return }
        vecMin = simd_min(vecMin, other.vecMin)
        vecMax = simd_max(vecMax, other.vecMax)
    }

    mutating func grow(by distance: Float) {
        let d = SIMD3(repeating: distance)
        vecMin -= d
        vecMax += d
    }
}

// MARK: - Triangle (Swift alias)

extension PKTriangle {
    init(_ a: Int32, _ b: Int32, _ c: Int32) {
        self.init(a: a, b: b, c: c)
    }
}

// MARK: - simd_float4x4 helpers for camera math

extension simd_float4x4 {
    /// Create a perspective projection matrix.
    init(perspectiveFovRadians fov: Float, aspectRatio: Float, near: Float, far: Float) {
        let y = 1.0 / tanf(fov * 0.5)
        let x = y / aspectRatio
        let z = far / (near - far)
        self.init(columns: (
            SIMD4(x, 0, 0,  0),
            SIMD4(0, y, 0,  0),
            SIMD4(0, 0, z, -1),
            SIMD4(0, 0, z * near, 0)
        ))
    }

    /// Create a look-at view matrix (right-handed).
    init(lookAt eye: SIMD3<Float>, target: SIMD3<Float>, up: SIMD3<Float>) {
        let z = simd_normalize(eye - target)
        let x = simd_normalize(simd_cross(up, z))
        let y = simd_cross(z, x)

        self.init(columns: (
            SIMD4(x.x, y.x, z.x, 0),
            SIMD4(x.y, y.y, z.y, 0),
            SIMD4(x.z, y.z, z.z, 0),
            SIMD4(-simd_dot(x, eye), -simd_dot(y, eye), -simd_dot(z, eye), 1)
        ))
    }

    /// Create an orthographic projection matrix.
    init(orthographicWidth width: Float, height: Float, near: Float, far: Float) {
        let sx = 2.0 / width
        let sy = 2.0 / height
        let sz = 1.0 / (near - far)
        self.init(columns: (
            SIMD4(sx, 0,  0,  0),
            SIMD4(0,  sy, 0,  0),
            SIMD4(0,  0,  sz, 0),
            SIMD4(0,  0,  sz * near, 1)
        ))
    }
}
