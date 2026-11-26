import UIKit

enum Installer {
    /// Отправляет IPA в TrollStore через его URL-схему
    static func viaTrollStore(_ ipa: URL, completion: @escaping (Bool) -> Void) {
        var c = URLComponents()
        c.scheme = "apple-magnifier"
        c.host = "install"
        c.queryItems = [URLQueryItem(name: "url", value: ipa.absoluteString)]
        guard let u = c.url, UIApplication.shared.canOpenURL(u) else {
            completion(false)
            return
        }
        UIApplication.shared.open(u, options: [:]) { ok in
            DispatchQueue.main.async { completion(ok) }
        }
    }
}
