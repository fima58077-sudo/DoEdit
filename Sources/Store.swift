import Foundation

extension Notification.Name {
    static let ipaImported = Notification.Name("DoEditIPAImported")
}

/// Хранилище IPA внутри приложения (Documents/IPAs)
final class Store {
    static let shared = Store()

    private let fm = FileManager.default
    private var cache: [String: IPAInfo] = [:]

    private var documents: URL {
        return fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    let dir: URL

    private init() {
        let d = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("IPAs")
        try? fm.createDirectory(at: d, withIntermediateDirectories: true)
        dir = d
    }

    @discardableResult
    func importFile(_ url: URL) -> Bool {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }

        let base = url.deletingPathExtension().lastPathComponent
        var dest = dir.appendingPathComponent(base + ".ipa")
        var n = 1
        while fm.fileExists(atPath: dest.path) {
            dest = dir.appendingPathComponent("\(base) (\(n)).ipa")
            n += 1
        }
        do {
            try fm.copyItem(at: url, to: dest)
            if url.path.contains("/Inbox/") { try? fm.removeItem(at: url) }
            return true
        } catch {
            return false
        }
    }

    /// Подбирает .ipa, которые закинули через «Файлы» или iTunes в корень Documents
    private func collectLoose() {
        guard let files = try? fm.contentsOfDirectory(at: documents, includingPropertiesForKeys: nil) else { return }
        for f in files where f.pathExtension.lowercased() == "ipa" {
            let dest = dir.appendingPathComponent(f.lastPathComponent)
            if !fm.fileExists(atPath: dest.path) { try? fm.moveItem(at: f, to: dest) }
        }
    }

    func list() -> [IPAInfo] {
        collectLoose()
        guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey]) else { return [] }
        let ipas = files.filter { $0.pathExtension.lowercased() == "ipa" }
        let sorted = ipas.sorted { a, b in
            let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
            let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
            return da > db
        }
        var out: [IPAInfo] = []
        for f in sorted {
            if let c = cache[f.path] { out.append(c); continue }
            let info = IPAParser.parse(url: f)
            cache[f.path] = info
            out.append(info)
        }
        return out
    }

    func delete(_ info: IPAInfo) {
        try? fm.removeItem(at: info.url)
        cache[info.url.path] = nil
    }
}
