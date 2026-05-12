import Foundation

enum CourtSeedStore {
    static func loadCourts() -> [Court] {
        guard let url = Bundle.main.url(forResource: "CourtsSeed", withExtension: "json") else {
            return fallbackCourts
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode([Court].self, from: data)
        } catch {
            return fallbackCourts
        }
    }

    static let fallbackCourts: [Court] = [
        Court(
            id: "fallback-dev-green",
            name: "Devonshire Green Court",
            area: "City Centre",
            city: "Local",
            latitude: 53.3802,
            longitude: -1.4795,
            source: .hoopLifeManual,
            sourceLicense: "HoopLife manual seed",
            confidence: .needsCheck,
            lastCheckedAt: "2026-05-12",
            courtType: .outdoor,
            accessType: .public,
            priceType: .free,
            hasLights: .no,
            drynessAfterRain: .slowToDry,
            slipperyWhenWet: .sometimes,
            rainPlayable: .partially,
            surfaceType: .concrete,
            surfaceCondition: .worn,
            courtCleanliness: .acceptable,
            courtSpace: .tightEdges,
            runoffSafety: .limited,
            peakTimes: [.weekdayEvening, .weekendAfternoon],
            hasNets: .unknown,
            rimHeight: .unknown,
            rimType: .unknown,
            backboardCondition: .unknown,
            rimCondition: .unknown,
            hoopCount: 2,
            openingHours: "Open access, not officially confirmed",
            eveningAccess: .unknown,
            hasToilets: .nearby,
            hasDrinkingWater: .unknown,
            hasParking: .nearby,
            hasChangingRooms: .no,
            goodForSolo: .yes,
            goodForPickup: .sometimes,
            goodForTraining: .yes,
            beginnerFriendly: .yes,
            notes: "Seed record for MVP prototyping."
        )
    ]
}
