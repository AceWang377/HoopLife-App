import SwiftUI
import CoreLocation

struct AdminCourtEditorView: View {
    @EnvironmentObject private var store: AppStore
    @State private var searchText = ""
    @State private var isAddingCourt = false
    @State private var isConfirmingReset = false

    private var filteredCourts: [Court] {
        guard !searchText.isEmpty else { return store.courts }
        return store.courts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.area.localizedCaseInsensitiveContains(searchText) ||
            $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            Section {
                TextField("Search courts", text: $searchText)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(true)
            }

            Section {
                Button {
                    isAddingCourt = true
                } label: {
                    Label("Add verified court", systemImage: "plus.circle.fill")
                }

                Button(role: .destructive) {
                    isConfirmingReset = true
                } label: {
                    Label("Reset to bundled seed data", systemImage: "arrow.counterclockwise")
                }
            } footer: {
                Text("Admin edits are stored on this device for the MVP. Use this to fill HoopLife-only facts before you wire a backend.")
            }

            Section("Courts") {
                ForEach(filteredCourts) { court in
                    NavigationLink {
                        AdminCourtFormView(mode: .edit(court))
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(court.name)
                                .font(.headline)
                            Text("\(court.area) · \(court.confidence.displayName)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Admin editor")
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 96)
        }
        .sheet(isPresented: $isAddingCourt) {
            NavigationStack {
                AdminCourtFormView(mode: .add)
            }
        }
        .alert("Reset court data?", isPresented: $isConfirmingReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                store.resetCourtsToSeed()
            }
        } message: {
            Text("This removes local admin edits and reloads the bundled seed file.")
        }
    }
}

