import Foundation
import CoreLocation

@MainActor
final class AppStore: ObservableObject {
    @Published var courts: [Court]
    @Published var filters = CourtFilters()
    @Published var selectedCourt: Court?
    @Published var savedCourtIDs: Set<String>
    @Published var suggestions: [CourtSuggestion] = []
    @Published var courtCandidates: [CourtCandidate] = []
    @Published var hasCompletedOnboarding: Bool
    @Published var isAdminUnlocked: Bool

    private let savedKey = "hooplife.savedCourts"
    private let onboardingKey = "hooplife.hasCompletedOnboarding"
    private let courtsKey = "hooplife.courts.override"
    private let adminKey = "hooplife.adminUnlocked"
    private let adminPasscode = "HOOPLIFE-ADMIN"

    init(courts: [Court] = CourtSeedStore.loadCourts()) {
        self.courts = Self.loadPersistedCourts() ?? courts
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        self.isAdminUnlocked = UserDefaults.standard.bool(forKey: adminKey)
        let saved = UserDefaults.standard.stringArray(forKey: savedKey) ?? []
        self.savedCourtIDs = Set(saved)
    }

    var filteredCourts: [Court] {
        courts.filter { filters.matches($0) }
    }

    var savedCourts: [Court] {
        courts.filter { savedCourtIDs.contains($0.id) }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    func toggleSaved(_ court: Court) {
        if savedCourtIDs.contains(court.id) {
            savedCourtIDs.remove(court.id)
        } else {
            savedCourtIDs.insert(court.id)
        }
        UserDefaults.standard.set(Array(savedCourtIDs), forKey: savedKey)
    }

    func isSaved(_ court: Court) -> Bool {
        savedCourtIDs.contains(court.id)
    }

    func addSuggestion(_ suggestion: CourtSuggestion) {
        suggestions.insert(suggestion, at: 0)
    }

    func updateCourt(_ court: Court) {
        guard let index = courts.firstIndex(where: { $0.id == court.id }) else { return }
        courts[index] = court
        persistCourts()
    }

    func addApprovedCourt(_ court: Court) {
        courts.insert(court, at: 0)
        persistCourts()
    }

    func resetCourtsToSeed() {
        courts = CourtSeedStore.loadCourts()
        UserDefaults.standard.removeObject(forKey: courtsKey)
    }

    func unlockAdmin(passcode: String) -> Bool {
        let didUnlock = passcode.trimmingCharacters(in: .whitespacesAndNewlines) == adminPasscode
        if didUnlock {
            isAdminUnlocked = true
            UserDefaults.standard.set(true, forKey: adminKey)
        }
        return didUnlock
    }

    func lockAdmin() {
        isAdminUnlocked = false
        UserDefaults.standard.set(false, forKey: adminKey)
    }

    func submitCourtCandidate(name: String, area: String, latitude: Double, longitude: Double, courtType: CourtType) {
        courtCandidates.insert(
            CourtCandidate(
                name: name.isEmpty ? "Unnamed court candidate" : name,
                area: area.isEmpty ? "Area pending" : area,
                latitude: latitude,
                longitude: longitude,
                courtType: courtType
            ),
            at: 0
        )
    }

    private func persistCourts() {
        guard let data = try? JSONEncoder().encode(courts) else { return }
        UserDefaults.standard.set(data, forKey: courtsKey)
    }

    private static func loadPersistedCourts() -> [Court]? {
        guard let data = UserDefaults.standard.data(forKey: "hooplife.courts.override") else { return nil }
        return try? JSONDecoder().decode([Court].self, from: data)
    }
}

struct CourtCandidate: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var area: String
    var latitude: Double
    var longitude: Double
    var courtType: CourtType
    var submittedAt = Date()
}
