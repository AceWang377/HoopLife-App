import SwiftUI
import MapKit

struct AddCourtView: View {
    @EnvironmentObject private var store: AppStore
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 53.3811, longitude: -1.4701),
            span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
        )
    )
    @State private var name = ""
    @State private var area = ""
    @State private var type: CourtType = .outdoor
    @State private var submitted = false
    @State private var selectedCoordinate = CLLocationCoordinate2D(latitude: 53.3811, longitude: -1.4701)

    private let defaultCoordinate = CLLocationCoordinate2D(latitude: 53.3811, longitude: -1.4701)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add a court")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                        Text("Tap the map to place a candidate. New courts stay pending until reviewed.")
                            .font(.body.weight(.medium))
                            .foregroundStyle(HLColor.secondaryText)
                    }

                    MapReader { proxy in
                        Map(position: $cameraPosition) {
                            Marker("Candidate court", coordinate: selectedCoordinate)
                                .tint(HLColor.basketballOrange)
                        }
                        .mapStyle(.standard(elevation: .flat))
                        .gesture(
                            SpatialTapGesture().onEnded { value in
                                if let coordinate = proxy.convert(value.location, from: .local) {
                                    HLHaptics.selection()
                                    selectedCoordinate = coordinate
                                    submitted = false
                                }
                            }
                        )
                    }
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    .overlay(alignment: .bottomLeading) {
                        Text("Lat \(selectedCoordinate.latitude.formatted(.number.precision(.fractionLength(5)))) · Lon \(selectedCoordinate.longitude.formatted(.number.precision(.fractionLength(5))))")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.58))
                            .clipShape(Capsule())
                            .padding(12)
                    }

                    SectionCard(title: "Court details") {
                        VStack(alignment: .leading, spacing: 14) {
                            field("Court name", text: $name, placeholder: "e.g. Park court near...")
                            field("Area", text: $area, placeholder: "e.g. Broomhall")

                            Text("Court type")
                                .font(.subheadline.weight(.semibold))
                            FlowLayout(spacing: 10) {
                                SelectableChip(label: "Outdoor", isSelected: type == .outdoor) { type = .outdoor }
                                SelectableChip(label: "Indoor", isSelected: type == .indoor) { type = .indoor }
                                SelectableChip(label: "Not sure", isSelected: type == .unknown) { type = .unknown }
                            }
                        }
                    }

                    if submitted {
                        Text("Candidate submitted for review. It will not appear on the public map until approved.")
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
            .safeAreaInset(edge: .bottom) {
                Button("Submit candidate") {
                    HLHaptics.medium()
                    store.submitCourtCandidate(
                        name: name,
                        area: area,
                        latitude: selectedCoordinate.latitude,
                        longitude: selectedCoordinate.longitude,
                        courtType: type
                    )
                    name = ""
                    area = ""
                    submitted = true
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(20)
                .padding(.bottom, 76)
                .background(.regularMaterial)
            }
        }
    }

    private func field(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            TextField(placeholder, text: text)
                .padding(14)
                .foregroundStyle(HLColor.text)
                .background(Color.white.opacity(0.94))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(HLColor.stroke.opacity(0.8), lineWidth: 1)
                }
        }
    }
}
