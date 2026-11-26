import Foundation
import Compression

struct ZipEntry {
    let name: String
    let method: Int
    let compressedSize: Int
    let size: Int
    let localOffset: Int
}

/// Мини-читалка ZIP (IPA = ZIP): без внешних библиотек, только чтение.
final class ZipReader {
    private let data: Data
    private(set) var entries: [ZipEntry] = []

    init?(url: URL) {
        guard let d = try? Data(contentsOf: url, options: .mappedIfSafe) else { return nil }
        data = d
        if !parse() { return nil }
    }

    private func u16(_ o: Int) -> Int {
        return Int(data[data.startIndex + o]) | (Int(data[data.startIndex + o + 1]) << 8)
    }

    private func u32(_ o: Int) -> Int {
        return u16(o) | (u16(o + 2) << 16)
    }

    private func parse() -> Bool {
        let n = data.count
        if n < 22 { return false }
        var eocd = -1
        var i = n - 22
        let lower = max(0, n - 22 - 65535)
        while i >= lower {
            if u32(i) == 0x06054b50 { eocd = i; break }
            i -= 1
        }
        if eocd < 0 { return false }
        let count = u16(eocd + 10)
        var p = u32(eocd + 16)
        for _ in 0..<count {
            if p + 46 > n || u32(p) != 0x02014b50 { break }
            let method = u16(p + 10)
            let csize = u32(p + 20)
            let usize = u32(p + 24)
            let nl = u16(p + 28)
            let el = u16(p + 30)
            let cl = u16(p + 32)
            let lo = u32(p + 42)
            if p + 46 + nl > n { break }
            let start = data.startIndex + p + 46
            let nameData = data.subdata(in: start..<(start + nl))
            let name = String(data: nameData, encoding: .utf8) ?? ""
            entries.append(ZipEntry(name: name, method: method, compressedSize: csize, size: usize, localOffset: lo))
            p += 46 + nl + el + cl
        }
        return !entries.isEmpty
    }

    func read(_ e: ZipEntry) -> Data? {
        let o = e.localOffset
        guard o + 30 <= data.count, u32(o) == 0x04034b50 else { return nil }
        let start = o + 30 + u16(o + 26) + u16(o + 28)
        guard start + e.compressedSize <= data.count else { return nil }
        let s = data.startIndex + start
        let raw = data.subdata(in: s..<(s + e.compressedSize))
        if e.method == 0 { return raw }
        if e.method == 8 { return inflate(raw, size: e.size) }
        return nil
    }

    private func inflate(_ src: Data, size: Int) -> Data? {
        if size == 0 { return Data() }
        if src.isEmpty { return nil }
        var dst = Data(count: size)
        let written: Int = dst.withUnsafeMutableBytes { (dp: UnsafeMutableRawBufferPointer) -> Int in
            return src.withUnsafeBytes { (sp: UnsafeRawBufferPointer) -> Int in
                guard let dBase = dp.baseAddress, let sBase = sp.baseAddress else { return 0 }
                return compression_decode_buffer(
                    dBase.assumingMemoryBound(to: UInt8.self), size,
                    sBase.assumingMemoryBound(to: UInt8.self), src.count,
                    nil, COMPRESSION_ZLIB)
            }
        }
        if written <= 0 { return nil }
        return written == size ? dst : dst.prefix(written)
    }
}
