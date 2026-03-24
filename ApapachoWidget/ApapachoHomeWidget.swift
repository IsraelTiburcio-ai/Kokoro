import WidgetKit
import SwiftUI

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
                Color(red: 0.95, green: 0.89, blue: 0.84),
                Color(red: 0.89, green: 0.93, blue: 0.98),
                Color(red: 0.92, green: 0.97, blue: 0.92)
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
            Text("Tu dia")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            if entry.payload.challengeTitle == ApapachoWidgetPayload.empty.challengeTitle,
               entry.payload.goals.isEmpty {
                Text("Sin datos por ahora")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                Text("Abre Apapacho")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            } else {
                Text("Reto")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.74, green: 0.41, blue: 0.20))

                Text(entry.payload.challengeTitle)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(3)

                Spacer(minLength: 0)

                Text("Progreso: \(progressText)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var mediumBody: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Reto del dia")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.74, green: 0.41, blue: 0.20))

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
            .background(Color.white.opacity(0.42))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

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
                                    .fill(Color(red: 0.20, green: 0.63, blue: 0.57))
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
            .background(Color.white.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            updatedAt: .now
        )
    )
}
