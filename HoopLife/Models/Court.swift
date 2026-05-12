import Foundation
import CoreLocation

struct Court: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var area: String
    var city: String
    var latitude: Double
    var longitude: Double
    var source: DataSource
    var sourceLicense: String
    var confidence: DataConfidence
    var lastCheckedAt: String
    var courtType: CourtType
    var accessType: AccessType
    var priceType: PriceType
    var hasLights: FactStatus
    var drynessAfterRain: DrynessAfterRain
    var slipperyWhenWet: FactStatus
    var rainPlayable: RainPlayable
    var surfaceType: SurfaceType
    var surfaceCondition: SurfaceCondition
    var courtCleanliness: CourtCleanliness
    var courtSpace: CourtSpace
    var runoffSafety: RunoffSafety
    var peakTimes: [PeakTime]
    var hasNets: NetsStatus
    var rimHeight: RimHeight
    var rimType: RimType
    var backboardCondition: HardwareCondition
    var rimCondition: HardwareCondition
    var hoopCount: Int?
    var openingHours: String
    var eveningAccess: EveningAccess
    var hasToilets: FacilityStatus
    var hasDrinkingWater: FacilityStatus
    var hasParking: FacilityStatus
    var hasChangingRooms: FactStatus
    var goodForSolo: FactStatus
    var goodForPickup: FactStatus
    var goodForTraining: FactStatus
    var beginnerFriendly: FactStatus
    var notes: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var topFacts: [CourtFact] {
        [
            CourtFact(label: courtType.displayName, tone: .neutral),
            CourtFact(label: priceType.displayName, tone: priceType == .free ? .positive : .neutral),
            CourtFact(label: drynessAfterRain.shortLabel, tone: drynessAfterRain.tone),
            CourtFact(label: hasNets.shortLabel, tone: hasNets.tone),
            CourtFact(label: hasLights.shortLightLabel, tone: hasLights == .yes ? .positive : hasLights == .no ? .warning : .unknown)
        ]
    }
}

struct CourtFact: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let tone: FactTone
}

enum FactTone: String, Codable {
    case positive
    case neutral
    case warning
    case unknown
}

enum DataSource: String, Codable, CaseIterable {
    case openStreetMap
    case activePlaces
    case hoopLifeManual
    case userSuggested

    var displayName: String {
        switch self {
        case .openStreetMap: "OpenStreetMap"
        case .activePlaces: "Sport England Active Places"
        case .hoopLifeManual: "HoopLife manual check"
        case .userSuggested: "User suggested"
        }
    }
}

enum DataConfidence: String, Codable, CaseIterable {
    case imported
    case needsCheck
    case userSuggested
    case verified
    case recentlyChecked

    var displayName: String {
        switch self {
        case .imported: "Imported"
        case .needsCheck: "Needs check"
        case .userSuggested: "User suggested"
        case .verified: "Verified"
        case .recentlyChecked: "Recently checked"
        }
    }
}

enum CourtType: String, Codable, CaseIterable {
    case indoor
    case outdoor
    case mixed
    case unknown

    var displayName: String {
        switch self {
        case .indoor: "Indoor"
        case .outdoor: "Outdoor"
        case .mixed: "Mixed"
        case .unknown: "Unknown type"
        }
    }
}

enum AccessType: String, Codable, CaseIterable {
    case `public`
    case `private`
    case membersOnly
    case school
    case bookingRequired
    case unknown

    var displayName: String {
        switch self {
        case .public: "Public access"
        case .private: "Private"
        case .membersOnly: "Members only"
        case .school: "School"
        case .bookingRequired: "Booking required"
        case .unknown: "Access unknown"
        }
    }
}

enum PriceType: String, Codable, CaseIterable {
    case free
    case paid
    case mixed
    case unknown

    var displayName: String {
        switch self {
        case .free: "Free"
        case .paid: "Paid"
        case .mixed: "Mixed cost"
        case .unknown: "Cost unknown"
        }
    }
}

