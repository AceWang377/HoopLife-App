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

    private let defaultCoordinate = CLLocationCoordinate2D(latitude: 53.3811, longitude: -1.4701)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add a court")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                        Text("Drop a missing court into the Sheffield seed set. You can add richer facts after it exists.")
                            .font(.body.weight(.medium))
                            .foregroundStyle(HLColor.secondaryText)
                    }

                    Map(position: $cameraPosition) {
                        Marker("New court", coordinate: defaultCoordinate)
                            .tint(HLColor.basketballOrange)
                    }
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

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
                        Text("Court added as a user suggestion. It is marked as needs review.")
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
                Button("Submit court") {
                    store.addMissingCourt(
                        name: name,
                        area: area,
                        latitude: defaultCoordinate.latitude,
                        longitude: defaultCoordinate.longitude,
                        courtType: type
                    )
                    name = ""
                    area = ""
                    submitted = true
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(20)
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
                .background(HLColor.background)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
