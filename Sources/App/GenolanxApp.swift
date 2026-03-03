// GenolanxApp.swift
// Genolanx — macOS native computational engineering application
//
// Swift/Metal port of PicoGK + ShapeKernel + Morland components
// Built on picogk.1.7.dylib (ARM64 OpenVDB geometry kernel)

import SwiftUI

@main
struct GenolanxApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1400, height: 800)
    }
}
