import SwiftUI
import UniformTypeIdentifiers

struct AppPickerView: View {
    let fileType: FileTypeItem
    let onDefaultAppChanged: () -> Void

    @State private var currentApp: InstalledApp?
    @State private var availableApps: [InstalledApp] = []
    @State private var selectedApp: InstalledApp?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) { // Spacing between panels reduced to 8pt to match outer margins
            header

            if isLoading {
                ProgressView("正在加载应用列表…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if availableApps.isEmpty {
                ContentUnavailableView(
                    "没有可用应用",
                    systemImage: "app.dashed",
                    description: Text("系统中没有可打开 .\(fileType.fileExtension) 文件的应用。")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                appList
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 8) // Balanced 8pt horizontal margins
        .padding(.top, 56) // Matches the searchable offset to sit perfectly below the top window chrome
        .padding(.bottom, 8) // Bottom margin reduced to 8pt to match outer margins
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ignoresSafeArea(.container, edges: .top) // Extends view layout fully into the titlebar area
        .contentShape(Rectangle()) // Makes the entire background area hit-testable
        .onTapGesture {
            // Dismiss focus from the search text field when clicking empty/background areas of detail view
            DispatchQueue.main.async {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
        .navigationTitle(fileType.label)
        .task(id: fileType.id) {
            await loadApps()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("当前默认应用")
                .font(.headline)

            if let currentApp {
                AppRowView(app: currentApp, isDefault: true)
            } else {
                Text("未设置")
                    .foregroundStyle(.secondary)
            }

            Text("修改后将应用于所有 .\(fileType.fileExtension) 文件。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassPanel()
    }

    private var appList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择应用")
                .font(.headline)

            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(availableApps) { app in
                        AppRowButton(app: app, isDefault: app == currentApp, isSelected: app == selectedApp) {
                            selectedApp = app
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollContentBackground(.hidden)

            HStack {
                if let successMessage {
                    Text(successMessage)
                        .font(.subheadline)
                        .foregroundStyle(.green)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }

                Spacer()
                Button {
                    Task { await applyDefault() }
                } label: {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.horizontal, 8)
                    } else {
                        Text("设为默认")
                    }
                }
                .buttonStyle(.glassProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(selectedApp == nil || selectedApp == currentApp || isSaving)
                .pointingHandCursor()
            }
            .animation(.default, value: successMessage)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensures the content within the panel stretches fully and fills the height
        .liquidGlassPanel()
    }

    private func loadApps() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        let service = DefaultAppService.shared
        currentApp = service.currentDefaultApp(for: fileType.utType)
        availableApps = service.availableApps(for: fileType.utType)
        selectedApp = currentApp ?? availableApps.first

        isLoading = false
    }

    private func applyDefault() async {
        guard let selectedApp else { return }

        isSaving = true
        errorMessage = nil
        successMessage = nil

        do {
            try await DefaultAppService.shared.setDefaultApp(selectedApp, for: fileType.utType)
            currentApp = selectedApp
            onDefaultAppChanged()
            
            withAnimation {
                successMessage = "设置成功"
            }
            
            // 3秒后自动淡出成功提示
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    if successMessage == "设置成功" {
                        successMessage = nil
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}

private struct AppRowButton: View {
    let app: InstalledApp
    let isDefault: Bool
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                AppIconView(url: app.url)

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name)
                        .lineLimit(1)
                        .font(.body)
                        .foregroundStyle(isSelected ? .white : .primary)
                    if let bundleIdentifier = app.bundleIdentifier {
                        Text(bundleIdentifier)
                            .font(.caption)
                            .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if isDefault {
                    Text("默认")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .pointingHandCursor()
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.accentColor : (isHovered ? Color.primary.opacity(0.05) : Color.clear))
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .pointingHandCursor()
    }
}

private struct AppRowView: View {
    let app: InstalledApp
    let isDefault: Bool

    var body: some View {
        HStack(spacing: 12) {
            AppIconView(url: app.url)

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .lineLimit(1)
                if let bundleIdentifier = app.bundleIdentifier {
                    Text(bundleIdentifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if isDefault {
                Text("默认")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle()) // Makes the entire row area clickable and hoverable
    }
}

private struct AppIconView: View {
    let url: URL

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
            .resizable()
            .frame(width: 32, height: 32)
    }
}
