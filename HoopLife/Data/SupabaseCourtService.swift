import Foundation
import MapKit

enum SupabaseConfig {
    static let projectURL = URL(string: "https://mcvqmgzsklltrikuuigh.supabase.co")!
    static let publishableKey = "sb_publishable_18IzWW2F4scgneSmgz7fsA_p_t28wXf"
}

struct SupabaseCourtService {
    private let maximumViewportLimit = 700

    func fetchCourts(limit: Int = 10_000) async throws -> [Court] {
        let pageSize = 1_000
        var allCourts: [Court] = []
        var offset = 0

        while allCourts.count < limit {
            let page = try await fetchCourtPage(limit: min(pageSize, limit - allCourts.count), offset: offset)
            allCourts.append(contentsOf: page)
            if page.count < pageSize { break }
            offset += pageSize
        }

        return allCourts
    }

    func fetchCourts(in region: MKCoordinateRegion, limit: Int = 600, countryCode: String? = nil) async throws -> [Court] {
        let boundedLimit = min(max(limit, 1), maximumViewportLimit)

        do {
            return try await fetchCourtsInViewRPC(region: region, limit: boundedLimit, countryCode: countryCode)
        } catch {
            print("HoopLife Supabase RPC viewport load failed, falling back to REST bbox: \(error)")
            return try await fetchCourtsInBoundingBox(region: region, limit: boundedLimit, countryCode: countryCode)
        }
    }

