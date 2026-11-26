import UIKit

struct IPAInfo {
    var url: URL
    var name: String
    var bundleID: String
    var version: String
    var build: String
    var minOS: String
    var size: Int64
    var icon: UIImage?
    var readable: Bool

    var sizeText: String {
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var subtitle: String {
        if !readable { return "Не удалось прочитать IPA • \(sizeText)" }
        var parts: [String] = []
        if !version.isEmpty { parts.append("v\(version)" + (build.isEmpty || build == version ? "" : " (\(build))")) }
        if !minOS.isEmpty { parts.append("iOS \(minOS)+") }
        parts.append(sizeText)
        return bundleID + "\n" + parts.joined(separator: " • ")
    }
}

enum IPAParser {
    private static func isInfoPlist(_ n: String) -> Bool {
        let parts = n.split(separator: "/")
        return parts.count == 3 && parts[0] == "Payload" && parts[1].hasSuffix(".app") && parts[2] == "Info.plist"
    }

    static func parse(url: URL) -> IPAInfo {
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
        let fallback = IPAInfo(url: url, name: url.deletingPathExtension().lastPathComponent,
                               bundleID: "", version: "", build: "", minOS: "",
                               size: size, icon: nil, readable: false)

        guard let zip = ZipReader(url: url),
              let plistEntry = zip.entries.first(where: { isInfoPlist($0.name) }),
              let pdata = zip.read(plistEntry),
              let obj = (try? PropertyListSerialization.propertyList(from: pdata, options: [], format: nil)) as? [String: Any]
        else { return fallback }

        var info = fallback
        info.readable = true
        info.name = (obj["CFBundleDisplayName"] as? String) ?? (obj["CFBundleName"] as? String) ?? fallback.name
        info.bundleID = (obj["CFBundleIdentifier"] as? String) ?? ""
        info.version = (obj["CFBundleShortVersionString"] as? String) ?? ""
        info.build = (obj["CFBundleVersion"] as? String) ?? ""
        info.minOS = (obj["MinimumOSVersion"] as? String) ?? ""

        // иконка
        var names: [String] = []
        if let icons = obj["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String] { names += files }
        if let files = obj["CFBundleIconFiles"] as? [String] { names += files }
        if let n = obj["CFBundleIconFile"] as? String { names.append(n) }
        let bases = names.map { ($0 as NSString).deletingPathExtension }
        let appDir = (plistEntry.name as NSString).deletingLastPathComponent + "/"
        let candidates = zip.entries.filter { e in
            guard e.name.hasPrefix(appDir), e.name.lowercased().hasSuffix(".png") else { return false }
            let base = (e.name as NSString).lastPathComponent
            return bases.contains(where: { !$0.isEmpty && base.hasPrefix($0) })
        }
        if let best = candidates.max(by: { $0.size < $1.size }), let d = zip.read(best) {
            info.icon = UIImage(data: d)
        }
        return info
    }
}
