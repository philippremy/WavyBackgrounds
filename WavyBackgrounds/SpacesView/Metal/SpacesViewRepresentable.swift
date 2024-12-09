//
//  SpacesViewRepresentable.swift
//  WavyBackgrounds
//
//  Created by Philipp Remy on 13.11.24.
//

import Foundation
import Metal
import MetalKit
import SwiftUI

struct SpacesViewRepresentable: NSViewRepresentable {
    
    typealias NSViewType = MTKView
    
    class Coordinator: NSObject {
        var parent: SpacesViewRepresentable

        init(_ parent: SpacesViewRepresentable) {
            self.parent = parent
        }
    }
    
    @EnvironmentObject var globalState: GlobalViewState
    
    public let renderer: MTLSpacesRenderer
    
    func makeNSView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero)
        view.device = MTLCreateSystemDefaultDevice()
        view.delegate = renderer
        view.framebufferOnly = false
        view.preferredFramesPerSecond = self.globalState.fps
        return view
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        nsView.preferredFramesPerSecond = self.globalState.fps
        self.renderer.globalState = context.coordinator.parent.globalState
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
}
