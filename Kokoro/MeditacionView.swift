import SwiftUI
import SwiftData
import CryptoKit
import LinkPresentation
import UIKit
import Combine

// MARK: - Modelo de catálogo

struct MediaItem: Identifiable, Hashable {
    enum Platform: String, Codable {
        case spotify = "Spotify"
        case youtube = "YouTube"
        case applePodcasts = "Apple Podcasts"

        var brandColor: Color {
            switch self {
            case .spotify:
                return Color(red: 0.12, green: 0.73, blue: 0.33)
            case .youtube:
                return Color(red: 1.0, green: 0.23, blue: 0.19)
            case .applePodcasts:
                return Color(red: 0.62, green: 0.29, blue: 0.94)
            }
        }

        var systemImage: String {
            switch self {
            case .spotify:
                return "waveform.circle.fill"
            case .youtube:
                return "play.rectangle.fill"
            case .applePodcasts:
                return "mic.circle.fill"
            }
        }
    }

    enum Kind: String, Codable {
        case meditation = "Meditación"
        case podcast = "Podcast"
        case healingTalk = "Reflexión"
    }

    let id: UUID
    let title: String
    let subtitle: String
    let author: String
    let durationLabel: String
    let platform: Platform
    let kind: Kind
    let link: String
    let imageSystemName: String
    let accentHex: String

    init(
        id: UUID? = nil,
        title: String,
        subtitle: String,
        author: String,
        durationLabel: String,
        platform: Platform,
        kind: Kind,
        link: String,
        imageSystemName: String,
        accentHex: String
    ) {
        self.id = id ?? Self.deterministicID(from: link)
        self.title = title
        self.subtitle = subtitle
        self.author = author
        self.durationLabel = durationLabel
        self.platform = platform
        self.kind = kind
        self.link = link
        self.imageSystemName = imageSystemName
        self.accentHex = accentHex
    }

    var accentColor: Color {
        Color(hex: accentHex)
    }

    // Stable IDs ensure progress records keep matching after app relaunches.
    private static func deterministicID(from seed: String) -> UUID {
        let digest = SHA256.hash(data: Data(seed.utf8))
        var bytes = Array(digest.prefix(16))

        // Set UUID version/variant bits to produce a standards-compliant UUID.
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        let tuple: uuid_t = (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        )

        return UUID(uuid: tuple)
    }
}

// MARK: - Persistencia SwiftData

@Model
final class MediaProgressRecord {
    @Attribute(.unique) var mediaID: UUID
    var title: String
    var source: String
    var lastWatched: Date?
    var progress: Double
    var isCompleted: Bool
    var estimatedListenSeconds: Double

    init(
        mediaID: UUID,
        title: String,
        source: String,
        lastWatched: Date? = nil,
        progress: Double = 0,
        isCompleted: Bool = false,
        estimatedListenSeconds: Double = 0
    ) {
        self.mediaID = mediaID
        self.title = title
        self.source = source
        self.lastWatched = lastWatched
        self.progress = progress
        self.isCompleted = isCompleted
        self.estimatedListenSeconds = estimatedListenSeconds
    }
}

// MARK: - Link Preview

struct LinkPreviewData {
    let title: String?
    let image: UIImage?
}

@MainActor
final class LinkPreviewStore: ObservableObject {
    @Published private(set) var previews: [URL: LinkPreviewData] = [:]

    private var loadingURLs: Set<URL> = []

    func preview(for item: MediaItem) -> LinkPreviewData? {
        guard let url = URL(string: item.link) else { return nil }
        return previews[url]
    }

