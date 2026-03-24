import SwiftUI
import SwiftData
import LinkPresentation
import UIKit
import Combine

// MARK: - MODELOS

@Model
final class ChallengeEntry {
    @Attribute(.unique) var id: UUID
    var dayKey: String
    var title: String
    var reflection: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        date: Date = .now,
        title: String,
        reflection: String
    ) {
        let normalizedDay = Calendar.current.startOfDay(for: date)
        self.id = id
        self.dayKey = LogrosDateHelper.dayKey(for: normalizedDay)
        self.title = title
        self.reflection = reflection
        self.createdAt = date
    }
}

@Model
final class GoalItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var detail: String
    var targetDate: Date
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        targetDate: Date,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.targetDate = targetDate
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

@Model
final class DailyInsightSummary {
    @Attribute(.unique) var dayKey: String
    var date: Date
    var summaryText: String
    var generatedAt: Date

    init(
        date: Date = .now,
        summaryText: String,
        generatedAt: Date = .now
    ) {
        let normalizedDay = Calendar.current.startOfDay(for: date)
        self.dayKey = LogrosDateHelper.dayKey(for: normalizedDay)
        self.date = normalizedDay
        self.summaryText = summaryText
        self.generatedAt = generatedAt
    }
}

// MARK: - LINK PREVIEW ÚLTIMO AUDIO

struct LastMediaPreview {
    let title: String?
    let image: UIImage?
}

@MainActor
final class LastMediaPreviewStore: ObservableObject {
    @Published private(set) var preview: LastMediaPreview?

    private var loadedURLString: String = ""

    func fetchIfNeeded(urlString: String) {
        guard !urlString.isEmpty else {
            preview = nil
            loadedURLString = ""
            return
        }

        guard loadedURLString != urlString else { return }
        loadedURLString = urlString

        Task { @MainActor in
            do {
                guard let url = URL(string: urlString) else {
                    preview = nil
                    return
                }

                let metadata = try await LPMetadataProvider().startFetchingMetadata(for: url)

                let image: UIImage?
                if let primaryImage = await Self.loadImage(from: metadata.imageProvider) {
                    image = primaryImage
                } else {
                    image = await Self.loadImage(from: metadata.iconProvider)
                }

                preview = LastMediaPreview(
                    title: metadata.title,
                    image: image
                )
            } catch {
                preview = LastMediaPreview(title: nil, image: nil)
            }
        }
    }

    private static func loadImage(from provider: NSItemProvider?) async -> UIImage? {
        guard let provider, provider.canLoadObject(ofClass: UIImage.self) else { return nil }

        return await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: UIImage.self) { object, _ in
                continuation.resume(returning: object as? UIImage)
            }
        }
    }
}

// MARK: - GROQ DTOs

private struct GroqChatRequest: Encodable {
    let model: String
    let messages: [GroqMessage]
    let temperature: Double
    let max_tokens: Int
}

private struct GroqMessage: Encodable {
    let role: String
    let content: String
}

private struct GroqChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }

    let choices: [Choice]
}

private struct GroqErrorResponse: Decodable {
    struct GroqError: Decodable {
        let message: String
        let type: String?
    }

    let error: GroqError
}

// MARK: - VIEW

struct LogrosViews: View {
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL

    @Query(sort: \ChallengeEntry.createdAt, order: .reverse)
    private var challengeEntries: [ChallengeEntry]

    @Query(sort: \GoalItem.targetDate, order: .forward)
    private var goals: [GoalItem]

    @Query(sort: \DailyInsightSummary.generatedAt, order: .reverse)
    private var savedInsights: [DailyInsightSummary]

    // Lo que ya escribe MeditationHubView
    @AppStorage("lastPlayedTitle") private var lastPlayedTitle: String = ""
    @AppStorage("lastPlayedSource") private var lastPlayedSource: String = ""
    @AppStorage("lastPlayedKind") private var lastPlayedKind: String = ""
    @AppStorage("lastPlayedAuthor") private var lastPlayedAuthor: String = ""
    @AppStorage("lastPlayedEstimatedSeconds") private var lastPlayedEstimatedSeconds: Double = 0
    @AppStorage("lastPlayedURL") private var lastPlayedURL: String = ""

    @StateObject private var lastMediaPreviewStore = LastMediaPreviewStore()

