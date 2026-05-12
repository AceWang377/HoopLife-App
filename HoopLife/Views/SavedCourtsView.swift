import SwiftUI

struct SavedCourtsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedCourt: Court?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Saved courts")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                        Text("Quickly check your regular spots. Saved courts stay on this device in v1.")
                            .font(.body.weight(.medium))
                            .foregroundStyle(HLColor.secondaryText)
                    }

                    if store.savedCourts.isEmpty {
                        emptyState
                    } else {
                        ForEach(store.savedCourts) { court in
                            CourtCard(court: court, isSaved: true) {
                                store.toggleSaved(court)
                            }
                            .onTapGesture {
                                selectedCourt = court
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 110)
            }
            .pageBackground()
            .sheet(item: $selectedCourt) { court in
                CourtDetailView(court: court, showSuggestion: {})
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "bookmark")
                .font(.largeTitle)
                .foregroundStyle(HLColor.electricBlue)
            Text("Save courts you want to check again.")
                .font(.title2.weight(.black))
            Text("No account needed. Your list is local to this device for the MVP.")
                .foregroundStyle(HLColor.secondaryText)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(radius: 24)
    }
}
