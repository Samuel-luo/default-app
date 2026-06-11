import AppKit
import UniformTypeIdentifiers

struct InstalledApp: Identifiable, Hashable, Sendable {
    let url: URL
    let name: String
    let bundleIdentifier: String?

    var id: String { url.path }

    init(url: URL) {
        self.url = url
        self.name = FileManager.default.displayName(atPath: url.path)
        self.bundleIdentifier = Bundle(url: url)?.bundleIdentifier
    }
}

enum DefaultAppError: LocalizedError {
    case noDefaultApp
    case setFailed(String)

    var errorDescription: String? {
        switch self {
        case .noDefaultApp:
            return "未找到当前默认应用"
        case .setFailed(let message):
            return "设置失败：\(message)"
        }
    }
}

@MainActor
final class DefaultAppService {
    static let shared = DefaultAppService()

    private init() {}

    func currentDefaultApp(for utType: UTType) -> InstalledApp? {
        guard let url = NSWorkspace.shared.urlForApplication(toOpen: utType) else {
            return nil
        }
        return InstalledApp(url: url)
    }

    func availableApps(for utType: UTType) -> [InstalledApp] {
        NSWorkspace.shared.urlsForApplications(toOpen: utType)
            .map(InstalledApp.init(url:))
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func setDefaultApp(_ app: InstalledApp, for utType: UTType) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NSWorkspace.shared.setDefaultApplication(at: app.url, toOpen: utType) { error in
                if let error {
                    continuation.resume(throwing: DefaultAppError.setFailed(error.localizedDescription))
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
