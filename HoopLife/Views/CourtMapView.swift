import SwiftUI
import MapKit

struct CourtMapView: View {
    @EnvironmentObject private var store: AppStore
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

    var visibleCourts: [Court] {
        let filtered = store.filteredCourts
        guard !searchText.isEmpty else { return filtered }
        return filtered.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.area.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $cameraPosition) {
                    ForEach(visibleCourts) { court in
                        Annotation(court.name, coordinate: court.coordinate) {
                            Button {
                                store.selectedCourt = court
                            } label: {
                                CourtPin(court: court, isSelected: store.selectedCourt?.id == court.id)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat))
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    searchBar
                    filterChips
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                VStack {
                    Spacer()
                    bottomPanel
                }
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
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(HLColor.secondaryText)
            TextField("Search court, area, postcode", text: $searchText)
                .textInputAutocapitalization(.words)
                .disableAutocorrection(true)
            Button {
                showingFilters = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(store.filters.isActive ? HLColor.electricBlue : HLColor.text)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectableChip(label: "Outdoor", isSelected: store.filters.outdoor) { store.filters.outdoor.toggle() }
                SelectableChip(label: "Indoor", isSelected: store.filters.indoor) { store.filters.indoor.toggle() }
                SelectableChip(label: "Free", isSelected: store.filters.free) { store.filters.free.toggle() }
                SelectableChip(label: "Lights", isSelected: store.filters.lights) { store.filters.lights.toggle() }
                SelectableChip(label: "Dry", isSelected: store.filters.dryAfterRain) { store.filters.dryAfterRain.toggle() }
                SelectableChip(label: "Nets", isSelected: store.filters.nets) { store.filters.nets.toggle() }
                SelectableChip(label: "Standard rim", isSelected: store.filters.standardRim) { store.filters.standardRim.toggle() }
                SelectableChip(label: "Solo", isSelected: store.filters.solo) { store.filters.solo.toggle() }
            }
        }
    }

    private var bottomPanel: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(HLColor.stroke)
                .frame(width: 72, height: 5)
                .padding(.top, 10)

            if let court = store.selectedCourt {
                selectedCourtPreview(court)
            } else {
                nearbyCourtsList
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 94)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.96), Color.white.opacity(0.88)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 34, topTrailingRadius: 34))
        .shadow(color: .black.opacity(0.14), radius: 24, y: -6)
    }

    private var nearbyCourtsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Playable nearby")
                            .font(.title2.weight(.black))
                        Text("Court facts, not ratings")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(HLColor.secondaryText)
                    }
                Spacer()
                Text("\(visibleCourts.count) in Sheffield")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(HLColor.secondaryText)
            }

            if visibleCourts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("No matching courts")
                        .font(.headline.weight(.semibold))
                    Text("Try fewer filters or add a missing court.")
                        .foregroundStyle(HLColor.secondaryText)
                    Button("Reset filters") {
                        store.filters = CourtFilters()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding()
                .cardStyle(radius: 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(visibleCourts) { court in
                            CourtCard(court: court, isSaved: store.isSaved(court)) {
                                store.toggleSaved(court)
                            }
                            .frame(width: 326)
                            .onTapGesture {
                                store.selectedCourt = court
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }
            }
        }
    }

    private func selectedCourtPreview(_ court: Court) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(court.name)
                        .font(.title2.weight(.black))
                    Text(court.area)
                        .font(.subheadline)
                        .foregroundStyle(HLColor.secondaryText)
                }
                Spacer()
                ConfidenceBadge(confidence: court.confidence)
            }

            FlowLayout(spacing: 8) {
                ForEach(court.topFacts) { fact in
                    FactChip(label: fact.label, tone: fact.tone)
                }
            }

            Text(warningText(for: court))
                .font(.subheadline)
                .foregroundStyle(HLColor.secondaryText)

            HStack(spacing: 12) {
                Button("Directions") {
                    openDirections(to: court)
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(maxWidth: .infinity)

                Button("Details") {
                    showingDetail = true
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 4)
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
}

struct CourtPin: View {
    let court: Court
    let isSelected: Bool

    var body: some View {
        Circle()
            .fill(fill)
            .frame(width: isSelected ? 32 : 24, height: isSelected ? 32 : 24)
            .overlay {
                Image(systemName: court.courtType == .indoor ? "building.2.fill" : "basketball.fill")
                    .font(.system(size: isSelected ? 13 : 10, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay {
                Circle().stroke(.white, lineWidth: 3)
            }
            .shadow(color: .black.opacity(0.18), radius: 8, y: 4)
    }

    private var fill: Color {
        if isSelected { return HLColor.basketballOrange }
        switch court.confidence {
        case .verified, .recentlyChecked: return HLColor.courtGreen
        case .needsCheck: return HLColor.warning
        case .userSuggested: return HLColor.electricBlue
        case .imported: return HLColor.imported
        }
    }
}
