//
//  Untitled.swift
//  Kokoro 2
//
//  Created by Cristian Yair Gómez Herrera on 24/03/26.

import SwiftUI

struct BreatheCloudGameView: View {
    
    enum BreathingPhase: String {
        case inhale = "Inhala"
        case hold = "Sostén"
        case exhale = "Exhala"
        case rest = "Prepárate"
    }
    
    @State private var currentPhase: BreathingPhase = .rest
    @State private var cloudScale: CGFloat = 0.85
    @State private var isRunning = false
    @State private var cycleCount = 0
    
    let inhaleDuration: Double = 4.0
    let holdDuration: Double = 2.0
    let exhaleDuration: Double = 5.0
    let restDuration: Double = 1.5
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.88, green: 0.94, blue: 1.0),
                    Color(red: 0.92, green: 0.88, blue: 0.99),
                    Color(red: 0.84, green: 0.92, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 28) {
                
                VStack(spacing: 8) {
                    Text("Respira con la nube")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.24, green: 0.24, blue: 0.38))
                    
                    Text("Sigue el ritmo de la nube y respira con calma")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.42, green: 0.43, blue: 0.58))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 10)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.28))
                        .frame(width: 290, height: 290)
                        .blur(radius: 8)
                    
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 240, height: 240)
                    
                    cloudView
                        .scaleEffect(cloudScale)
                        .animation(.easeInOut(duration: 0.5), value: cloudScale)
                }
                .frame(height: 320)
                
                VStack(spacing: 10) {
                    Text(currentPhase.rawValue)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.28, green: 0.26, blue: 0.44))
                    
                    Text(phaseDescription)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.58))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Text("Ciclos completados: \(cycleCount)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.50, green: 0.48, blue: 0.65))
                        .padding(.top, 6)
                }
                
                Spacer()
                
                VStack(spacing: 14) {
                    Button {
                        if isRunning {
                            stopBreathing()
                        } else {
                            startBreathingCycle()
                        }
                    } label: {
                        Text(isRunning ? "Detener" : "Comenzar")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: isRunning
                                    ? [
                                        Color(red: 0.93, green: 0.53, blue: 0.65),
                                        Color(red: 0.84, green: 0.38, blue: 0.56)
                                    ]
                                    : [
                                        Color(red: 0.54, green: 0.63, blue: 0.95),
                                        Color(red: 0.43, green: 0.50, blue: 0.88)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 5)
                    }
                    
                    Button {
                        resetGame()
                    } label: {
                        Text("Reiniciar")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.35, green: 0.35, blue: 0.48))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.white.opacity(0.75))
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
    }
    
    var phaseDescription: String {
        switch currentPhase {
        case .inhale:
            return "Llena tus pulmones lentamente mientras la nube crece."
        case .hold:
            return "Sostén un momento con suavidad."
        case .exhale:
            return "Suelta el aire despacio mientras la nube se relaja."
        case .rest:
            return "Cuando quieras, comenzamos."
        }
    }
    
    var cloudView: some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.90, green: 0.95, blue: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 180, height: 95)
            
            Circle()
                .fill(Color.white)
                .frame(width: 80, height: 80)
                .offset(x: -52, y: -10)
            
            Circle()
                .fill(Color.white)
                .frame(width: 95, height: 95)
                .offset(x: 0, y: -20)
            
            Circle()
                .fill(Color.white)
                .frame(width: 72, height: 72)
                .offset(x: 55, y: -8)
        }
        .shadow(color: Color.white.opacity(0.55), radius: 12, x: 0, y: 0)
        .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 8)
    }
    
    func startBreathingCycle() {
        isRunning = true
        runCycle()
    }
    
    func runCycle() {
        guard isRunning else { return }
        
        currentPhase = .inhale
        withAnimation(.easeInOut(duration: inhaleDuration)) {
            cloudScale = 1.20
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + inhaleDuration) {
            guard isRunning else { return }
            
            currentPhase = .hold
            
            DispatchQueue.main.asyncAfter(deadline: .now() + holdDuration) {
                guard isRunning else { return }
                
                currentPhase = .exhale
                withAnimation(.easeInOut(duration: exhaleDuration)) {
                    cloudScale = 0.82
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + exhaleDuration) {
                    guard isRunning else { return }
                    
                    cycleCount += 1
                    currentPhase = .rest
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + restDuration) {
                        guard isRunning else { return }
                        runCycle()
                    }
                }
            }
        }
    }
    
    func stopBreathing() {
        isRunning = false
        currentPhase = .rest
        
        withAnimation(.easeInOut(duration: 0.5)) {
            cloudScale = 0.85
        }
    }
    
    func resetGame() {
        isRunning = false
        currentPhase = .rest
        cycleCount = 0
        
        withAnimation(.easeInOut(duration: 0.5)) {
            cloudScale = 0.85
        }
    }
}

#Preview {
    BreatheCloudGameView()
}

