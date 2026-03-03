// ViewportView.swift
// Genolanx — MTKView embedded in SwiftUI via NSViewRepresentable

import SwiftUI
import MetalKit

struct ViewportView: NSViewRepresentable {
    @ObservedObject var sceneManager: SceneManager

    func makeNSView(context: Context) -> MTKView {
        let mtkView = NXMetalView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = false // Continuous rendering
        mtkView.isPaused = false

        let renderer = MetalRenderer(metalView: mtkView)
        mtkView.renderer = renderer

        DispatchQueue.main.async {
            sceneManager.renderer = renderer
        }

        return mtkView
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}
}

// MARK: - Custom MTKView subclass for mouse/keyboard handling

final class NXMetalView: MTKView {
    weak var renderer: MetalRenderer?

    private var isDragging = false
    private var previousMouseLocation: CGPoint = .zero

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        isDragging = true
        previousMouseLocation = convert(event.locationInWindow, from: nil)
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard isDragging else { return }
        let location = convert(event.locationInWindow, from: nil)
        let dx = Float(location.x - previousMouseLocation.x)
        let dy = Float(location.y - previousMouseLocation.y)
        renderer?.camera.handleDrag(delta: SIMD2(dx, -dy)) // Invert Y for natural feel
        previousMouseLocation = location
    }

    override func rightMouseDragged(with event: NSEvent) {
        // Right-drag for pan (future enhancement)
    }

    override func scrollWheel(with event: NSEvent) {
        if event.hasPreciseScrollingDeltas {
            // Trackpad: use magnification-style zoom
            renderer?.camera.handleScroll(delta: Float(-event.scrollingDeltaY) / 10.0)
        } else {
            // Mouse wheel
            renderer?.camera.handleScroll(delta: Float(-event.scrollingDeltaY))
        }
    }

    override func magnify(with event: NSEvent) {
        renderer?.camera.handleMagnify(magnification: Float(event.magnification))
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 123: // Left arrow
            renderer?.camera.snapToNearest(horizontal: true, direction: -1)
        case 124: // Right arrow
            renderer?.camera.snapToNearest(horizontal: true, direction: 1)
        case 125: // Down arrow
            renderer?.camera.snapToNearest(horizontal: false, direction: -1)
        case 126: // Up arrow
            renderer?.camera.snapToNearest(horizontal: false, direction: 1)
        case 15:  // R key — reset camera
            renderer?.camera.reset()
        case 5:   // G key — toggle grid
            renderer?.showGrid.toggle()
        default:
            super.keyDown(with: event)
        }
    }
}
