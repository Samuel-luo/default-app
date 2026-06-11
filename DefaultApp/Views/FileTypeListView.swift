import SwiftUI

struct FileTypeListView: View {
    @Bindable var catalog: FileTypeCatalog
    @Binding var selection: FileTypeItem?
    @Binding var searchText: String
    @Binding var selectedTab: FileTypeListTab
    
    let onRefresh: () -> Void
    let onAdd: () -> Void

    private var currentItems: [FileTypeItem] {
        switch selectedTab {
        case .common:
            return catalog.commonItems
        case .supplement:
            return catalog.supplementItems
        }
    }

    private var filteredItems: [FileTypeItem] {
        guard !searchText.isEmpty else { return currentItems }
        let query = searchText.lowercased()
        return currentItems.filter { item in
            let defaultAppName = catalog.defaultAppNames[item.fileExtension] ?? ""
            return item.fileExtension.contains(query)
                || item.displayName.lowercased().contains(query)
                || defaultAppName.lowercased().contains(query)
                || item.listSubtitle(defaultAppName: defaultAppName).lowercased().contains(query)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Underneath: List which ignores top safe area to extend all the way under the traffic lights
            List(selection: $selection) {
                // Top placeholder to push content below the floating capsule and gradient blur.
                // This scrolls away naturally as the user scrolls, creating a perfect distance
                // from the top in the default (unscrolled) state.
                Color.clear
                    .frame(height: 88)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .disabled(true) // Disable interaction on the spacer row

                ForEach(filteredItems) { item in
                    FileTypeRowView(
                        item: item,
                        defaultAppName: catalog.defaultAppNames[item.fileExtension] ?? "未设置"
                    )
                    .tag(item)
                    .pointingHandCursor()
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .onTapGesture {
                // Dismiss focus from the search text field when tapping on empty/background list areas
                DispatchQueue.main.async {
                    NSApp.keyWindow?.makeFirstResponder(nil)
                }
            }
            // Disable scroll clipping so elements are rendered properly when scrolling up under the glass and traffic lights
            .scrollClipDisabled()

            // Floated on Top: Gradient blur panel that smoothly fades the list items as they scroll to the top.
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 96)
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.3) // Lower the opacity further to make the blur extremely soft, subtle, and highly transparent
                            .mask(
                                LinearGradient(
                                    stops: [
                                        .init(color: .black, location: 0.0),
                                        .init(color: .black, location: 0.65),
                                        .init(color: .black.opacity(0.0), location: 1.0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                Spacer()
            }
            // Allows clicks and scroll gestures to pass directly through the gradient blur mask to the list below
            .allowsHitTesting(false)

            // Floated on Top: Authentic Liquid Glass floating capsule panel with background blur & refract
            HStack(alignment: .center, spacing: 8) {
                Picker("", selection: $selectedTab) {
                    ForEach(FileTypeListTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize(horizontal: false, vertical: true)
                .pointingHandCursor()

                Spacer(minLength: 4)

                Button(action: onRefresh) {
                    if catalog.isScanning {
                        ProgressView()
                            .controlSize(.small)
                            // Match the visual footprint of the button icon roughly
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.body)
                    }
                }
                .buttonStyle(.borderless)
                .disabled(catalog.isScanning)
                .help("重新扫描")
                .pointingHandCursor()

                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.body)
                }
                .buttonStyle(.borderless)
                .help("添加扩展名")
                .pointingHandCursor()

                Button {
                    SidebarToggle.perform()
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.body)
                }
                .buttonStyle(.borderless)
                .help("隐藏侧边栏")
                .pointingHandCursor()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            // Liquid Glass effect with capsule shape and interactive highlight
            // Using .clear material blending with a vibrant specular overlay to greatly enhance 
            // the refraction, edge specular shine, and transparency of the physical liquid glass.
            .glassEffect(.clear.interactive(), in: Capsule())
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.35),
                                .white.opacity(0.05),
                                .black.opacity(0.02),
                                .white.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
                    .blendMode(.plusLighter) // Perfectly overlays high-fidelity light reflections
            )
            .padding(.horizontal, 12)
            // Sits perfectly below the window traffic lights (which end at y=28)
            .padding(.top, 36)
        }
        // Force the entire ZStack to ignore top safe area, aligning both list and capsule coordinates from absolute top (y=0)
        .ignoresSafeArea(.container, edges: .top)
        .overlay { scanningOverlay }
        .onChange(of: selectedTab) { _, _ in ensureValidSelection() }
        .onChange(of: catalog.commonItems) { _, _ in ensureValidSelection() }
        .onChange(of: catalog.supplementItems) { _, _ in ensureValidSelection() }
    }

    @ViewBuilder
    private var scanningOverlay: some View {
        if selectedTab == .supplement, catalog.supplementItems.isEmpty, catalog.isScanning {
            ProgressView("正在扫描已安装应用…")
        }
    }

    private func ensureValidSelection() {
        if let selection, currentItems.contains(selection) {
            return
        }
        selection = currentItems.first
    }
}

private struct FileTypeRowView: View {
    let item: FileTypeItem
    let defaultAppName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(".\(item.fileExtension)")
                .font(.body.weight(.medium))

            Text(item.listSubtitle(defaultAppName: defaultAppName))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle()) // Makes the entire row area clickable and hoverable, not just the text
    }
}
