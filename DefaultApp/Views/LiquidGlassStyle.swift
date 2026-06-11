import SwiftUI

enum LiquidGlassStyle {
    static let panelCornerRadius: CGFloat = 16
    static let controlCornerRadius: CGFloat = 7
}

/// A native AppKit view representable that reliably overrides and forces the cursor to a specific NSCursor.
/// This prevents SwiftUI's internal gesture and click handlers from resetting the cursor back to the default arrow.
private struct CursorViewRepresentable: NSViewRepresentable {
    let cursor: NSCursor

    func makeNSView(context: Context) -> NSView {
        let view = CursorNSView(cursor: cursor)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if let cursorNSView = nsView as? CursorNSView {
            cursorNSView.cursor = cursor
        }
    }

    private class CursorNSView: NSView {
        var cursor: NSCursor

        init(cursor: NSCursor) {
            self.cursor = cursor
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func resetCursorRects() {
            super.resetCursorRects()
            addCursorRect(bounds, cursor: cursor)
        }
    }
}

extension View {
    func liquidGlassPanel(
        cornerRadius: CGFloat = LiquidGlassStyle.panelCornerRadius,
        contentPadding: CGFloat = 16
    ) -> some View {
        self
            .padding(contentPadding)
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
    }

    /// Applies a native pointing hand cursor when the mouse hovers over the view.
    /// Uses the native pointerStyle on macOS 15.0+ or falls back to an AppKit cursor rectangle.
    @ViewBuilder
    func pointingHandCursor() -> some View {
        if #available(macOS 15.0, *) {
            self.pointerStyle(.link)
        } else {
            self.background(CursorViewRepresentable(cursor: .pointingHand))
        }
    }
}
