import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Group {
            if store.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .map

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .map:
                    CourtMapView()
                case .saved:
                    SavedCourtsView()
                case .contribute:
                    AddCourtView()
                case .data:
                    AboutDataView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingDock(selectedTab: $selectedTab)
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
        }
        .background(HLColor.night.ignoresSafeArea())
    }
}

enum AppTab: CaseIterable {
    case map
    case saved
    case contribute
    case data

    var title: String {
        switch self {
        case .map: "Map"
        case .saved: "Saved"
        case .contribute: "Add"
        case .data: "Data"
        }
    }

    var icon: String {
        switch self {
        case .map: "map.fill"
        case .saved: "bookmark.fill"
        case .contribute: "plus"
        case .data: "chart.bar.doc.horizontal"
        }
    }
}

struct FloatingDock: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 17, weight: .bold))
                        Text(tab.title)
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(selectedTab == tab ? HLColor.night : .white.opacity(0.70))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(selectedTab == tab ? HLColor.freshGreen : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.black.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.30), radius: 22, y: 10)
    }
}