enum FactStatus: String, Codable, CaseIterable {
    case yes
    case no
    case sometimes
    case unknown

    var displayName: String {
        switch self {
        case .yes: "Yes"
        case .no: "No"
        case .sometimes: "Sometimes"
        case .unknown: "Unknown"
        }
    }

    var shortLightLabel: String {
        switch self {
        case .yes: "Lights"
        case .no: "No lights"
        case .sometimes: "Lights vary"
        case .unknown: "Lights unknown"
        }
    }
}

enum DrynessAfterRain: String, Codable, CaseIterable {
    case driesFast
    case slowToDry
    case puddlesCommon
    case indoorUnaffected
    case unknown

    var displayName: String {
        switch self {
        case .driesFast: "Dries fast"
        case .slowToDry: "Slow to dry"
        case .puddlesCommon: "Puddles common"
        case .indoorUnaffected: "Indoor, rain unaffected"
        case .unknown: "Dryness unknown"
        }
    }

    var shortLabel: String {
        switch self {
        case .driesFast: "Dry after rain"
        case .slowToDry: "Dries slowly"
        case .puddlesCommon: "Puddles"
        case .indoorUnaffected: "Rain OK"
        case .unknown: "Rain unknown"
        }
    }

    var tone: FactTone {
        switch self {
        case .driesFast, .indoorUnaffected: .positive
        case .slowToDry, .puddlesCommon: .warning
        case .unknown: .unknown
        }
    }
}

enum RainPlayable: String, Codable, CaseIterable {
    case yes
    case no
    case partially
    case indoorUnaffected
    case unknown

    var displayName: String {
        switch self {
        case .yes: "Playable after rain"
        case .no: "Not playable after rain"
        case .partially: "Partially playable"
        case .indoorUnaffected: "Rain unaffected"
        case .unknown: "Rain impact unknown"
        }
    }
}

enum SurfaceType: String, Codable, CaseIterable {
    case concrete
    case asphalt
    case rubber
    case wood
    case synthetic
    case unknown

    var displayName: String {
        switch self {
        case .concrete: "Concrete"
        case .asphalt: "Asphalt"
        case .rubber: "Rubber"
        case .wood: "Wood"
        case .synthetic: "Synthetic"
        case .unknown: "Surface unknown"
        }
    }
}

enum SurfaceCondition: String, Codable, CaseIterable {
    case smooth
    case cracked
    case uneven
    case worn
    case unknown

    var displayName: String {
        switch self {
        case .smooth: "Smooth"
        case .cracked: "Cracked"
        case .uneven: "Uneven"
        case .worn: "Worn"
        case .unknown: "Condition unknown"
        }
    }
}

enum CourtCleanliness: String, Codable, CaseIterable {
    case clean
    case acceptable
    case littered
    case poor
    case unknown

    var displayName: String {
        switch self {
        case .clean: "Clean"
        case .acceptable: "Acceptable"
        case .littered: "Littered"
        case .poor: "Poor"
        case .unknown: "Cleanliness unknown"
        }
    }
}

enum CourtSpace: String, Codable, CaseIterable {
    case spacious
    case tightEdges
    case fencedTight
    case sharedSpace
    case unknown

    var displayName: String {
        switch self {
        case .spacious: "Spacious"
        case .tightEdges: "Tight edges"
        case .fencedTight: "Fenced tight"
        case .sharedSpace: "Shared space"
        case .unknown: "Space unknown"
        }
    }
}

enum RunoffSafety: String, Codable, CaseIterable {
    case safe
    case limited
    case unsafe
    case unknown

    var displayName: String {
        switch self {
        case .safe: "Safe runoff"
        case .limited: "Limited runoff"
        case .unsafe: "Unsafe runoff"
        case .unknown: "Runoff unknown"
        }
    }
}