    func fetchIfNeeded(for item: MediaItem) {
        guard let url = URL(string: item.link) else { return }
        guard previews[url] == nil, !loadingURLs.contains(url) else { return }

        loadingURLs.insert(url)

        Task { @MainActor in
            defer { loadingURLs.remove(url) }

            do {
                let metadata = try await LPMetadataProvider().startFetchingMetadata(for: url)
                let image: UIImage?
                if let primaryImage = await Self.loadImage(from: metadata.imageProvider) {
                    image = primaryImage
                } else {
                    image = await Self.loadImage(from: metadata.iconProvider)
                }

                previews[url] = LinkPreviewData(
                    title: metadata.title,
                    image: image
                )
            } catch {
                previews[url] = LinkPreviewData(title: nil, image: nil)
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

// MARK: - Session tracking

private struct PlaybackSession {
    let itemID: UUID
    let startedAt: Date
}

// MARK: - Vista Principal

struct MeditationHubView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    @Query(sort: \MediaProgressRecord.lastWatched, order: .reverse)
    private var progressRecords: [MediaProgressRecord]

    @AppStorage("lastPlayedTitle") private var lastPlayedTitle: String = ""
    @AppStorage("lastPlayedSource") private var lastPlayedSource: String = ""
    @AppStorage("lastPlayedKind") private var lastPlayedKind: String = ""
    @AppStorage("lastPlayedAuthor") private var lastPlayedAuthor: String = ""
    @AppStorage("lastPlayedEstimatedSeconds") private var lastPlayedEstimatedSeconds: Double = 0

    @StateObject private var previewStore = LinkPreviewStore()

    @State private var selectedID: UUID?
    @State private var appeared = false
    @State private var currentSession: PlaybackSession?
    @State private var showResetProgressAlert = false

    private let featuredMeditations: [MediaItem] = [
        .init(
            title: "15 minutos mágicos para eliminar ansiedad",
            subtitle: "Meditación guiada para soltar tensión y bajar revoluciones.",
            author: "Anabel Otero",
            durationLabel: "15 min",
            platform: .youtube,
            kind: .meditation,
            link: "https://www.youtube.com/watch?v=aBsnQjJ2_Nk",
            imageSystemName: "sparkles",
            accentHex: "#5B8CFF"
        ),
        .init(
            title: "Meditación guiada enfocada en la NADA",
            subtitle: "Una pausa distinta para vaciar la mente y observar.",
            author: "Migala",
            durationLabel: "Guiada",
            platform: .spotify,
            kind: .meditation,
            link: "https://open.spotify.com/episode/3p6pdrIFhKyiNUw8dLfCZu",
            imageSystemName: "moon.stars.fill",
            accentHex: "#A855F7"
        )
    ]

    private let podcastAndTalks: [MediaItem] = [
        .init(
            title: "Entiende Tu Mente",
            subtitle: "Conversaciones claras sobre emociones, ansiedad y bienestar.",
            author: "Molo Cebrián",
            durationLabel: "Serie",
            platform: .spotify,
            kind: .podcast,
            link: "https://open.spotify.com/show/0sGGLIDnnijRPLef7InllD?si=c48dd25f9dea4632",
            imageSystemName: "brain.head.profile",
            accentHex: "#EC4899"
        ),
        .init(
            title: "¿Esto que me pasa es normal?",
            subtitle: "Ansiedad, comparación y cómo recuperar calma.",
            author: "Entiende Tu Mente",
            durationLabel: "Episodio",
            platform: .applePodcasts,
            kind: .podcast,
            link: "https://podcasts.apple.com/mx/podcast/entiende-tu-mente/id1229124446",
            imageSystemName: "heart.text.square.fill",
            accentHex: "#8B5CF6"
        ),
        .init(
            title: "Humano “iluminado”",
            subtitle: "Una reflexión intensa sobre conciencia e identidad.",
            author: "Diego Dreyfus",
            durationLabel: "Audio",
            platform: .spotify,
            kind: .podcast,
            link: "https://open.spotify.com/episode/5z9y69NdXB5sfdRStTPfv9",
            imageSystemName: "figure.mind.and.body",
            accentHex: "#3B82F6"
        ),
        .init(
            title: "¿Es un juego o una historia?",
            subtitle: "Tal vez sólo es poesía. Un audio para pensar y sentir distinto.",
            author: "Migala",
            durationLabel: "Audio",
            platform: .spotify,
            kind: .podcast,
            link: "https://open.spotify.com/episode/5xkiUn3FNqw5OTEx8Gqv3k",
            imageSystemName: "book.pages.fill",
            accentHex: "#14B8A6"
        ),
        .init(
            title: "Tú y yo ¿Qué Somos?",
            subtitle: "Una exploración emocional sobre vínculos y significado.",
            author: "Migala",
            durationLabel: "Audio",
            platform: .spotify,
            kind: .podcast,
            link: "https://open.spotify.com/episode/0OX0UtoxrB3kNg1aYZE4YF",
            imageSystemName: "person.2.fill",
            accentHex: "#F59E0B"
        ),
        .init(
            title: "Aprender a soltar",
            subtitle: "Apegos, límites sanos y contacto cero explicado con sensibilidad.",
            author: "Se Regalan Dudas",
            durationLabel: "Episodio",
            platform: .youtube,
            kind: .healingTalk,
            link: "https://www.youtube.com/watch?v=hAW2bX8ll38",
            imageSystemName: "leaf.fill",
            accentHex: "#22C55E"
        )
    ]

    private var allItems: [MediaItem] {
        featuredMeditations + podcastAndTalks
    }

    var body: some View {
        ZStack {
            ZenAnimatedBackground()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 28) {
                    heroSection

                    if !continueWatchingItems.isEmpty {
                        continueWatchingSection
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .opacity
                                )
                            )
                    }

                    sectionHeader(
                        title: "Respira ahora",
                        subtitle: "Contenido corto y guiado para regresar a tu centro."
                    )

                    LazyVStack(spacing: 18) {
                        ForEach(featuredMeditations) { item in
                            FeaturedMeditationCard(
                                item: item,
                                preview: previewStore.preview(for: item),
                                progress: progressValue(for: item),
                                estimatedListenText: estimatedListenText(for: item),
                                isCompleted: isCompleted(item),
                                isSelected: selectedID == item.id
                            ) {
                                handleTap(on: item)
                            }
                            .task {
                                previewStore.fetchIfNeeded(for: item)
                            }
                        }
                    }

                    sectionHeader(
                        title: "Explora tu mente",
                        subtitle: "Podcasts y conversaciones para acompañarte con más calma."
                    )

                    LazyVStack(spacing: 14) {
                        ForEach(podcastAndTalks) { item in
                            CompactMediaCard(
                                item: item,
                                preview: previewStore.preview(for: item),
                                progress: progressValue(for: item),
                                estimatedListenText: estimatedListenText(for: item),
                                isCompleted: isCompleted(item)
                            ) {
                                handleTap(on: item)
                            }
                            .task {
                                previewStore.fetchIfNeeded(for: item)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.selection, trigger: selectedID)
        .animation(.spring(response: 0.55, dampingFraction: 0.86), value: continueWatchingItems.count)
        .onAppear {
            appeared = true
            migrateLegacyProgressIDsIfNeeded()
            allItems.forEach { previewStore.fetchIfNeeded(for: $0) }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                finalizeExternalPlaybackSession()
            }
        }
        .alert("¿Resetear progreso de meditación?", isPresented: $showResetProgressAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Resetear", role: .destructive) {
                resetMeditationProgress()
            }
        } message: {
            Text("Se borrará tu progreso guardado y el último contenido reproducido.")
        }
    }
}

// MARK: - Secciones

private extension MeditationHubView {
    var heroSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.30), lineWidth: 1)
                        }
                        .frame(width: 70, height: 70)

                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#D946EF"),
                                    Color(hex: "#8B5CF6"),
                                    Color(hex: "#3B82F6")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("Tu espacio para volver a ti")
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Abre contenido y deja que la app recuerde qué te acompañó.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            DailyZenBanner()

            Button {
                showResetProgressAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                    Text("Resetear progreso")
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.white.opacity(0.56))
                .clipShape(Capsule(style: .continuous))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
    }

    var continueWatchingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                title: "Continuar viendo",
                subtitle: "Retoma donde te quedaste."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(continueWatchingItems) { item in
                        ContinueWatchingCard(
                            item: item,
                            preview: previewStore.preview(for: item),
                            progress: progressValue(for: item),
                            estimatedListenText: estimatedListenText(for: item)
                        ) {
                            handleTap(on: item)
                        }
                        .frame(width: 280)
                        .task {
                            previewStore.fetchIfNeeded(for: item)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
    }

    func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Lógica

private extension MeditationHubView {
    var continueWatchingItems: [MediaItem] {
        allItems.filter { item in
            let progress = progressValue(for: item)
            return progress > 0 && progress < 1 && !isCompleted(item)
        }
    }

    func record(for item: MediaItem) -> MediaProgressRecord? {
        progressRecords.first(where: { $0.mediaID == item.id })
    }

    func migrateLegacyProgressIDsIfNeeded() {
        var migratedCount = 0

        for item in allItems {
            guard record(for: item) == nil else { continue }

            let normalizedCurrentTitle = normalizeTitle(item.title)
            guard let legacy = progressRecords.first(where: {
                $0.source == item.platform.rawValue && normalizeTitle($0.title) == normalizedCurrentTitle
            }) else {
                continue
            }

            legacy.mediaID = item.id
            migratedCount += 1
        }

        if migratedCount > 0 {
            _ = persistChanges(action: "migrateLegacyProgressIDs")
        }
    }

    func progressValue(for item: MediaItem) -> Double {
        record(for: item)?.progress ?? 0
    }

    func isCompleted(_ item: MediaItem) -> Bool {
        record(for: item)?.isCompleted ?? false
    }

    func estimatedListenText(for item: MediaItem) -> String? {
        guard let seconds = record(for: item)?.estimatedListenSeconds, seconds >= 5 else { return nil }
        return "≈ \(formattedEstimatedTime(seconds))"
    }

    func handleTap(on item: MediaItem) {
        finalizeExternalPlaybackSession()

        selectedID = item.id

        lastPlayedTitle = resolvedTitle(for: item)
        lastPlayedSource = item.platform.rawValue
        lastPlayedKind = item.kind.rawValue
        lastPlayedAuthor = item.author

        markOpened(item)
        currentSession = PlaybackSession(itemID: item.id, startedAt: .now)

        guard let url = URL(string: item.link) else { return }
        openURL(url)
    }

    func resetMeditationProgress() {
        currentSession = nil
        selectedID = nil

        for record in progressRecords {
            modelContext.delete(record)
        }

        lastPlayedTitle = ""
        lastPlayedSource = ""
        lastPlayedKind = ""
        lastPlayedAuthor = ""
        lastPlayedEstimatedSeconds = 0

        _ = persistChanges(action: "resetMeditationProgress")
    }

    func markOpened(_ item: MediaItem) {
        if let existing = record(for: item) {
            existing.lastWatched = .now
            existing.title = resolvedTitle(for: item)
            existing.source = item.platform.rawValue
        } else {
            let new = MediaProgressRecord(
                mediaID: item.id,
                title: resolvedTitle(for: item),
                source: item.platform.rawValue,
                lastWatched: .now,
                progress: 0.03,
                isCompleted: false,
                estimatedListenSeconds: 0
            )
            modelContext.insert(new)
        }

        _ = persistChanges(action: "markOpened")
    }

    func finalizeExternalPlaybackSession() {
        guard let session = currentSession else { return }
        defer { currentSession = nil }

        guard let item = allItems.first(where: { $0.id == session.itemID }) else { return }

        let rawElapsed = Date().timeIntervalSince(session.startedAt)
        let elapsed = min(max(rawElapsed, 0), 60 * 60 * 3)

        guard elapsed >= 3 else { return }

        let resolvedDuration = resolvedDurationSeconds(for: item)

        if let existing = record(for: item) {
            existing.lastWatched = .now
            existing.title = resolvedTitle(for: item)
            existing.source = item.platform.rawValue
            existing.estimatedListenSeconds += elapsed

            if let duration = resolvedDuration, duration > 0 {
                existing.progress = min(1, existing.estimatedListenSeconds / duration)
                existing.isCompleted = existing.progress >= 0.98
            } else {
                existing.progress = min(0.95, existing.progress + min(0.25, elapsed / 1800))
            }

            lastPlayedEstimatedSeconds = existing.estimatedListenSeconds
        } else {
            let progress: Double
            if let duration = resolvedDuration, duration > 0 {
                progress = min(1, elapsed / duration)
            } else {
                progress = min(0.25, elapsed / 1800)
            }

            let new = MediaProgressRecord(
                mediaID: item.id,
                title: resolvedTitle(for: item),
                source: item.platform.rawValue,
                lastWatched: .now,
                progress: progress,
                isCompleted: progress >= 0.98,
                estimatedListenSeconds: elapsed
            )
            modelContext.insert(new)
            lastPlayedEstimatedSeconds = elapsed
        }

        _ = persistChanges(action: "finalizeExternalPlaybackSession")
    }

    @discardableResult
    func persistChanges(action: String) -> Bool {
        do {
            try modelContext.save()
            print("✅ [MeditationHub] Save OK (\(action))")
            return true
        } catch {
            modelContext.rollback()
            print("❌ [MeditationHub] Save FAILED (\(action)): \(error.localizedDescription)")
            return false
        }
    }

    func resolvedTitle(for item: MediaItem) -> String {
        let previewTitle = previewStore.preview(for: item)?.title?.trimmedNonEmpty
        return previewTitle ?? item.title
    }

    func resolvedDurationSeconds(for item: MediaItem) -> Double? {
        let label = item.durationLabel.lowercased()
        let digits = label.filter(\.isNumber)

        guard let minutes = Double(digits), minutes > 0 else { return nil }
        return minutes * 60
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

    func normalizeTitle(_ title: String) -> String {
        title
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Background

private struct ZenAnimatedBackground: View {
    @State private var animate = false

    var body: some View {
        Group {
            if #available(iOS 18.0, *) {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: animate
                    ? [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.55], [0.6, 0.45], [1.0, 0.5],
                        [0.0, 1.0], [0.45, 1.0], [1.0, 1.0]
                    ]
                    : [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.45], [0.4, 0.6], [1.0, 0.5],
                        [0.0, 1.0], [0.55, 1.0], [1.0, 1.0]
                    ],
                    colors: [
                        Color(hex: "#F5E8FA"),
                        Color(hex: "#E9EEFF"),
                        Color(hex: "#E7F6F8"),
                        Color(hex: "#F4E5FA"),
                        Color(hex: "#E3EFFF"),
                        Color(hex: "#E9F8F5"),
                        Color(hex: "#F7EEF9"),
                        Color(hex: "#EAF3FF"),
                        Color(hex: "#EDF9F8")
                    ]
                )
                .onAppear {
                    withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                        animate = true
                    }
                }
            } else {
                LinearGradient(
                    colors: [
                        Color(hex: "#F5E8FA"),
                        Color(hex: "#E9EEFF"),
                        Color(hex: "#EEF8F8")
                    ],
                    startPoint: animate ? .topLeading : .bottomTrailing,
                    endPoint: animate ? .bottomTrailing : .topLeading
                )
                .onAppear {
                    withAnimation(.easeInOut(duration: 7.5).repeatForever(autoreverses: true)) {
                        animate.toggle()
                    }
                }
            }
        }
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(Color(hex: "#D946EF").opacity(0.10))
                .frame(width: 280, height: 280)
                .blur(radius: 55)
                .offset(x: -95, y: -55)
        }
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(Color(hex: "#3B82F6").opacity(0.10))
                .frame(width: 300, height: 300)
                .blur(radius: 55)
                .offset(x: 90, y: 90)
        }
    }
}

