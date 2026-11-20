import CoreText
import Foundation

// CoreText resolves fonts stored in versioned or hidden macOS asset directories.
func registeredPingFangURL() -> URL? {
    let font = CTFontCreateWithName("PingFangSC-Regular" as CFString, 14, nil)
    guard String(CTFontCopyPostScriptName(font)).lowercased().contains("pingfang"),
          let url = CTFontCopyAttribute(font, kCTFontURLAttribute) as? URL,
          FileManager.default.isReadableFile(atPath: url.path) else {
        return nil
    }
    return url
}

func assetPingFangURL() -> URL? {
    let manager = FileManager.default
    let roots = ["/System/Library/AssetsV2", "/System/Library/Fonts", "/Library/Fonts"]
    for root in roots {
        guard let files = manager.enumerator(
            at: URL(fileURLWithPath: root),
            includingPropertiesForKeys: nil,
            options: [],
            errorHandler: { _, _ in true }
        ) else { continue }
        for case let file as URL in files {
            if file.lastPathComponent.lowercased().contains("pingfang"),
               file.pathExtension.lowercased() == "ttc",
               manager.isReadableFile(atPath: file.path) {
                return file
            }
        }
    }
    return nil
}

guard let fontURL = registeredPingFangURL() ?? assetPingFangURL() else {
    fputs("No readable system PingFang font was found; golden checks cannot run.\n", stderr)
    exit(1)
}
guard let outputPath = ProcessInfo.processInfo.environment["GITHUB_ENV"] else {
    fputs("GITHUB_ENV is required.\n", stderr)
    exit(1)
}
let outputURL = URL(fileURLWithPath: outputPath)
let line = Data("XIAOYU_TEST_FONT=\(fontURL.path)\n".utf8)
if FileManager.default.fileExists(atPath: outputPath) {
    let handle = try FileHandle(forWritingTo: outputURL)
    try handle.seekToEnd()
    try handle.write(contentsOf: line)
    try handle.close()
} else {
    try line.write(to: outputURL)
}
print("Golden font: \(fontURL.path)")
