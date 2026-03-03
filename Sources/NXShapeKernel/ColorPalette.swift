// ColorPalette.swift
// Genolanx — Named color palette (port of LEAP71 ShapeKernel ColorPalette Cp)

import PicoGKBridge

/// Color palette matching PicoGK's Cp class naming.
enum Cp {
    static let clrGray      = PKColorFloat(r: 0.5,  g: 0.5,  b: 0.5,  a: 1.0)
    static let clrRock      = PKColorFloat(r: 0.45, g: 0.40, b: 0.35, a: 1.0)
    static let clrCrystal   = PKColorFloat(r: 0.7,  g: 0.8,  b: 0.9,  a: 0.8)
    static let clrWarning   = PKColorFloat(r: 0.9,  g: 0.6,  b: 0.1,  a: 1.0)
    static let clrFrozen    = PKColorFloat(r: 0.6,  g: 0.75, b: 0.85, a: 1.0)
    static let clrHot       = PKColorFloat(r: 0.9,  g: 0.2,  b: 0.1,  a: 1.0)
    static let clrGreen     = PKColorFloat(r: 0.2,  g: 0.8,  b: 0.3,  a: 1.0)
    static let clrBlue      = PKColorFloat(r: 0.2,  g: 0.4,  b: 0.9,  a: 1.0)
    static let clrGold      = PKColorFloat(r: 0.85, g: 0.7,  b: 0.3,  a: 1.0)
    static let clrCopper    = PKColorFloat(r: 0.72, g: 0.45, b: 0.2,  a: 1.0)
    static let clrSilver    = PKColorFloat(r: 0.75, g: 0.75, b: 0.8,  a: 1.0)
    static let clrBlack     = PKColorFloat(r: 0.1,  g: 0.1,  b: 0.1,  a: 1.0)
    static let clrRed       = PKColorFloat(r: 0.9,  g: 0.15, b: 0.1,  a: 1.0)
    static let clrYellow    = PKColorFloat(r: 0.95, g: 0.85, b: 0.2,  a: 1.0)
    static let clrPitaya    = PKColorFloat(r: 0.85, g: 0.2,  b: 0.55, a: 1.0)
    static let clrToothpaste = PKColorFloat(r: 0.4, g: 0.85, b: 0.85, a: 1.0)
    static let clrRacingGreen = PKColorFloat(r: 0.0, g: 0.42, b: 0.24, a: 1.0)
    static let clrNavy      = PKColorFloat(r: 0.0,  g: 0.0,  b: 0.33, a: 1.0)
}
