import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: "English"
        case .simplifiedChinese: "Chinese"
        }
    }

    var nativeName: String {
        switch self {
        case .english: "English"
        case .simplifiedChinese: "简体中文"
        }
    }

    var shortName: String {
        switch self {
        case .english: "EN"
        case .simplifiedChinese: "中"
        }
    }

    static var preferred: AppLanguage {
        Locale.preferredLanguages.first?.hasPrefix("zh") == true ? .simplifiedChinese : .english
    }
}

enum HLCopy {
    case languageTitle
    case languageSubtitle
    case languageContinue
    case introTitle
    case introSubtitle
    case introMapTitle
    case introMapSubtitle
    case introFactsTitle
    case introFactsSubtitle
    case introNoLoginTitle
    case introNoLoginSubtitle
    case startMap
    case chooseFacts
    case preferencesTitle
    case preferencesSubtitle
    case showCourtMap
    case skipFilters
    case courts
    case login
    case map
    case searchPlaceholder
    case searchThisArea
    case details
    case directions
    case outdoor
    case indoor
    case free
    case lights
    case dry
    case dryAfterRain
    case nets
    case standardRim
    case soloShooting
    case pickup
    case filters
    case filterSubtitle
    case courtType
    case conditions
    case rimAndHoop
    case use
    case reset
    case done
    case applyFilters
    case mapTab
    case profileTab
    case profileTitle
    case profileSubtitle
    case saved
    case verified
    case language
    case appLanguage
    case appLanguageSubtitle
    case importedWarning
    case incompleteWarning
    case rainWarning
    case rimNetWarning
    case readyWarning

    func text(_ language: AppLanguage) -> String {
        switch language {
        case .english:
            english
        case .simplifiedChinese:
            chinese
        }
    }

    private var english: String {
        switch self {
        case .languageTitle: "Choose your language"
        case .languageSubtitle: "HoopLife can start in English or Simplified Chinese. You can change this later from Profile."
        case .languageContinue: "Continue"
        case .introTitle: "Court facts before pickup."
        case .introSubtitle: "HoopLife helps you check real basketball court facts before you leave: surface, rain, nets, rim, lights, space and access."
        case .introMapTitle: "Find nearby courts"
        case .introMapSubtitle: "Browse courts on a live map and search by city, area or court name."
        case .introFactsTitle: "Check practical facts"
        case .introFactsSubtitle: "See useful details instead of ratings: dry surface, nets, rim height, lights and whether it is free."
        case .introNoLoginTitle: "No account needed"
        case .introNoLoginSubtitle: "Read the map immediately. Saved courts stay on this device."
        case .startMap: "Start with map"
        case .chooseFacts: "Choose court facts"
        case .preferencesTitle: "What should the map surface first?"
        case .preferencesSubtitle: "Pick the factual court signals that matter for your next run."
        case .showCourtMap: "Show court map"
        case .skipFilters: "Skip filters"
        case .courts: "courts"
        case .login: "login"
        case .map: "map"
        case .searchPlaceholder: "Search city, court or area"
        case .searchThisArea: "Search this area"
        case .details: "Details"
        case .directions: "Directions"
        case .outdoor: "Outdoor"
        case .indoor: "Indoor"
        case .free: "Free"
        case .lights: "Lights"
        case .dry: "Dry"
        case .dryAfterRain: "Dry after rain"
        case .nets: "Nets"
        case .standardRim: "Standard rim"
        case .soloShooting: "Solo shooting"
        case .pickup: "Pickup"
        case .filters: "Filters"
        case .filterSubtitle: "Choose the court facts that matter."
        case .courtType: "Court type"
        case .conditions: "Conditions"
        case .rimAndHoop: "Rim and hoop"
        case .use: "Use"
        case .reset: "Reset"
        case .done: "Done"
        case .applyFilters: "Apply filters"
        case .mapTab: "Map"
        case .profileTab: "Profile"
        case .profileTitle: "Profile"
        case .profileSubtitle: "Browse courts without an account. Saved courts stay on this device."
        case .saved: "saved"
        case .verified: "verified"
        case .language: "Language"
        case .appLanguage: "App language"
        case .appLanguageSubtitle: "Change the HoopLife interface language."
        case .importedWarning: "Imported from OpenStreetMap. Not yet verified by HoopLife."
        case .incompleteWarning: "Imported from OpenStreetMap. Details may be incomplete."
        case .rainWarning: "May be slippery after rain. Check before travelling."
        case .rimNetWarning: "Rim and net details still need confirmation."
        case .readyWarning: "Key court facts are ready to check."
        }
    }

