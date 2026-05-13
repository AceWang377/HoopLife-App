import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    #if DEBUG
    @State private var passcode = ""
    @State private var adminError = false
    @State private var showingOwnerTools = false
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    quickStats
                    languageSection
                    librarySection
                    dataSection
                }
                .padding(20)
                .padding(.bottom, 150)
            }
            .pageBackground()
            .navigationBarTitleDisplayMode(.inline)
            #if DEBUG
            .sheet(isPresented: $showingOwnerTools) {
                NavigationStack {
                    ScrollView {
                        adminSection
                            .padding(20)
                            .padding(.bottom, 50)
                    }
                    .pageBackground()
                    .navigationTitle("Owner tools")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                showingOwnerTools = false
                            }
                        }
                    }
                }
            }
            #endif
        }
        .task {
            await store.loadCountrySummaries()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(store.copy(.profileTitle))
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(store.copy(.profileSubtitle))
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.66))
        }
        #if DEBUG
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 1.2) {
            HLHaptics.medium()
            showingOwnerTools = true
        }
        #endif
    }

    private var quickStats: some View {
        HStack(spacing: 10) {
            StatTile(value: formatCount(store.totalCourtCount), label: store.copy(.courts))
            StatTile(value: "\(store.savedCourts.count)", label: store.copy(.saved))
            StatTile(value: "\(verifiedCount)", label: store.copy(.verified))
        }
    }

    private var verifiedCount: Int {
        store.courts.filter { $0.confidence == .verified || $0.confidence == .recentlyChecked }.count
    }

    private func formatCount(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private var librarySection: some View {
        SectionCard(title: "Your HoopLife") {
            VStack(spacing: 10) {
                ProfileLink(title: "Saved courts", subtitle: "Your local list", icon: "bookmark.fill") {
                    SavedCourtsView()
                }
            }
        }
    }

    private var languageSection: some View {
        SectionCard(title: store.copy(.language)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(HLColor.night)
                        .frame(width: 38, height: 38)
                        .background(HLColor.freshGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.copy(.appLanguage))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                        Text(store.copy(.appLanguageSubtitle))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.58))
                    }

                    Spacer()
                }

                HStack(spacing: 10) {
                    ForEach(AppLanguage.allCases) { language in
                        Button {
                            HLHaptics.selection()
                            store.setLanguage(language)
                        } label: {
                            Text(language.nativeName)
                                .font(.subheadline.weight(.black))
                                .foregroundStyle(store.appLanguage == language ? HLColor.night : .white.opacity(0.78))
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(store.appLanguage == language ? HLColor.freshGreen : .white.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var dataSection: some View {
        SectionCard(title: "Data and app info") {
            VStack(spacing: 10) {
                ProfileLink(title: "Data sources", subtitle: "OSM, manual checks, confidence", icon: "chart.bar.doc.horizontal") {
                    AboutDataView()
                }
                HStack(spacing: 12) {
                    Image(systemName: store.isLoadingRemoteCourts ? "arrow.triangle.2.circlepath" : "externaldrive.connected.to.line.below.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(HLColor.night)
                        .frame(width: 38, height: 38)
                        .background(HLColor.freshGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Court source")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                        Text(store.isLoadingRemoteCourts ? "Syncing courts..." : store.courtDataSource)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white.opacity(0.58))
                    }

                    Spacer()
                }
                .padding(14)
                .background(.white.opacity(0.09))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                ProfileLink(title: "Terms and privacy", subtitle: "How HoopLife handles data", icon: "doc.text.fill") {
                    TermsView()
                }
            }
        }
    }

    #if DEBUG
    private var adminSection: some View {
        SectionCard(title: "Admin") {
            VStack(alignment: .leading, spacing: 12) {
                if store.isAdminUnlocked {
                    ProfileLink(title: "Court database editor", subtitle: "Add or update verified facts", icon: "slider.horizontal.3") {
                        AdminCourtEditorView()
                    }

                    Button {
                        HLHaptics.light()
                        store.lockAdmin()
                        passcode = ""
                    } label: {
                        Label("Lock admin mode", systemImage: "lock.fill")
                            .font(.subheadline.weight(.bold))
                    }
                    .buttonStyle(SecondaryButtonStyle())
                } else {
                    Text("Hidden owner tool for adding Google Maps checked courts and updating verified facts before a backend exists.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.62))

                    SecureField("Admin passcode", text: $passcode)
                        .textInputAutocapitalization(.characters)
                        .disableAutocorrection(true)
                        .padding(14)
                        .foregroundStyle(.white)
                        .background(.white.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(adminError ? HLColor.basketballOrange : HLColor.stroke, lineWidth: 1)
                        }

                    if adminError {
                        Text("Passcode not recognised.")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(HLColor.basketballOrange)
                    }

                    Button {
                        HLHaptics.medium()
                        adminError = !store.unlockAdmin(passcode: passcode)
                    } label: {
                        Label("Unlock admin", systemImage: "key.fill")
                            .font(.subheadline.weight(.bold))
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
    }
    #endif
}

struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.title.weight(.black))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .cardStyle(radius: 18)
    }
}

struct ProfileLink<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @ViewBuilder var destination: Destination

    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(HLColor.night)
                    .frame(width: 38, height: 38)
                    .background(HLColor.freshGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.58))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.42))
            }
            .padding(14)
            .background(.white.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Terms and privacy")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                SectionCard(title: "Privacy promise") {
                    Text("HoopLife shows practical court facts without requiring an account. Saved courts stay on this device.")
                        .foregroundStyle(.white.opacity(0.62))
                }

                SectionCard(title: "Court data") {
                    Text("Imported OpenStreetMap records are starting points and may be incomplete. Manual HoopLife checks should be used before marking a court verified.")
                        .foregroundStyle(.white.opacity(0.62))
                }

                SectionCard(title: "OpenStreetMap attribution") {
                    Text("Contains information from OpenStreetMap contributors, available under the Open Database License.")
                        .foregroundStyle(.white.opacity(0.62))
                }

                SectionCard(title: "Contributions") {
                    Text("Public user submissions are not available in this release. Court records are imported or reviewed before they appear in HoopLife.")
                        .foregroundStyle(.white.opacity(0.62))
                }
            }
            .padding(20)
            .padding(.bottom, 110)
        }
        .pageBackground()
        .navigationTitle("Terms")
        .navigationBarTitleDisplayMode(.inline)
    }
}
