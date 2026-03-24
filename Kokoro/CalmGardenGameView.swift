import SwiftUI

struct CalmGardenGameView: View {
    
    @State private var growth: CGFloat = 0.2
    @State private var waterDrops: [WaterDrop] = []
    @State private var showSunGlow = false
    @State private var leafBounce = false
    @State private var message = "Tu jardín está listo para crecer contigo."
    @State private var breathingInProgress = false
    @State private var completedBreaths = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.91, green: 0.97, blue: 0.93),
                    Color(red: 0.92, green: 0.95, blue: 1.00),
                    Color(red: 0.97, green: 0.93, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                
                VStack(spacing: 8) {
                    Text("Jardín de Calma")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.22, green: 0.28, blue: 0.22))
                    
                    Text("Cuida tu planta con acciones suaves y hazla crecer poco a poco.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.38, green: 0.45, blue: 0.40))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.top, 10)
                
                VStack(spacing: 12) {
                    Text("Crecimiento")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.40, green: 0.48, blue: 0.41))
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.7))
                            .frame(height: 18)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.53, green: 0.79, blue: 0.54),
                                        Color(red: 0.36, green: 0.66, blue: 0.46)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(28, growth * 300), height: 18)
                            .animation(.easeInOut(duration: 0.4), value: growth)
                    }
                    .frame(width: 300)
                    
                    Text("\(Int(growth * 100))%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 0.27, green: 0.38, blue: 0.28))
                }
                
                Spacer()
                
                ZStack {
                    RoundedRectangle(cornerRadius: 34)
                        .fill(Color.white.opacity(0.42))
                        .overlay(
                            RoundedRectangle(cornerRadius: 34)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 8)
                    
                    gardenScene
                }
                .frame(height: 360)
                .padding(.horizontal, 20)
                
                VStack(spacing: 10) {
                    Text(message)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0.34, green: 0.42, blue: 0.35))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    
                    Text("Respiraciones completadas: \(completedBreaths)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.48, green: 0.54, blue: 0.50))
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        actionButton(
                            title: "Regar",
                            icon: "drop.fill",
                            colors: [
                                Color(red: 0.47, green: 0.74, blue: 0.96),
                                Color(red: 0.34, green: 0.60, blue: 0.88)
                            ]
                        ) {
                            waterPlant()
                        }
                        
                        actionButton(
                            title: "Luz",
                            icon: "sun.max.fill",
                            colors: [
                                Color(red: 0.99, green: 0.80, blue: 0.38),
                                Color(red: 0.94, green: 0.67, blue: 0.26)
                            ]
                        ) {
                            giveLight()
                        }
                    }
                    
                    actionButton(
                        title: breathingInProgress ? "Respirando..." : "Respirar",
                        icon: "wind",
                        colors: [
                            Color(red: 0.62, green: 0.59, blue: 0.95),
                            Color(red: 0.48, green: 0.45, blue: 0.86)
                        ]
                    ) {
                        startBreathingBoost()
                    }
                    .disabled(breathingInProgress)
                    
                    Button {
                        resetGarden()
                    } label: {
                        Text("Reiniciar jardín")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 0.35, green: 0.40, blue: 0.36))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.white.opacity(0.78))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    var gardenScene: some View {
        GeometryReader { geo in
            ZStack {
                
                // Cielo suave
                LinearGradient(
                    colors: [
                        Color(red: 0.86, green: 0.94, blue: 1.0),
                        Color(red: 0.92, green: 0.97, blue: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: 34))
                
                // Sol
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.93, blue: 0.65).opacity(showSunGlow ? 0.95 : 0.75),
                                Color(red: 1.0, green: 0.83, blue: 0.45).opacity(showSunGlow ? 0.55 : 0.25),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 8,
                            endRadius: showSunGlow ? 70 : 45
                        )
                    )
                    .frame(width: 90, height: 90)
                    .position(x: geo.size.width - 55, y: 55)
                    .animation(.easeInOut(duration: 0.6), value: showSunGlow)
                
                // Suelo
                VStack {
                    Spacer()
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.64, green: 0.83, blue: 0.62),
                                    Color(red: 0.47, green: 0.72, blue: 0.49)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 110)
                        .offset(y: 20)
                }
                
                // Flores pequeñas desbloqueadas por crecimiento
                if growth > 0.35 {
                    flower(x: 70, y: geo.size.height - 85, scale: 0.8, petalColor: Color.pink)
                    flower(x: geo.size.width - 90, y: geo.size.height - 95, scale: 0.7, petalColor: Color.yellow)
                }
                
                if growth > 0.60 {
                    flower(x: 110, y: geo.size.height - 120, scale: 0.9, petalColor: Color.purple)
                    flower(x: geo.size.width - 130, y: geo.size.height - 120, scale: 0.85, petalColor: Color(red: 1.0, green: 0.62, blue: 0.72))
                }
                
                // Maceta
                VStack {
                    Spacer()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.77, green: 0.49, blue: 0.32),
                                        Color(red: 0.63, green: 0.36, blue: 0.23)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 120, height: 90)
                        
                        Ellipse()
                            .fill(Color(red: 0.42, green: 0.27, blue: 0.16))
                            .frame(width: 108, height: 22)
                            .offset(y: -26)
                    }
                    .offset(y: -30)
                }
                
                // Planta
                VStack {
                    Spacer()
                    
                    ZStack {
                        // Tallo
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.36, green: 0.67, blue: 0.38),
                                        Color(red: 0.24, green: 0.53, blue: 0.28)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 12, height: 60 + growth * 120)
                            .offset(y: 10)
                        
                        // Hojas
                        leafPair(offsetY: -20, size: 34 + growth * 20)
                        leafPair(offsetY: -60, size: 28 + growth * 18)
                        
                        if growth > 0.45 {
                            leafPair(offsetY: -100, size: 24 + growth * 16)
                        }
                        
                        // Flor superior
                        if growth > 0.70 {
                            flowerTop(scale: 0.7 + growth * 0.35)
                                .offset(y: -(90 + growth * 65))
                        }
                    }
                    .scaleEffect(leafBounce ? 1.03 : 1.0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.5), value: leafBounce)
                    .offset(y: -70)
                }
                
                // Gotas de agua
                ForEach(waterDrops) { drop in
                    Image(systemName: "drop.fill")
                        .font(.system(size: drop.size))
                        .foregroundColor(Color(red: 0.38, green: 0.69, blue: 0.98).opacity(0.8))
                        .position(drop.position)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 34))
        }
    }
    
    func leafPair(offsetY: CGFloat, size: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.53, green: 0.82, blue: 0.47),
                            Color(red: 0.30, green: 0.64, blue: 0.32)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size * 0.55)
                .rotationEffect(.degrees(-35))
                .offset(x: -20, y: offsetY)
            
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.53, green: 0.82, blue: 0.47),
                            Color(red: 0.30, green: 0.64, blue: 0.32)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size * 0.55)
                .rotationEffect(.degrees(35))
                .offset(x: 20, y: offsetY)
        }
    }
    
    func flowerTop(scale: CGFloat) -> some View {
        ZStack {
            ForEach(0..<6, id: \.self) { index in
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.76, blue: 0.86),
                                Color(red: 0.96, green: 0.55, blue: 0.72)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 22, height: 36)
                    .offset(y: -16)
                    .rotationEffect(.degrees(Double(index) * 60))
            }
            
            Circle()
                .fill(Color.yellow.opacity(0.95))
                .frame(width: 20, height: 20)
        }
        .scaleEffect(scale)
    }
    
    func flower(x: CGFloat, y: CGFloat, scale: CGFloat, petalColor: Color) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.green.opacity(0.8))
                .frame(width: 4, height: 35)
                .offset(y: 10)
            
            ForEach(0..<6, id: \.self) { index in
                Ellipse()
                    .fill(petalColor.opacity(0.9))
                    .frame(width: 12, height: 18)
                    .offset(y: -8)
                    .rotationEffect(.degrees(Double(index) * 60))
            }
            
            Circle()
                .fill(Color.yellow.opacity(0.95))
                .frame(width: 10, height: 10)
        }
        .scaleEffect(scale)
        .position(x: x, y: y)
    }
    
    @ViewBuilder
    func actionButton(title: String, icon: String, colors: [Color], action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                
                Text(title)
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 5)
        }
    }
    
    func waterPlant() {
        message = "Un poco de agua también es un gesto de cuidado."
        triggerLeafBounce()
        increaseGrowth(by: 0.08)
        createWaterAnimation()
    }
    
    func giveLight() {
        message = "La luz también ayuda a florecer."
        triggerLeafBounce()
        increaseGrowth(by: 0.06)
        
        showSunGlow = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showSunGlow = false
        }
    }
    
    func startBreathingBoost() {
        guard !breathingInProgress else { return }
        
        breathingInProgress = true
        message = "Inhala... sostén... exhala..."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            message = "Sostén un momento..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            message = "Exhala lentamente..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            completedBreaths += 1
            breathingInProgress = false
            message = "Tu respiración también hace crecer tu jardín."
            triggerLeafBounce()
            increaseGrowth(by: 0.10)
        }
    }
    
    func increaseGrowth(by amount: CGFloat) {
        growth = min(1.0, growth + amount)
    }
    
    func triggerLeafBounce() {
        leafBounce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            leafBounce = false
        }
    }
    
    func createWaterAnimation() {
        waterDrops = [
            WaterDrop(position: CGPoint(x: 120, y: 70), size: 18),
            WaterDrop(position: CGPoint(x: 150, y: 85), size: 15),
            WaterDrop(position: CGPoint(x: 180, y: 60), size: 16)
        ]
        
        withAnimation(.easeIn(duration: 0.8)) {
            waterDrops = waterDrops.map {
                WaterDrop(position: CGPoint(x: $0.position.x, y: $0.position.y + 170), size: $0.size)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            waterDrops.removeAll()
        }
    }
    
    func resetGarden() {
        growth = 0.2
        waterDrops.removeAll()
        showSunGlow = false
        leafBounce = false
        message = "Tu jardín está listo para crecer contigo."
        breathingInProgress = false
        completedBreaths = 0
    }
}

struct WaterDrop: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
}

#Preview {
    CalmGardenGameView()
}
