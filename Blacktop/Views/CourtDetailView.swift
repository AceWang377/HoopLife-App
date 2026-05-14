import SwiftUI
import MapKit

struct CourtDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let court: Court

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    quickFacts
                    locationFacts
                    playingConditions
                    rimAndHoop
                    accessAndTiming
                    facilities
                }
                .padding(20)
            }
            .pageBackground()
            .navigationTitle(store.localized("Court details", "球场详情"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(store.localized("Close", "关闭")) { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    Button {
                        store.toggleSaved(court)
                    } label: {
                        Label(store.isSaved(court) ? store.localized("Saved", "已收藏") : store.localized("Save", "收藏"), systemImage: store.isSaved(court) ? "bookmark.fill" : "bookmark")
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button(store.copy(.directions)) {
                        openDirections()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(20)
                .background(.black.opacity(0.72))
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
                    Label(court.photoAssetName == nil ? store.localized("Default image", "默认图片") : store.localized("Court photo", "球场照片"), systemImage: "photo.fill")
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
                        .foregroundStyle(.white)
                    Text(court.area)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white.opacity(0.62))
                }
                Spacer()
                Button {
                    store.toggleSaved(court)
                } label: {
                    Image(systemName: store.isSaved(court) ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .foregroundStyle(store.isSaved(court) ? HLColor.basketballOrange : HLColor.secondaryText)
                        .padding(10)
                        .background(.white.opacity(0.12))
                        .clipShape(Circle())
                }
            }
        }
    }

    private var quickFacts: some View {
        SectionCard(title: store.localized("Quick facts", "快速信息")) {
            FlowLayout(spacing: 8) {
                ForEach(court.topFacts(language: store.appLanguage)) { fact in
                    FactChip(label: fact.label, tone: fact.tone)
                }
                FactChip(label: court.rimHeight.displayName(store.appLanguage), tone: court.rimHeight == .standard ? .positive : court.rimHeight == .unknown ? .unknown : .warning)
            }
        }
    }

    private var locationFacts: some View {
        SectionCard(title: store.localized("Location", "位置")) {
            FactRow(title: store.localized("Area", "区域"), value: court.area)
            FactRow(title: store.localized("City", "城市"), value: court.city)
            FactRow(title: store.localized("Postcode", "邮编"), value: court.postcode ?? store.localized("Not available", "暂无"), tone: court.postcode == nil ? .unknown : .neutral)
            if let addressLine = court.addressLine {
                FactRow(title: store.localized("Address", "地址"), value: addressLine)
            }
        }
    }

    private var playingConditions: some View {
        SectionCard(title: store.localized("Playing conditions", "场地状态")) {
            FactRow(title: store.localized("Surface", "地面"), value: court.surfaceType.displayName(store.appLanguage))
            FactRow(title: store.localized("Dryness", "干燥情况"), value: court.drynessAfterRain.displayName(store.appLanguage), tone: court.drynessAfterRain.tone)
            FactRow(title: store.localized("Slippery", "湿滑"), value: court.slipperyWhenWet.displayName(store.appLanguage), tone: court.slipperyWhenWet == .yes ? .warning : court.slipperyWhenWet == .no ? .positive : .unknown)
            FactRow(title: store.localized("Rain", "雨天"), value: court.rainPlayable.displayName(store.appLanguage), tone: court.rainPlayable == .indoorUnaffected || court.rainPlayable == .yes ? .positive : court.rainPlayable == .no ? .warning : .unknown)
            FactRow(title: store.localized("Space", "空间"), value: court.courtSpace.displayName(store.appLanguage), tone: court.courtSpace == .spacious ? .positive : court.courtSpace == .unknown ? .unknown : .warning)
            FactRow(title: store.localized("Clean", "清洁度"), value: court.courtCleanliness.displayName(store.appLanguage), tone: court.courtCleanliness == .clean ? .positive : court.courtCleanliness == .unknown ? .unknown : .neutral)
        }
    }

    private var rimAndHoop: some View {
        SectionCard(title: store.localized("Rim and hoop", "篮筐与篮网")) {
            FactRow(title: store.localized("Hoops", "篮筐数量"), value: court.hoopCount.map(String.init) ?? store.localized("Unknown", "未知"))
            FactRow(title: store.localized("Nets", "篮网"), value: court.hasNets.displayName(store.appLanguage), tone: court.hasNets.tone)
            FactRow(title: store.localized("Height", "高度"), value: court.rimHeight.displayName(store.appLanguage), tone: court.rimHeight == .standard ? .positive : court.rimHeight == .unknown ? .unknown : .warning)
            FactRow(title: store.localized("Rim", "篮筐"), value: court.rimType.displayName(store.appLanguage), tone: court.rimType == .doubleRim ? .warning : court.rimType == .unknown ? .unknown : .neutral)
            FactRow(title: store.localized("Backboard", "篮板"), value: court.backboardCondition.displayName(store.appLanguage))
            FactRow(title: store.localized("Rim condition", "篮筐状态"), value: court.rimCondition.displayName(store.appLanguage))
        }
    }

    private var accessAndTiming: some View {
        SectionCard(title: store.localized("Access and timing", "开放与时间")) {
            FactRow(title: store.localized("Access", "开放方式"), value: court.accessType.displayName(store.appLanguage))
            FactRow(title: store.localized("Cost", "费用"), value: court.priceType.displayName(store.appLanguage), tone: court.priceType == .free ? .positive : court.priceType == .unknown ? .unknown : .neutral)
            FactRow(title: store.localized("Hours", "开放时间"), value: court.openingHours)
            FactRow(title: store.localized("Evening", "晚上"), value: court.eveningAccess.displayName(store.appLanguage))
            FactRow(title: store.localized("Peak", "高峰"), value: court.peakTimes.map { $0.displayName(store.appLanguage) }.joined(separator: ", "))
        }
    }

    private var facilities: some View {
        SectionCard(title: store.localized("Facilities", "配套设施")) {
            FactRow(title: store.localized("Toilets", "厕所"), value: court.hasToilets.displayName(store.appLanguage))
            FactRow(title: store.localized("Water", "饮水"), value: court.hasDrinkingWater.displayName(store.appLanguage))
            FactRow(title: store.localized("Parking", "停车"), value: court.hasParking.displayName(store.appLanguage))
            FactRow(title: store.localized("Changing", "更衣"), value: court.hasChangingRooms.displayName(store.appLanguage))
        }
    }

    private func openDirections() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: court.coordinate))
        item.name = court.name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}
