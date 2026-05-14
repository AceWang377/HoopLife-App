import SwiftUI

#if DEBUG
struct SuggestEditView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let court: Court

    @State private var category = "Dryness and rain"
    @State private var value = "Puddles common"
    @State private var note = ""
    @State private var didSubmit = false

    private let categories = ["Dryness and rain", "Nets and rim", "Lights", "Surface", "Cleanliness", "Peak times", "Facilities", "Access"]
    private let values = ["Dries fast", "Puddles common", "Not slippery", "Nets present", "Standard rim", "Double rim", "No lights", "Unknown"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(court.name)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Help make this court more accurate. Suggestions are reviewed before they appear in Blacktop.")
                        .foregroundStyle(.white.opacity(0.66))

                    SectionCard(title: "What do you want to update?") {
                        FlowLayout(spacing: 10) {
                            ForEach(categories, id: \.self) { item in
                                SelectableChip(label: item, isSelected: category == item) {
                                    category = item
                                }
                            }
                        }
                    }

                    SectionCard(title: "What did you notice?") {
                        FlowLayout(spacing: 10) {
                            ForEach(values, id: \.self) { item in
                                SelectableChip(label: item, isSelected: value == item) {
                                    value = item
                                }
                            }
                        }
                    }

                    SectionCard(title: "Optional note") {
                        TextField("e.g. left hoop has no net", text: $note, axis: .vertical)
                            .lineLimit(3...5)
                            .padding(14)
                            .foregroundStyle(.white)
                            .background(.white.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }

                    if didSubmit {
                        Text("Thanks. This will be reviewed before it appears in Blacktop.")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(HLColor.courtGreen)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(HLColor.softGreen)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding(20)
            }
            .pageBackground()
            .navigationTitle("Suggest edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button("Submit suggestion") {
                    store.addSuggestion(CourtSuggestion(courtName: court.name, category: category, value: value, note: note))
                    didSubmit = true
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(20)
                .background(.black.opacity(0.72))
            }
        }
    }
}
#endif
