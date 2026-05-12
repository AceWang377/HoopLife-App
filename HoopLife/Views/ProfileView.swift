import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @State private var passcode = ""
    @State private var adminError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    quickStats
                    librarySection
                    dataSection
                    Color.clear.frame(height: 52)
                    adminSection
                }
                .padding(20)
                .padding(.bottom, 150)
            }
            .pageBackground()
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Profile")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("Browse courts without an account. Saved courts stay local to this device for the MVP.")
                .font(.body.weight(.medium))
                .foregroundStyle(.white.opacity(0.66))
        }
    }

    private var quickStats: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(store.courts.count)", label: "courts")
            StatTile(value: "\(store.savedCourts.count)", label: "saved")
            StatTile(value: "\(verifiedCount)", label: "verified")
        }
    }

    private var verifiedCount: Int {
        store.courts.filter { $0.confidence == .verified || $0.confidence == .recentlyChecked }.count
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
                ProfileLink(title: "Terms and privacy", subtitle: "Simple MVP terms", icon: "doc.text.fill") {
                    TermsView()
                }
            }
        }
    }

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

                SectionCard(title: "MVP promise") {
                    Text("HoopLife shows practical court facts without requiring a public account. Saved courts and owner-only admin edits are stored on this device in the current MVP.")
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
                    Text("Public user submissions are planned for a later backend version. The current build keeps browsing open and uses owner-reviewed data only.")
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
