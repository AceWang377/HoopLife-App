import SwiftUI

struct FactChip: View {
    let label: String
    let tone: FactTone

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(foreground)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(background)
            .clipShape(Capsule())
    }

    private var background: Color {
        switch tone {
        case .positive: HLColor.softGreen
        case .warning: HLColor.softWarning
        case .unknown: Color(red: 0.937, green: 0.945, blue: 0.953)
        case .neutral: Color.white.opacity(0.92)
        }
    }

    private var foreground: Color {
        switch tone {
        case .positive: HLColor.courtGreen
        case .warning: Color(red: 0.604, green: 0.396, blue: 0.0)
        case .unknown: HLColor.secondaryText
        case .neutral: HLColor.text
        }
    }
}

struct SelectableChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : HLColor.secondaryText)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? HLColor.night : Color.white.opacity(0.86))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? HLColor.night : HLColor.stroke.opacity(0.7), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct ConfidenceBadge: View {
    let confidence: DataConfidence

    var body: some View {
        Text(confidence.displayName)
            .font(.caption.weight(.bold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(background)
            .clipShape(Capsule())
    }

    private var background: Color {
        switch confidence {
        case .verified, .recentlyChecked: HLColor.softGreen
        case .needsCheck: HLColor.softWarning
        case .userSuggested: HLColor.softBlue
        case .imported: Color(red: 0.937, green: 0.945, blue: 0.953)
        }
    }

    private var foreground: Color {
        switch confidence {
        case .verified, .recentlyChecked: HLColor.courtGreen
        case .needsCheck: Color(red: 0.604, green: 0.396, blue: 0.0)
        case .userSuggested: HLColor.electricBlue
        case .imported: HLColor.secondaryText
        }
    }
}

struct CourtCard: View {
    let court: Court
    var isSaved: Bool
    var onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                courtBadge
                VStack(alignment: .leading, spacing: 4) {
                    Text(court.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(HLColor.text)
                        .lineLimit(1)
                    Text(court.area)
                        .font(.subheadline)
                        .foregroundStyle(HLColor.secondaryText)
                        .lineLimit(1)
                }
                Spacer()
                Button(action: onSave) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.headline)
                        .foregroundStyle(isSaved ? HLColor.basketballOrange : HLColor.secondaryText)
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(court.topFacts) { fact in
                        FactChip(label: fact.label, tone: fact.tone)
                    }
                }
            }

            HStack {
                ConfidenceBadge(confidence: court.confidence)
                Spacer()
                Label("Sheffield", systemImage: "location")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(HLColor.secondaryText)
            }
        }
        .padding(16)
        .cardStyle(radius: 24)
    }

    private var courtBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(court.courtType == .indoor ? HLColor.softBlue : HLColor.softGreen)
                .frame(width: 42, height: 42)
            Image(systemName: court.courtType == .indoor ? "building.2.fill" : "basketball.fill")
                .foregroundStyle(court.courtType == .indoor ? HLColor.electricBlue : HLColor.courtGreen)
        }
    }
}

struct FactRow: View {
    let title: String
    let value: String
    var tone: FactTone = .neutral

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(iconBackground)
                .frame(width: 32, height: 32)
                .overlay {
                    Text(String(title.prefix(1)))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(iconForeground)
                }
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(HLColor.text)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(HLColor.secondaryText)
                .multilineTextAlignment(.trailing)
        }
    }

    private var iconBackground: Color {
        switch tone {
        case .positive: HLColor.softGreen
        case .warning: HLColor.softWarning
        case .unknown: Color(red: 0.937, green: 0.945, blue: 0.953)
        case .neutral: Color(red: 0.937, green: 0.945, blue: 0.953)
        }
    }

    private var iconForeground: Color {
        switch tone {
        case .positive: HLColor.courtGreen
        case .warning: HLColor.warning
        case .unknown, .neutral: HLColor.secondaryText
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(HLColor.text)
            content
        }
        .padding(18)
        .cardStyle(radius: 22)
    }
}
