import UIKit

struct Palette {
    let name: String
    let title: String
    let primary: UInt32
    let container: UInt32
}

/// Цвета в стиле Material You (светлая и тёмная тема, 8 акцентов)
enum Theme {
    static let palettes: [Palette] = [
        Palette(name: "purple", title: "Фиолетовый", primary: 0x7E57D1, container: 0xEADDFF),
        Palette(name: "blue",   title: "Синий",      primary: 0x4F83F1, container: 0xD3E3FD),
        Palette(name: "green",  title: "Зелёный",    primary: 0x2E9E5B, container: 0xC4EED0),
        Palette(name: "pink",   title: "Розовый",    primary: 0xD6407A, container: 0xFFD8E4),
        Palette(name: "orange", title: "Оранжевый",  primary: 0xE8710A, container: 0xFFE0B2),
        Palette(name: "teal",   title: "Бирюзовый",  primary: 0x00897B, container: 0xC4F0EE),
        Palette(name: "red",    title: "Красный",    primary: 0xD93025, container: 0xFAD2CF),
        Palette(name: "yellow", title: "Жёлтый",     primary: 0xF9AB00, container: 0xFFF1B0)
    ]

    static var index: Int {
        get { min(max(UserDefaults.standard.integer(forKey: "accentIndex"), 0), palettes.count - 1) }
        set { UserDefaults.standard.set(newValue, forKey: "accentIndex") }
    }

    static var current: Palette { return palettes[index] }

    static func hex(_ v: UInt32) -> UIColor {
        return UIColor(red: CGFloat((v >> 16) & 0xFF) / 255.0,
                       green: CGFloat((v >> 8) & 0xFF) / 255.0,
                       blue: CGFloat(v & 0xFF) / 255.0,
                       alpha: 1.0)
    }

    static func mix(_ a: UInt32, _ b: UInt32, _ t: CGFloat) -> UInt32 {
        var out: UInt32 = 0
        for shift in [16, 8, 0] as [UInt32] {
            let ca = CGFloat((a >> shift) & 0xFF)
            let cb = CGFloat((b >> shift) & 0xFF)
            let c = ca * (1 - t) + cb * t
            out |= UInt32(c.rounded()) << shift
        }
        return out
    }

    static func dynamic(_ light: UInt32, _ dark: UInt32) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(dynamicProvider: { traits in
                return traits.userInterfaceStyle == .dark ? hex(dark) : hex(light)
            })
        }
        return hex(light)
    }

    static var background: UIColor { return dynamic(0xFEF7FF, 0x141218) }
    static var surface: UIColor { return dynamic(0xF3EDF7, 0x211F26) }
    static var onSurface: UIColor { return dynamic(0x1D1B20, 0xE6E0E9) }
    static var onSurfaceVariant: UIColor { return dynamic(0x49454F, 0xCAC4D0) }
    static var primary: UIColor { return dynamic(current.primary, mix(current.primary, 0xFFFFFF, 0.35)) }
    static var container: UIColor { return dynamic(current.container, mix(current.primary, 0x000000, 0.55)) }
    static var onContainer: UIColor { return dynamic(mix(current.primary, 0x000000, 0.6), current.container) }
}
