import SwiftUI
import UIKit

struct GamesMenuView: View {
    @State private var selectedCategory: GameCategory = .all
    
    private let games: [MentalGame] = [
        MentalGame(
            title: "Respira con la nube",
            subtitle: "Sigue el ritmo de la respiración y baja revoluciones poco a poco.",
            imageName: "game_breath_cloud",
            color1: Color(red: 0.77, green: 0.86, blue: 0.98),
            color2: Color(red: 0.67, green: 0.76, blue: 0.96),
            category: .calm,
            duration: "2 min",
            benefit: "Respiración"
        ),
        MentalGame(
            title: "Revienta el estrés",
            subtitle: "Explota burbujas y suelta tensión con una interacción rápida y ligera.",
            imageName: "game_stress_pop",
            color1: Color(red: 0.91, green: 0.78, blue: 0.94),
            color2: Color(red: 0.81, green: 0.67, blue: 0.91),
            category: .release,
            duration: "3 min",
            benefit: "Descarga"
        ),
        MentalGame(
            title: "Bola al hoyo",
            subtitle: "Dirige la bola a su destino mientras disfrutas de un momento de concentración.",
            imageName: "game_tilt_ball",
            color1: Color(red: 0.91, green: 0.78, blue: 0.94),
            color2: Color(red: 0.81, green: 0.67, blue: 0.91),
            category: .release,
            duration: "4 min",
            benefit: "Enfoque"
        ),
        MentalGame(
            title: "Ordena tu rincón",
            subtitle: "Organiza un pequeño espacio y recupera sensación de control.",
            imageName: "game_order_corner",
            color1: Color(red: 0.83, green: 0.93, blue: 0.87),
            color2: Color(red: 0.70, green: 0.85, blue: 0.77),
            category: .focus,
            duration: "4 min",
            benefit: "Enfoque"
        ),
        MentalGame(
            title: "Jardín de calma",
            subtitle: "Cuida tu jardín a tu ritmo y convierte la pausa en un momento amable.",
            imageName: "game_calm_garden",
            color1: Color(red: 0.78, green: 0.90, blue: 0.84),
            color2: Color(red: 0.63, green: 0.81, blue: 0.74),
            category: .calm,
            duration: "5 min",
            benefit: "Calma"
        ),
        MentalGame(
            title: "Suelta tus pensamientos",
            subtitle: "Deja ir lo que pesa mientras observas cómo tus ideas se alejan.",
            imageName: "game_release_thoughts",
            color1: Color(red: 0.86, green: 0.80, blue: 0.97),
            color2: Color(red: 0.75, green: 0.68, blue: 0.93),
            category: .release,
            duration: "3 min",
            benefit: "Soltar"
        ),
        MentalGame(
            title: "Sigue la luciérnaga",
            subtitle: "Fija tu atención en una luz suave y regresa al presente.",
            imageName: "game_firefly",
            color1: Color(red: 0.76, green: 0.84, blue: 0.98),
            color2: Color(red: 0.63, green: 0.74, blue: 0.95),
            category: .focus,
            duration: "2 min",
            benefit: "Atención"
        ),
        MentalGame(
            title: "Pinta sin pensar",
            subtitle: "Traza colores libremente sin presión ni reglas.",
            imageName: "game_paint",
            color1: Color(red: 0.97, green: 0.84, blue: 0.89),
            color2: Color(red: 0.92, green: 0.72, blue: 0.82),
            category: .release,
            duration: "6 min",
            benefit: "Creatividad"
        ),
        MentalGame(
            title: "Ondas en el agua",
            subtitle: "Toca la pantalla y crea ondas suaves para relajarte.",
            imageName: "game_water",
            color1: Color(red: 0.79, green: 0.90, blue: 0.98),
            color2: Color(red: 0.64, green: 0.81, blue: 0.95),
            category: .calm,
            duration: "3 min",
            benefit: "Relajación"
        ),
        MentalGame(
            title: "Conecta las estrellas",
            subtitle: "Une puntos de luz y mantén tu mente en una sola tarea.",
            imageName: "game_stars",
            color1: Color(red: 0.82, green: 0.80, blue: 0.98),
            color2: Color(red: 0.70, green: 0.69, blue: 0.95),
            category: .focus,
            duration: "4 min",
            benefit: "Concentración"
        ),
        MentalGame(
            title: "Arma tu espacio seguro",
            subtitle: "Construye un rincón visual donde te sientas tranquilo y acompañado.",
            imageName: "game_safe_space",
            color1: Color(red: 0.90, green: 0.85, blue: 0.97),
            color2: Color(red: 0.80, green: 0.73, blue: 0.93),
            category: .calm,
            duration: "5 min",
            benefit: "Espacio seguro"
        )
    ]
    
