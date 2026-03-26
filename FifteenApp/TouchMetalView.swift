import SwiftUI
import Metal
import MetalKit

// MARK: - Touch Handler
class TouchHandler: NSObject, UIGestureRecognizerDelegate {
    var touchPoints: [SIMD2<Float>] = Array(repeating: SIMD2<Float>(0, 0), count: 10)
    var touchActive: [Bool] = Array(repeating: false, count: 10)
    
    func updateTouchPoint(_ point: CGPoint, at index: Int) {
        guard index < touchPoints.count else { return }
        
        let normalized = SIMD2<Float>(
            Float(point.x),
            Float(point.y)
        )
        
        touchPoints[index] = normalized
        touchActive[index] = true
    }
    
    func releaseTouchPoint(at index: Int) {
        guard index < touchActive.count else { return }
        touchActive[index] = false
    }
}

// MARK: - Metal Renderer with Touch
class TouchMetalRenderer: NSObject, MTKViewDelegate {
    var commandQueue: MTLCommandQueue?
    var pipelineState: MTLRenderPipelineState?
    var time: Float = 0
    var touchHandler = TouchHandler()
    var screenSize: SIMD2<Float> = SIMD2(1440, 3120)
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        screenSize = SIMD2<Float>(Float(size.width), Float(size.height))
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let descriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue?.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor),
              let pipelineState = pipelineState else { return }
        
        time += 0.016
        
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Pass time
        var timeData = time
        renderEncoder.setVertexBytes(&timeData, length: MemoryLayout<Float>.size, index: 0)
        renderEncoder.setFragmentBytes(&timeData, length: MemoryLayout<Float>.size, index: 0)
        
        // Pass screen size
        var screenData = screenSize
        renderEncoder.setFragmentBytes(&screenData, length: MemoryLayout<SIMD2<Float>>.size, index: 1)
        
        // Ensure touch points array is properly sized
        var touchPointsBuffer = touchHandler.touchPoints
        if touchPointsBuffer.isEmpty {
            touchPointsBuffer = Array(repeating: SIMD2<Float>(0, 0), count: 10)
        }
        
        // Pass touch points - FIX: Use proper buffer size
        renderEncoder.setFragmentBytes(&touchPointsBuffer,
                                      length: MemoryLayout<SIMD2<Float>>.size * 10,
                                      index: 2)
        
        // Pass touch active states - FIX: Use proper buffer size
        var touchActiveBuffer = touchHandler.touchActive
        if touchActiveBuffer.isEmpty {
            touchActiveBuffer = Array(repeating: false, count: 10)
        }
        
        renderEncoder.setFragmentBytes(&touchActiveBuffer,
                                      length: MemoryLayout<Bool>.size * 10,
                                      index: 3)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

// MARK: - Metal View with Touch Handling
struct TouchMetalViewRepresentable: UIViewRepresentable {
    var renderer: TouchMetalRenderer
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported")
        }
        
        mtkView.device = device
        mtkView.delegate = renderer
        renderer.commandQueue = device.makeCommandQueue()
        
        // Setup pipeline
        let library = device.makeDefaultLibrary()
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = library?.makeFunction(name: "touchVertexShader")
        pipelineDescriptor.fragmentFunction = library?.makeFunction(name: "touchFragmentShader")
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        renderer.pipelineState = try? device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        mtkView.clearColor = MTLClearColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1.0)
        mtkView.preferredFramesPerSecond = 60
        
        // Add touch handling
        let touchGesture = UITouchableView(renderer: renderer)
        mtkView.addSubview(touchGesture)
        touchGesture.frame = mtkView.bounds
        touchGesture.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {}
}

// MARK: - Touch Detection View
class UITouchableView: UIView {
    var renderer: TouchMetalRenderer
    var touchMapping: [UITouch: Int] = [:]
    
    init(renderer: TouchMetalRenderer) {
        self.renderer = renderer
        super.init(frame: .zero)
        self.isUserInteractionEnabled = true
        self.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for (index, touch) in touches.enumerated() where index < 10 {
            let location = touch.location(in: self)
            renderer.touchHandler.updateTouchPoint(location, at: index)
            touchMapping[touch] = index
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let index = touchMapping[touch] {
                let location = touch.location(in: self)
                renderer.touchHandler.updateTouchPoint(location, at: index)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let index = touchMapping[touch] {
                renderer.touchHandler.releaseTouchPoint(at: index)
                touchMapping.removeValue(forKey: touch)
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let index = touchMapping[touch] {
                renderer.touchHandler.releaseTouchPoint(at: index)
                touchMapping.removeValue(forKey: touch)
            }
        }
    }
}

// MARK: - SwiftUI View
struct TouchMetalVisualEffectsView: View {
    @State private var renderer = TouchMetalRenderer()
    @State private var touchCount = 0
    
    var body: some View {
        ZStack {
            TouchMetalViewRepresentable(renderer: renderer)
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    Text("Touch Responsive Metal Effects")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
                .background(Color.black.opacity(0.5))
                
                Spacer()
                
                VStack(spacing: 16) {
                    Text("Multi-Touch Interactive Shaders")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Touch Points: \(renderer.touchHandler.touchActive.filter { $0 }.count)", systemImage: "touchid")
                                .font(.caption)
                                .foregroundColor(.cyan)
                            
                            Text("Tap and drag to create ripples")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Label("GPU Rendered", systemImage: "bolt.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Label("60 FPS", systemImage: "speedometer")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.black.opacity(0.5))
                .cornerRadius(12)
                .padding()
            }
        }
    }
}

#Preview {
    TouchMetalVisualEffectsView()
}
