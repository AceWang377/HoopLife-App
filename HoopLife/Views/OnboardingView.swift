import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var step: OnboardingStep = .language
    @State private var selectedPreferences: Set<OnboardingPreference> = [.outdoor, .free, .dryAfterRain]

    private let preferences = OnboardingPreference.allCases

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AnimatedCourtIntro()
                    .ignoresSafeArea()

                switch step {
                case .language:
                    languageView(size: proxy.size)
                case .intro:
                    welcome(size: proxy.size)
                case .preferences:
                    preferencesView(size: proxy.size)
                }
            }
            .background(HLColor.night.ignoresSafeArea())
        }
    }

    private func languageView(size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            brandPill

            Spacer(minLength: 28)

            VStack(alignment: .leading, spacing: 14) {
                Text(store.copy(.languageTitle))
                    .font(.system(size: min(size.width * 0.108, 42), weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(store.copy(.languageSubtitle))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.76))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 24)

            VStack(spacing: 12) {
                ForEach(AppLanguage.allCases) { language in
                    Button {
                        HLHaptics.selection()
                        store.setLanguage(language)
                    } label: {
                        HStack(spacing: 14) {
                            Text(language.shortName)
                                .font(.headline.weight(.black))
                                .foregroundStyle(store.appLanguage == language ? HLColor.night : .white)
                                .frame(width: 46, height: 46)
                                .background(store.appLanguage == language ? HLColor.freshGreen : .white.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(language.nativeName)
                                    .font(.headline.weight(.black))
                                    .foregroundStyle(.white)
                                Text(language.displayName)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.58))
                            }

                            Spacer()

                            Image(systemName: store.appLanguage == language ? "checkmark.circle.fill" : "circle")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(store.appLanguage == language ? HLColor.freshGreen : .white.opacity(0.32))
                        }
                        .padding(14)
                        .background(.black.opacity(store.appLanguage == language ? 0.48 : 0.28))
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(store.appLanguage == language ? HLColor.freshGreen.opacity(0.72) : .white.opacity(0.13), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 26)

            Button(store.copy(.languageContinue)) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    step = .intro
                }
            }
            .buttonStyle(DarkPrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .safeAreaPadding(.top, 32)
        .safeAreaPadding(.bottom, 30)
    }

    private func welcome(size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            brandPill

            Spacer(minLength: 28)

            VStack(alignment: .leading, spacing: 14) {
                Text(store.copy(.introTitle))
                    .font(.system(size: min(size.width * 0.108, 42), weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(store.copy(.introSubtitle))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.76))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    IntroFeatureRow(icon: "map.fill", title: store.copy(.introMapTitle), subtitle: store.copy(.introMapSubtitle))
                    IntroFeatureRow(icon: "checklist.checked", title: store.copy(.introFactsTitle), subtitle: store.copy(.introFactsSubtitle))
                    IntroFeatureRow(icon: "person.slash.fill", title: store.copy(.introNoLoginTitle), subtitle: store.copy(.introNoLoginSubtitle))
                }
                .padding(.top, 8)
            }

            Spacer(minLength: 30)

            VStack(spacing: 12) {
                Button(store.copy(.startMap)) {
                    store.completeOnboarding()
                }
                .buttonStyle(DarkPrimaryButtonStyle())

                Button(store.copy(.chooseFacts)) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                        step = .preferences
                    }
                }
                .buttonStyle(DarkSecondaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .safeAreaPadding(.top, 32)
        .safeAreaPadding(.bottom, 30)
    }

    private func preferencesView(size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                    step = .intro
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.28))
                    .clipShape(Circle())
            }

            Spacer()

            Text(store.copy(.preferencesTitle))
                .font(.system(size: min(size.width * 0.105, 40), weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(store.copy(.preferencesSubtitle))
                .font(.body.weight(.semibold))
                .foregroundStyle(.white.opacity(0.76))

            FlowLayout(spacing: 10) {
                ForEach(preferences, id: \.self) { preference in
                    SelectableChip(label: preference.title(store.appLanguage), isSelected: selectedPreferences.contains(preference)) {
                        if selectedPreferences.contains(preference) {
                            selectedPreferences.remove(preference)
                        } else {
                            selectedPreferences.insert(preference)
                        }
                    }
                }
            }

            Button(store.copy(.showCourtMap)) {
                store.filters.outdoor = selectedPreferences.contains(.outdoor)
                store.filters.indoor = selectedPreferences.contains(.indoor)
                store.filters.free = selectedPreferences.contains(.free)
                store.filters.lights = selectedPreferences.contains(.lights)
                store.filters.dryAfterRain = selectedPreferences.contains(.dryAfterRain)
                store.filters.nets = selectedPreferences.contains(.nets)
                store.filters.standardRim = selectedPreferences.contains(.standardRim)
                store.filters.solo = selectedPreferences.contains(.soloShooting)
                store.completeOnboarding()
            }
            .buttonStyle(DarkPrimaryButtonStyle())
            .padding(.top, 8)

            Button(store.copy(.skipFilters)) {
                store.completeOnboarding()
            }
            .buttonStyle(DarkSecondaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .safeAreaPadding(.top, 32)
        .safeAreaPadding(.bottom, 30)
    }

    private var brandPill: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "basketball.fill")
                    .foregroundStyle(HLColor.basketballOrange)
                Text("HoopLife")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(.black.opacity(0.28))
            .clipShape(Capsule())
            .overlay {
                Capsule().stroke(.white.opacity(0.12), lineWidth: 1)
            }

            Spacer()
        }
    }
}

