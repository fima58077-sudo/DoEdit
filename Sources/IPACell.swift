import UIKit

final class IPACell: UITableViewCell {
    private let card = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subLabel = UILabel()
    private let button = UIButton(type: .system)
    var onInstall: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        card.translatesAutoresizingMaskIntoConstraints = false
        card.layer.cornerRadius = 28
        contentView.addSubview(card)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = 15
        iconView.clipsToBounds = true
        iconView.contentMode = .scaleAspectFill
        card.addSubview(iconView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        card.addSubview(titleLabel)

        subLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.font = UIFont.systemFont(ofSize: 12)
        subLabel.numberOfLines = 2
        card.addSubview(subLabel)

        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Установить", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 18
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
        button.addTarget(self, action: #selector(tapInstall), for: .touchUpInside)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        card.addSubview(button)

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            iconView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            iconView.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -16),
            iconView.widthAnchor.constraint(equalToConstant: 56),
            iconView.heightAnchor.constraint(equalToConstant: 56),

            button.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            button.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
            button.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -10),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),

            subLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            subLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapInstall() { onInstall?() }

    func configure(_ info: IPAInfo) {
        card.backgroundColor = Theme.surface
        titleLabel.text = info.name
        titleLabel.textColor = Theme.onSurface
        subLabel.text = info.subtitle
        subLabel.textColor = Theme.onSurfaceVariant
        button.backgroundColor = Theme.container
        button.setTitleColor(Theme.onContainer, for: .normal)
        iconView.image = info.icon ?? IPACell.placeholder(info.name)
    }

    private static func placeholder(_ name: String) -> UIImage {
        let size = CGSize(width: 56, height: 56)
        let letter = String(name.prefix(1)).uppercased() as NSString
        return UIGraphicsImageRenderer(size: size).image { _ in
            Theme.container.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 26, weight: .bold),
                .foregroundColor: Theme.onContainer
            ]
            let s = letter.size(withAttributes: attrs)
            letter.draw(at: CGPoint(x: (size.width - s.width) / 2, y: (size.height - s.height) / 2), withAttributes: attrs)
        }
    }
}
