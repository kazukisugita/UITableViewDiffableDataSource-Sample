import UIKit

final class ViewController: UIViewController {
    @IBOutlet private weak var tableView: UITableView!
    private let indicatorView: UIView = {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: .zero, height: 45.0)))
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.startAnimating()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicator)
        NSLayoutConstraint.activate([indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                     indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)])
        return view
    }()
    private lazy var dataSource: UITableViewDiffableDataSource<Int, Int> = {
        let dataSource = UITableViewDiffableDataSource<Int, Int>(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            cell.textLabel?.text = "\(item)"
            return cell
        }
        dataSource.defaultRowAnimation = .none
        return dataSource
    }()
    private let sectionsCount: Int = 10
    private lazy var numbers: [[Int]] = {
        (0..<sectionsCount).map { section in
            (1...10).map { row in
                return (section * 10) + row
            }
        }
    }()
    private var cursor: Int = 0
    private var isLoading: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
    }
}

private extension ViewController {
    func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.tableFooterView = indicatorView

        var snapshot = dataSource.snapshot()
        snapshot.appendSections([cursor, cursor + 1])
        snapshot.appendItems(numbers[cursor], toSection: cursor)
        snapshot.appendItems(numbers[cursor + 1], toSection: cursor + 1)
        dataSource.apply(snapshot, animatingDifferences: false)

        forwardCursor()
    }

    func appendSections() {
        let cursorNext = cursor + 1

        guard numbers.indices.contains(cursor),
              numbers.indices.contains(cursorNext)
            else { return }

        isLoading = true

        var snapshot = dataSource.snapshot()
        snapshot.appendSections([cursor, cursorNext])
        snapshot.appendItems(numbers[cursor], toSection: cursor)
        snapshot.appendItems(numbers[cursorNext], toSection: cursorNext)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.dataSource.apply(snapshot, animatingDifferences: false) { [weak self] in
                guard let self = self else { return }
                self.isLoading = false
                self.forwardCursor()

                if snapshot.numberOfSections >= self.sectionsCount {
                    self.tableView.tableFooterView = nil
                }
            }
        }
    }

    func forwardCursor() {
        if cursor >= sectionsCount { return }
        cursor += 2
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard !isLoading,
              indexPath == IndexPath(item: numbers[cursor - 1].count - 1, section: cursor - 1),
              tableView.numberOfSections <= cursor
            else { return }

        appendSections()
    }
}
