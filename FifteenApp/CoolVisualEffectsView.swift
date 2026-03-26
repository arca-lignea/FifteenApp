//
//  CoolVisualEffectsView.swift
//  FifteenApp
//
//  Created by sophie on 2026-03-07.
//

import Foundation
import SwiftUI

struct CoolVisualEffectsView: View {
    @State private var isAnimating = false
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Animated glowing circle
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.8),
                                Color.purple.opacity(0.4)
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 60
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.cyan, radius: isAnimating ? 30 : 10)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                // Rotating gradient square
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.pink,
                                Color.orange,
                                Color.yellow,
                                Color.pink
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(rotation))
                    .onAppear {
                        withAnimation(
                            Animation.linear(duration: 4).repeatForever(autoreverses: false)
                        ) {
                            rotation = 360
                        }
                    }
                
                
                // Stacked cards with parallax effect
                ZStack(alignment: .bottom) {
                    ForEach(0..<3, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 15)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue.opacity(0.7 - Double(index) * 0.1),
                                        Color.purple.opacity(0.7 - Double(index) * 0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 120)
                            .offset(y: CGFloat(index) * 20)
                            .scaleEffect(1.0 - CGFloat(index) * 0.05, anchor: .bottom)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.top, 60)
        }
    }
}

#Preview {
    CoolVisualEffectsView()
}
