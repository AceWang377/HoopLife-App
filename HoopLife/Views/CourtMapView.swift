import SwiftUI
import MapKit
import CoreLocation

struct CourtMapView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var locationManager = HoopLifeLocationManager()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 53.3811, longitude: -1.4701),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 53.3811, longitude: -1.4701),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    @State private var searchRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 53.3811, longitude: -1.4701),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    @State private var searchText = ""
    @State private var isSearchingCity = false
    @State private var showingFilters = false
    @State private var showingDetail = false
    @FocusState private var isSearchFocused: Bool

    private var visibleCourts: [Court] {
        let filtered = store.filteredCourts
        let query = normalizedSearchText
        guard !query.isEmpty else { return filtered }
        let matches = matchingCourts(for: query, in: filtered)
        return matches.isEmpty ? filtered : matches
    }

    private var areaCourtCount: Int {
        visibleCourts.filter { mapRegion.contains($0.coordinate, padding: 0.18) }.count
    }

    private var shouldShowSearchAreaButton: Bool {
        !searchRegion.isSimilar(to: mapRegion)
    }

    private var mapCourts: [Court] {
        let regionCourts = visibleCourts
            .filter { mapRegion.contains($0.coordinate, padding: 0.18) }
            .sorted {
                mapRegion.center.distance(to: $0.coordinate) < mapRegion.center.distance(to: $1.coordinate)
            }

        var courts = Array(regionCourts.prefix(360))
        if let selectedCourt = store.selectedCourt, !courts.contains(where: { $0.id == selectedCourt.id }) {
            courts.append(selectedCourt)
        }
        return courts
    }

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                ForEach(mapCourts) { court in
                    Annotation("", coordinate: court.coordinate) {
                        Button {
                            HLHaptics.selection()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.84)) {
                                store.selectedCourt = court
                                focusMap(on: court)
                            }
                        } label: {
                            CourtPin(court: court, isSelected: store.selectedCourt?.id == court.id)
                        }
                        .buttonStyle(.plain)
                    }
                }

                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .including([.park, .publicTransport, .school])))
            .onMapCameraChange(frequency: .onEnd) { context in
                mapRegion = context.region
            }
            .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.32), .clear, .clear, .black.opacity(0.20)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                topControlStack
                Spacer()
                bottomSurface
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 88)
        }
        .sheet(isPresented: $showingFilters) {
            FilterSheetView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingDetail) {
            if let court = store.selectedCourt {
                CourtDetailView(court: court)
            }
        }
        .onReceive(locationManager.$lastLocation.compactMap { $0 }) { coordinate in
            withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                let region = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
                )
                cameraPosition = .region(region)
                mapRegion = region
                searchRegion = region
            }
        }
    }

    private var topControlStack: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                brandPill
                Spacer()
                Button {
                    locateUser()
                } label: {
                    Image(systemName: locationManager.isLocating ? "location.fill" : "location")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(locationManager.lastLocation == nil ? .white : HLColor.night)
                        .frame(width: 48, height: 48)
                        .background(locationManager.lastLocation == nil ? .black.opacity(0.54) : HLColor.freshGreen)
                        .clipShape(Circle())
                        .overlay {
                            Circle().stroke(.white.opacity(0.13), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)

                Button {
                    HLHaptics.light()
                    showingFilters = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(store.filters.isActive ? HLColor.night : .white)
                        .frame(width: 48, height: 48)
                        .background(store.filters.isActive ? HLColor.freshGreen : .black.opacity(0.54))
                        .clipShape(Circle())
                        .overlay {
                            Circle().stroke(.white.opacity(0.13), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }

            searchBar
            searchAreaButton
            filterChips
        }
    }

    private var brandPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "basketball.fill")
                .foregroundStyle(HLColor.basketballOrange)
            Text("HoopLife")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
            Text("\(areaCourtCount)")
                .font(.caption.weight(.black))
                .foregroundStyle(HLColor.night)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(HLColor.freshGreen)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(.black.opacity(0.58))
        .clipShape(Capsule())
        .overlay {
            Capsule().stroke(.white.opacity(0.13), lineWidth: 1)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.64))
            TextField(store.copy(.searchPlaceholder), text: $searchText)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .foregroundStyle(.white)
                .tint(HLColor.freshGreen)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    Task {
                        await submitSearch()
                    }
                }
            if isSearchingCity {
                ProgressView()
                    .tint(HLColor.freshGreen)
                    .controlSize(.small)
            }
            if !searchText.isEmpty {
                Button {
                    HLHaptics.light()
                    searchText = ""
                    store.selectedCourt = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.72))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(.black.opacity(0.54))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.13), lineWidth: 1)
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                MapFilterChip(label: store.copy(.outdoor), isSelected: store.filters.outdoor) { toggleFilter { store.filters.outdoor.toggle() } }
                MapFilterChip(label: store.copy(.indoor), isSelected: store.filters.indoor) { toggleFilter { store.filters.indoor.toggle() } }
                MapFilterChip(label: store.copy(.free), isSelected: store.filters.free) { toggleFilter { store.filters.free.toggle() } }
                MapFilterChip(label: store.copy(.lights), isSelected: store.filters.lights) { toggleFilter { store.filters.lights.toggle() } }
                MapFilterChip(label: store.copy(.dry), isSelected: store.filters.dryAfterRain) { toggleFilter { store.filters.dryAfterRain.toggle() } }
                MapFilterChip(label: store.copy(.nets), isSelected: store.filters.nets) { toggleFilter { store.filters.nets.toggle() } }
                MapFilterChip(label: store.copy(.standardRim), isSelected: store.filters.standardRim) { toggleFilter { store.filters.standardRim.toggle() } }
            }
            .padding(.trailing, 20)
        }
    }

    @ViewBuilder
    private var searchAreaButton: some View {
        if shouldShowSearchAreaButton {
            Button {
                HLHaptics.selection()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    searchRegion = mapRegion
                    searchText = ""
                    store.selectedCourt = nil
                }
            } label: {
                Label(store.copy(.searchThisArea), systemImage: "scope")
                    .font(.caption.weight(.black))
                    .foregroundStyle(HLColor.night)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(HLColor.freshGreen)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var bottomSurface: some View {
        Group {
            if let court = store.selectedCourt {
                selectedCourtCard(court)
            }
        }
    }

    private func selectedCourtCard(_ court: Court) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(court.name)
                        .font(.title2.weight(.black))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Text(court.area)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.58))
                        .lineLimit(1)
                }
                Spacer()
                Button {
                    HLHaptics.light()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.86)) {
                        store.selectedCourt = nil
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            FlowLayout(spacing: 8) {
                ForEach(court.topFacts) { fact in
                    FactChip(label: fact.label, tone: fact.tone)
                }
            }

            Text(warningText(for: court))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.70))

            Button(store.copy(.details)) {
                HLHaptics.light()
                showingDetail = true
            }
            .buttonStyle(DarkPrimaryButtonStyle())

            Button(store.copy(.directions)) {
                    HLHaptics.medium()
                    openDirections(to: court)
            }
            .buttonStyle(DarkSecondaryButtonStyle())
        }
        .padding(16)
        .background(.black.opacity(0.62))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.13), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.25), radius: 24, y: 10)
    }

    private func warningText(for court: Court) -> String {
        if court.drynessAfterRain == .slowToDry || court.drynessAfterRain == .puddlesCommon {
            return store.copy(.rainWarning)
        }
        if court.hasNets == .unknown || court.rimHeight == .unknown {
            return court.confidence == .imported ? store.copy(.importedWarning) : store.copy(.rimNetWarning)
        }
        if court.confidence == .imported {
            return store.copy(.incompleteWarning)
        }
        return store.copy(.readyWarning)
    }

    private func openDirections(to court: Court) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: court.coordinate))
        item.name = court.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }

    private func toggleFilter(_ update: () -> Void) {
        HLHaptics.selection()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            update()
            store.selectedCourt = nil
        }
    }

    @MainActor
    private func submitSearch() async {
        isSearchFocused = false
        let query = normalizedSearchText
        guard !query.isEmpty else { return }

        let filtered = store.filteredCourts
        let matches = matchingCourts(for: query, in: filtered)
        let cityMatches = cityMatchingCourts(for: query, in: filtered)
        if let region = MKCoordinateRegion.enclosing(cityMatches.map(\.coordinate)) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                cameraPosition = .region(region)
                mapRegion = region
                searchRegion = region
                store.selectedCourt = nil
            }
            return
        }

        let exactMatches = exactCourtNameMatches(for: query, in: filtered)
        if let region = MKCoordinateRegion.enclosing(exactMatches.map(\.coordinate)) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                cameraPosition = .region(region)
                mapRegion = region
                searchRegion = region
                store.selectedCourt = exactMatches.count == 1 ? exactMatches[0] : nil
            }
            return
        }

        isSearchingCity = true
        defer { isSearchingCity = false }

        if let region = await geocodeRegion(for: searchText) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                searchText = ""
                cameraPosition = .region(region)
                mapRegion = region
                searchRegion = region
                store.selectedCourt = nil
            }
            return
        }

        if let region = MKCoordinateRegion.enclosing(matches.map(\.coordinate)) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                cameraPosition = .region(region)
                mapRegion = region
                searchRegion = region
                store.selectedCourt = nil
            }
        }
    }

    private var normalizedSearchText: String {
        normalize(searchText)
    }

    private func matchingCourts(for query: String, in courts: [Court]) -> [Court] {
        let cityMatches = cityMatchingCourts(for: query, in: courts)
        if !cityMatches.isEmpty { return cityMatches }

        let areaMatches = courts.filter { normalize($0.area).contains(query) }
        if !areaMatches.isEmpty { return areaMatches }

        return courts.filter { normalize($0.name).contains(query) }
    }

    private func cityMatchingCourts(for query: String, in courts: [Court]) -> [Court] {
        let exactCityMatches = courts.filter { normalize($0.city) == query }
        if !exactCityMatches.isEmpty { return exactCityMatches }

        return courts.filter { normalize($0.city).contains(query) }
    }

    private func exactCourtNameMatches(for query: String, in courts: [Court]) -> [Court] {
        courts.filter { normalize($0.name) == query }
    }

    private func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }

    private func geocodeRegion(for query: String) async -> MKCoordinateRegion? {
        let geocoder = CLGeocoder()
        let searchTerms = [
            "\(query), United Kingdom",
            query
        ]

        for term in searchTerms {
            if let placemark = try? await geocoder.geocodeAddressString(term).first,
               let region = placemark.mapRegion {
                return region
            }
        }

        return nil
    }

    private func focusMap(on court: Court) {
        let region = MKCoordinateRegion(
            center: court.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.028, longitudeDelta: 0.028)
        )
        cameraPosition = .region(region)
        mapRegion = region
        searchRegion = region
    }

    private func locateUser() {
        HLHaptics.light()
        locationManager.requestLocation()
    }
}