enum PeakTime: String, Codable, CaseIterable, Identifiable {
    case weekdayEvening
    case weekendMorning
    case weekendAfternoon
    case lunchTime
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weekdayEvening: "Weekday evenings"
        case .weekendMorning: "Weekend mornings"
        case .weekendAfternoon: "Weekend afternoons"
        case .lunchTime: "Lunch time"
        case .unknown: "Peak unknown"
        }
    }
}

enum NetsStatus: String, Codable, CaseIterable {
    case all
    case some
    case none
    case unknown

    var displayName: String {
        switch self {
        case .all: "All hoops have nets"
        case .some: "Some hoops have nets"
        case .none: "No nets"
        case .unknown: "Nets unknown"
        }
    }

    var shortLabel: String {
        switch self {
        case .all: "Nets"
        case .some: "Some nets"
        case .none: "No nets"
        case .unknown: "Nets unknown"
        }
    }

    var tone: FactTone {
        switch self {
        case .all, .some: .positive
        case .none: .warning
        case .unknown: .unknown
        }
    }
}

enum RimHeight: String, Codable, CaseIterable {
    case standard
    case tooLow
    case tooHigh
    case mixed
    case unknown

    var displayName: String {
        switch self {
        case .standard: "Standard height"
        case .tooLow: "Too low"
        case .tooHigh: "Too high"
        case .mixed: "Mixed heights"
        case .unknown: "Height unknown"
        }
    }
}

enum RimType: String, Codable, CaseIterable {
    case singleRim
    case doubleRim
    case mixed
    case unknown

    var displayName: String {
        switch self {
        case .singleRim: "Single rim"
        case .doubleRim: "Double rim"
        case .mixed: "Mixed rims"
        case .unknown: "Rim type unknown"
        }
    }
}

enum HardwareCondition: String, Codable, CaseIterable {
    case good
    case worn
    case damaged
    case missing
    case bent
    case loose
    case unknown

    var displayName: String {
        switch self {
        case .good: "Good"
        case .worn: "Worn"
        case .damaged: "Damaged"
        case .missing: "Missing"
        case .bent: "Bent"
        case .loose: "Loose"
        case .unknown: "Unknown"
        }
    }
}

enum EveningAccess: String, Codable, CaseIterable {
    case yes
    case no
    case seasonal
    case unknown

    var displayName: String {
        switch self {
        case .yes: "Evening access"
        case .no: "No evening access"
        case .seasonal: "Seasonal evenings"
        case .unknown: "Evening access unknown"
        }
    }
}

enum FacilityStatus: String, Codable, CaseIterable {
    case yes
    case no
    case nearby
    case unknown

    var displayName: String {
        switch self {
        case .yes: "Yes"
        case .no: "No"
        case .nearby: "Nearby"
        case .unknown: "Unknown"
        }
    }
}

struct CourtFilters: Equatable {
    var outdoor = false
    var indoor = false
    var free = false
    var lights = false
    var dryAfterRain = false
    var nets = false
    var standardRim = false
    var solo = false

    var isActive: Bool {
        outdoor || indoor || free || lights || dryAfterRain || nets || standardRim || solo
    }

    func matches(_ court: Court) -> Bool {
        if outdoor && court.courtType != .outdoor { return false }
        if indoor && court.courtType != .indoor { return false }
        if free && court.priceType != .free { return false }
        if lights && court.hasLights != .yes { return false }
        if dryAfterRain && !(court.drynessAfterRain == .driesFast || court.drynessAfterRain == .indoorUnaffected) { return false }
        if nets && !(court.hasNets == .all || court.hasNets == .some) { return false }
        if standardRim && court.rimHeight != .standard { return false }
        if solo && court.goodForSolo != .yes { return false }
        return true
    }
}

struct CourtSuggestion: Identifiable, Hashable {
    let id = UUID()
    var courtName: String
    var category: String
    var value: String
    var note: String
    var createdAt = Date()
}
