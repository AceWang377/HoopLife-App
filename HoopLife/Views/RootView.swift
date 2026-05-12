import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            Group {
                if store.hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }

            if isShowingSplash {
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.15))
            withAnimation(.easeOut(duration: 0.45)) {
                isShowingSplash = false
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Image("HoopLifeCourtArt")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay {
                    LinearGradient(
                        colors: [
                            Color(red: 0.018, green: 0.075, blue: 0.065).opacity(0.28),
                            .black.opacity(0.44)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }

            VStack(spacing: 18) {
                Image("HoopLifeSplashMark")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 172, height: 172)
                    .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 42, style: .continuous)
                            .stroke(.white.opacity(0.24), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.28), radius: 30, y: 18)

                VStack(spacing: 6) {
                    Text("HoopLife")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("court facts, not ratings")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white.opacity(0.72))
                }
            }
            .padding(.horizontal, 32)
        }
        .background(Color(red: 0.018, green: 0.075, blue: 0.065))
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
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .background(HLColor.night.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
                    HLHaptics.selection()
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
