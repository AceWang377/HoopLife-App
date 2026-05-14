import Foundation
import CoreLocation
import MapKit

@MainActor
final class AppStore: ObservableObject {
    @Published var courts: [Court]
    @Published var filters = CourtFilters()
    @Published var selectedCourt: Court?
    @Published var savedCourtIDs: Set<String>
    @Published var appLanguage: AppLanguage
    #if DEBUG
    @Published var suggestions: [CourtSuggestion] = []
    @Published var courtCandidates: [CourtCandidate] = []
    @Published var isAdminUnlocked: Bool
    #endif
    @Published var hasCompletedOnboarding: Bool
    @Published var courtDataSource = "Local seed"
    @Published var isLoadingRemoteCourts = false
    @Published var countrySummaries: [CountryCourtSummary] = []

    private let savedKey = "blacktop.savedCourts"
    private let onboardingKey = "blacktop.hasCompletedOnboarding"
    private let languageKey = "blacktop.appLanguage"
    private let maximumCachedCourts = 30_000
    #if DEBUG
    private let courtsKey = "blacktop.courts.override"
    private let adminKey = "blacktop.adminUnlocked"
    private let adminPasscode = "BLACKTOP-ADMIN"
    #endif
    private let supabaseCourtService = SupabaseCourtService()
    private var loadedRemoteRegions: [MKCoordinateRegion] = []
    private var remoteLoadGeneration = 0

    init(courts: [Court] = CourtSeedStore.loadCourts()) {
        let cachedCourts = CourtDiskCache.load()
        #if DEBUG
        self.courts = Self.loadPersistedCourts() ?? cachedCourts ?? courts
        self.isAdminUnlocked = UserDefaults.standard.bool(forKey: adminKey)
        #else
        self.courts = cachedCourts ?? courts
        #endif
        let storedLanguage = UserDefaults.standard.string(forKey: languageKey).flatMap(AppLanguage.init(rawValue:))
        self.appLanguage = storedLanguage ?? AppLanguage.preferred
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        self.courtDataSource = cachedCourts == nil ? "Local seed" : "Cached courts"
        let saved = UserDefaults.standard.stringArray(forKey: savedKey) ?? []
        self.savedCourtIDs = Set(saved)
    }

    var filteredCourts: [Court] {
        courts.filter { filters.matches($0) }
    }

    var savedCourts: [Court] {
        courts.filter { savedCourtIDs.contains($0.id) }
    }

