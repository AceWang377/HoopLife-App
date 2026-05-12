import SwiftUI

struct AboutDataView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About the data")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("HoopLife is honest about what is verified, imported, or still unknown.")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white.opacity(0.66))
                    }

                    SectionCard(title: "What HoopLife tracks") {
                        Text("Court type, access, rain impact, rim quality, lighting, facilities, space, cleanliness, and peak times.")
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    SectionCard(title: "What verified means") {
                        Text("A verified court has been manually checked by HoopLife or a trusted contributor. Imported records are useful starting points, not final truth.")
                            .foregroundStyle(.white.opacity(0.62))
                    }

                    SectionCard(title: "Sources") {
                        VStack(alignment: .leading, spacing: 12) {
                            FactRow(title: "OSM", value: "OpenStreetMap contributors")
                            FactRow(title: "Active", value: "Sport England Active Places")
                            FactRow(title: "Manual", value: "HoopLife local seed")
                        }
                    }

                    SectionCard(title: "Current MVP stats") {
                        FactRow(title: "Courts", value: "\(store.courts.count)")
                        FactRow(title: "Verified", value: "\(store.courts.filter { $0.confidence == .verified || $0.confidence == .recentlyChecked }.count)")
                        FactRow(title: "Edits", value: "\(store.suggestions.count) pending")
                    }
                }
                .padding(20)
                .padding(.bottom, 110)
            }
            .pageBackground()
        }
    }
}
