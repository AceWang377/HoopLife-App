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
                        VStack(alignment: .leading, spacing: 10) {
                            Text("A verified court has been manually checked by HoopLife or a trusted contributor.")
                                .foregroundStyle(.white.opacity(0.62))
                            FactRow(title: "Imported", value: "Imported from OpenStreetMap")
                            FactRow(title: "Status", value: "Not yet verified by HoopLife", tone: .warning)
                            FactRow(title: "Details", value: "Details may be incomplete", tone: .unknown)
                        }
                    }

                    SectionCard(title: "Sources") {
                        VStack(alignment: .leading, spacing: 12) {
                            FactRow(title: "OSM", value: "OpenStreetMap contributors")
                            FactRow(title: "Active", value: "Sport England Active Places")
                            FactRow(title: "Manual", value: "HoopLife local seed")
                        }
                    }

                    SectionCard(title: "Current data stats") {
                        FactRow(title: "Courts", value: "\(store.courts.count)")
                        FactRow(title: "Verified", value: "\(store.courts.filter { $0.confidence == .verified || $0.confidence == .recentlyChecked }.count)")
                        FactRow(title: "Imported", value: "\(store.courts.filter { $0.confidence == .imported }.count)")
                    }
                }
                .padding(20)
                .padding(.bottom, 110)
            }
            .pageBackground()
        }
    }
}