    @State private var showAddGoalSheet = false
    @State private var showAddChallengeSheet = false
    @State private var showCompletedGoals = false
    @State private var showAnsweredChallenges = false

    @State private var goalTitle = ""
    @State private var goalDetail = ""
    @State private var goalDate = Date()

    @State private var challengeTitle = ""
    @State private var challengeReflection = ""
    @State private var isCustomChallenge = false

    @State private var isGeneratingInsight = false
    @State private var insightError: String?

    @State private var feedbackToken = 0

    private let challengeTemplates: [String] = [
        "Agradece un nuevo día conscientemente",
        "Abraza a alguien cercano",
        "Dile a una persona importante que la quieres",
        "Respira profundo por dos minutos sin distracciones",
        "Observa el cielo por un minuto y nota cómo te sientes",
        "Desconéctate diez minutos del celular",
        "Toma agua con plena atención y sin prisa",
        "Escribe una cosa que hoy sí salió bien",
        "Camina cinco minutos sin música ni pantalla",
        "Haz una pausa para notar tres sonidos a tu alrededor",
        "Envía un mensaje amable a alguien que aprecias",
        "Abre la ventana y respira conscientemente",
        "Haz un estiramiento suave por un minuto",
        "Come algo lento y con atención",
        "Ponle nombre a una emoción que sientes hoy",
        "Haz una lista de tres cosas que sí puedes controlar",
        "Agradece algo de tu cuerpo hoy",
        "Descansa cinco minutos sin multitarea",
        "Anota una preocupación y suéltala por ahora",
        "Escribe algo que te gustaría recordarte esta noche"
    ]

    var body: some View {
        ZStack {
            logrosBackground

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    header
                    summaryRow

                    if hasLastMedia {
                        lastMediaCard
                    }

                    challengesSection
                    goalsSection
                    aiReflectionSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAddGoalSheet) {
            addGoalSheet
        }
        .sheet(isPresented: $showAddChallengeSheet) {
            addChallengeSheet
        }
        .sensoryFeedback(.success, trigger: feedbackToken)
        .alert("No se pudo generar el resumen", isPresented: insightErrorBinding) {
            Button("OK", role: .cancel) {
                insightError = nil
            }
        } message: {
            Text(insightError ?? "")
        }
        .onAppear {
            lastMediaPreviewStore.fetchIfNeeded(urlString: lastPlayedURL)
        }
        .onChange(of: lastPlayedURL) { _, newValue in
            lastMediaPreviewStore.fetchIfNeeded(urlString: newValue)
        }
    }
}

// MARK: - HEADER

private extension LogrosViews {
    var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hoy")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Pequeñas acciones crean grandes cambios.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Text(accompanimentLine)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.white.opacity(0.58))
                .clipShape(Capsule(style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var summaryRow: some View {
        HStack(spacing: 12) {
            statCard(
                value: streak == 0 ? "🌱" : "\(streak)",
                label: streak == 1 ? "día contigo" : "días contigo"
            )

            statCard(
                value: "\(todayEntries.count)",
                label: todayEntries.count == 1 ? "reto hoy" : "retos hoy"
            )

            statCard(
                value: "\(pendingGoals.count)",
                label: pendingGoals.count == 1 ? "meta activa" : "metas activas"
            )
        }
    }

    func statCard(value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        }
    }
}

// MARK: - ÚLTIMO AUDIO

private extension LogrosViews {
    var hasLastMedia: Bool {
        lastPlayedTitle.trimmedNonEmpty != nil || lastPlayedURL.trimmedNonEmpty != nil
    }

