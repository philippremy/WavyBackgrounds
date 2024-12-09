//
//  MTLSpacesViewRenderer.swift
//  WavyBackgrounds
//
//  Created by Philipp Remy on 13.11.24.
//

import Foundation
import Metal
import MetalKit

import WavyBackgroundsKit

public final class MTLSpacesRenderer: NSObject, MTKViewDelegate {
    
    // Global State, will be updated if necessary
    public var globalState: GlobalViewState
    
    // Internal Locks
    private let internalLockVertexBuffers = NSRecursiveLock()
    private let internalLockMTLTextures = NSRecursiveLock()
    
    // Metal Stuff
    private let pipelineState: MTLRenderPipelineState
    public let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let samplerDescriptor: MTLSamplerDescriptor
    private let sampler: MTLSamplerState
    private let vertices = [
        Vertex(position: SIMD4<Float>(Float(-1), Float(-1), Float(0), Float(1)), texCoords: SIMD2<Float>(Float(0), Float(1))),
        Vertex(position: SIMD4<Float>(Float(1), Float(-1), Float(0), Float(1)), texCoords: SIMD2<Float>(Float(1), Float(1))),
        Vertex(position: SIMD4<Float>(Float(-1), Float(1), Float(0), Float(1)), texCoords: SIMD2<Float>(Float(0), Float(0))),
        
        Vertex(position: SIMD4<Float>(Float(1), Float(-1), Float(0), Float(1)), texCoords: SIMD2<Float>(Float(1), Float(1))),
        Vertex(position: SIMD4<Float>(Float(1), Float(1), Float(0), Float(1)), texCoords: SIMD2<Float>(Float(1), Float(0))),
        Vertex(position: SIMD4<Float>(Float(-1), Float(1), Float(0), Float(1)), texCoords: SIMD2<Float>(Float(0), Float(0))),
    ]
    private var cachedMTLTextures: Dictionary<SLSSpaceID, MTLTexture> = [:];
    
    // Buffers
    private var padding: [[Float]] = []
    private var paddingBuffer: [MTLBuffer] = [];
    private var paddingGlobal: [Float] = []
    private var paddingGlobalBuffer: MTLBuffer;
    private var offsets: [[Float]] = []
    private var offsetBuffers: [MTLBuffer] = []
    private var vertexBufferArray: [MTLBuffer] = []
    private var numberOfSpacesArray: [Float] = []
    private let numberOfSpacesBuffer: MTLBuffer
    private let uniformBuffer: MTLBuffer
    private let aspectRatio: [Float] = [Float(getAspectRatioDecimal())]
    
    init(globalState: GlobalViewState) {
        
        // Set initial global View state
        self.globalState = globalState
        
        // Initialize Metal Variables
        self.device = MTLCreateSystemDefaultDevice()!
        self.commandQueue = self.device.makeCommandQueue()!
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = device.makeDefaultLibrary()?.makeFunction(name: "vertex_main")
        pipelineDescriptor.fragmentFunction = device.makeDefaultLibrary()?.makeFunction(name: "fragment_main")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        self.pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        self.samplerDescriptor = MTLSamplerDescriptor()
        self.sampler = device.makeSamplerState(descriptor: self.samplerDescriptor)!
        
        // Initialize Buffers
        self.paddingGlobal.append(Float(self.globalState.spacesViewPadding))
        self.paddingGlobalBuffer = device.makeBuffer(bytes: self.paddingGlobal, length: self.paddingGlobal.count * MemoryLayout<Float>.stride)!
        // Size Offset Padding to required size
        self.paddingBuffer.reserveCapacity(self.globalState.spaceIDs.count)
        // Fill Padding Buffer
        for index in 0...(self.globalState.spaceIDs.count == 0 ? self.globalState.spaceIDs.count : self.globalState.spaceIDs.count-1) {
            if index != 0 {
                self.padding.append([Float(Float(self.globalState.spacesViewPadding) * Float(index))])
            } else {
                self.padding.append([Float(0)])
            }
            self.paddingBuffer.append(device.makeBuffer(bytes: self.padding[index], length: self.padding[index].count * MemoryLayout<Float>.stride)!)
        }
        self.numberOfSpacesArray.append(Float(self.globalState.spaceIDs.count))
        self.numberOfSpacesBuffer = device.makeBuffer(bytes: self.numberOfSpacesArray, length: MemoryLayout<Float>.stride * self.numberOfSpacesArray.count)!
        self.uniformBuffer = device.makeBuffer(bytes: self.aspectRatio, length: self.aspectRatio.count * MemoryLayout<Float>.stride)!
        
        // super.init() needs to be called before we change the DispatchQueue
        super.init()
        
        // Initialize the Vertex Buffer concurrently
        DispatchQueue.global().asyncAndWait {
            DispatchQueue.concurrentPerform(iterations: self.globalState.spaceIDs.count, execute: { index in
                // Vertex Buffers
                self.internalLockVertexBuffers.lock()
                self.vertexBufferArray.append(device.makeBuffer(bytes: self.vertices, length: self.vertices.count * MemoryLayout<Vertex>.stride)!)
                self.internalLockVertexBuffers.unlock()
            })
        }
        
    }
    
