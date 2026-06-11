import UniformTypeIdentifiers

enum CommonExtensions {
    private static func utType(_ ext: String, fallback: UTType = .data) -> UTType {
        UTType(filenameExtension: ext) ?? fallback
    }

    static let items: [FileTypeItem] = [
        FileTypeItem(fileExtension: "pdf", displayName: "PDF", utType: .pdf),
        FileTypeItem(fileExtension: "txt", displayName: "纯文本", utType: .plainText),
        FileTypeItem(fileExtension: "md", displayName: "Markdown", utType: utType("md", fallback: .plainText)),
        FileTypeItem(fileExtension: "rtf", displayName: "RTF", utType: .rtf),
        FileTypeItem(fileExtension: "html", displayName: "HTML", utType: .html),
        FileTypeItem(fileExtension: "htm", displayName: "HTML", utType: .html),
        FileTypeItem(fileExtension: "json", displayName: "JSON", utType: .json),
        FileTypeItem(fileExtension: "xml", displayName: "XML", utType: .xml),
        FileTypeItem(fileExtension: "csv", displayName: "CSV", utType: .commaSeparatedText),
        FileTypeItem(fileExtension: "jpg", displayName: "JPEG 图片", utType: .jpeg),
        FileTypeItem(fileExtension: "jpeg", displayName: "JPEG 图片", utType: .jpeg),
        FileTypeItem(fileExtension: "png", displayName: "PNG 图片", utType: .png),
        FileTypeItem(fileExtension: "gif", displayName: "GIF 图片", utType: .gif),
        FileTypeItem(fileExtension: "webp", displayName: "WebP 图片", utType: .webP),
        FileTypeItem(fileExtension: "heic", displayName: "HEIC 图片", utType: .heic),
        FileTypeItem(fileExtension: "svg", displayName: "SVG", utType: .svg),
        FileTypeItem(fileExtension: "mp3", displayName: "MP3 音频", utType: .mp3),
        FileTypeItem(fileExtension: "wav", displayName: "WAV 音频", utType: .wav),
        FileTypeItem(fileExtension: "m4a", displayName: "M4A 音频", utType: .mpeg4Audio),
        FileTypeItem(fileExtension: "mp4", displayName: "MP4 视频", utType: .mpeg4Movie),
        FileTypeItem(fileExtension: "mov", displayName: "QuickTime 视频", utType: .quickTimeMovie),
        FileTypeItem(fileExtension: "mkv", displayName: "Matroska 视频", utType: utType("mkv", fallback: .movie)),
        FileTypeItem(fileExtension: "zip", displayName: "ZIP 压缩包", utType: .zip),
        FileTypeItem(fileExtension: "gz", displayName: "Gzip", utType: .gzip),
        FileTypeItem(fileExtension: "tar", displayName: "Tar 归档", utType: utType("tar", fallback: .archive)),
        FileTypeItem(fileExtension: "doc", displayName: "Word 文档", utType: utType("doc")),
        FileTypeItem(fileExtension: "docx", displayName: "Word 文档", utType: utType("docx")),
        FileTypeItem(fileExtension: "xls", displayName: "Excel 表格", utType: utType("xls")),
        FileTypeItem(fileExtension: "xlsx", displayName: "Excel 表格", utType: utType("xlsx")),
        FileTypeItem(fileExtension: "ppt", displayName: "PowerPoint", utType: utType("ppt")),
        FileTypeItem(fileExtension: "pptx", displayName: "PowerPoint", utType: utType("pptx")),
        FileTypeItem(fileExtension: "swift", displayName: "Swift 源码", utType: .swiftSource),
        FileTypeItem(fileExtension: "py", displayName: "Python 源码", utType: utType("py", fallback: .plainText)),
        FileTypeItem(fileExtension: "js", displayName: "JavaScript", utType: utType("js", fallback: .plainText)),
        FileTypeItem(fileExtension: "ts", displayName: "TypeScript", utType: utType("ts", fallback: .plainText)),
        FileTypeItem(fileExtension: "css", displayName: "CSS", utType: utType("css", fallback: .plainText)),
    ]

    static var uniqueItems: [FileTypeItem] {
        var seen = Set<String>()
        return items.filter { seen.insert($0.utType.identifier).inserted }
    }
}