final class HoopLifeLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var lastLocation: CLLocationCoordinate2D?
    @Published var isLocating = false

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        isLocating = true
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            isLocating = false
        @unknown default:
            isLocating = false
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
            isLocating = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last?.coordinate
        isLocating = false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLocating = false
    }
}

struct MapFilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.black))
                .foregroundStyle(isSelected ? HLColor.night : .white)
                .padding(.horizontal, 13)
                .frame(height: 34)
                .background(isSelected ? HLColor.freshGreen : .black.opacity(0.50))
                .clipShape(Capsule())
                .overlay {
                    Capsule().stroke(.white.opacity(isSelected ? 0 : 0.13), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct CourtPin: View {
    let court: Court
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? HLColor.basketballOrange : fill)
                .frame(width: isSelected ? 38 : 30, height: isSelected ? 38 : 30)
                .shadow(color: .black.opacity(0.30), radius: 10, y: 5)

            Image(systemName: court.courtType == .indoor ? "building.2.fill" : "basketball.fill")
                .font(.system(size: isSelected ? 15 : 12, weight: .black))
                .foregroundStyle(.white)
        }
        .overlay {
            Circle()
                .stroke(.white, lineWidth: isSelected ? 4 : 3)
        }
    }

    private var fill: Color {
        switch court.confidence {
        case .verified, .recentlyChecked: HLColor.courtGreen
        case .needsCheck: HLColor.warning
        case .userSuggested: HLColor.electricBlue
        case .imported: HLColor.imported
        }
    }
}

