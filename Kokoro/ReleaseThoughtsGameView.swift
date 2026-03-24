import SwiftUI

struct ReleaseThoughtsGameView: View {
    
    struct ThoughtBubble: Identifiable, Equatable {
        let id = UUID()
        let text: String
        var position: CGPoint
        var rotation: Double
        var scale: CGFloat
        var opacity: Double
        var isReleased: Bool = false
        var color: Color
    }
    
    @State private var thoughts: [ThoughtBubble] = []
    @State private var calmProgress: CGFloat = 0.0
    @State private var releasedCount = 0
    @State private var message = "Toca un pensamiento para dejarlo ir."
    @State private var boardSize: CGSize = .zero
    
    let sampleThoughts: [String] = [
        "No puedo con todo",
        "¿Y si sale mal?",
        "Estoy muy cansado",
        "Tengo demasiadas cosas",
        "No dejo de pensar",
        "Necesito descansar",
        "Me siento saturado",
        "Todo va muy rápido",
        "Quiero soltar esto",
        "Necesito un respiro"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.94, green: 0.92, blue: 1.0),
                        Color(red: 0.90, green: 0.95, blue: 1.0),
                        Color(red: 0.98, green: 0.93, blue: 0.97)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 18) {
                    
                    VStack(spacing: 8) {
                        Text("Suelta tus pensamientos")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.25, green: 0.23, blue: 0.39))
                        
                        Text("No tienes que pelear con todo. Toca y deja ir.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.43, green: 0.42, blue: 0.57))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 10)
                    
                    VStack(spacing: 10) {
                        Text("Calma recuperada")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 0.48, green: 0.45, blue: 0.63))
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.7))
                                .frame(height: 18)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.69, green: 0.62, blue: 0.96),
                                            Color(red: 0.50, green: 0.72, blue: 0.95)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(20, calmProgress * 300), height: 18)
                                .animation(.easeInOut(duration: 0.35), value: calmProgress)
                        }
                        .frame(width: 300)
                        
                        Text("\(Int(calmProgress * 100))%")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.29, green: 0.28, blue: 0.43))
                    }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 34)
                            .fill(Color.white.opacity(0.42))
                            .overlay(
                                RoundedRectangle(cornerRadius: 34)
                                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
                        
                        ZStack {
                            ForEach(thoughts) { thought in
                                thoughtView(thought)
                                    .position(thought.position)
                                    .rotationEffect(.degrees(thought.rotation))
                                    .scaleEffect(thought.scale)
                                    .opacity(thought.opacity)
                                    .onTapGesture {
                                        releaseThought(thought)
                                    }
                            }
                            
                            if thoughts.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 34, weight: .medium))
                                        .foregroundColor(Color(red: 0.63, green: 0.58, blue: 0.88))
                                    
                                    Text("Tu mente se siente un poco más ligera")
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 0.26, green: 0.24, blue: 0.40))
                                        .multilineTextAlignment(.center)
                                    
                                    Text("A veces soltar un poco también es avanzar.")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(Color(red: 0.45, green: 0.44, blue: 0.58))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.horizontal, 28)
                            }
                        }
                    }
                    .frame(height: 430)
                    .padding(.horizontal, 20)
                    .onAppear {
                        boardSize = geometry.size
                        if thoughts.isEmpty {
                            loadThoughts(in: geometry.size)
                        }
                    }
                    
                    VStack(spacing: 8) {
                        Text(message)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.39, green: 0.38, blue: 0.52))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                        
                        Text("Pensamientos liberados: \(releasedCount)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(red: 0.53, green: 0.50, blue: 0.66))
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            loadThoughts(in: geometry.size)
                        } label: {
                            Text("Volver a empezar")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.57, green: 0.50, blue: 0.93),
                                            Color(red: 0.45, green: 0.40, blue: 0.84)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                        }
                        
                        Button {
                            releaseAllThoughts()
                        } label: {
                            Text("Soltar todo")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(red: 0.34, green: 0.34, blue: 0.48))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.78))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 22)
                }
            }
        }
    }
    
    @ViewBuilder
    private func thoughtView(_ thought: ThoughtBubble) -> some View {
        Text(thought.text)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(Color(red: 0.28, green: 0.27, blue: 0.40))
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(thought.color.opacity(0.95))
            )
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 4)
    }
    
    private func loadThoughts(in size: CGSize) {
        releasedCount = 0
        calmProgress = 0
        message = "Toca un pensamiento para dejarlo ir."
        
        let areaTop: CGFloat = 170
        let areaBottom: CGFloat = 520
        
        let generated = sampleThoughts.prefix(6).enumerated().map { index, text in
            ThoughtBubble(
                text: text,
                position: CGPoint(
                    x: CGFloat.random(in: 90...(size.width - 90)),
                    y: CGFloat.random(in: areaTop...min(areaBottom, size.height - 180))
                ),
                rotation: Double.random(in: -8...8),
                scale: 1.0,
                opacity: 1.0,
                color: bubbleColors[index % bubbleColors.count]
            )
        }
        
        thoughts = generated
    }
    
    private var bubbleColors: [Color] {
        [
            Color(red: 0.92, green: 0.84, blue: 0.98),
            Color(red: 0.84, green: 0.90, blue: 1.0),
            Color(red: 0.98, green: 0.86, blue: 0.92),
            Color(red: 0.87, green: 0.95, blue: 0.90),
            Color(red: 0.88, green: 0.86, blue: 1.0),
            Color(red: 0.96, green: 0.89, blue: 0.84)
        ]
    }
    
    private func releaseThought(_ thought: ThoughtBubble) {
        guard let index = thoughts.firstIndex(of: thought) else { return }
        
        message = releaseMessage()
        
        withAnimation(.easeInOut(duration: 0.9)) {
            thoughts[index].position.y -= 150
            thoughts[index].opacity = 0
            thoughts[index].scale = 1.15
            thoughts[index].rotation += Double.random(in: -12...12)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            thoughts.removeAll { $0.id == thought.id }
            releasedCount += 1
            calmProgress = min(1.0, calmProgress + 0.16)
            
            if thoughts.isEmpty {
                calmProgress = 1.0
                message = "Bien hecho. Ya soltaste por hoy."
            }
        }
    }
    
    private func releaseAllThoughts() {
        let currentThoughts = thoughts
        
        for (offset, thought) in currentThoughts.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(offset) * 0.12) {
                releaseThought(thought)
            }
        }
    }
    
    private func releaseMessage() -> String {
        let messages = [
            "Eso también puede irse.",
            "Un poco más ligero.",
            "No tienes que cargarlo todo.",
            "Déjalo pasar por ahora.",
            "Soltar también es cuidarte.",
            "Tu mente puede descansar un poco."
        ]
        return messages.randomElement() ?? "Déjalo ir."
    }
}

#Preview {
    ReleaseThoughtsGameView()
}
