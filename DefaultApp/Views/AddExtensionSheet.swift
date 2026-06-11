import SwiftUI

struct AddExtensionSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onAdd: (String) throws -> FileTypeItem

    @State private var input = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("添加扩展名")
                .font(.title2.weight(.semibold))

            Text("输入不带或带点的扩展名，例如 pdf 或 .pdf。")
                .font(.callout)
                .foregroundStyle(.secondary)

            TextField("扩展名", text: $input)
                .textFieldStyle(.roundedBorder)
                .onSubmit(submit)

            if let errorMessage {
                Text(errorMessage)
                    .font(.callout)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.glass)
                .pointingHandCursor()

                Button("添加") {
                    submit()
                }
                .buttonStyle(.glassProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .pointingHandCursor()
            }
        }
        .padding(24)
        .frame(width: 360)
    }

    private func submit() {
        do {
            _ = try onAdd(input)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
