enum FileTypeListTab: String, CaseIterable, Identifiable {
    case common = "常用"
    case supplement = "应用补充"

    var id: String { rawValue }
}
