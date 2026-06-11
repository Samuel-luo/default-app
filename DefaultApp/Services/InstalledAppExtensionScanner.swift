import Foundation
import UniformTypeIdentifiers

enum ExtensionNormalizer {
    static func normalize(_ raw: String) -> String? {
        var value = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix(".") {
            value.removeFirst()
        }

        guard !value.isEmpty, value.count <= 16 else { return nil }
        guard value.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }) else {
            return nil
        }

        return value
    }
}

enum InstalledAppExtensionScanner {
    private static let applicationDirectories: [URL] = [
        URL(fileURLWithPath: "/Applications", isDirectory: true),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true),
        URL(fileURLWithPath: "/System/Applications", isDirectory: true),
    ]

    static func scan() async -> [String: Set<String>] {
        await Task.detached(priority: .utility) {
            scanSynchronously()
        }.value
    }

    private static func scanSynchronously() -> [String: Set<String>] {
        var extensionOwners: [String: Set<String>] = [:]
        let fileManager = FileManager.default

        for directory in applicationDirectories where fileManager.fileExists(atPath: directory.path) {
            merge(&extensionOwners, with: collectExtensions(in: directory, fileManager: fileManager))
        }

        return extensionOwners
    }

    private static func merge(_ target: inout [String: Set<String>], with source: [String: Set<String>]) {
        for (ext, appNames) in source {
            target[ext, default: []].formUnion(appNames)
        }
    }

    private static func collectExtensions(in directory: URL, fileManager: FileManager) -> [String: Set<String>] {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return [:]
        }

        var extensionOwners: [String: Set<String>] = [:]

        for case let url as URL in enumerator where url.pathExtension == "app" {
            let appName = applicationName(for: url)
            let extensions = collectExtensionsDeclared(by: url)

            for ext in extensions {
                extensionOwners[ext, default: []].insert(appName)
            }
        }

        return extensionOwners
    }

    private static func applicationName(for appURL: URL) -> String {
        guard let bundle = Bundle(url: appURL) else {
            return FileManager.default.displayName(atPath: appURL.path)
        }

        if let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           !displayName.isEmpty {
            return displayName
        }

        if let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String,
           !bundleName.isEmpty {
            return bundleName
        }

        return FileManager.default.displayName(atPath: appURL.path)
    }

    private static func collectExtensionsDeclared(by appURL: URL) -> Set<String> {
        guard let bundle = Bundle(url: appURL),
              let info = bundle.infoDictionary else {
            return []
        }

        var extensions = Set<String>()

        if let documentTypes = info["CFBundleDocumentTypes"] as? [[String: Any]] {
            for documentType in documentTypes {
                extensions.formUnion(strings(from: documentType["CFBundleTypeExtensions"]))
                extensions.formUnion(collectExtensions(fromContentTypes: documentType["LSItemContentTypes"]))
            }
        }

        for key in ["UTExportedTypeDeclarations", "UTImportedTypeDeclarations"] {
            guard let declarations = info[key] as? [[String: Any]] else { continue }
            for declaration in declarations {
                extensions.formUnion(collectExtensions(fromTagSpecification: declaration["UTTypeTagSpecification"]))
            }
        }

        return Set(extensions.compactMap(ExtensionNormalizer.normalize))
    }

    private static func strings(from value: Any?) -> Set<String> {
        switch value {
        case let string as String:
            return Set([string])
        case let strings as [String]:
            return Set(strings)
        default:
            return []
        }
    }

    private static func collectExtensions(fromContentTypes value: Any?) -> Set<String> {
        let identifiers = strings(from: value)
        var extensions = Set<String>()

        for identifier in identifiers {
            guard let utType = UTType(identifier) else { continue }
            if let preferred = utType.preferredFilenameExtension {
                extensions.insert(preferred)
            }
            extensions.formUnion(utType.tags[.filenameExtension] ?? [])
        }

        return extensions
    }

    private static func collectExtensions(fromTagSpecification value: Any?) -> Set<String> {
        guard let specification = value as? [String: Any] else { return [] }
        return strings(from: specification["public.filename-extension"])
    }
}
