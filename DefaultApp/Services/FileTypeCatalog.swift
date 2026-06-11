import Foundation
import Observation
import UniformTypeIdentifiers

enum FileTypeCatalogError: LocalizedError {
    case invalidExtension
    case duplicateExtension

    var errorDescription: String? {
        switch self {
        case .invalidExtension:
            return "扩展名无效，请输入类似 pdf 或 .pdf 的格式。"
        case .duplicateExtension:
            return "该扩展名已在列表中。"
        }
    }
}

@Observable
@MainActor
final class FileTypeCatalog {
    private(set) var commonItems: [FileTypeItem] = []
    private(set) var supplementItems: [FileTypeItem] = []
    private(set) var defaultAppNames: [String: String] = [:]
    private(set) var isScanning = false

    private var customExtensions: Set<String> = []
    private var scannedExtensions: [String: Set<String>] = [:]
    private var hasLoaded = false

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true

        customExtensions = CustomExtensionStore.load()
        rebuildItems()
        await refreshInstalledExtensions()
    }

    func refreshInstalledExtensions() async {
        isScanning = true
        scannedExtensions = await InstalledAppExtensionScanner.scan()
        isScanning = false
        rebuildItems()
    }

    @discardableResult
    func addCustomExtension(_ raw: String) throws -> FileTypeItem {
        guard let normalized = ExtensionNormalizer.normalize(raw) else {
            throw FileTypeCatalogError.invalidExtension
        }

        if containsExtension(normalized) {
            throw FileTypeCatalogError.duplicateExtension
        }

        customExtensions.insert(normalized)
        CustomExtensionStore.save(customExtensions)
        rebuildItems()

        guard let item = supplementItems.first(where: { $0.fileExtension == normalized }) else {
            throw FileTypeCatalogError.invalidExtension
        }

        return item
    }

    func containsExtension(_ fileExtension: String) -> Bool {
        commonItems.contains(where: { $0.fileExtension == fileExtension })
            || supplementItems.contains(where: { $0.fileExtension == fileExtension })
    }

    func refreshDefaultAppName(for item: FileTypeItem) {
        defaultAppNames[item.fileExtension] = resolveDefaultAppName(for: item)
    }

    private func rebuildItems() {
        commonItems = CommonExtensions.uniqueItems.sorted {
            $0.fileExtension.localizedCaseInsensitiveCompare($1.fileExtension) == .orderedAscending
        }

        let commonExtensionSet = Set(commonItems.map(\.fileExtension))
        var supplements: [FileTypeItem] = []
        var seenSupplements = Set<String>()

        for ext in customExtensions.sorted() where !commonExtensionSet.contains(ext) {
            supplements.append(makeItem(fileExtension: ext, source: .custom))
            seenSupplements.insert(ext)
        }

        for ext in scannedExtensions.keys.sorted() where !commonExtensionSet.contains(ext) && !seenSupplements.contains(ext) {
            let appNames = scannedExtensions[ext]?.sorted {
                $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
            } ?? []
            supplements.append(makeItem(fileExtension: ext, source: .installed, declaringAppNames: appNames))
            seenSupplements.insert(ext)
        }

        supplementItems = supplements.sorted {
            $0.fileExtension.localizedCaseInsensitiveCompare($1.fileExtension) == .orderedAscending
        }

        refreshAllDefaultAppNames()
    }

    private func refreshAllDefaultAppNames() {
        var names: [String: String] = [:]
        for item in commonItems + supplementItems {
            names[item.fileExtension] = resolveDefaultAppName(for: item)
        }
        defaultAppNames = names
    }

    private func resolveDefaultAppName(for item: FileTypeItem) -> String {
        DefaultAppService.shared.currentDefaultApp(for: item.utType)?.name ?? "未设置"
    }

    private func makeItem(
        fileExtension: String,
        source: FileTypeSource,
        declaringAppNames: [String] = []
    ) -> FileTypeItem {
        let utType = UTType(filenameExtension: fileExtension) ?? .data
        let displayName = utType.localizedDescription ?? fileExtension.uppercased()
        return FileTypeItem(
            fileExtension: fileExtension,
            displayName: displayName,
            utType: utType,
            source: source,
            declaringAppNames: declaringAppNames
        )
    }
}

private enum CustomExtensionStore {
    private static let key = "customExtensions"

    static func load() -> Set<String> {
        let stored = UserDefaults.standard.stringArray(forKey: key) ?? []
        return Set(stored.compactMap(ExtensionNormalizer.normalize))
    }

    static func save(_ extensions: Set<String>) {
        let sorted = extensions.sorted()
        UserDefaults.standard.set(sorted, forKey: key)
    }
}
