import Foundation
import CoreLocation

@MainActor
final class AppStore: ObservableObject {
    @Published var courts: [Court]
    @Published var filters = CourtFilters()
    @Published var selectedCourt: Court?
    @Published var savedCourtIDs: Set<String>
    @Published var suggestions: [CourtSuggestion] = []
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

    func addMissingCourt(name: String, area: String, latitude: Double, longitude: Double, courtType: CourtType) {
        let court = Court(
            id: "user-\(UUID().uuidString)",
            name: name.isEmpty ? "Untitled court" : name,
            area: area.isEmpty ? "Area pending" : area,
            city: "Local",
            latitude: latitude,
            longitude: longitude,
            source: .userSuggested,
            sourceLicense: "User submitted",
            confidence: .userSuggested,
            lastCheckedAt: "Pending review",
            courtType: courtType,
            accessType: .unknown,
            priceType: .unknown,
            hasLights: .unknown,
            drynessAfterRain: .unknown,
            slipperyWhenWet: .unknown,
            rainPlayable: .unknown,
            surfaceType: .unknown,
            surfaceCondition: .unknown,
            courtCleanliness: .unknown,
            courtSpace: .unknown,
            runoffSafety: .unknown,
            peakTimes: [.unknown],
            hasNets: .unknown,
            rimHeight: .unknown,
            rimType: .unknown,
            backboardCondition: .unknown,
            rimCondition: .unknown,
            hoopCount: nil,
            openingHours: "Unknown",
            eveningAccess: .unknown,
            hasToilets: .unknown,
            hasDrinkingWater: .unknown,
            hasParking: .unknown,
            hasChangingRooms: .unknown,
            goodForSolo: .unknown,
            goodForPickup: .unknown,
            goodForTraining: .unknown,
            beginnerFriendly: .unknown,
            notes: "Submitted from the app. Needs review."
        )
        courts.insert(court, at: 0)
        selectedCourt = court
    }
}
