import UniformTypeIdentifiers

struct FileTypeItem: Identifiable, Hashable, Sendable {
    let id: String
    let fileExtension: String
    let displayName: String
    let utType: UTType
    let source: FileTypeSource
    let declaringAppNames: [String]

    init(
        fileExtension: String,
        displayName: String,
        utType: UTType,
        source: FileTypeSource = .common,
        declaringAppNames: [String] = []
    ) {
        let normalized = fileExtension.lowercased()
        self.id = normalized
        self.fileExtension = normalized
        self.displayName = displayName
        self.utType = utType
        self.source = source
        self.declaringAppNames = declaringAppNames
    }

    func listSubtitle(defaultAppName: String) -> String {
        "\(displayName) - \(defaultAppName)"
    }

    var label: String {
        ".\(fileExtension) — \(displayName)"
    }
}
