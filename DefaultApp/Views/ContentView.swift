import SwiftUI

struct ContentView: View {
    @State private var catalog = FileTypeCatalog()
    @State private var selection: FileTypeItem?
    @State private var searchText = ""
    @State private var selectedTab: FileTypeListTab = .common
    @State private var isAddingExtension = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var isSidebarVisible: Bool {
        columnVisibility != .detailOnly
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            FileTypeListView(
                catalog: catalog,
                selection: $selection,
                searchText: $searchText,
                selectedTab: $selectedTab,
                onRefresh: {
                    Task { await catalog.refreshInstalledExtensions() }
                },
                onAdd: { isAddingExtension = true }
            )
            .navigationSplitViewColumnWidth(340) // Lock the width of the sidebar (fixed/non-resizable)
            .toolbar(removing: .sidebarToggle) // Clean title bar above sidebar
        } detail: {
            Group {
                if let selection {
                    AppPickerView(fileType: selection) {
                        catalog.refreshDefaultAppName(for: selection)
                    }
                } else {
                    ContentUnavailableView(
                        "选择文件类型",
                        systemImage: "doc.badge.gearshape",
                        description: Text("从左侧列表选择一个扩展名，查看并修改其默认打开方式。")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .searchable(text: $searchText, placement: .toolbar, prompt: "搜索扩展名")
            .toolbar(removing: .sidebarToggle)
            .toolbar {
                // When sidebar is hidden, show toggle button in detail toolbar to reopen it
                if !isSidebarVisible {
                    ToolbarItem(placement: .navigation) {
                        Button {
                            SidebarToggle.perform()
                        } label: {
                            Label("展开侧边栏", systemImage: "sidebar.left")
                        }
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .sheet(isPresented: $isAddingExtension) {
            AddExtensionSheet { raw in
                let item = try catalog.addCustomExtension(raw)
                selectedTab = .supplement
                selection = item
                return item
            }
            .presentationBackground(.regularMaterial)
        }
        .task {
            await catalog.loadIfNeeded()
            if selection == nil {
                selection = catalog.commonItems.first
            }
        }
    }
}

#Preview {
    ContentView()
}
