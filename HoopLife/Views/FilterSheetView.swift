import SwiftUI

struct FilterSheetView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(store.copy(.filters))
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text(store.copy(.filterSubtitle))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.66))
                    }

                    filterSection(store.copy(.courtType)) {
                        SelectableChip(label: store.copy(.outdoor), isSelected: store.filters.outdoor) { store.filters.outdoor.toggle() }
                        SelectableChip(label: store.copy(.indoor), isSelected: store.filters.indoor) { store.filters.indoor.toggle() }
                    }

                    filterSection(store.copy(.conditions)) {
                        SelectableChip(label: store.copy(.dryAfterRain), isSelected: store.filters.dryAfterRain) { store.filters.dryAfterRain.toggle() }
                        SelectableChip(label: store.copy(.lights), isSelected: store.filters.lights) { store.filters.lights.toggle() }
                    }

                    filterSection(store.copy(.rimAndHoop)) {
                        SelectableChip(label: store.copy(.nets), isSelected: store.filters.nets) { store.filters.nets.toggle() }
                        SelectableChip(label: store.copy(.standardRim), isSelected: store.filters.standardRim) { store.filters.standardRim.toggle() }
                    }

                    filterSection(store.copy(.use)) {
                        SelectableChip(label: store.copy(.free), isSelected: store.filters.free) { store.filters.free.toggle() }
                        SelectableChip(label: store.copy(.soloShooting), isSelected: store.filters.solo) { store.filters.solo.toggle() }
                    }
                }
                .padding(24)
            }
            .pageBackground()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(store.copy(.reset)) {
                        store.filters = CourtFilters()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(store.copy(.done)) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("\(store.copy(.applyFilters))  ·  \(store.filteredCourts.count) \(store.copy(.courts))") {
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(20)
                .background(.black.opacity(0.72))
            }
        }
    }

    private func filterSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
            FlowLayout(spacing: 10) {
                content()
            }
        }
        .padding(20)
        .cardStyle(radius: 26)
    }
}
