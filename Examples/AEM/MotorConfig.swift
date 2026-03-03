// MotorConfig.swift
// Genolanx — Algorithme de configuration moteur brushless triphasé
//
// Pour un stator à S slots (multiple de 3, 12…42) :
//   1. Calcule toutes les configurations de pôles P (paires) avec q ∈ [0.25, 1.5]
//   2. Vérifie l'équilibre triphasé (star of slots : Q* = S/GCD(S,P/2), balanced si Q* % 3 == 0)
//   3. Calcule le facteur d'enroulement kw₁ = kd × kp (méthode des phaseurs)
//   4. Évalue le cogging via LCM(S, P)
//   5. Trie par qualité (équilibré + kw₁ descroissant) et renvoie les meilleures configs

import Foundation

// ═══════════════════════════════════════════════════════════════
// MARK: - Pole Candidate
// ═══════════════════════════════════════════════════════════════

struct PoleCandidate: Identifiable, Hashable {
    let poles: Int          // P (nombre de pôles rotor, pair)
    let q: Float            // slots per pole per phase = S / (3×P)
    let kw1: Float          // fundamental winding factor
    let lcmSP: Int          // LCM(S, P) — plus élevé = cogging plus faible
    let gcdSP: Int          // GCD(S, P) — symétrie magnétique
    let balanced: Bool      // true si bobinage triphasé équilibré

    var id: Int { poles }

    /// Cogging qualitatif basé sur LCM/S
    var coggingLabel: String {
        let ratio = lcmSP / max(poles, 1)
        if ratio >= 10 { return "Excellent" }
        if ratio >= 3  { return "Bon" }
        return "Modéré"
    }

    /// Score composite pour le tri (plus élevé = meilleur)
    var score: Float {
        var s: Float = kw1 * 100.0
        if balanced { s += 50.0 }
        s += Float(gcdSP) * 2.0                     // symétrie bonus
        s += min(Float(lcmSP) / Float(poles), 20.0)  // cogging bonus (plafonné)
        return s
    }
}

// ═══════════════════════════════════════════════════════════════
// MARK: - Motor Configuration Algorithm
// ═══════════════════════════════════════════════════════════════

enum MotorConfig {

    /// All valid stator slot counts (multiple of 3, 12…42)
    static let slotRange = stride(from: 12, through: 42, by: 3).map { $0 }

    /// Compute recommended pole configurations for a given slot count S.
    /// Returns candidates sorted by quality (best first).
    static func recommendPoles(forSlots S: Int) -> [PoleCandidate] {
        guard S >= 6 && S % 3 == 0 else { return [] }

        // P range : q ∈ [0.25, 1.5] → P ∈ [S/4.5, S/0.75]
        let pMin = max(4, Int(ceil(Float(S) / 4.5)))
        let pMax = min(S * 2, Int(floor(Float(S) / 0.75)))

        var candidates: [PoleCandidate] = []

        // Iterate even pole counts only
        let pStart = pMin % 2 == 0 ? pMin : pMin + 1
        for p in stride(from: pStart, through: pMax, by: 2) {
            let q = Float(S) / (3.0 * Float(p))

            // ── Balance check (star of slots) ──
            let halfP = p / 2
            let t = gcd(S, halfP)
            let qStar = S / t
            let isBalanced = (qStar % 3 == 0)

            // ── GCD / LCM ──
            let g = gcd(S, p)
            let l = S * p / g

            // ── Winding factor kw₁ = kd × kp ──
            let kw1 = computeKw1(slots: S, poles: p)

            candidates.append(PoleCandidate(
                poles: p, q: q, kw1: kw1,
                lcmSP: l, gcdSP: g, balanced: isBalanced
            ))
        }

        // Sort: balanced first, then by score descending
        candidates.sort { a, b in
            if a.balanced != b.balanced { return a.balanced }
            return a.score > b.score
        }

        return candidates
    }

    /// Top N balanced candidates (for Picker display).
    static func topBalanced(forSlots S: Int, count: Int = 4) -> [PoleCandidate] {
        let all = recommendPoles(forSlots: S)
        return Array(all.filter { $0.balanced }.prefix(count))
    }

    // ═══════════════════════════════════════════════════════════
    // MARK: - Winding Factor Computation
    // ═══════════════════════════════════════════════════════════

    /// Fundamental winding factor kw₁ = kd × kp
    /// using the star-of-slots phasor method + concentrated pitch factor.
    static func computeKw1(slots S: Int, poles P: Int) -> Float {
        guard S > 0 && P > 0 else { return 0 }

        // ── Pitch factor (concentrated coil, span = 1 slot) ──
        // kp = sin(π/2 × coil_span / pole_pitch)
        //    = sin(π × P / (2 × S))
        let kp = sin(Float.pi * Float(P) / (2.0 * Float(S)))

        // ── Distribution factor (phasor sum method) ──
        let alphaE = Float(P) * Float.pi / Float(S)  // electrical rad per slot

        var sumCos: Float = 0
        var sumSin: Float = 0
        var nPhaseA = 0

        for k in 0..<S {
            var theta = Float(k) * alphaE
            // Normalize to [-π, π]
            theta = theta.truncatingRemainder(dividingBy: 2.0 * Float.pi)
            if theta > Float.pi { theta -= 2.0 * Float.pi }
            if theta < -Float.pi { theta += 2.0 * Float.pi }

            let absTheta = abs(theta)

            // Phase A+ zone: |θ| ≤ π/6 (30°)
            if absTheta <= Float.pi / 6.0 + 0.01 {
                sumCos += cos(theta)
                sumSin += sin(theta)
                nPhaseA += 1
            }
            // Phase A− zone: |θ| ≥ 5π/6 (150°) — flip by 180°
            else if absTheta >= 5.0 * Float.pi / 6.0 - 0.01 {
                sumCos -= cos(theta)    // flip = cos(θ−π) = −cos(θ)
                sumSin -= sin(theta)    // flip = sin(θ−π) = −sin(θ)
                nPhaseA += 1
            }
        }

        guard nPhaseA > 0 else { return abs(kp) }

        let magnitude = sqrt(sumCos * sumCos + sumSin * sumSin)
        let kd = magnitude / Float(nPhaseA)

        return abs(kd * kp)
    }

    /// Electrical frequency at given RPM.
    /// f = (P/2) × (RPM / 60)
    static func electricalFrequency(poles P: Int, rpm: Float) -> Float {
        return Float(P) / 2.0 * rpm / 60.0
    }

    // ── GCD helper ──
    private static func gcd(_ a: Int, _ b: Int) -> Int {
        var x = abs(a), y = abs(b)
        while y != 0 {
            let t = y
            y = x % y
            x = t
        }
        return x
    }
}
