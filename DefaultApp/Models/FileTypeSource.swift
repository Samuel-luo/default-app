enum FileTypeSource: String, Codable, Sendable {
    case common
    case installed
    case custom

    var label: String {
        switch self {
        case .common:
            return "常用"
        case .installed:
            return "已安装应用"
        case .custom:
            return "自定义"
        }
    }
}