struct AdminCourtFormView: View {
    enum Mode {
        case add
        case edit(Court)
    }

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let mode: Mode
    @State private var draft: CourtDraft
    @State private var didSave = false

    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .add:
            _draft = State(initialValue: CourtDraft())
        case .edit(let court):
            _draft = State(initialValue: CourtDraft(court: court))
        }
    }

    private var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(draft.latitude) != nil &&
        Double(draft.longitude) != nil
    }

    var body: some View {
        Form {
            Section("Identity") {
                TextField("Name", text: $draft.name)
                TextField("Area", text: $draft.area)
                TextField("City", text: $draft.city)
                TextField("Latitude", text: $draft.latitude)
                    .keyboardType(.decimalPad)
                TextField("Longitude", text: $draft.longitude)
                    .keyboardType(.decimalPad)
                TextField("Photo asset name", text: $draft.photoAssetName)
                picker("Confidence", selection: $draft.confidence)
                TextField("Last checked", text: $draft.lastCheckedAt)
            }

            Section("Access") {
                picker("Court type", selection: $draft.courtType)
                picker("Access", selection: $draft.accessType)
                picker("Cost", selection: $draft.priceType)
                TextField("Opening hours", text: $draft.openingHours)
                picker("Evening access", selection: $draft.eveningAccess)
            }

            Section("Rain and surface") {
                picker("Dryness after rain", selection: $draft.drynessAfterRain)
                picker("Slippery when wet", selection: $draft.slipperyWhenWet)
                picker("Rain playable", selection: $draft.rainPlayable)
                picker("Surface", selection: $draft.surfaceType)
                picker("Surface condition", selection: $draft.surfaceCondition)
                picker("Cleanliness", selection: $draft.courtCleanliness)
                picker("Space", selection: $draft.courtSpace)
                picker("Runoff", selection: $draft.runoffSafety)
            }

            Section("Hoops") {
                picker("Nets", selection: $draft.hasNets)
                picker("Rim height", selection: $draft.rimHeight)
                picker("Rim type", selection: $draft.rimType)
                picker("Backboard", selection: $draft.backboardCondition)
                picker("Rim condition", selection: $draft.rimCondition)
                TextField("Hoop count", text: $draft.hoopCount)
                    .keyboardType(.numberPad)
            }

            Section("Facilities") {
                picker("Lights", selection: $draft.hasLights)
                picker("Toilets", selection: $draft.hasToilets)
                picker("Drinking water", selection: $draft.hasDrinkingWater)
                picker("Parking", selection: $draft.hasParking)
                picker("Changing rooms", selection: $draft.hasChangingRooms)
            }

            Section("Use cases") {
                picker("Solo shooting", selection: $draft.goodForSolo)
                picker("Pickup", selection: $draft.goodForPickup)
                picker("Training", selection: $draft.goodForTraining)
                picker("Beginner friendly", selection: $draft.beginnerFriendly)
            }

            Section("Notes") {
                TextField("Admin notes", text: $draft.notes, axis: .vertical)
                    .lineLimit(4...8)
            }

            if didSave {
                Section {
                    Text("Saved locally.")
                        .foregroundStyle(HLColor.courtGreen)
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    save()
                }
                .disabled(!canSave)
            }
        }
    }

    private var navigationTitle: String {
        switch mode {
        case .add: "Add court"
        case .edit: "Edit court"
        }
    }

    private func picker<Value: CaseIterable & Hashable>(_ title: String, selection: Binding<Value>) -> some View where Value.AllCases: RandomAccessCollection {
        Picker(title, selection: selection) {
            ForEach(Array(Value.allCases), id: \.self) { value in
                Text(displayName(for: value)).tag(value)
            }
        }
    }

    private func displayName<Value>(for value: Value) -> String {
        switch value {
        case let item as DataConfidence: item.displayName
        case let item as CourtType: item.displayName
        case let item as AccessType: item.displayName
        case let item as PriceType: item.displayName
        case let item as FactStatus: item.displayName
        case let item as DrynessAfterRain: item.displayName
        case let item as RainPlayable: item.displayName
        case let item as SurfaceType: item.displayName
        case let item as SurfaceCondition: item.displayName
        case let item as CourtCleanliness: item.displayName
        case let item as CourtSpace: item.displayName
        case let item as RunoffSafety: item.displayName
        case let item as NetsStatus: item.displayName
        case let item as RimHeight: item.displayName
        case let item as RimType: item.displayName
        case let item as HardwareCondition: item.displayName
        case let item as EveningAccess: item.displayName
        case let item as FacilityStatus: item.displayName
        default: String(describing: value)
        }
    }

    private func save() {
        guard let court = draft.makeCourt(existingID: existingID) else { return }
        switch mode {
        case .add:
            store.addApprovedCourt(court)
        case .edit:
            store.updateCourt(court)
        }
        HLHaptics.medium()
        didSave = true
    }

    private var existingID: String? {
        if case .edit(let court) = mode {
            return court.id
        }
        return nil
    }
}

struct CourtDraft {
    var name = ""
    var area = ""
    var city = "Sheffield"
    var latitude = "53.38110"
    var longitude = "-1.47010"
    var photoAssetName = ""
    var confidence: DataConfidence = .verified
    var lastCheckedAt = CourtDraft.todayString
    var courtType: CourtType = .outdoor
    var accessType: AccessType = .public
    var priceType: PriceType = .free
    var hasLights: FactStatus = .unknown
    var drynessAfterRain: DrynessAfterRain = .unknown
    var slipperyWhenWet: FactStatus = .unknown
    var rainPlayable: RainPlayable = .unknown
    var surfaceType: SurfaceType = .unknown
    var surfaceCondition: SurfaceCondition = .unknown
    var courtCleanliness: CourtCleanliness = .unknown
    var courtSpace: CourtSpace = .unknown
    var runoffSafety: RunoffSafety = .unknown
    var hasNets: NetsStatus = .unknown
    var rimHeight: RimHeight = .unknown
    var rimType: RimType = .unknown
    var backboardCondition: HardwareCondition = .unknown
    var rimCondition: HardwareCondition = .unknown
    var hoopCount = ""
    var openingHours = "Open access, not officially confirmed"
    var eveningAccess: EveningAccess = .unknown
    var hasToilets: FacilityStatus = .unknown
    var hasDrinkingWater: FacilityStatus = .unknown
    var hasParking: FacilityStatus = .unknown
    var hasChangingRooms: FactStatus = .unknown
    var goodForSolo: FactStatus = .unknown
    var goodForPickup: FactStatus = .unknown
    var goodForTraining: FactStatus = .unknown
    var beginnerFriendly: FactStatus = .unknown
    var notes = ""

