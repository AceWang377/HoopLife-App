import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var step = 0
    @State private var selectedPreferences: Set<String> = ["Outdoor", "Free", "Dry after rain"]

    private let preferences = ["Outdoor", "Indoor", "Free", "Lights", "Dry after rain", "Nets", "Standard rim", "Solo shooting", "Pickup"]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                HLColor.night.ignoresSafeArea()

                if step == 0 {
                    welcome(size: proxy.size)
                } else if step == 1 {
                    location(size: proxy.size)
                } else {
                    preferencesView
                        .pageBackground()
                }
            }
        }
    }

    private func welcome(size: CGSize) -> some View {
        ZStack(alignment: .bottomLeading) {
            AnimatedCourtIntro()
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Spacer(minLength: 0)

                HStack(spacing: 10) {
                    Image(systemName: "basketball.fill")
                        .foregroundStyle(HLColor.basketballOrange)
                    Text("HoopLife")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }

                Text("Know the court before you leave.")
                    .font(.system(size: min(size.width * 0.098, 40), weight: .bold, design: .default))
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Dry surface, nets, rim height, lights, space and real Sheffield court facts.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)

                Button("Find courts near me") {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                        step = 1
                    }
                }
                .buttonStyle(DarkPrimaryButtonStyle())
                .padding(.top, 12)

                Button("Explore Sheffield") {
                    store.completeOnboarding()
                }
                .buttonStyle(DarkSecondaryButtonStyle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.horizontal, 24)
            .padding(.bottom, max(size.height * 0.07, 42))
        }
        .frame(width: size.width, height: size.height, alignment: .bottomLeading)
        .ignoresSafeArea()
    }

    private func location(size: CGSize) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            MapIllustration()
                .frame(height: min(size.height * 0.46, 390))
                .padding(.top, 18)

            VStack(alignment: .leading, spacing: 12) {
                Text("Use your location?")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(HLColor.text)

                Text("HoopLife uses it to sort nearby courts. You can still browse Sheffield without it.")
                    .font(.body.weight(.medium))
                    .foregroundStyle(HLColor.secondaryText)
            }
            .padding(.top, 6)

            Spacer(minLength: 8)

            Button("Allow location") {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                    step = 2
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Not now") {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                    step = 2
                }
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(24)
        .pageBackground()
    }

    private var preferencesView: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("What matters today?")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(HLColor.text)

            Text("Pick the court facts you care about most. No account needed.")
                .foregroundStyle(HLColor.secondaryText)

            FlowLayout(spacing: 10) {
                ForEach(preferences, id: \.self) { preference in
                    SelectableChip(label: preference, isSelected: selectedPreferences.contains(preference)) {
                        if selectedPreferences.contains(preference) {
                            selectedPreferences.remove(preference)
                        } else {
                            selectedPreferences.insert(preference)
                        }
                    }
                }
            }

            Spacer()

            Button("Show courts") {
                store.filters.outdoor = selectedPreferences.contains("Outdoor")
                store.filters.indoor = selectedPreferences.contains("Indoor")
                store.filters.free = selectedPreferences.contains("Free")
                store.filters.lights = selectedPreferences.contains("Lights")
                store.filters.dryAfterRain = selectedPreferences.contains("Dry after rain")
                store.filters.nets = selectedPreferences.contains("Nets")
                store.filters.standardRim = selectedPreferences.contains("Standard rim")
                store.filters.solo = selectedPreferences.contains("Solo shooting")
                store.completeOnboarding()
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("Skip for now") {
                store.completeOnboarding()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(24)
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
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.05, blue: 0.035),
                        Color(red: 0.02, green: 0.24, blue: 0.14),
                        Color(red: 0.04, green: 0.38, blue: 0.20),
                        Color(red: 0.02, green: 0.08, blue: 0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Rectangle()
                    .fill(Color.white.opacity(0.035))
                    .frame(width: width * 1.4, height: height * 0.46)
                    .rotationEffect(.degrees(-7))
                    .offset(y: -height * 0.18)

                FullScreenCourtLines()
                    .stroke(.white.opacity(0.31), lineWidth: 3.2)
                    .frame(width: width * 1.28, height: height * 0.86)
                    .offset(x: width * 0.03, y: animate ? height * 0.19 : height * 0.25)
                    .scaleEffect(animate ? 1 : 1.04)
                    .animation(.easeOut(duration: 1.2), value: animate)

                Circle()
                    .fill(HLColor.basketballOrange)
                    .frame(width: 58, height: 58)
                    .overlay(BasketballLines().stroke(HLColor.night.opacity(0.55), lineWidth: 2))
                    .offset(x: animate ? width * 0.31 : -width * 0.30, y: animate ? -height * 0.18 : -height * 0.34)
                    .rotationEffect(.degrees(animate ? 360 : 0))
                    .shadow(color: HLColor.basketballOrange.opacity(0.35), radius: 24)
                    .animation(.spring(response: 1.15, dampingFraction: 0.78).delay(0.18), value: animate)

                LinearGradient(
                    colors: [
                        .black.opacity(0.08),
                        .clear,
                        .black.opacity(0.34),
                        .black.opacity(0.56)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
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
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(HLColor.electricBlue.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(HLColor.text)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.white.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(HLColor.stroke, lineWidth: 1)
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