    private func fetchCourtPage(limit: Int, offset: Int) async throws -> [Court] {
        var components = URLComponents(
            url: SupabaseConfig.projectURL.appending(path: "/rest/v1/courts"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "select", value: SupabaseCourtDTO.selectColumns),
            URLQueryItem(name: "order", value: "name.asc"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        guard let url = components?.url else {
            throw SupabaseCourtError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseCourtError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw SupabaseCourtError.requestFailed(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([SupabaseCourtDTO].self, from: data).map(\.court)
    }

    private func fetchCourtsInViewRPC(region: MKCoordinateRegion, limit: Int, countryCode: String?) async throws -> [Court] {
        let bounds = region.bounds
        let url = SupabaseConfig.projectURL.appending(path: "/rest/v1/rpc/courts_in_view")
        let payload = CourtsInViewRequest(
            minLat: bounds.minLatitude,
            minLng: bounds.minLongitude,
            maxLat: bounds.maxLatitude,
            maxLng: bounds.maxLongitude,
            limitCount: limit,
            countryCodeFilter: countryCode
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.snakeCase.encode(payload)

        return try await performCourtRequest(request)
    }

    private func fetchCourtsInBoundingBox(region: MKCoordinateRegion, limit: Int, countryCode: String?) async throws -> [Court] {
        let bounds = region.bounds
        var queryItems = [
            URLQueryItem(name: "select", value: SupabaseCourtDTO.selectColumns),
            URLQueryItem(name: "latitude", value: "gte.\(bounds.minLatitude)"),
            URLQueryItem(name: "latitude", value: "lte.\(bounds.maxLatitude)"),
            URLQueryItem(name: "longitude", value: "gte.\(bounds.minLongitude)"),
            URLQueryItem(name: "longitude", value: "lte.\(bounds.maxLongitude)"),
            URLQueryItem(name: "order", value: "name.asc"),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        if let countryCode {
            queryItems.append(URLQueryItem(name: "country_code", value: "eq.\(countryCode)"))
        }

        var components = URLComponents(
            url: SupabaseConfig.projectURL.appending(path: "/rest/v1/courts"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw SupabaseCourtError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(SupabaseConfig.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return try await performCourtRequest(request)
    }

    private func performCourtRequest(_ request: URLRequest) async throws -> [Court] {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseCourtError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw SupabaseCourtError.requestFailed(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode([SupabaseCourtDTO].self, from: data).map(\.court)
    }
}

enum SupabaseCourtError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int)
}

private struct CourtsInViewRequest: Encodable {
    var minLat: Double
    var minLng: Double
    var maxLat: Double
    var maxLng: Double
    var limitCount: Int
    var countryCodeFilter: String?
}

private extension JSONEncoder {
    static var snakeCase: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }
}

private extension MKCoordinateRegion {
    var bounds: CourtBounds {
        let latitudeDelta = max(span.latitudeDelta, 0.001)
        let longitudeDelta = max(span.longitudeDelta, 0.001)
        return CourtBounds(
            minLatitude: center.latitude - latitudeDelta / 2,
            minLongitude: center.longitude - longitudeDelta / 2,
            maxLatitude: center.latitude + latitudeDelta / 2,
            maxLongitude: center.longitude + longitudeDelta / 2
        )
    }
}

private struct CourtBounds {
    var minLatitude: Double
    var minLongitude: Double
    var maxLatitude: Double
    var maxLongitude: Double
}

private struct SupabaseCourtDTO: Decodable {
    static let selectColumns = [
        "id",
        "name",
        "area",
        "city",
        "latitude",
        "longitude",
        "source",
        "source_license",
        "confidence",
        "last_checked_at",
        "court_type",
        "access_type",
        "price_type",
        "has_lights",
        "dryness_after_rain",
        "slippery_when_wet",
        "rain_playable",
        "surface_type",
        "surface_condition",
        "court_cleanliness",
        "court_space",
        "runoff_safety",
        "peak_times",
        "has_nets",
        "rim_height",
        "rim_type",
        "backboard_condition",
        "rim_condition",
        "hoop_count",
        "opening_hours",
        "evening_access",
        "has_toilets",
        "has_drinking_water",
        "has_parking",
        "has_changing_rooms",
        "good_for_solo",
        "good_for_pickup",
        "good_for_training",
        "beginner_friendly",
        "notes",
        "photo_asset_name",
        "osm_ref",
        "osm_tags_json"
    ].joined(separator: ",")

    var id: String
    var name: String?
    var area: String?
    var city: String?
    var latitude: Double
    var longitude: Double
    var source: String?
    var sourceLicense: String?
    var confidence: String?
    var lastCheckedAt: String?
    var courtType: String?
    var accessType: String?
    var priceType: String?
    var hasLights: String?
    var drynessAfterRain: String?
    var slipperyWhenWet: String?
    var rainPlayable: String?
    var surfaceType: String?
    var surfaceCondition: String?
    var courtCleanliness: String?
    var courtSpace: String?
    var runoffSafety: String?
    var peakTimes: String?
    var hasNets: String?
    var rimHeight: String?
    var rimType: String?
    var backboardCondition: String?
    var rimCondition: String?
    var hoopCount: Int?
    var openingHours: String?
    var eveningAccess: String?
    var hasToilets: String?
    var hasDrinkingWater: String?
    var hasParking: String?
    var hasChangingRooms: String?
    var goodForSolo: String?
    var goodForPickup: String?
    var goodForTraining: String?
    var beginnerFriendly: String?
    var notes: String?
    var photoAssetName: String?
    var osmRef: String?
    var osmTagsJson: [String: String]?

    var court: Court {
        Court(
            id: id,
            name: displayName,
            area: displayArea,
            city: displayCity,
            latitude: latitude,
            longitude: longitude,
            source: enumValue(DataSource.self, source, fallback: .openStreetMap),
            sourceLicense: clean(sourceLicense, fallback: "ODbL - OpenStreetMap contributors"),
            confidence: enumValue(DataConfidence.self, confidence, fallback: .imported),
            lastCheckedAt: clean(lastCheckedAt, fallback: "Imported"),
            courtType: enumValue(CourtType.self, courtType, fallback: .unknown),
            accessType: enumValue(AccessType.self, accessType, fallback: .unknown),
            priceType: enumValue(PriceType.self, priceType, fallback: .unknown),
            hasLights: enumValue(FactStatus.self, hasLights, fallback: .unknown),
            drynessAfterRain: enumValue(DrynessAfterRain.self, drynessAfterRain, fallback: .unknown),
            slipperyWhenWet: enumValue(FactStatus.self, slipperyWhenWet, fallback: .unknown),
            rainPlayable: enumValue(RainPlayable.self, rainPlayable, fallback: .unknown),
            surfaceType: enumValue(SurfaceType.self, surfaceType, fallback: .unknown),
            surfaceCondition: enumValue(SurfaceCondition.self, surfaceCondition, fallback: .unknown),
            courtCleanliness: enumValue(CourtCleanliness.self, courtCleanliness, fallback: .unknown),
            courtSpace: enumValue(CourtSpace.self, courtSpace, fallback: .unknown),
            runoffSafety: enumValue(RunoffSafety.self, runoffSafety, fallback: .unknown),
            peakTimes: parsePeakTimes(peakTimes),
            hasNets: enumValue(NetsStatus.self, hasNets, fallback: .unknown),
            rimHeight: enumValue(RimHeight.self, rimHeight, fallback: .unknown),
            rimType: enumValue(RimType.self, rimType, fallback: .unknown),
            backboardCondition: enumValue(HardwareCondition.self, backboardCondition, fallback: .unknown),
            rimCondition: enumValue(HardwareCondition.self, rimCondition, fallback: .unknown),
            hoopCount: hoopCount,
            openingHours: clean(openingHours, fallback: "Access not confirmed"),
            eveningAccess: enumValue(EveningAccess.self, eveningAccess, fallback: .unknown),
            hasToilets: enumValue(FacilityStatus.self, hasToilets, fallback: .unknown),
            hasDrinkingWater: enumValue(FacilityStatus.self, hasDrinkingWater, fallback: .unknown),
            hasParking: enumValue(FacilityStatus.self, hasParking, fallback: .unknown),
            hasChangingRooms: enumValue(FactStatus.self, hasChangingRooms, fallback: .unknown),
            goodForSolo: enumValue(FactStatus.self, goodForSolo, fallback: .unknown),
            goodForPickup: enumValue(FactStatus.self, goodForPickup, fallback: .unknown),
            goodForTraining: enumValue(FactStatus.self, goodForTraining, fallback: .unknown),
            beginnerFriendly: enumValue(FactStatus.self, beginnerFriendly, fallback: .unknown),
            notes: clean(notes, fallback: ""),
            photoAssetName: cleanOptional(photoAssetName),
            addressLine: addressLine,
            postcode: postcode,
            osmRef: cleanOptional(osmRef)
        )
    }

    private var displayName: String {
        if let cleanedName = cleanOptional(name), !isSyntheticOSMName(cleanedName) {
            return cleanedName
        }

        if let osmName = cleanOptional(osmTagsJson?["name"]) ?? cleanOptional(osmTagsJson?["official_name"]) {
            return osmName
        }

        if let operatorName = cleanOptional(osmTagsJson?["operator"]) {
            return "\(operatorName) basketball court"
        }

        if let addressLabel = cleanOptional(postcode) ?? cleanOptional(streetOrArea) {
            return "Basketball court near \(addressLabel)"
        }

        if let osmRef = cleanOptional(osmRef) {
            return "Basketball court (\(osmRef))"
        }

        return clean(name, fallback: "Unnamed basketball court")
    }

    private var displayArea: String {
        if let existingArea = cleanOptional(area), !isGenericLocation(existingArea) {
            return existingArea
        }

        return cleanOptional(osmTagsJson?["addr:suburb"]) ??
            cleanOptional(osmTagsJson?["addr:neighbourhood"]) ??
            cleanOptional(osmTagsJson?["addr:district"]) ??
            cleanOptional(osmTagsJson?["addr:street"]) ??
            cleanOptional(osmTagsJson?["operator"]) ??
            clean(area, fallback: "Unknown area")
    }

    private var displayCity: String {
        if let existingCity = cleanOptional(city), !isGenericLocation(existingCity) {
            return existingCity
        }

        return cleanOptional(osmTagsJson?["addr:city"]) ??
            cleanOptional(osmTagsJson?["addr:town"]) ??
            cleanOptional(osmTagsJson?["addr:village"]) ??
            clean(city, fallback: "UK")
    }

    private var postcode: String? {
        cleanOptional(osmTagsJson?["addr:postcode"])
    }

    private var streetOrArea: String? {
        cleanOptional(osmTagsJson?["addr:street"]) ??
            cleanOptional(osmTagsJson?["addr:suburb"]) ??
            cleanOptional(osmTagsJson?["addr:neighbourhood"]) ??
            cleanOptional(osmTagsJson?["addr:city"])
    }

    private var addressLine: String? {
        let streetAddress = [
            cleanOptional(osmTagsJson?["addr:housenumber"]),
            cleanOptional(osmTagsJson?["addr:street"])
        ]
            .compactMap(\.self)
            .joined(separator: " ")

        let parts = [
            cleanOptional(streetAddress),
            cleanOptional(osmTagsJson?["addr:suburb"]),
            cleanOptional(osmTagsJson?["addr:city"]),
            postcode
        ]
            .compactMap(\.self)

        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    private func clean(_ value: String?, fallback: String) -> String {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return fallback
        }
        return value
    }

    private func cleanOptional(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func isSyntheticOSMName(_ value: String) -> Bool {
        value.localizedCaseInsensitiveContains("OSM Basketball Court") ||
            value.localizedCaseInsensitiveContains("Unnamed court")
    }

    private func isGenericLocation(_ value: String) -> Bool {
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized == "uk" || normalized == "unknown area"
    }

    private func enumValue<Value: RawRepresentable>(_ type: Value.Type, _ rawValue: String?, fallback: Value) -> Value where Value.RawValue == String {
        guard let rawValue else { return fallback }
        return Value(rawValue: rawValue) ?? fallback
    }

    private func parsePeakTimes(_ value: String?) -> [PeakTime] {
        guard let value else { return [.unknown] }
        let cleaned = value
            .replacingOccurrences(of: "{", with: "")
            .replacingOccurrences(of: "}", with: "")
            .replacingOccurrences(of: "\"", with: "")

        let items = cleaned
            .split(separator: ",")
            .compactMap { PeakTime(rawValue: String($0).trimmingCharacters(in: .whitespacesAndNewlines)) }

        return items.isEmpty ? [.unknown] : items
    }
}
