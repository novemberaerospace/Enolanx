// PicoGKLattice.swift
// Genolanx — Swift wrapper for PicoGK Lattice

import simd
import PicoGKBridge

final class PicoGKLattice: @unchecked Sendable {
    let handle: PKHandle

    init() {
        handle = Lattice_hCreate()
        assert(handle != nil, "Lattice_hCreate returned nil")
        assert(Lattice_bIsValid(handle), "Lattice handle is not valid")
    }

    deinit {
        Lattice_Destroy(handle)
    }

    /// Add a sphere to the lattice.
    func addSphere(center: SIMD3<Float>, radius: Float) {
        var c = PKVector3(center)
        Lattice_AddSphere(handle, &c, radius)
    }

    /// Add a tapered beam between two points.
    func addBeam(from a: SIMD3<Float>, radiusA: Float,
                 to b: SIMD3<Float>, radiusB: Float,
                 roundCap: Bool = true) {
        var va = PKVector3(a)
        var vb = PKVector3(b)
        Lattice_AddBeam(handle, &va, &vb, radiusA, radiusB, roundCap)
    }
}