// MARK: - Banner

private struct DailyZenBanner: View {
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.20))
                    .frame(width: 46, height: 46)

                Image(systemName: "link.circle.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Preview inteligente")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))

                Text("La meditación no es sólo para relajarse, sino también para mejorar la concentración y aumentar la creatividad.")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "#D946EF").opacity(0.86),
                    Color(hex: "#8B5CF6").opacity(0.84),
                    Color(hex: "#3B82F6").opacity(0.80)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: Color(hex: "#8B5CF6").opacity(0.18), radius: 22, x: 0, y: 12)
    }
}

// MARK: - Cards

private struct FeaturedMeditationCard: View {
    let item: MediaItem
    let preview: LinkPreviewData?
    let progress: Double
    let estimatedListenText: String?
    let isCompleted: Bool
    let isSelected: Bool
    let action: () -> Void

    private var displayTitle: String {
        preview?.title?.trimmedNonEmpty ?? item.title
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                MediaArtworkView(
                    item: item,
                    image: preview?.image,
                    size: CGSize(width: 102, height: 132),
                    cornerRadius: 26,
                    overlayText: progress > 0 && !isCompleted ? "Sigue" : nil
                )

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        BadgeView(text: item.kind.rawValue, tint: item.accentColor)
                        Spacer()
                        PlatformBadge(platform: item.platform)
                    }