    private var chinese: String {
        switch self {
        case .languageTitle: "选择语言"
        case .languageSubtitle: "HoopLife 支持英文和简体中文。之后也可以在 Profile 中修改。"
        case .languageContinue: "继续"
        case .introTitle: "出门前，先看清球场事实。"
        case .introSubtitle: "HoopLife 帮你在出发前查看真实篮球场信息：地面、雨后情况、篮网、篮筐、灯光、空间和开放方式。"
        case .introMapTitle: "在地图上找球场"
        case .introMapSubtitle: "查看附近球场，也可以按城市、区域或球场名称搜索。"
        case .introFactsTitle: "只看实用事实"
        case .introFactsSubtitle: "不做星级评分，重点展示干不干、有没有网、篮筐高度、灯光、是否免费。"
        case .introNoLoginTitle: "无需注册"
        case .introNoLoginSubtitle: "打开就能看地图。收藏球场只保存在本机。"
        case .startMap: "进入地图"
        case .chooseFacts: "选择关注信息"
        case .preferencesTitle: "你最关心哪些球场信息？"
        case .preferencesSubtitle: "选择后，地图会优先显示符合这些事实条件的球场。"
        case .showCourtMap: "显示球场地图"
        case .skipFilters: "跳过筛选"
        case .courts: "球场"
        case .login: "登录"
        case .map: "地图"
        case .searchPlaceholder: "搜索城市、球场或区域"
        case .searchThisArea: "搜索此区域"
        case .details: "查看详情"
        case .directions: "导航"
        case .outdoor: "室外"
        case .indoor: "室内"
        case .free: "免费"
        case .lights: "有灯"
        case .dry: "干燥"
        case .dryAfterRain: "雨后可打"
        case .nets: "有篮网"
        case .standardRim: "标准篮筐"
        case .soloShooting: "适合投篮"
        case .pickup: "适合野球"
        case .filters: "筛选"
        case .filterSubtitle: "选择你关心的球场事实。"
        case .courtType: "球场类型"
        case .conditions: "场地状态"
        case .rimAndHoop: "篮筐与篮网"
        case .use: "使用方式"
        case .reset: "重置"
        case .done: "完成"
        case .applyFilters: "应用筛选"
        case .mapTab: "地图"
        case .profileTab: "我的"
        case .profileTitle: "我的"
        case .profileSubtitle: "无需账号即可浏览球场。收藏内容只保存在本机。"
        case .saved: "收藏"
        case .verified: "已核实"
        case .language: "语言"
        case .appLanguage: "App 语言"
        case .appLanguageSubtitle: "切换 HoopLife 的界面语言。"
        case .importedWarning: "来自 OpenStreetMap，HoopLife 尚未人工核实。"
        case .incompleteWarning: "来自 OpenStreetMap，具体信息可能不完整。"
        case .rainWarning: "雨后可能湿滑，出发前建议再确认。"
        case .rimNetWarning: "篮筐和篮网信息仍待确认。"
        case .readyWarning: "关键球场事实已可查看。"
        }
    }
}

extension AppStore {
    func copy(_ key: HLCopy) -> String {
        key.text(appLanguage)
    }
}