private enum OnboardingStep {
    case language
    case intro
    case preferences
}

private enum OnboardingPreference: String, CaseIterable {
    case outdoor
    case indoor
    case free
    case lights
    case dryAfterRain
    case nets
    case standardRim
    case soloShooting
    case pickup

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .outdoor: HLCopy.outdoor.text(language)
        case .indoor: HLCopy.indoor.text(language)
        case .free: HLCopy.free.text(language)
        case .lights: HLCopy.lights.text(language)
        case .dryAfterRain: HLCopy.dryAfterRain.text(language)
        case .nets: HLCopy.nets.text(language)
        case .standardRim: HLCopy.standardRim.text(language)
        case .soloShooting: HLCopy.soloShooting.text(language)
        case .pickup: HLCopy.pickup.text(language)
        }
    }
}

struct IntroFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline.weight(.black))
                .foregroundStyle(HLColor.night)
                .frame(width: 38, height: 38)
                .background(HLColor.freshGreen)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.66))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.black.opacity(0.26))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.13), lineWidth: 1)
        }
    }
}

struct WelcomeMetric: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 17, weight: .black))
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.62))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.black.opacity(0.24))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.13), lineWidth: 1)
        }
    }
}

struct CourtHeroGraphic: View {
    var body: some View {
        ZStack {
            HLColor.card
            RoundedRectangle(cornerRadius: 24)
                .fill(HLColor.courtGreen)
                .frame(width: 290, height: 178)
                .overlay {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white.opacity(0.75), lineWidth: 2)
                            .frame(width: 210, height: 108)
                        Rectangle()
                            .fill(.white.opacity(0.75))
                            .frame(width: 2, height: 178)
                        Circle()
                            .stroke(.white.opacity(0.75), lineWidth: 2)
                            .frame(width: 68, height: 68)
                    }
                }
            Circle()
                .fill(HLColor.basketballOrange)
                .frame(width: 48, height: 48)
                .offset(x: 92, y: -92)
        }
    }
}

struct AnimatedCourtIntro: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                Image("HoopLifeCourtArt")
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .scaleEffect(animate ? 1.04 : 1.0)
                    .offset(x: animate ? -width * 0.018 : width * 0.018, y: animate ? -height * 0.018 : height * 0.018)
                    .animation(.easeOut(duration: 1.4), value: animate)

                LinearGradient(
                    colors: [
                        .black.opacity(0.18),
                        Color(red: 0.01, green: 0.12, blue: 0.10).opacity(0.12),
                        .black.opacity(0.38),
                        .black.opacity(0.70)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.42)
                    ],
                    center: .center,
                    startRadius: min(width, height) * 0.18,
                    endRadius: max(width, height) * 0.62
                )
            }
            .frame(width: width, height: height)
            .onAppear { animate = true }
        }
    }
}

struct FullScreenCourtLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let court = rect.insetBy(dx: -18, dy: 0)
        path.addRect(court)
        path.move(to: CGPoint(x: court.midX, y: court.minY))
        path.addLine(to: CGPoint(x: court.midX, y: court.maxY))
        path.addEllipse(in: CGRect(x: court.midX - 58, y: court.midY - 58, width: 116, height: 116))

        let leftPaint = CGRect(x: court.minX + court.width * 0.08, y: court.midY - 124, width: court.width * 0.34, height: 248)
        let rightPaint = CGRect(x: court.maxX - court.width * 0.42, y: court.midY - 124, width: court.width * 0.34, height: 248)
        path.addRoundedRect(in: leftPaint, cornerSize: CGSize(width: 18, height: 18))
        path.addRoundedRect(in: rightPaint, cornerSize: CGSize(width: 18, height: 18))

        path.addArc(
            center: CGPoint(x: leftPaint.maxX, y: court.midY),
            radius: 72,
            startAngle: .degrees(-90),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addArc(
            center: CGPoint(x: rightPaint.minX, y: court.midY),
            radius: 72,
            startAngle: .degrees(90),
            endAngle: .degrees(270),
            clockwise: false
        )
        return path
    }
}

struct CourtLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 24, height: 24))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addEllipse(in: CGRect(x: rect.midX - 42, y: rect.midY - 42, width: 84, height: 84))
        path.addRoundedRect(in: CGRect(x: rect.minX + 34, y: rect.midY - 88, width: 108, height: 176), cornerSize: CGSize(width: 12, height: 12))
        path.addRoundedRect(in: CGRect(x: rect.maxX - 142, y: rect.midY - 88, width: 108, height: 176), cornerSize: CGSize(width: 12, height: 12))
        return path
    }
}

struct BasketballLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect.insetBy(dx: 1, dy: 1))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addEllipse(in: rect.insetBy(dx: 15, dy: -4))
        return path
    }
}

struct MapIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(red: 0.918, green: 0.945, blue: 0.91))

            ForEach(0..<6) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(.white)
                    .frame(width: index.isMultiple(of: 2) ? 360 : 8, height: index.isMultiple(of: 2) ? 8 : 340)
                    .rotationEffect(.degrees(Double(index * 17 - 30)))
                    .opacity(0.9)
            }

            Circle()
                .fill(HLColor.electricBlue)
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(.white, lineWidth: 4))
        }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 24, y: 12)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(HLColor.night)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(HLColor.freshGreen.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(.white.opacity(configuration.isPressed ? 0.10 : 0.16))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.20), lineWidth: 1)
            }
    }
}

struct DarkPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(HLColor.night)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(.white.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct DarkSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(.white.opacity(configuration.isPressed ? 0.12 : 0.18))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
