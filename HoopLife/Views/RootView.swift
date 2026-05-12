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
    var body: some View {
        TabView {
            CourtMapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }

            SavedCourtsView()
                .tabItem {
                    Label("Saved", systemImage: "bookmark")
                }

            AddCourtView()
                .tabItem {
                    Label("Contribute", systemImage: "plus.circle")
                }

            AboutDataView()
                .tabItem {
                    Label("Data", systemImage: "info.circle")
                }
        }
        .tint(HLColor.electricBlue)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
