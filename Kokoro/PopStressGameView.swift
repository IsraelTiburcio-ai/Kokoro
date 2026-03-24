import SwiftUI
import UIKit

struct PopStressGameView: View {
    
    struct Bubble: Identifiable, Equatable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var speed: CGFloat
        var color: Color
    }
    
    @State private var bubbles: [Bubble] = []
    @State private var score = 0
    @State private var timeLeft = 30
    @State private var isGameRunning = false
    @State private var gameTimer: Timer?
    @State private var bubbleTimer: Timer?
    @State private var movementTimer: Timer?
    @State private var boardSize: CGSize = .zero
    @State private var popHapticGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.92, blue: 1.0),
                        Color(red: 0.91, green: 0.96, blue: 1.0),
                        Color(red: 0.98, green: 0.92, blue: 0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 18) {
                    VStack(spacing: 8) {
                        Text("Revienta el estrés")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.24, green: 0.22, blue: 0.38))
                        
                        Text("Toca las burbujas y libera tensión")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.43, green: 0.42, blue: 0.57))
                    }
                    .padding(.top, 12)
                    
                    HStack(spacing: 14) {
                        infoCard(title: "Puntos", value: "\(score)")
                        infoCard(title: "Tiempo", value: "\(timeLeft)s")
                    }
                    .padding(.horizontal, 4)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white.opacity(0.45))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
                        
                        ForEach(bubbles) { bubble in
                            BubbleView(bubble: bubble)
                                .position(x: bubble.x, y: bubble.y)
                                .onTapGesture {
                                    popBubble(bubble)
                                }
                        }
                        
                        if !isGameRunning {
                            VStack(spacing: 14) {
                                Text(timeLeft == 30 ? "¿Listo para empezar?" : "Juego terminado")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.24, green: 0.22, blue: 0.38))
                                
                                Text(timeLeft == 30
                                     ? "Revienta todas las burbujas que puedas."
                                     : "Reventaste \(score) burbujas.")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(red: 0.42, green: 0.42, blue: 0.55))
                                    .multilineTextAlignment(.center)
                                
                                Button {
                                    startGame(in: geometry.size)
                                } label: {
                                    Text(timeLeft == 30 ? "Comenzar" : "Jugar otra vez")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 28)
                                        .padding(.vertical, 14)
                                        .background(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.56, green: 0.49, blue: 0.93),
                                                    Color(red: 0.43, green: 0.38, blue: 0.84)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(28)
                            .background(Color.white.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                            .padding(.horizontal, 32)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .onAppear {
                        boardSize = geometry.size
                        popHapticGenerator.prepare()
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            startGame(in: geometry.size)
                        } label: {
                            Text("Reiniciar")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.51, green: 0.72, blue: 0.92),
                                            Color(red: 0.39, green: 0.60, blue: 0.84)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                        }
                        
                        Button {
                            stopGame()
                            resetGame()
                        } label: {
                            Text("Detener")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 0.34, green: 0.34, blue: 0.48))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.75))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.bottom, 22)
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    @ViewBuilder
    private func infoCard(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(red: 0.48, green: 0.46, blue: 0.62))
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.25, green: 0.22, blue: 0.40))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func startGame(in size: CGSize) {
        stopGame()
        resetGame()
        
        boardSize = size
        isGameRunning = true
        
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            guard isGameRunning else { return }
            
            if timeLeft > 0 {
                timeLeft -= 1
            } else {
                stopGame()
            }
        }
        
        bubbleTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            guard isGameRunning else { return }
            spawnBubble()
        }
        
        movementTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            guard isGameRunning else { return }
            updateBubbles()
        }
    }
    
    private func stopGame() {
        isGameRunning = false
        gameTimer?.invalidate()
        bubbleTimer?.invalidate()
        movementTimer?.invalidate()
        gameTimer = nil
        bubbleTimer = nil
        movementTimer = nil
    }
    
    private func resetGame() {
        bubbles.removeAll()
        score = 0
        timeLeft = 30
    }
    
    private func spawnBubble() {
        let playAreaTop: CGFloat = 180
        let playAreaBottom: CGFloat = boardSize.height - 140
        
        guard playAreaBottom > playAreaTop else { return }
        
        let size = CGFloat.random(in: 45...85)
        let x = CGFloat.random(in: 40...(boardSize.width - 40))
        let y = playAreaBottom + size
        
        let bubble = Bubble(
            x: x,
            y: y,
            size: size,
            speed: CGFloat.random(in: 1.2...2.8),
            color: randomBubbleColor()
        )
        
        bubbles.append(bubble)
    }
    
    private func updateBubbles() {
        let playAreaTop: CGFloat = 140
        
        for index in bubbles.indices {
            bubbles[index].y -= bubbles[index].speed
        }
        
        bubbles.removeAll { $0.y < playAreaTop - $0.size }
    }
    
    private func popBubble(_ bubble: Bubble) {
        guard isGameRunning else { return }
        
        if let index = bubbles.firstIndex(of: bubble) {
            score += 1
            bubbles.remove(at: index)
            popHapticGenerator.impactOccurred(intensity: 0.9)
            popHapticGenerator.prepare()
        }
    }
    
    private func randomBubbleColor() -> Color {
        let colors: [Color] = [
            Color(red: 0.79, green: 0.87, blue: 1.0),
            Color(red: 0.93, green: 0.80, blue: 0.98),
            Color(red: 0.82, green: 0.94, blue: 0.89),
            Color(red: 0.99, green: 0.86, blue: 0.91),
            Color(red: 0.85, green: 0.84, blue: 1.0)
        ]
        return colors.randomElement() ?? .blue
    }
}

struct BubbleView: View {
    let bubble: PopStressGameView.Bubble
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            bubble.color.opacity(0.85),
                            bubble.color.opacity(0.55)
                        ],
                        center: .topLeading,
                        startRadius: 4,
                        endRadius: bubble.size / 2
                    )
                )
                .frame(width: bubble.size, height: bubble.size)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.75), lineWidth: 2)
                )
                .shadow(color: bubble.color.opacity(0.22), radius: 10, x: 0, y: 5)
            
            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: bubble.size * 0.22, height: bubble.size * 0.22)
                .offset(x: -bubble.size * 0.18, y: -bubble.size * 0.18)
        }
    }
}

#Preview {
    PopStressGameView()
}