    var lastMediaCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Lo último que te acompañó")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                if let source = lastPlayedSource.trimmedNonEmpty {
                    sourceBadge(source)
                }
            }

            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.pink.opacity(0.82), Color.purple.opacity(0.72), Color.blue.opacity(0.68)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 96, height: 96)

                    if let image = lastMediaPreviewStore.preview?.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 96, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    } else {
                        Image(systemName: iconForLastMediaKind)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(lastMediaPreviewStore.preview?.title?.trimmedNonEmpty ?? lastPlayedTitle)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(lastPlayedAuthor.trimmedNonEmpty ?? "Contenido reciente")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let kind = lastPlayedKind.trimmedNonEmpty {
                            Text(kind)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.purple)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.10))
                                .clipShape(Capsule(style: .continuous))
                        }

                        if lastPlayedEstimatedSeconds >= 5 {
                            Text("≈ \(formattedEstimatedTime(lastPlayedEstimatedSeconds))")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text("Esta referencia también alimenta tu reflejo del día.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if let url = URL(string: lastPlayedURL), lastPlayedURL.trimmedNonEmpty != nil {
                Button {
                    openURL(url)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Abrir de nuevo")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.28), lineWidth: 1)
        }
    }

    func sourceBadge(_ source: String) -> some View {
        Text(source)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(sourceColor(source))
            .clipShape(Capsule(style: .continuous))
    }

    var iconForLastMediaKind: String {
        switch lastPlayedKind.lowercased() {
        case "meditación":
            return "sparkles"
        case "podcast":
            return "mic.fill"
        case "reflexión":
            return "book.pages.fill"
        default:
            return "headphones"
        }
    }

    func sourceColor(_ source: String) -> Color {
        let lower = source.lowercased()
        if lower.contains("spotify") { return Color(red: 0.12, green: 0.73, blue: 0.33) }
        if lower.contains("youtube") { return Color(red: 1.0, green: 0.23, blue: 0.19) }
        if lower.contains("apple") { return Color(red: 0.62, green: 0.29, blue: 0.94) }
        return .blue
    }
}

// MARK: - RETOS

private extension LogrosViews {
    var challengesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Retos de hoy")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Responde el reto del día y te mostramos el siguiente.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    startCustomChallenge()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if let challenge = currentDailyChallenge {
                dailyChallengeCard(challenge)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Completaste todos los retos del día")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Puedes crear un reto libre o esperar a mañana para seguir con la lista.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }

