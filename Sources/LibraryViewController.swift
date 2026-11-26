import UIKit

final class LibraryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIDocumentPickerDelegate {
    private let table = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let fab = UIButton(type: .system)
    private var items: [IPAInfo] = []
    private var docController: UIDocumentInteractionController?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "DoEdit"
        if #available(iOS 11.0, *) { navigationController?.navigationBar.prefersLargeTitles = true }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Цвет", style: .plain, target: self, action: #selector(pickColor))

        table.translatesAutoresizingMaskIntoConstraints = false
        table.dataSource = self
        table.delegate = self
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 96
        table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 96, right: 0)
        table.register(IPACell.self, forCellReuseIdentifier: "cell")
        view.addSubview(table)

        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = "Пока пусто\nНажми «Добавить IPA» или открой файл через «Поделиться → DoEdit»"
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.font = UIFont.systemFont(ofSize: 15)
        view.addSubview(emptyLabel)

        fab.translatesAutoresizingMaskIntoConstraints = false
        fab.setTitle("＋  Добавить IPA", for: .normal)
        fab.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        fab.contentEdgeInsets = UIEdgeInsets(top: 0, left: 22, bottom: 0, right: 22)
        fab.layer.cornerRadius = 20
        fab.layer.shadowColor = UIColor.black.cgColor
        fab.layer.shadowOpacity = 0.2
        fab.layer.shadowRadius = 8
        fab.layer.shadowOffset = CGSize(width: 0, height: 3)
        fab.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        view.addSubview(fab)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            table.topAnchor.constraint(equalTo: view.topAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            fab.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            fab.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -20),
            fab.heightAnchor.constraint(equalToConstant: 56)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: .ipaImported, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: UIApplication.didBecomeActiveNotification, object: nil)
        applyTheme()
        reload()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()
        table.reloadData()
    }

    private func applyTheme() {
        view.backgroundColor = Theme.background
        view.window?.backgroundColor = Theme.background
        emptyLabel.textColor = Theme.onSurfaceVariant
        fab.backgroundColor = Theme.container
        fab.setTitleColor(Theme.onContainer, for: .normal)

        guard let bar = navigationController?.navigationBar else { return }
        bar.tintColor = Theme.primary
        bar.barTintColor = Theme.background
        bar.isTranslucent = false
        bar.largeTitleTextAttributes = [.foregroundColor: Theme.onSurface]
        bar.titleTextAttributes = [.foregroundColor: Theme.onSurface]
        if #available(iOS 13.0, *) {
            let a = UINavigationBarAppearance()
            a.configureWithOpaqueBackground()
            a.backgroundColor = Theme.background
            a.shadowColor = .clear
            a.titleTextAttributes = [.foregroundColor: Theme.onSurface]
            a.largeTitleTextAttributes = [.foregroundColor: Theme.onSurface]
            bar.standardAppearance = a
            bar.scrollEdgeAppearance = a
        }
    }

    @objc private func reload() {
        DispatchQueue.global(qos: .userInitiated).async {
            let list = Store.shared.list()
            DispatchQueue.main.async {
                self.items = list
                self.table.reloadData()
                self.emptyLabel.isHidden = !list.isEmpty
            }
        }
    }

    // MARK: Цвет
    @objc private func pickColor() {
        let sheet = UIAlertController(title: "Акцентный цвет", message: nil, preferredStyle: .actionSheet)
        for (i, p) in Theme.palettes.enumerated() {
            sheet.addAction(UIAlertAction(title: p.title, style: .default) { _ in
                Theme.index = i
                self.applyTheme()
                self.table.reloadData()
            })
        }
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        sheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(sheet, animated: true)
    }

    // MARK: Добавление
    @objc private func addTapped() {
        let picker = UIDocumentPickerViewController(documentTypes: ["public.data"], in: .import)
        picker.delegate = self
        if #available(iOS 11.0, *) { picker.allowsMultipleSelection = true }
        present(picker, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for u in urls { Store.shared.importFile(u) }
        reload()
    }

    // MARK: Таблица
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! IPACell
        let info = items[indexPath.row]
        cell.configure(info)
        cell.onInstall = { [weak self, weak cell] in
            self?.showActions(for: info, source: cell)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        showActions(for: items[indexPath.row], source: tableView.cellForRow(at: indexPath))
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { return true }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            Store.shared.delete(items[indexPath.row])
            items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            emptyLabel.isHidden = !items.isEmpty
        }
    }

    // MARK: Действия
    private func showActions(for info: IPAInfo, source: UIView?) {
        let sheet = UIAlertController(title: info.name, message: info.readable ? info.bundleID : nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Установить через TrollStore", style: .default) { _ in
            Installer.viaTrollStore(info.url) { ok in
                if !ok { self.alert("TrollStore не найден", "Установи TrollStore или выбери «Открыть в…» и укажи Filza, Sideloadly или другое приложение для установки.") }
            }
        })
        sheet.addAction(UIAlertAction(title: "Открыть в…", style: .default) { _ in self.openIn(info.url, source: source) })
        sheet.addAction(UIAlertAction(title: "Поделиться файлом", style: .default) { _ in
            let vc = UIActivityViewController(activityItems: [info.url], applicationActivities: nil)
            vc.popoverPresentationController?.sourceView = source ?? self.view
            self.present(vc, animated: true)
        })
        sheet.addAction(UIAlertAction(title: "Удалить", style: .destructive) { _ in
            Store.shared.delete(info)
            self.reload()
        })
        sheet.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        sheet.popoverPresentationController?.sourceView = source ?? view
        if let s = source { sheet.popoverPresentationController?.sourceRect = s.bounds }
        present(sheet, animated: true)
    }

    private func openIn(_ url: URL, source: UIView?) {
        let dc = UIDocumentInteractionController(url: url)
        docController = dc
        let rect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        if !dc.presentOpenInMenu(from: rect, in: view, animated: true) {
            alert("Нет подходящих приложений", "Не нашлось приложения, которое может открыть IPA. Поставь TrollStore, Filza или Sideloadly.")
        }
    }

    private func alert(_ title: String, _ message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}
