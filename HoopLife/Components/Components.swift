import SwiftUI
import UIKit

enum HLHaptics {
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

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
        case .neutral: HLColor.darkText
        }
    }
}

struct SelectableChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            HLHaptics.selection()
            action()
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? HLColor.night : .white.opacity(0.82))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? HLColor.freshGreen : .white.opacity(0.12))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? HLColor.freshGreen.opacity(0.7) : .white.opacity(0.16), lineWidth: 1)
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
        case .imported: HLColor.darkText.opacity(0.72)
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
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(court.area)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(1)
                }
                Spacer()
                Button {
                    HLHaptics.selection()
                    onSave()
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.headline)
                        .foregroundStyle(isSaved ? HLColor.basketballOrange : .white.opacity(0.68))
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
                Label(court.area, systemImage: "location")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
            }
        }
        .padding(16)
        .background(.black.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.13), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 20, y: 8)
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
                .foregroundStyle(.white.opacity(0.88))
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.58))
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
                .foregroundStyle(.white)
            content
        }
        .padding(18)
        .cardStyle(radius: 22)
    }
}