    init() {}

    init(court: Court) {
        name = court.name
        area = court.area
        city = court.city
        latitude = String(format: "%.6f", court.latitude)
        longitude = String(format: "%.6f", court.longitude)
        photoAssetName = court.photoAssetName ?? ""
        confidence = court.confidence
        lastCheckedAt = court.lastCheckedAt
        courtType = court.courtType
        accessType = court.accessType
        priceType = court.priceType
        hasLights = court.hasLights
        drynessAfterRain = court.drynessAfterRain
        slipperyWhenWet = court.slipperyWhenWet
        rainPlayable = court.rainPlayable
        surfaceType = court.surfaceType
        surfaceCondition = court.surfaceCondition
        courtCleanliness = court.courtCleanliness
        courtSpace = court.courtSpace
        runoffSafety = court.runoffSafety
        hasNets = court.hasNets
        rimHeight = court.rimHeight
        rimType = court.rimType
        backboardCondition = court.backboardCondition
        rimCondition = court.rimCondition
        hoopCount = court.hoopCount.map(String.init) ?? ""
        openingHours = court.openingHours
        eveningAccess = court.eveningAccess
        hasToilets = court.hasToilets
        hasDrinkingWater = court.hasDrinkingWater
        hasParking = court.hasParking
        hasChangingRooms = court.hasChangingRooms
        goodForSolo = court.goodForSolo
        goodForPickup = court.goodForPickup
        goodForTraining = court.goodForTraining
        beginnerFriendly = court.beginnerFriendly
        notes = court.notes
    }

    func makeCourt(existingID: String?) -> Court? {
        guard let lat = Double(latitude), let lon = Double(longitude) else { return nil }
        return Court(
            id: existingID ?? "manual-\(UUID().uuidString.lowercased())",
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            area: area.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Sheffield" : area,
            city: city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Sheffield" : city,
            latitude: lat,
            longitude: lon,
            source: .hoopLifeManual,
            sourceLicense: "HoopLife admin entry",
            confidence: confidence,
            lastCheckedAt: lastCheckedAt,
            courtType: courtType,
            accessType: accessType,
            priceType: priceType,
            hasLights: hasLights,
            drynessAfterRain: drynessAfterRain,
            slipperyWhenWet: slipperyWhenWet,
            rainPlayable: rainPlayable,
            surfaceType: surfaceType,
            surfaceCondition: surfaceCondition,
            courtCleanliness: courtCleanliness,
            courtSpace: courtSpace,
            runoffSafety: runoffSafety,
            peakTimes: [.unknown],
            hasNets: hasNets,
            rimHeight: rimHeight,
            rimType: rimType,
            backboardCondition: backboardCondition,
            rimCondition: rimCondition,
            hoopCount: Int(hoopCount),
            openingHours: openingHours,
            eveningAccess: eveningAccess,
            hasToilets: hasToilets,
            hasDrinkingWater: hasDrinkingWater,
            hasParking: hasParking,
            hasChangingRooms: hasChangingRooms,
            goodForSolo: goodForSolo,
            goodForPickup: goodForPickup,
            goodForTraining: goodForTraining,
            beginnerFriendly: beginnerFriendly,
            notes: notes,
            photoAssetName: photoAssetName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : photoAssetName
        )
    }

    private static var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