            if todayEntries.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Todavía no has registrado ningún reto hoy.")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Haz uno pequeño, escríbelo y después pide tu interpretación con IA cuando tú quieras.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                DisclosureGroup(isExpanded: $showAnsweredChallenges) {
                    VStack(spacing: 12) {
                        ForEach(todayEntries) { entry in
                            challengeEntryRow(entry)
                        }
                    }
                    .padding(.top, 12)
                } label: {
                    HStack {
                        Text("Retos respondidos hoy")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("\(todayEntries.count)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.58))
                            .clipShape(Capsule(style: .continuous))
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        }
    }

    func dailyChallengeCard(_ challenge: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Reto del día")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.purple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.10))
                    .clipShape(Capsule(style: .continuous))

                Spacer()

                Text("\(todayEntries.count) completados")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Text(challenge)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Cuando lo respondas, te mostramos automáticamente el siguiente reto.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button {
                    startChallenge(challenge)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.bubble.fill")
                        Text("Responder reto")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    startCustomChallenge()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.pencil")
                        Text("Reto libre")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.56))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.26), lineWidth: 1)
        }
    }

    func challengeEntryRow(_ entry: ChallengeEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                Text(entry.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Text(entry.reflection.trimmedNonEmpty ?? "Sin reflexión escrita.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.26), lineWidth: 1)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteChallenge(entry)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
}

// MARK: - METAS

private extension LogrosViews {
    var goalsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tus metas")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Pendientes arriba, completadas plegadas abajo.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showAddGoalSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            if pendingGoals.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("No tienes metas pendientes.")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Puedes agregar una meta pequeña para darte una dirección clara.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                VStack(spacing: 12) {
                    ForEach(pendingGoals) { goal in
                        goalRow(goal, isInCompletedSection: false)
                    }
                }
            }

            if !completedGoals.isEmpty {
                DisclosureGroup(isExpanded: $showCompletedGoals) {
                    VStack(spacing: 12) {
                        ForEach(completedGoals) { goal in
                            goalRow(goal, isInCompletedSection: true)
                        }
                    }
                    .padding(.top, 12)
                } label: {
                    HStack {
                        Text("Metas completadas")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)

                        Spacer()

                        Text("\(completedGoals.count)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.white.opacity(0.58))
                            .clipShape(Capsule(style: .continuous))
                    }
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        }
    }

    func goalRow(_ goal: GoalItem, isInCompletedSection: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Button {
                toggleGoal(goal)
            } label: {
                Image(systemName: goal.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(goal.isCompleted ? .green : .secondary)
                    .padding(.top, 2)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                Text(goal.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .strikethrough(goal.isCompleted, color: .secondary)

                if goal.detail.trimmedNonEmpty != nil {
                    Text(goal.detail)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if goal.isCompleted, let completedAt = goal.completedAt {
                    Text("Completada el \(completedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.green)
                } else {
                    Text("Fecha objetivo: \(goal.targetDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isInCompletedSection ? AnyShapeStyle(Color.green.opacity(0.08)) : AnyShapeStyle(.ultraThinMaterial))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.26), lineWidth: 1)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteGoal(goal)
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
}

// MARK: - IA

private extension LogrosViews {
    var aiReflectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tu reflejo de hoy")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Pídelo tú. Cuando se genere, se guarda.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    Task {
                        await generateInsight()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isGeneratingInsight {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: todayInsight == nil ? "sparkles" : "arrow.clockwise")
                        }

                        Text(todayInsight == nil ? "Generar" : "Actualizar")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isGeneratingInsight || todayEntries.isEmpty)
                .opacity((isGeneratingInsight || todayEntries.isEmpty) ? 0.6 : 1)
            }

            if let insight = todayInsight {
                VStack(alignment: .leading, spacing: 12) {
                    Text(insight.summaryText)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Generado el \(insight.generatedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.18),
                            Color.blue.opacity(0.14),
                            Color.white.opacity(0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.26), lineWidth: 1)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Cuando quieras, la IA puede interpretar cómo fue tu día usando tus retos, reflexiones, metas y el último contenido que escuchaste.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)

                    if todayEntries.isEmpty {
                        Text("Primero registra al menos un reto hoy para poder generar una interpretación útil.")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(.purple)
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        }
    }
}

// MARK: - SHEETS

private extension LogrosViews {
    var addGoalSheet: some View {
        NavigationStack {
            Form {
                Section("Nueva meta") {
                    TextField("Título", text: $goalTitle)
                    TextField("Descripción", text: $goalDetail, axis: .vertical)
                        .lineLimit(3...6)
                    DatePicker("Fecha objetivo", selection: $goalDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Agregar meta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        resetGoalDraft()
                        showAddGoalSheet = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveGoal()
                    }
                    .disabled(goalTitle.trimmedNonEmpty == nil)
                }
            }
        }
    }

    var addChallengeSheet: some View {
        NavigationStack {
            Form {
                Section("Nuevo reto") {
                    if isCustomChallenge {
                        TextField("Título del reto", text: $challengeTitle)
                    } else {
                        Text(challengeTitle)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }

                    TextField("¿Cómo te hizo sentir? ¿Qué pensaste?", text: $challengeReflection, axis: .vertical)
                        .lineLimit(4...8)
                }

                Section {
                    Text("Este reto se guardará como parte de tu día y luego podrá entrar en tu interpretación con IA.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Registrar reto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        resetChallengeDraft()
                        showAddChallengeSheet = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveChallenge()
                    }
                    .disabled(challengeTitle.trimmedNonEmpty == nil || challengeReflection.trimmedNonEmpty == nil)
                }
            }
        }
    }
}

// MARK: - LÓGICA

private extension LogrosViews {
    var todayKey: String {
        LogrosDateHelper.dayKey(for: Calendar.current.startOfDay(for: .now))
    }

    var todayEntries: [ChallengeEntry] {
        challengeEntries
            .filter { $0.dayKey == todayKey }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var currentDailyChallenge: String? {
        let answeredTitles = Set(todayEntries.map(\.title))
        return challengeTemplates.first(where: { !answeredTitles.contains($0) })
    }

    var todayInsight: DailyInsightSummary? {
        savedInsights.first(where: { $0.dayKey == todayKey })
    }

    var pendingGoals: [GoalItem] {
        goals.filter { !$0.isCompleted }.sorted { $0.targetDate < $1.targetDate }
    }

    var completedGoals: [GoalItem] {
        goals.filter(\.isCompleted).sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var accompanimentLine: String {
        switch streak {
        case 0:
            return "Empieza hoy con un gesto pequeño 🌱"
        case 1:
            return "Llevas 1 día acompañándote"
        default:
            return "Llevas \(streak) días acompañándote"
        }
    }

    var streak: Int {
        let calendar = Calendar.current
        let completedDays = Set(challengeEntries.map(\.dayKey))

        let today = calendar.startOfDay(for: .now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let startingDay: Date
        if completedDays.contains(LogrosDateHelper.dayKey(for: today)) {
            startingDay = today
        } else if completedDays.contains(LogrosDateHelper.dayKey(for: yesterday)) {
            startingDay = yesterday
        } else {
            return 0
        }

        var count = 0
        var currentDay = startingDay

        while completedDays.contains(LogrosDateHelper.dayKey(for: currentDay)) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: currentDay) else { break }
            currentDay = previous
        }

        return count
    }

    var insightErrorBinding: Binding<Bool> {
        Binding(
            get: { insightError != nil },
            set: { newValue in
                if !newValue { insightError = nil }
            }
        )
    }

    func startChallenge(_ title: String) {
        challengeTitle = title
        challengeReflection = ""
        isCustomChallenge = false
        showAddChallengeSheet = true
    }

    func startCustomChallenge() {
        challengeTitle = ""
        challengeReflection = ""
        isCustomChallenge = true
        showAddChallengeSheet = true
    }

    func saveChallenge() {
        guard let title = challengeTitle.trimmedNonEmpty,
              let reflection = challengeReflection.trimmedNonEmpty else { return }

        let entry = ChallengeEntry(
            date: .now,
            title: title,
            reflection: reflection
        )

        context.insert(entry)
        guard persistChanges(action: "saveChallenge") else { return }

        feedbackToken += 1
        resetChallengeDraft()
        showAddChallengeSheet = false
    }

    func resetChallengeDraft() {
        challengeTitle = ""
        challengeReflection = ""
        isCustomChallenge = false
    }

    func deleteChallenge(_ entry: ChallengeEntry) {
        context.delete(entry)
        _ = persistChanges(action: "deleteChallenge")
    }

    func saveGoal() {
        guard let title = goalTitle.trimmedNonEmpty else { return }

        let goal = GoalItem(
            title: title,
            detail: goalDetail,
            targetDate: goalDate
        )

        context.insert(goal)
        guard persistChanges(action: "saveGoal") else { return }

        feedbackToken += 1
        resetGoalDraft()
        showAddGoalSheet = false
    }

    func resetGoalDraft() {
        goalTitle = ""
        goalDetail = ""
        goalDate = Date()
    }

    func toggleGoal(_ goal: GoalItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
            goal.isCompleted.toggle()
            goal.completedAt = goal.isCompleted ? .now : nil
        }

        _ = persistChanges(action: "toggleGoal")
        feedbackToken += 1
    }

    func deleteGoal(_ goal: GoalItem) {
        context.delete(goal)
        _ = persistChanges(action: "deleteGoal")
    }

    @discardableResult
    func persistChanges(action: String) -> Bool {
        do {
            try context.save()
            print("✅ [Logros] Save OK (\(action))")
            return true
        } catch {
            context.rollback()
            print("❌ [Logros] Save FAILED (\(action)): \(error.localizedDescription)")
            return false
        }
    }

    func formattedEstimatedTime(_ seconds: Double) -> String {
        let total = Int(seconds)
        let minutes = total / 60
        let remainingSeconds = total % 60

        if minutes >= 60 {
            let hours = minutes / 60
            let leftoverMinutes = minutes % 60
            return "\(hours)h \(leftoverMinutes)m"
        }

        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        }

        return "\(remainingSeconds)s"
    }
}

// MARK: - GROQ

private extension LogrosViews {
    var groqAPIKey: String? {
        if let keyFromPlist = (Bundle.main.object(forInfoDictionaryKey: "GROQ_API_KEY") as? String)?.trimmedNonEmpty {
            return keyFromPlist
        }

        // Fallback temporal para no bloquear pruebas en dispositivo mientras se estabiliza Info.plist.
        return "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".trimmedNonEmpty
    }

    func generateInsight() async {
        guard !todayEntries.isEmpty else { return }

        guard let apiKey = groqAPIKey else {
            insightError = "No encontré tu GROQ_API_KEY en Info.plist."
            return
        }

        isGeneratingInsight = true
        defer { isGeneratingInsight = false }

        let prompt = buildInsightPrompt()

        let requestBody = GroqChatRequest(
            model: "llama-3.1-8b-instant",
            messages: [
                GroqMessage(
                    role: "system",
                    content: """
                    Eres un acompañante emocional amable. Responde en español de México.
                    Tu tarea es interpretar el día del usuario a partir de sus acciones y reflexiones.
                    No diagnostiques, no hagas afirmaciones clínicas, no des consejos médicos.
                    Devuelve un texto breve y cálido con esta estructura exacta:
                    Síntesis:
                    ...
                    
                    Patrones:
                    ...
                    
                    Sugerencia amable:
                    ...
                    """
                ),
                GroqMessage(
                    role: "user",
                    content: prompt
                )
            ],
            temperature: 0.7,
            max_tokens: 260
        )

        do {
            var request = URLRequest(url: URL(string: "https://api.groq.com/openai/v1/chat/completions")!)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                insightError = "No pude validar la respuesta del servidor."
                return
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                if let groqError = try? JSONDecoder().decode(GroqErrorResponse.self, from: data) {
                    insightError = groqError.error.message
                } else {
                    insightError = "Groq respondió con error \(httpResponse.statusCode)."
                }
                return
            }

            let decoded = try JSONDecoder().decode(GroqChatResponse.self, from: data)
            guard let content = decoded.choices.first?.message.content.trimmedNonEmpty else {
                insightError = "La respuesta vino vacía."
                return
            }

            saveInsight(content)
            feedbackToken += 1

        } catch {
            insightError = error.localizedDescription
        }
    }

    func buildInsightPrompt() -> String {
        let reflections = todayEntries.enumerated().map { index, entry in
            """
            \(index + 1). Reto: \(entry.title)
            Reflexión: \(entry.reflection)
            """
        }.joined(separator: "\n\n")

        let activeGoalsText: String = {
            if pendingGoals.isEmpty { return "No hay metas activas." }
            return pendingGoals.map {
                "- \($0.title) (fecha objetivo: \($0.targetDate.formatted(date: .abbreviated, time: .omitted)))"
            }.joined(separator: "\n")
        }()

        let completedGoalsText: String = {
            if completedGoals.isEmpty { return "No hay metas completadas recientemente." }
            return completedGoals.prefix(3).map {
                "- \($0.title)"
            }.joined(separator: "\n")
        }()

        let lastMediaText: String = {
            guard hasLastMedia else { return "No hay contenido reciente escuchado o visto." }

            return """
            Título: \(lastPlayedTitle)
            Autor: \(lastPlayedAuthor)
            Tipo: \(lastPlayedKind)
            Fuente: \(lastPlayedSource)
            Tiempo estimado: \(lastPlayedEstimatedSeconds >= 5 ? formattedEstimatedTime(lastPlayedEstimatedSeconds) : "muy breve")
            """
        }()

        return """
        Interpreta cómo fue mi día con base en esta información.

        Retos y reflexiones de hoy:
        \(reflections)

        Último contenido consumido:
        \(lastMediaText)

        Metas activas:
        \(activeGoalsText)

        Metas completadas:
        \(completedGoalsText)

        Quiero una lectura amable, clara y útil. No me diagnostiques.
        """
    }

    func saveInsight(_ text: String) {
        if let existing = todayInsight {
            existing.summaryText = text
            existing.generatedAt = .now
        } else {
            let insight = DailyInsightSummary(
                date: .now,
                summaryText: text,
                generatedAt: .now
            )
            context.insert(insight)
        }

        if !persistChanges(action: "saveInsight") {
            insightError = "No se pudo guardar el resumen. Revisa la consola para ver el error de SwiftData."
        }
    }
}

// MARK: - BACKGROUND

private extension LogrosViews {
    var logrosBackground: some View {
        LinearGradient(
            colors: [
                Color.purple.opacity(0.16),
                Color.blue.opacity(0.12),
                Color.white,
                Color.mint.opacity(0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(Color.purple.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 42)
                .offset(x: -80, y: -40)
        }
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(Color.blue.opacity(0.08))
                .frame(width: 260, height: 260)
                .blur(radius: 42)
                .offset(x: 90, y: 90)
        }
    }
}

// MARK: - HELPERS

private enum LogrosDateHelper {
    static func dayKey(for date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return "\(year)-\(month)-\(day)"
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - PREVIEW

#Preview {
    NavigationStack {
        LogrosViews()
            .modelContainer(
                for: [
                    ChallengeEntry.self,
                    GoalItem.self,
                    DailyInsightSummary.self
                ],
                inMemory: true
            )
    }
}
