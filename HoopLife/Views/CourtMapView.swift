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
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var showingDetail = false
    @State private var showingSuggestion = false
    @FocusState private var isSearchFocused: Bool

    private var visibleCourts: [Court] {
        let filtered = store.filteredCourts
        guard !searchText.isEmpty else { return filtered }
        return filtered.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.area.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var cityCourtCount: Int {
        store.courts.count
    }

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                ForEach(visibleCourts) { court in
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
                CourtDetailView(court: court, showSuggestion: {
                    showingDetail = false
                    showingSuggestion = true
                })
            }
        }
        .sheet(isPresented: $showingSuggestion) {
            if let court = store.selectedCourt {
                SuggestEditView(court: court)
            }
        }
        .onReceive(locationManager.$lastLocation.compactMap { $0 }) { coordinate in
            withAnimation(.spring(response: 0.38, dampingFraction: 0.88)) {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
                    )
                )
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
            Text("\(cityCourtCount)")
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
            TextField("Search court or area", text: $searchText)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
                .foregroundStyle(.white)
                .tint(HLColor.freshGreen)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    isSearchFocused = false
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
                MapFilterChip(label: "Outdoor", isSelected: store.filters.outdoor) { toggleFilter { store.filters.outdoor.toggle() } }
                MapFilterChip(label: "Indoor", isSelected: store.filters.indoor) { toggleFilter { store.filters.indoor.toggle() } }
                MapFilterChip(label: "Free", isSelected: store.filters.free) { toggleFilter { store.filters.free.toggle() } }
                MapFilterChip(label: "Lights", isSelected: store.filters.lights) { toggleFilter { store.filters.lights.toggle() } }
                MapFilterChip(label: "Dry", isSelected: store.filters.dryAfterRain) { toggleFilter { store.filters.dryAfterRain.toggle() } }
                MapFilterChip(label: "Nets", isSelected: store.filters.nets) { toggleFilter { store.filters.nets.toggle() } }
                MapFilterChip(label: "Standard rim", isSelected: store.filters.standardRim) { toggleFilter { store.filters.standardRim.toggle() } }
            }
            .padding(.trailing, 20)
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

            HStack(spacing: 10) {
                Button("Facts") {
                    HLHaptics.light()
                    showingSuggestion = true
                }
                .buttonStyle(DarkPrimaryButtonStyle())

                Button("Details") {
                    HLHaptics.light()
                    showingDetail = true
                }
                .buttonStyle(DarkSecondaryButtonStyle())
            }

            Button("Directions") {
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
            return "May be slippery after rain. Check before travelling."
        }
        if court.hasNets == .unknown || court.rimHeight == .unknown {
            return "Rim and net details still need confirmation."
        }
        return "Key court facts are ready to check."
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

    private func focusMap(on court: Court) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: court.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.028, longitudeDelta: 0.028)
            )
        )
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