private extension MKCoordinateRegion {
    static func enclosing(_ coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion? {
        guard let first = coordinates.first else { return nil }

        let bounds = coordinates.reduce((minLat: first.latitude, maxLat: first.latitude, minLon: first.longitude, maxLon: first.longitude)) { result, coordinate in
            (
                minLat: min(result.minLat, coordinate.latitude),
                maxLat: max(result.maxLat, coordinate.latitude),
                minLon: min(result.minLon, coordinate.longitude),
                maxLon: max(result.maxLon, coordinate.longitude)
            )
        }

        let latitudeDelta = max((bounds.maxLat - bounds.minLat) * 1.45, 0.028)
        let longitudeDelta = max((bounds.maxLon - bounds.minLon) * 1.45, 0.028)

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (bounds.minLat + bounds.maxLat) / 2,
                longitude: (bounds.minLon + bounds.maxLon) / 2
            ),
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }

    func contains(_ coordinate: CLLocationCoordinate2D, padding: Double) -> Bool {
        let latitudePadding = span.latitudeDelta * padding
        let longitudePadding = span.longitudeDelta * padding
        let minLatitude = center.latitude - span.latitudeDelta / 2 - latitudePadding
        let maxLatitude = center.latitude + span.latitudeDelta / 2 + latitudePadding
        let minLongitude = center.longitude - span.longitudeDelta / 2 - longitudePadding
        let maxLongitude = center.longitude + span.longitudeDelta / 2 + longitudePadding

        return coordinate.latitude >= minLatitude &&
            coordinate.latitude <= maxLatitude &&
            coordinate.longitude >= minLongitude &&
            coordinate.longitude <= maxLongitude
    }

    func isSimilar(to region: MKCoordinateRegion) -> Bool {
        abs(center.latitude - region.center.latitude) < max(span.latitudeDelta, region.span.latitudeDelta) * 0.10 &&
            abs(center.longitude - region.center.longitude) < max(span.longitudeDelta, region.span.longitudeDelta) * 0.10 &&
            abs(span.latitudeDelta - region.span.latitudeDelta) < max(span.latitudeDelta, region.span.latitudeDelta) * 0.25 &&
            abs(span.longitudeDelta - region.span.longitudeDelta) < max(span.longitudeDelta, region.span.longitudeDelta) * 0.25
    }
}

private extension CLLocationCoordinate2D {
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
}

private extension CLPlacemark {
    var mapRegion: MKCoordinateRegion? {
        if let circularRegion = region as? CLCircularRegion {
            let meters = max(circularRegion.radius * 2.2, 12_000)
            return MKCoordinateRegion(
                center: circularRegion.center,
                latitudinalMeters: meters,
                longitudinalMeters: meters
            )
        }

        guard let coordinate = location?.coordinate else { return nil }
        return MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 36_000,
            longitudinalMeters: 36_000
        )
    }
}
