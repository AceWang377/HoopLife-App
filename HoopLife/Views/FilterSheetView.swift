import SwiftUI

struct FilterSheetView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Filters")
                            .font(.system(size: 36, weight: .black, design: .rounded))
                        Text("Choose the court facts that matter.")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(HLColor.secondaryText)
                    }

                    filterSection("Court type") {
                        SelectableChip(label: "Outdoor", isSelected: store.filters.outdoor) { store.filters.outdoor.toggle() }
                        SelectableChip(label: "Indoor", isSelected: store.filters.indoor) { store.filters.indoor.toggle() }
                    }

                    filterSection("Conditions") {
                        SelectableChip(label: "Dry after rain", isSelected: store.filters.dryAfterRain) { store.filters.dryAfterRain.toggle() }
                        SelectableChip(label: "Lights", isSelected: store.filters.lights) { store.filters.lights.toggle() }
                    }

                    filterSection("Rim and hoop") {
                        SelectableChip(label: "Nets", isSelected: store.filters.nets) { store.filters.nets.toggle() }
                        SelectableChip(label: "Standard rim", isSelected: store.filters.standardRim) { store.filters.standardRim.toggle() }
                    }

                    filterSection("Use") {
                        SelectableChip(label: "Free", isSelected: store.filters.free) { store.filters.free.toggle() }
                        SelectableChip(label: "Solo shooting", isSelected: store.filters.solo) { store.filters.solo.toggle() }
                    }
                }
                .padding(24)
            }
            .pageBackground()
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        store.filters = CourtFilters()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Apply filters  ·  \(store.filteredCourts.count) courts") {
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(20)
                .background(.regularMaterial)
            }
        }
    }

    private func filterSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline.weight(.bold))
            FlowLayout(spacing: 10) {
                content()
            }
        }
        .padding(20)
        .cardStyle(radius: 26)
    }
}
