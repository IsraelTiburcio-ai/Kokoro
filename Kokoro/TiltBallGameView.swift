//
//  TiltBallGameView.swift
//  Kokoro
//
//  Created by Cristian Yair Gómez Herrera on 23/03/26.
//

import SwiftUI
import CoreMotion
import Combine

struct TiltBallGameView: View {
    
    @StateObject private var motionManager = MotionManager()
    
    @State private var ballPosition: CGPoint = CGPoint(x: 180, y: 300)
    @State private var holePosition: CGPoint = CGPoint(x: 280, y: 550)
    @State private var hasWon = false
    
    @State private var velocity: CGSize = .zero
    
    let ballSize: CGFloat = 32
    let holeSize: CGFloat = 46
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                
                LinearGradient(
                    colors: [
                        Color(red: 0.93, green: 0.95, blue: 1.0),
                        Color(red: 0.89, green: 0.92, blue: 0.98),
                        Color(red: 0.95, green: 0.90, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                RoundedRectangle(cornerRadius: 30)
                    .fill(Color.white.opacity(0.45))
                    .padding(20)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 8)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.black.opacity(0.85),
                                Color.black.opacity(0.95)
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: holeSize / 2
                        )
                    )
                    .frame(width: holeSize, height: holeSize)
                    .position(holePosition)
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white,
                                Color(red: 0.75, green: 0.80, blue: 0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: ballSize, height: ballSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.7), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 6)
                    .position(ballPosition)
                
                VStack(spacing: 8) {
                    Text("Lleva la bolita al hoyo")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.22, green: 0.22, blue: 0.35))
                    
                    Text("Inclina tu teléfono con suavidad")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.40, green: 0.42, blue: 0.55))
                }
                .padding(.top, 30)
                .frame(maxHeight: .infinity, alignment: .top)
                
                VStack {
                    Spacer()
                    
                    Button {
                        resetGame(in: geometry.size)
                    } label: {
                        Text("Reiniciar")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.57, green: 0.49, blue: 0.92),
                                        Color(red: 0.45, green: 0.39, blue: 0.82)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 5)
                    }
                    .padding(.bottom, 35)
                }
                
                if hasWon {
                    ZStack {
                        Color.black.opacity(0.18)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            Text("¡Muy bien!")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.22, green: 0.22, blue: 0.35))
                            
                            Text("Lograste meter la bolita en el hoyo.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.35, green: 0.36, blue: 0.48))
                                .multilineTextAlignment(.center)
                            
                            Button {
                                resetGame(in: geometry.size)
                            } label: {
                                Text("Jugar otra vez")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 26)
                                    .padding(.vertical, 14)
                                    .background(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.50, green: 0.75, blue: 0.55),
                                                Color(red: 0.38, green: 0.64, blue: 0.44)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(28)
                        .frame(maxWidth: 300)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
                    }
                }
            }
            .onAppear {
                resetGame(in: geometry.size)
                motionManager.startUpdates()
            }
            .onDisappear {
                motionManager.stopUpdates()
            }
            .onReceive(motionManager.$tilt) { tilt in
                guard !hasWon else { return }
                updateBallPosition(tilt: tilt, boardSize: geometry.size)
                checkWin()
            }
        }
    }
    
    private func updateBallPosition(tilt: CGSize, boardSize: CGSize) {
        
        let accelerationFactor: CGFloat = 0.9   // qué tan fuerte responde al tilt
        let maxVelocity: CGFloat = 25           // límite de velocidad
        let friction: CGFloat = 0.98            // desaceleración
        
        // 1. Aplicar aceleración
        velocity.width += tilt.width * accelerationFactor
        velocity.height += tilt.height * accelerationFactor
        
        // 2. Limitar velocidad (para que no se vuelva imposible)
        velocity.width = min(max(velocity.width, -maxVelocity), maxVelocity)
        velocity.height = min(max(velocity.height, -maxVelocity), maxVelocity)
        
        // 3. Aplicar fricción
        velocity.width *= friction
        velocity.height *= friction
        
        // 4. Mover bola con velocidad acumulada
        var newX = ballPosition.x + velocity.width
        var newY = ballPosition.y + velocity.height
        
        let minX = 20 + ballSize / 2
        let maxX = boardSize.width - 20 - ballSize / 2
        let minY = 20 + ballSize / 2
        let maxY = boardSize.height - 20 - ballSize / 2
        
        // 5. Colisiones con bordes (rebote suave)
        if newX < minX {
            newX = minX
            velocity.width *= -0.4
        }
        if newX > maxX {
            newX = maxX
            velocity.width *= -0.4
        }
        if newY < minY {
            newY = minY
            velocity.height *= -0.4
        }
        if newY > maxY {
            newY = maxY
            velocity.height *= -0.4
        }
        
        
        ballPosition = CGPoint(x: newX, y: newY)
    }
    
    private func checkWin() {
        let dx = ballPosition.x - holePosition.x
        let dy = ballPosition.y - holePosition.y
        let distance = sqrt(dx * dx + dy * dy)

        if distance < 18 {
            hasWon = true
            
            velocity = .zero
            
            withAnimation(.easeIn(duration: 0.3)) {
                ballPosition = holePosition
            }
        }
    }
    
    private func resetGame(in size: CGSize) {
        hasWon = false
        ballPosition = CGPoint(x: size.width * 0.3, y: size.height * 0.35)
        holePosition = CGPoint(x: size.width * 0.75, y: size.height * 0.72)
    }
}

final class MotionManager: ObservableObject {
    
    private let manager = CMMotionManager()
    
    @Published var tilt: CGSize = .zero
    
    func startUpdates() {
        guard manager.isAccelerometerAvailable else { return }
        
        manager.accelerometerUpdateInterval = 1.0 / 60.0
        
        manager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            
            let x = CGFloat(data.acceleration.x)
            let y = CGFloat(data.acceleration.y)
            
            self?.tilt = CGSize(width: x, height: -y)
        }
    }
    
    func stopUpdates() {
        manager.stopAccelerometerUpdates()
    }
}

#Preview {
    TiltBallGameView()
}