                    Text(displayTitle)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)

                    Text(item.subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text(item.author)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        Label(item.durationLabel, systemImage: "clock")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)

                        if let estimatedListenText {
                            Text(estimatedListenText)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(item.platform.brandColor)
                        }

                        Spacer()

                        if isCompleted {
                            Label("Completado", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.green)
                        } else if progress > 0 {
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                        }
                    }

                    ProgressCapsule(progress: progress, accent: item.accentColor)
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(Color.white.opacity(0.34), lineWidth: 1)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.16),
                                        .clear,
                                        item.accentColor.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
            )
            .overlay {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(isSelected ? item.accentColor.opacity(0.45) : .clear, lineWidth: 1.4)
            }
            .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 8)
            .scaleEffect(isSelected ? 0.992 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

private struct CompactMediaCard: View {
    let item: MediaItem
    let preview: LinkPreviewData?
    let progress: Double
    let estimatedListenText: String?
    let isCompleted: Bool
    let action: () -> Void

    private var displayTitle: String {
        preview?.title?.trimmedNonEmpty ?? item.title
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                MediaArtworkView(
                    item: item,
                    image: preview?.image,
                    size: CGSize(width: 72, height: 72),
                    cornerRadius: 22,
                    overlayText: nil
                )

                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text(displayTitle)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Spacer(minLength: 8)

                        PlatformBadge(platform: item.platform)
                    }

                    Text(item.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(item.author)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Spacer()

                        if let estimatedListenText {
                            Text(estimatedListenText)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(item.platform.brandColor)
                        }

                        if isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else if progress > 0 {
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                        }
                    }

                    ProgressCapsule(progress: progress, accent: item.accentColor)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.30), lineWidth: 1)
                    }
            )
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}

