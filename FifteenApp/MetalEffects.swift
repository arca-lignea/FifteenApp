import SwiftUI
import Metal
import MetalKit

// MARK: - Metal Renderer
class MetalRenderer: NSObject, MTKViewDelegate {
    var commandQueue: MTLCommandQueue?
    var pipelineState: MTLRenderPipelineState?
    var time: Float = 0
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle resize if needed
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
              let pipelineState = pipelineState else { return }
        
        time += 0.016 // ~60 FPS
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        var timeData = time
        renderEncoder.setVertexBytes(&timeData, length: MemoryLayout<Float>.size, index: 0)
        renderEncoder.setFragmentBytes(&timeData, length: MemoryLayout<Float>.size, index: 0)
        
        // Draw full screen quad
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - Metal View Representation
struct MetalViewRepresentable: UIViewRepresentable {
    var renderer: MetalRenderer
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        
        mtkView.device = device
        mtkView.delegate = renderer
        renderer.commandQueue = device.makeCommandQueue()
        
        // Create shader library and pipeline
        let library = device.makeDefaultLibrary()
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "vertexShader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "fragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        renderer.pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        mtkView.preferredFramesPerSecond = 60
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {}
}

// MARK: - SwiftUI View
struct MetalVisualEffectsView: View {
    @State private var renderer = MetalRenderer()
    
    var body: some View {
        ZStack {
            MetalViewRepresentable(renderer: renderer)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Text("Metal Visual Effects")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                .background(Color.black.opacity(0.5))
                
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Procedural Shader Effects")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 20) {
                        Label("60 FPS", systemImage: "bolt.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Label("GPU Rendered", systemImage: "square.and.pencil")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
                .padding()
            }
        }
    }
}

#Preview {
    MetalVisualEffectsView()
}