    func generateMTLTexturesFromIOSurfaces() -> Dictionary<SLSSpaceID, MTLTexture> {
        var mtlTextureDict: Dictionary<SLSSpaceID, MTLTexture> = [:]
        DispatchQueue.concurrentPerform(iterations: self.globalState.spaceIDs.count, execute: { index in
            var ioSurface: IOSurfaceRef? = nil
            
            let request = prepareSpaceIOSurfaceCaptureServiceRequest(requestType: .RequestIOSurfaceForSpaceID, spaceID: self.globalState.spaceIDs[index])
            do {
                let answer = try self.globalState.spaceCaptureServiceConnection.sendSync(message: request)
                guard let xpcResponse: xpc_object_t = answer["xpcResponse"] else {
                    print("Reponse entry in XPCDictionary not found.")
                    return
                }
                guard let xpcReponseDecoded = decodeToSpaceIOSurfaceCaptureServiceResponse(xpcObj: xpcResponse) else {
                    print("Reponse object could not be decoded.")
                    return
                }
                switch xpcReponseDecoded.requestType {
                case .Error:
                    // print(xpcReponseDecoded.error)
                    return
                case .Ok:
                    guard let ioSurfaceXPCObject: xpc_object_t = answer["ioSurfaceXPCObject"] else {
                        print("Could not extract XPCObject for IOSurfaceRef, altough it should be available.")
                        return
                    }
                    guard let ioSurfaceRef = IOSurfaceLookupFromXPCObject(ioSurfaceXPCObject) else {
                        print("Could not lookup IOSurfaceRef from xpc_object_t.")
                        return
                    }
                    ioSurface = ioSurfaceRef
                    break
                default:
                    return
                }
            } catch {
                print(error)
            }
            
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .bgra8Unorm,
                width: ioSurface == nil ? 1 : IOSurfaceGetWidth(ioSurface!),
                height: ioSurface == nil ? 1 : IOSurfaceGetHeight(ioSurface!),
                mipmapped: false
            )
            textureDescriptor.usage = [.shaderRead]
            textureDescriptor.storageMode = .managed
            textureDescriptor.resourceOptions = .storageModeManaged
            self.internalLockMTLTextures.lock()
            if ioSurface == nil {
                mtlTextureDict[self.globalState.spaceIDs[index]] = self.cachedMTLTextures[self.globalState.spaceIDs[index]]
            } else {
                let tex = device.makeTexture(descriptor: textureDescriptor, iosurface: ioSurface!, plane: 0)!
                mtlTextureDict[self.globalState.spaceIDs[index]] = tex
                self.cachedMTLTextures[self.globalState.spaceIDs[index]] = tex
            }
            self.internalLockMTLTextures.unlock()
        })
        return mtlTextureDict
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Not required to implement
    }
    
    public func draw(in view: MTKView) {
        let workItem = DispatchWorkItem(block: {
         
            guard let commandBuffer = self.commandQueue.makeCommandBuffer(),
                  let renderPassDescriptor = view.currentRenderPassDescriptor,
                  let drawable = view.currentDrawable
            else {
                print("Could not perform draw!")
                return
            }
            
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: self.globalState.currentBackgroundColor.usingColorSpace(.deviceRGB)!.redComponent, green: self.globalState.currentBackgroundColor.usingColorSpace(.deviceRGB)!.greenComponent, blue: self.globalState.currentBackgroundColor.usingColorSpace(.deviceRGB)!.blueComponent, alpha: self.globalState.currentBackgroundColor.usingColorSpace(.deviceRGB)!.alphaComponent)
            renderPassDescriptor.colorAttachments[0].loadAction = .clear
            renderPassDescriptor.colorAttachments[0].storeAction = .store
            guard let encoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: renderPassDescriptor
            ) else {
                print("Could not create encoder.")
                return
            }
            
            encoder.setRenderPipelineState(self.pipelineState)
            
            // Always recreate offsets
            // Size Offset Buffer to required size
            self.offsetBuffers.removeAll(keepingCapacity: true)
            self.offsetBuffers.reserveCapacity(self.globalState.spaceIDs.count)
            // Fill Offset Buffer
            for index in 0...(self.globalState.spaceIDs.count == 0 ? self.globalState.spaceIDs.count : self.globalState.spaceIDs.count) {
                self.offsets.append([Float(index)])
                self.offsetBuffers.append(self.device.makeBuffer(bytes: self.offsets[index], length: self.offsets[index].count * MemoryLayout<Float>.stride)!)
            }
            
            // Update buffers if size changes
            if self.globalState.spaceIDs.count != self.vertexBufferArray.count || self.paddingGlobal[0] != Float(self.globalState.spacesViewPadding) {
                
                // Number of Spaces Buffer
                self.numberOfSpacesArray[0] = Float(self.globalState.spaceIDs.count)
                memcpy(self.numberOfSpacesBuffer.contents(), self.numberOfSpacesArray, self.numberOfSpacesArray.count * MemoryLayout<Float>.stride)
                
                // Recreate Padding
                self.paddingGlobal[0] = Float(self.globalState.spacesViewPadding)
                memcpy(self.paddingGlobalBuffer.contents(), self.paddingGlobal, self.paddingGlobal.count * MemoryLayout<Float>.stride)
                if self.globalState.spaceIDs.count == self.vertexBufferArray.count {
                    self.padding.removeAll(keepingCapacity: true)
                    for index in 0...self.globalState.spaceIDs.count-1 {
                        if index != 0 {
                            self.padding.append([Float(Float(self.globalState.spacesViewPadding) * Float(index))])
                        } else {
                            self.padding.append([Float(0)])
                        }
                        memcpy(self.paddingBuffer[index].contents(), self.padding[index], self.padding[index].count * MemoryLayout<Float>.stride)
                    }
                } else {
                    self.padding.removeAll(keepingCapacity: false)
                    if self.globalState.spaceIDs.count < self.vertexBufferArray.count {
                        while self.globalState.spaceIDs.count < self.paddingBuffer.count {
                            self.paddingBuffer.removeLast()
                        }
                    } else {
                        while self.globalState.spaceIDs.count > self.paddingBuffer.count {
                            self.paddingBuffer.append(self.device.makeBuffer(length: MemoryLayout<Float>.stride)!)
                        }
                    }
                    for index in 0...self.globalState.spaceIDs.count-1 {
                        if index != 0 {
                            self.padding.append([Float(Float(self.globalState.spacesViewPadding) * Float(index))])
                        } else {
                            self.padding.append([Float(0)])
                        }
                        memcpy(self.paddingBuffer[index].contents(), self.padding[index], self.padding[index].count * MemoryLayout<Float>.stride)
                    }
                }
                
                // Vertex Buffer (do last, because this is the origin of truth for how long the other buffers should be!)
                if self.globalState.spaceIDs.count < self.vertexBufferArray.count {
                    while self.globalState.spaceIDs.count < self.vertexBufferArray.count {
                        self.vertexBufferArray.removeLast()
                    }
                } else {
                    while self.globalState.spaceIDs.count > self.vertexBufferArray.count {
                        self.vertexBufferArray.append(self.device.makeBuffer(bytes: self.vertices, length:  self.vertices.count * MemoryLayout<Vertex>.stride)!)
                    }
                }
                
            }
            
            // Fetch textures
            let textures = self.generateMTLTexturesFromIOSurfaces()
            
            for (index, spaceID) in self.globalState.spaceIDs.enumerated() {
                let vertexBuffer = self.vertexBufferArray[index]
                encoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
                encoder.setVertexBuffer(self.uniformBuffer, offset: 0, index: 1)
                encoder.setVertexBuffer(self.offsetBuffers[index], offset: 0, index: 2)
                encoder.setVertexBuffer(self.numberOfSpacesBuffer, offset: 0, index: 3)
                encoder.setVertexBuffer(self.paddingBuffer[index], offset: 0, index: 4)
                encoder.setVertexBuffer(self.paddingGlobalBuffer, offset: 0, index: 5)
                encoder.setFragmentTexture(textures[spaceID], index: 0)
                encoder.setFragmentSamplerState(self.sampler, index: 0)
                encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: self.vertices.count)
            }
            
            encoder.endEncoding()
            
            commandBuffer.present(drawable)
            commandBuffer.commit()
            
        })
        DispatchQueue.global().asyncAndWait(execute: workItem)
    }
    
}
