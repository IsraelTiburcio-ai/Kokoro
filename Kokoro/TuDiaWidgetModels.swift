import Foundation

enum ApapachoAppGroup {
	// Replace with your real App Group identifier in Apple Developer + Xcode capabilities.
	static let suiteName = "group.yo.Kokoro.apapacho"
}

enum ApapachoWidgetSharedKeys {
	static let homePayload = "apapacho.home.widget.payload"
}

enum ApapachoCompanion: String, Codable, CaseIterable {
	case none
	case grandma
	case grandpa
	case custom

	var displayName: String {
		switch self {
		case .none:
			return "Ninguno"
		case .grandma:
			return "Abuelita"
		case .grandpa:
			return "Abuelito"
		case .custom:
			return "Tu foto"
		}
	}

	var assetName: String? {
		switch self {
		case .none:
			return nil
		case .grandma:
			return "companion_abuelita"
		case .grandpa:
			return "companion_abuelito"
		case .custom:
			return nil
		}
	}
}

enum ApapachoCompanionImageStore {
	private static let fileName = "apapacho_custom_companion_image"

	static func saveCustomAvatarData(_ data: Data) -> Bool {
		guard let url = fileURL else { return false }

		do {
			try data.write(to: url, options: .atomic)
			return true
		} catch {
			return false
		}
	}

	static func loadCustomAvatarData() -> Data? {
		guard let url = fileURL else { return nil }
		return try? Data(contentsOf: url)
	}

	private static var fileURL: URL? {
		FileManager.default
			.containerURL(forSecurityApplicationGroupIdentifier: ApapachoAppGroup.suiteName)?
			.appendingPathComponent(fileName)
	}
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
	let companionRawValue: String
	let updatedAt: Date

	var companion: ApapachoCompanion {
		ApapachoCompanion(rawValue: companionRawValue) ?? .none
	}

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
		companionRawValue: ApapachoCompanion.none.rawValue,
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
