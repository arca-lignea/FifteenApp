import SwiftUI

struct InteractiveTouchEffectsView: View {
    @State private var tapLocation: CGPoint = .zero
    @State private var isPressed = false
    @State private var particleEffects: [ParticleEffect] = []
    @State private var dragOffset: CGSize = .zero
    @State private var ripples: [RippleEffect] = []
    @State private var lastParticleTime: Date = Date()
    @State private var orbHue: Double = 0.5
    @State private var isHoveringRipple = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 50) {
                // Interactive ripple effect
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(isHoveringRipple ? 0.8 : 1.0)
                    
                    ForEach(ripples.indices, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.cyan,
                                        Color.blue.opacity(0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: ripples[index].size, height: ripples[index].size)
                            .opacity(ripples[index].opacity)
                            .animation(.easeOut(duration: 0.8), value: ripples[index].size)
                    }
                    
                    Text("Tap for Ripple Effect")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
                .frame(height: 200)
                .padding(.horizontal, 20)
                .gesture(
                    TapGesture()
                        .onEnded { _ in
                            addRipple(at: tapLocation)
                        }
                )
                .onHover { isHovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isHoveringRipple = isHovering
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            tapLocation = value.location
                        }
                )
                
                // Touch-responsive gradient orb
                ZStack {
                    // Glowing background circle
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(hue: orbHue, saturation: 0.8, brightness: 0.9),
                                    Color(hue: orbHue, saturation: 0.8, brightness: 0.3).opacity(0)
                                ]),
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .shadow(
                            color: Color(hue: orbHue, saturation: 0.8, brightness: 0.9).opacity(0.6),
                            radius: isPressed ? 40 : 20
                        )
                    
                    // Main orb
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(hue: orbHue, saturation: 0.7, brightness: 1.0),
                                    Color(hue: orbHue, saturation: 0.8, brightness: 0.6)
                                ]),
                                center: .topLeading,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(isPressed ? 1.15 : 1.0)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    withAnimation(.easeOut(duration: 0.1)) {
                                        isPressed = true
                                        orbHue = Double(value.location.x) / 400.0
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        isPressed = false
                                    }
                                }
                        )
                    
                    Text(isPressed ? "↓" : "↑")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .animation(.easeInOut(duration: 0.2), value: isPressed)
                }
                .frame(height: 250)
                
                // Draggable particle emitter
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.pink.opacity(0.2),
                                    Color.orange.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.pink,
                                    Color.red
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .offset(dragOffset)
                        .shadow(color: Color.pink.opacity(0.8), radius: 15)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation
                                    
                                    if Date().timeIntervalSince(lastParticleTime) > 0.05 {
                                        emitParticle(at: value.location)
                                        lastParticleTime = Date()
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        dragOffset = .zero
                                    }
                                }
                        )
                    
                    Text("Drag Me")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                        .offset(dragOffset)
                }
                .frame(height: 200)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 40)
            
            // Particle effects overlay
            ForEach(particleEffects.indices, id: \.self) { index in
                ParticleDisplayView(effect: particleEffects[index])
            }
        }
    }
    
    private func addRipple(at location: CGPoint) {
        let rippleID = UUID()
        let newRipple = RippleEffect(id: rippleID, location: location)
        ripples.append(newRipple)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if let index = ripples.firstIndex(where: { $0.id == rippleID }) {
                withAnimation(.easeOut(duration: 0.8)) {
                    ripples[index].size = 300
                    ripples[index].opacity = 0
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            ripples.removeAll { $0.id == rippleID }
        }
    }
    
    private func emitParticle(at location: CGPoint) {
        let colors: [Color] = [.pink, .orange, .red, .yellow]
        let randomColor = colors.randomElement() ?? .pink
        
        let particle = ParticleEffect(
            location: location,
            color: randomColor,
            velocity: CGVector(
                dx: CGFloat.random(in: -2...2),
                dy: CGFloat.random(in: -4...0)
            )
        )
        
        particleEffects.append(particle)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            particleEffects.removeAll { $0.id == particle.id }
        }
    }
}

// MARK: - Particle Display View
struct ParticleDisplayView: View {
    let effect: ParticleEffect
    @State private var position: CGPoint
    @State private var opacity: Double = 1.0
    
    init(effect: ParticleEffect) {
        self.effect = effect
        _position = State(initialValue: effect.location)
    }
    
    var body: some View {
        Circle()
            .fill(effect.color)
            .frame(width: 8, height: 8)
            .position(position)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    position = CGPoint(
                        x: position.x + effect.velocity.dx * 50,
                        y: position.y + effect.velocity.dy * 50
                    )
                    opacity = 0
                }
            }
    }
}

// MARK: - Data Models
struct RippleEffect: Identifiable {
    let id: UUID
    let location: CGPoint
    var size: CGFloat = 0
    var opacity: Double = 1.0
}

struct ParticleEffect: Identifiable {
    let id: UUID = UUID()
    let location: CGPoint
    let color: Color
    let velocity: CGVector
}

#Preview {
    InteractiveTouchEffectsView()
}
