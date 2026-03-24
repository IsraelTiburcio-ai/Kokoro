import WidgetKit
import SwiftUI
import UIKit

struct ApapachoHomeEntry: TimelineEntry {
    let date: Date
    let payload: ApapachoWidgetPayload
}

struct ApapachoHomeProvider: TimelineProvider {
    func placeholder(in context: Context) -> ApapachoHomeEntry {
        ApapachoHomeEntry(
            date: .now,
            payload: ApapachoWidgetPayload(
                challengeTitle: "Respira 2 minutos",
                challengeSubtitle: "Haz una pausa y nota como te sientes.",
                goals: [
                    ApapachoWidgetGoal(id: UUID(), title: "Tomar agua", detail: "8 vasos", isCompleted: true),
                    ApapachoWidgetGoal(id: UUID(), title: "Caminar", detail: "15 min", isCompleted: false),
                    ApapachoWidgetGoal(id: UUID(), title: "Escribir diario", detail: "3 lineas", isCompleted: false)
                ],
                companionRawValue: ApapachoCompanion.none.rawValue,
                updatedAt: .now
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ApapachoHomeEntry) -> Void) {
        completion(ApapachoHomeEntry(date: .now, payload: ApapachoWidgetSharedStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ApapachoHomeEntry>) -> Void) {
        let entry = ApapachoHomeEntry(date: .now, payload: ApapachoWidgetSharedStore.load())
        // Refresh periodically as a safety net; app-triggered reload is primary path.
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}

struct ApapachoHomeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ApapachoHomeProvider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            smallBody
                .containerBackground(for: .widget) { background }
        default:
            mediumBody
                .containerBackground(for: .widget) { background }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color.purple.opacity(0.10),
                Color.blue.opacity(0.08),
                Color.white.opacity(0.04),
                Color.mint.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var progressText: String {
        "\(entry.payload.completedGoals) de \(entry.payload.totalGoals)"
    }

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Retos y metas")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)

                companionAvatar(size: 28)
            }

            if entry.payload.challengeTitle == ApapachoWidgetPayload.empty.challengeTitle,
               entry.payload.goals.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sin datos por ahora")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    Text("Abre Apapacho")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(Color.white.opacity(0.16))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                Text("Reto")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.purple)

                Text(entry.payload.challengeTitle)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.12), Color.blue.opacity(0.10), Color.white.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Spacer(minLength: 0)

                Text("Progreso: \(progressText)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Capsule(style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var mediumBody: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("Reto del dia")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.purple)

                    Spacer(minLength: 0)

                    companionAvatar(size: 30)
                }

                if entry.payload.challengeTitle == ApapachoWidgetPayload.empty.challengeTitle,
                   entry.payload.goals.isEmpty {
                    Text("Aun no hay informacion")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text("Abre Apapacho para crear tu reto y metas.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                } else {
                    Text(entry.payload.challengeTitle)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(3)

                    Text(entry.payload.challengeSubtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.12), Color.blue.opacity(0.10), Color.white.opacity(0.14)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Metas")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("\(entry.payload.completedGoals) de \(entry.payload.totalGoals) completadas")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if entry.payload.pendingGoals.isEmpty {
                    Text("Sin metas pendientes")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(entry.payload.pendingGoals.prefix(3))) { goal in
                            HStack(alignment: .top, spacing: 5) {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 5, height: 5)
                                    .padding(.top, 5)

                                Text(goal.title)
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .background(Color.white.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private func companionAvatar(size: CGFloat) -> some View {
        if entry.payload.companion == .custom,
           let data = ApapachoCompanionImageStore.loadCustomAvatarData(),
           let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.42), lineWidth: 1)
                }
        } else if let assetName = entry.payload.companion.assetName {
            Image(assetName)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.42), lineWidth: 1)
                }
        }
    }
}

struct ApapachoHomeWidget: Widget {
    let kind: String = "ApapachoDailyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ApapachoHomeProvider()) { entry in
            ApapachoHomeWidgetView(entry: entry)
        }
        .configurationDisplayName("Apapacho: Tu dia")
        .description("Mira tu reto del dia y tus metas pendientes.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    ApapachoHomeWidget()
} timeline: {
    ApapachoHomeEntry(
        date: .now,
        payload: ApapachoWidgetPayload(
            challengeTitle: "Respira 2 minutos",
            challengeSubtitle: "Pausa suave antes de seguir.",
            goals: [
                ApapachoWidgetGoal(id: UUID(), title: "Tomar agua", detail: "8 vasos", isCompleted: true),
                ApapachoWidgetGoal(id: UUID(), title: "Caminar", detail: "15 min", isCompleted: false)
            ],
            companionRawValue: ApapachoCompanion.grandma.rawValue,
            updatedAt: .now
        )
    )
}

#Preview(as: .systemMedium) {
    ApapachoHomeWidget()
} timeline: {
    ApapachoHomeEntry(
        date: .now,
        payload: ApapachoWidgetPayload(
            challengeTitle: "Agradece algo de tu cuerpo hoy",
            challengeSubtitle: "Una frase honesta y amable contigo.",
            goals: [
                ApapachoWidgetGoal(id: UUID(), title: "Tomar agua", detail: "8 vasos", isCompleted: true),
                ApapachoWidgetGoal(id: UUID(), title: "Caminar", detail: "15 min", isCompleted: false),
                ApapachoWidgetGoal(id: UUID(), title: "Escribir diario", detail: "3 lineas", isCompleted: false)
            ],
            companionRawValue: ApapachoCompanion.grandpa.rawValue,
            updatedAt: .now
        )
    )
}