private struct ContinueWatchingCard: View {
    let item: MediaItem
    let preview: LinkPreviewData?
    let progress: Double
    let estimatedListenText: String?
    let action: () -> Void

    private var displayTitle: String {
        preview?.title?.trimmedNonEmpty ?? item.title
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Continuar", systemImage: "play.fill")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer()

                    Text(item.platform.rawValue)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                }

                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    Text(displayTitle)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(item.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(2)

                    if let estimatedListenText {
                        Text(estimatedListenText)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.92))
                    }

                    ProgressCapsule(progress: progress, accent: .white.opacity(0.95), trackOpacity: 0.22)

                    Text("\(Int(progress * 100))% completado")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                }
            }
            .padding(20)
            .frame(height: 190)
            .background(
                LinearGradient(
                    colors: [
                        item.accentColor.opacity(0.92),
                        Color(hex: "#8B5CF6").opacity(0.80),
                        Color(hex: "#3B82F6").opacity(0.76)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: item.accentColor.opacity(0.22), radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Support Views

private struct MediaArtworkView: View {
    let item: MediaItem
    let image: UIImage?
    let size: CGSize
    let cornerRadius: CGFloat
    let overlayText: String?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            item.accentColor.opacity(0.92),
                            item.accentColor.opacity(0.60),
                            .white.opacity(0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.width, height: size.height)

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            } else {
                Image(systemName: item.imageSystemName)
                    .font(.system(size: min(size.width, size.height) * 0.28, weight: .bold))
                    .foregroundStyle(.white)
            }

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 1)
                .frame(width: size.width, height: size.height)

            if let overlayText {
                VStack {
                    Spacer()
                    Text(overlayText)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.16))
                        .clipShape(Capsule(style: .continuous))
                        .padding(.bottom, 10)
                }
                .frame(width: size.width, height: size.height)
            }
        }
    }
}

private struct BadgeView: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12))
            .clipShape(Capsule(style: .continuous))
    }
}

private struct PlatformBadge: View {
    let platform: MediaItem.Platform

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: platform.systemImage)
                .font(.system(size: 10, weight: .bold))

            Text(platform.rawValue)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(platform.brandColor)
        .clipShape(Capsule(style: .continuous))
    }
}

private struct ProgressCapsule: View {
    let progress: Double
    let accent: Color
    var trackOpacity: Double = 0.10

    var body: some View {
        GeometryReader { geo in
            let width = max(0, min(progress, 1)) * geo.size.width

            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(accent.opacity(trackOpacity))

                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                accent,
                                accent.opacity(0.72)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width)
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: progress)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Helpers

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (
                255,
                ((int >> 8) & 0xF) * 17,
                ((int >> 4) & 0xF) * 17,
                (int & 0xF) * 17
            )
        case 6:
            (a, r, g, b) = (
                255,
                int >> 16,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        case 8:
            (a, r, g, b) = (
                int >> 24,
                int >> 16 & 0xFF,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MeditationHubView()
            .modelContainer(for: MediaProgressRecord.self, inMemory: true)
    }
}
