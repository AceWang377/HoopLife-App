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

    private let savedKey = "hooplife.savedCourts"
    private let onboardingKey = "hooplife.hasCompletedOnboarding"

    init(courts: [Court] = CourtSeedStore.loadCourts()) {
        self.courts = courts
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
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