    private var filteredGames: [MentalGame] {
        guard selectedCategory != .all else { return games }
        return games.filter { $0.category == selectedCategory }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.91, blue: 0.99),
                        Color(red: 0.92, green: 0.97, blue: 1.00),
                        Color(red: 0.98, green: 0.96, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        categoryPicker
                        featuredCard
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Juegos para volver a tu centro")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.black)
                            
                            Text("Pequeñas dinámicas para soltar tensión, recuperar enfoque y respirar mejor.")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.black.opacity(0.38))
                        }
                        
                        LazyVStack(spacing: 18) {
                            ForEach(filteredGames) { game in
                                NavigationLink {
                                    destinationView(for: game)
                                        .navigationBarTitleDisplayMode(.inline)
                                } label: {
                                    GameRowCard(game: game)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 10)
                    .padding(.bottom, 120)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    @ViewBuilder
    private func destinationView(for game: MentalGame) -> some View {
        switch game.title {
        case "Respira con la nube":
            BreatheCloudGameView()
        case "Jardín de calma":
            CalmGardenGameView()
        case "Revienta el estrés":
            PopStressGameView()
        case "Suelta tus pensamientos":
            ReleaseThoughtsGameView()
        case "Bola al hoyo":
            TiltBallGameView()
        default:
            ComingSoonGameView(gameTitle: game.title)
        }
    }
    
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.white.opacity(0.32))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(.white.opacity(0.55), lineWidth: 1)
                    )
                
                LinearGradient(
                    colors: [
                        Color(red: 0.85, green: 0.31, blue: 0.95),
                        Color(red: 0.35, green: 0.57, blue: 0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 62, height: 62)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                )
            }
            .frame(width: 116, height: 116)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Juegos que sí te abrazan")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("No es competir: es regalarte unos minutos para volver a ti.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.40))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 8)
        }
    }
    
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(GameCategory.allCases) { category in
                    Button {
                        withAnimation(.snappy) {
                            selectedCategory = category
                        }
                    } label: {
                        Text(category.title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(selectedCategory == category ? .white : .black)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background {
                                if selectedCategory == category {
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.82, green: 0.27, blue: 0.93),
                                            Color(red: 0.14, green: 0.52, blue: 0.98)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    Color.white.opacity(0.72)
                                }
                            }
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(.white.opacity(0.6), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
        .scrollIndicators(.hidden)
    }
    
    private var featuredCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.22))
                    .frame(width: 70, height: 70)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Recomendación del momento")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                
                Text("Empieza con una dinámica corta y después pasa a una de enfoque.")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.87, green: 0.27, blue: 0.90),
                    Color(red: 0.35, green: 0.57, blue: 0.98)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
    }
}

private struct GameRowCard: View {
    let game: GamesMenuView.MentalGame
    
    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [game.color1, game.color2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                if let image = UIImage(named: game.imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(18)
                } else {
                    Image(systemName: game.sfSymbol)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.white.opacity(0.92))
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: game.sfSymbol)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(.black.opacity(0.16))
                    .clipShape(Circle())
                    .padding(8)
            }
            .frame(width: 128, height: 128)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    pill(text: game.benefit, style: .softPurple, isCompact: false)
                    pill(text: game.duration, style: .softBlue, isCompact: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(game.title)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Text(game.subtitle)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.42))
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                HStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Jugar ahora")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.82, green: 0.27, blue: 0.93),
                            Color(red: 0.14, green: 0.52, blue: 0.98)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color.white.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.white.opacity(0.6), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
    }
    
    private func pill(text: String, style: PillStyle, isCompact: Bool) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.80)
            .allowsTightening(true)
            .truncationMode(.tail)
            .foregroundStyle(style.foreground)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(style.background)
            .clipShape(Capsule())
            .frame(minWidth: isCompact ? 62 : nil)
            .frame(maxWidth: isCompact ? nil : 150, alignment: .leading)
            .layoutPriority(isCompact ? 1 : 0)
    }
}

private struct ComingSoonGameView: View {
    let gameTitle: String
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.91, blue: 0.99),
                    Color(red: 0.92, green: 0.97, blue: 1.00)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 18) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.82, green: 0.27, blue: 0.93),
                                Color(red: 0.14, green: 0.52, blue: 0.98)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text(gameTitle)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                
                Text("Esta dinámica todavía no está conectada, pero ya quedó lista la navegación para cuando la construyas.")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .padding(28)
            .frame(maxWidth: 340)
            .background(Color.white.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(.white.opacity(0.7), lineWidth: 1)
            )
        }
    }
}

private enum PillStyle {
    case softPurple
    case softBlue
    
    var foreground: Color {
        switch self {
        case .softPurple:
            return Color(red: 0.63, green: 0.28, blue: 0.90)
        case .softBlue:
            return Color(red: 0.25, green: 0.46, blue: 0.92)
        }
    }
    
    var background: Color {
        switch self {
        case .softPurple:
            return Color(red: 0.95, green: 0.88, blue: 1.00)
        case .softBlue:
            return Color(red: 0.88, green: 0.93, blue: 1.00)
        }
    }
}

extension GamesMenuView {
    enum GameCategory: String, CaseIterable, Identifiable {
        case all
        case calm
        case focus
        case release
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .all:
                return "Todos"
            case .calm:
                return "Calma"
            case .focus:
                return "Enfoque"
            case .release:
                return "Soltar"
            }
        }
    }
    
    struct MentalGame: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let imageName: String
        let color1: Color
        let color2: Color
        let category: GameCategory
        let duration: String
        let benefit: String

        var sfSymbol: String {
            if title.localizedCaseInsensitiveContains("Respira") { return "wind" }
            if title.localizedCaseInsensitiveContains("estrés") || title.localizedCaseInsensitiveContains("Suelta") { return "sparkles" }
            if title.localizedCaseInsensitiveContains("Bola") { return "circle.grid.2x2.fill" }
            if title.localizedCaseInsensitiveContains("Jardín") { return "leaf.fill" }
            if title.localizedCaseInsensitiveContains("luciérnaga") { return "lightbulb.max.fill" }
            if title.localizedCaseInsensitiveContains("Pinta") { return "paintpalette.fill" }
            if title.localizedCaseInsensitiveContains("Ondas") { return "drop.fill" }
            if title.localizedCaseInsensitiveContains("estrellas") { return "star.fill" }
            if title.localizedCaseInsensitiveContains("espacio") { return "house.fill" }
            return "gamecontroller.fill"
        }
    }
}

#Preview {
    GamesMenuView()
}
