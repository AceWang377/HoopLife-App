import SwiftUI
import MapKit

struct CourtDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let court: Court
    var showSuggestion: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    quickFacts
                    playingConditions
                    rimAndHoop
                    accessAndTiming
                    facilities
                    dataSection
                }
                .padding(20)
            }
            .pageBackground()
            .navigationTitle("Court details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button("Suggest edit") {
                        showSuggestion()
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button("Directions") {
                        openDirections()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
                .background(.regularMaterial)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(court.displayPhotoAssetName)
                .resizable()
                .scaledToFill()
                .frame(height: 210)
                .frame(maxWidth: .infinity)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    Label(court.photoAssetName == nil ? "Default image" : "Court photo", systemImage: "photo.fill")
                        .font(.caption.weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.46))
                        .clipShape(Capsule())
                        .padding(14)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .stroke(.white.opacity(0.34), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.14), radius: 24, y: 12)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(court.name)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(HLColor.text)
                    Text(court.area)
                        .font(.body.weight(.medium))
                        .foregroundStyle(HLColor.secondaryText)
                }
                Spacer()
                Button {
                    store.toggleSaved(court)
                } label: {
                    Image(systemName: store.isSaved(court) ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .foregroundStyle(store.isSaved(court) ? HLColor.basketballOrange : HLColor.secondaryText)
                        .padding(10)
                        .background(.white)
                        .clipShape(Circle())
                }
            }
            ConfidenceBadge(confidence: court.confidence)
        }
    }

    private var quickFacts: some View {
        SectionCard(title: "Quick facts") {
            FlowLayout(spacing: 8) {
                ForEach(court.topFacts) { fact in
                    FactChip(label: fact.label, tone: fact.tone)
                }
                FactChip(label: court.rimHeight.displayName, tone: court.rimHeight == .standard ? .positive : court.rimHeight == .unknown ? .unknown : .warning)
            }
        }
    }

    private var playingConditions: some View {
        SectionCard(title: "Playing conditions") {
            FactRow(title: "Surface", value: court.surfaceType.displayName)
            FactRow(title: "Dryness", value: court.drynessAfterRain.displayName, tone: court.drynessAfterRain.tone)
            FactRow(title: "Slippery", value: court.slipperyWhenWet.displayName, tone: court.slipperyWhenWet == .yes ? .warning : court.slipperyWhenWet == .no ? .positive : .unknown)
            FactRow(title: "Rain", value: court.rainPlayable.displayName, tone: court.rainPlayable == .indoorUnaffected || court.rainPlayable == .yes ? .positive : court.rainPlayable == .no ? .warning : .unknown)
            FactRow(title: "Space", value: court.courtSpace.displayName, tone: court.courtSpace == .spacious ? .positive : court.courtSpace == .unknown ? .unknown : .warning)
            FactRow(title: "Clean", value: court.courtCleanliness.displayName, tone: court.courtCleanliness == .clean ? .positive : court.courtCleanliness == .unknown ? .unknown : .neutral)
        }
    }

    private var rimAndHoop: some View {
        SectionCard(title: "Rim and hoop") {
            FactRow(title: "Hoops", value: court.hoopCount.map(String.init) ?? "Unknown")
            FactRow(title: "Nets", value: court.hasNets.displayName, tone: court.hasNets.tone)
            FactRow(title: "Height", value: court.rimHeight.displayName, tone: court.rimHeight == .standard ? .positive : court.rimHeight == .unknown ? .unknown : .warning)
            FactRow(title: "Rim", value: court.rimType.displayName, tone: court.rimType == .doubleRim ? .warning : court.rimType == .unknown ? .unknown : .neutral)
            FactRow(title: "Backboard", value: court.backboardCondition.displayName)
            FactRow(title: "Rim condition", value: court.rimCondition.displayName)
        }
    }

    private var accessAndTiming: some View {
        SectionCard(title: "Access and timing") {
            FactRow(title: "Access", value: court.accessType.displayName)
            FactRow(title: "Cost", value: court.priceType.displayName, tone: court.priceType == .free ? .positive : court.priceType == .unknown ? .unknown : .neutral)
            FactRow(title: "Hours", value: court.openingHours)
            FactRow(title: "Evening", value: court.eveningAccess.displayName)
            FactRow(title: "Peak", value: court.peakTimes.map(\.displayName).joined(separator: ", "))
        }
    }

    private var facilities: some View {
        SectionCard(title: "Facilities") {
            FactRow(title: "Toilets", value: court.hasToilets.displayName)
            FactRow(title: "Water", value: court.hasDrinkingWater.displayName)
            FactRow(title: "Parking", value: court.hasParking.displayName)
            FactRow(title: "Changing", value: court.hasChangingRooms.displayName)
        }
    }

    private var dataSection: some View {
        SectionCard(title: "Data") {
            FactRow(title: "Source", value: court.source.displayName)
            FactRow(title: "License", value: court.sourceLicense)
            FactRow(title: "Checked", value: court.lastCheckedAt)
            Text(court.notes)
                .font(.footnote)
                .foregroundStyle(HLColor.secondaryText)
        }
    }

    private func openDirections() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: court.coordinate))
        item.name = court.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}