    var totalCourtCount: Int {
        let remoteTotal = countrySummaries.reduce(0) { $0 + $1.courtCount }
        return max(remoteTotal, courts.count)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    func setLanguage(_ language: AppLanguage) {
        appLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
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

    func loadRemoteCourts() async {
        remoteLoadGeneration += 1
        let generation = remoteLoadGeneration
        isLoadingRemoteCourts = true
        defer {
            if generation == remoteLoadGeneration {
                isLoadingRemoteCourts = false
            }
        }

        do {
            let remoteCourts = try await supabaseCourtService.fetchCourts()
            guard generation == remoteLoadGeneration else { return }
            guard !remoteCourts.isEmpty else { return }
            courts = remoteCourts
            courtDataSource = "Supabase"
            selectedCourt = selectedCourt.flatMap { selected in
                remoteCourts.first { $0.id == selected.id }
            }
            persistCourtCache()
            print("Blacktop loaded \(remoteCourts.count) courts from Supabase")
        } catch {
            print("Blacktop Supabase court load failed: \(error)")
        }
    }

    func loadRemoteCourts(in region: MKCoordinateRegion, force: Bool = false) async {
        if !force, hasLoadedRemoteRegion(covering: region) { return }

        remoteLoadGeneration += 1
        let generation = remoteLoadGeneration
        isLoadingRemoteCourts = true
        defer {
            if generation == remoteLoadGeneration {
                isLoadingRemoteCourts = false
            }
        }

        do {
            let remoteCourts = try await supabaseCourtService.fetchCourts(in: region)
            guard generation == remoteLoadGeneration else { return }
            guard !remoteCourts.isEmpty else { return }
            mergeRemoteCourts(remoteCourts)
            loadedRemoteRegions.append(region.expanded(by: 0.45))
            courtDataSource = "Supabase area"
            selectedCourt = selectedCourt.flatMap { selected in
                courts.first { $0.id == selected.id }
            }
            persistCourtCache()
            print("Blacktop loaded \(remoteCourts.count) courts for current map area")
        } catch {
            print("Blacktop Supabase area load failed: \(error)")
        }
    }

    func loadCountrySummaries(force: Bool = false) async {
        guard force || countrySummaries.isEmpty else { return }

        do {
            countrySummaries = try await supabaseCourtService.fetchCountrySummaries()
        } catch {
            print("Blacktop country summary load failed: \(error)")
        }
    }

    private func mergeRemoteCourts(_ remoteCourts: [Court]) {
        var merged = Dictionary(uniqueKeysWithValues: courts.map { ($0.id, $0) })
        for court in remoteCourts {
            merged[court.id] = court
        }
        courts = merged.values.sorted {
            if $0.city == $1.city { return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return $0.city.localizedCaseInsensitiveCompare($1.city) == .orderedAscending
        }
    }

    private func persistCourtCache() {
        let snapshot = Array(courts.prefix(maximumCachedCourts))
        Task.detached(priority: .utility) {
            CourtDiskCache.save(snapshot)
        }
    }

    private func hasLoadedRemoteRegion(covering region: MKCoordinateRegion) -> Bool {
        loadedRemoteRegions.contains { loadedRegion in
            loadedRegion.contains(region.center) &&
                loadedRegion.span.latitudeDelta >= region.span.latitudeDelta * 0.70 &&
                loadedRegion.span.longitudeDelta >= region.span.longitudeDelta * 0.70
        }
    }

    #if DEBUG
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
        guard let data = UserDefaults.standard.data(forKey: "blacktop.courts.override") else { return nil }
        return try? JSONDecoder().decode([Court].self, from: data)
    }
    #endif
}

private enum CourtDiskCache {
    private static let fileName = "blacktop-courts-cache-v1.json"
    private static let maxAge: TimeInterval = 60 * 60 * 24 * 14

    static func load() -> [Court]? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data) else { return nil }
        guard Date().timeIntervalSince1970 - payload.cachedAt < maxAge else { return nil }
        return payload.courts.isEmpty ? nil : payload.courts
    }

    static func save(_ courts: [Court]) {
        guard !courts.isEmpty else { return }
        let payload = Payload(cachedAt: Date().timeIntervalSince1970, courts: courts)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? FileManager.default.createDirectory(
            at: cacheURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: cacheURL, options: [.atomic])
    }

    private static var cacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appending(path: fileName)
    }

    private struct Payload: Codable {
        var cachedAt: TimeInterval
        var courts: [Court]
    }
}

#if DEBUG
struct CourtCandidate: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var area: String
    var latitude: Double
    var longitude: Double
    var courtType: CourtType
    var submittedAt = Date()
}
#endif

private extension MKCoordinateRegion {
    func expanded(by ratio: Double) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(
                latitudeDelta: span.latitudeDelta * (1 + ratio),
                longitudeDelta: span.longitudeDelta * (1 + ratio)
            )
        )
    }

    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let minLatitude = center.latitude - span.latitudeDelta / 2
        let maxLatitude = center.latitude + span.latitudeDelta / 2
        let minLongitude = center.longitude - span.longitudeDelta / 2
        let maxLongitude = center.longitude + span.longitudeDelta / 2

        return coordinate.latitude >= minLatitude &&
            coordinate.latitude <= maxLatitude &&
            coordinate.longitude >= minLongitude &&
            coordinate.longitude <= maxLongitude
    }
}
