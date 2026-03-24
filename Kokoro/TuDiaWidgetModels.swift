import Foundation

enum ApapachoAppGroup {
	// Replace with your real App Group identifier in Apple Developer + Xcode capabilities.
	static let suiteName = "group.yo.Kokoro.apapacho"
}

enum ApapachoWidgetSharedKeys {
	static let homePayload = "apapacho.home.widget.payload"
}

struct ApapachoWidgetGoal: Codable, Identifiable, Hashable {
	let id: UUID
	let title: String
	let detail: String
	let isCompleted: Bool
}

struct ApapachoWidgetPayload: Codable {
	let challengeTitle: String
	let challengeSubtitle: String
	let goals: [ApapachoWidgetGoal]
	let updatedAt: Date

	var totalGoals: Int {
		goals.count
	}

	var completedGoals: Int {
		goals.filter(\.isCompleted).count
	}

	var pendingGoals: [ApapachoWidgetGoal] {
		goals.filter { !$0.isCompleted }
	}

	static let empty = ApapachoWidgetPayload(
		challengeTitle: "Sin reto por ahora",
		challengeSubtitle: "Abre Apapacho para crear una accion de hoy.",
		goals: [],
		updatedAt: .now
	)
}

enum ApapachoWidgetSharedStore {
	static func save(_ payload: ApapachoWidgetPayload) {
		guard let defaults = UserDefaults(suiteName: ApapachoAppGroup.suiteName) else { return }

		do {
			let data = try JSONEncoder().encode(payload)
			defaults.set(data, forKey: ApapachoWidgetSharedKeys.homePayload)
		} catch {
			// Keep this silent for widget resiliency.
		}
	}

	static func load() -> ApapachoWidgetPayload {
		guard let defaults = UserDefaults(suiteName: ApapachoAppGroup.suiteName),
			  let data = defaults.data(forKey: ApapachoWidgetSharedKeys.homePayload),
			  let payload = try? JSONDecoder().decode(ApapachoWidgetPayload.self, from: data) else {
			return .empty
		}

		return payload
	}
}
