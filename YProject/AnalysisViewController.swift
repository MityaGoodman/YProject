//
//  AnalysisViewController.swift
//  YProject
//
//  Created by Митя on 11.07.2025.
//

import UIKit

private extension NumberFormatter {
    static func currency(code: String) -> NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle   = .currency
        f.currencyCode  = code
        f.maximumFractionDigits = 0
        return f
    }
}


private extension DateFormatter {
    static let monthYear: DateFormatter = {
        let df = DateFormatter()
        df.locale     = .current
        df.dateFormat = "LLLL yyyy"
        return df
    }()
}

final class AnalysisViewController: UIViewController {
    private var startDate: Date
    private var endDate:   Date
    private let startPicker = UIDatePicker()
    private let endPicker   = UIDatePicker()
    private var transactions: [Transaction]
    private let originalTransactions: [Transaction]
    
    private var total: Decimal {
        transactions.reduce(0) { $0 + $1.amount }
    }
    
    private var breakdown: [(category: Category, amount: Decimal, pct: Double)] {
      let filtered = originalTransactions.filter {
        $0.transactionDate >= startDate && $0.transactionDate <= endDate
      }
      let sumsByCat = filtered.reduce(into: [Category: Decimal]()) { dict, tx in
        dict[tx.category, default: 0] += tx.amount
      }
      let totalSum = sumsByCat.values.reduce(into: Decimal(0)) { $0 += $1 }
      let arr = sumsByCat.map { category, amount -> (Category, Decimal, Double) in
        let pct = totalSum == 0
          ? 0
          : (NSDecimalNumber(decimal: amount).doubleValue
             / NSDecimalNumber(decimal: totalSum).doubleValue * 100)
        return (category, amount, pct)
      }
      switch sortOption {
      case .byAmount:
        return arr.sorted { $0.1 > $1.1 }
      case .byCategory:
        return arr.sorted {
          $0.0.name.localizedCompare($1.0.name) == .orderedAscending
        }
      }
    }

    
    private let headerStack = UIStackView()
    private let tableView   = UITableView(frame: .zero, style: .plain)
    
    private var sumLabel: UILabel?
    
    private enum SortOption: Int {
        case byAmount = 0
        case byCategory
    }
    private var sortControl = UISegmentedControl(items: ["Сумма", "Категории"])
    private var sortOption: SortOption = .byAmount
    
    init(start: Date, end: Date, transactions: [Transaction]) {
        self.startDate    = start
        self.endDate      = end
        self.transactions = transactions
        self.originalTransactions   = transactions
        super.init(nibName: nil, bundle: nil)
        title = "Анализ"
    }
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupHeader()
        setupTable()
    }
    
    private func setupHeader() {
        headerStack.axis    = .vertical
        headerStack.spacing = 12
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerStack)
        
        let startRow = makeDateRow(title: "Начало", picker: startPicker, date: startDate, tag: 0)
        headerStack.addArrangedSubview(startRow)
        let endRow = makeDateRow(title: "Конец", picker: endPicker, date: endDate, tag: 1)
        headerStack.addArrangedSubview(endRow)
        let sumRow = makeRow(
            title: "Сумма",
            value: NumberFormatter.currency(
                code: transactions.first?.account.currency ?? "RUB"
            ).string(from: total as NSNumber) ?? ""
        )
        headerStack.addArrangedSubview(sumRow)
        
        if let lbl = (sumRow.subviews.first as? UIStackView)?
            .arrangedSubviews.last as? UILabel {
            sumLabel = lbl
        }
        
        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 16
            ),
            headerStack.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 16
            ),
            headerStack.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -16
            ),
        ])
        sortControl.selectedSegmentIndex = 0
        sortControl.addTarget(self, action: #selector(sortChanged(_:)), for: .valueChanged)
        sortControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sortControl)
        NSLayoutConstraint.activate([
          sortControl.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 16),
          sortControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
          sortControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }
    
    @objc private func sortChanged(_ sender: UISegmentedControl) {
      guard let opt = SortOption(rawValue: sender.selectedSegmentIndex) else { return }
      sortOption = opt
      tableView.reloadData()
    }
    
    private func makeRow(title: String, value: String) -> UIView {
        let lblTitle = UILabel()
        lblTitle.textColor = .secondaryLabel
        lblTitle.font      = .preferredFont(forTextStyle: .subheadline)
        lblTitle.text      = title
        
        let lblValue = UILabel()
        let base = UIFont.preferredFont(forTextStyle: .body)
        let desc = base.fontDescriptor
            .withSymbolicTraits(.traitBold) ?? base.fontDescriptor
        lblValue.font = UIFont(descriptor: desc, size: base.pointSize)
        lblValue.text = value
        lblValue.textAlignment = .right
        
        let h = UIStackView(arrangedSubviews: [lblTitle, lblValue])
        h.axis         = .horizontal
        h.spacing      = 8
        h.alignment    = .center
        h.translatesAutoresizingMaskIntoConstraints = false
        
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 10
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(h)
        NSLayoutConstraint.activate([
            h.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            h.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            h.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            h.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
        ])
        return container
    }
    
    private func makeDateRow(
    title: String,
    picker: UIDatePicker,
    date: Date,
    tag: Int
    ) -> UIView {
        let lblTitle = UILabel()
        lblTitle.textColor = .secondaryLabel
        lblTitle.font      = .preferredFont(forTextStyle: .subheadline)
        lblTitle.text      = title
        
        picker.preferredDatePickerStyle = .compact
        picker.datePickerMode           = .date
        picker.preferredDatePickerStyle = .compact
        picker.datePickerMode           = .date
        picker.date                     = date
        picker.tag                      = tag
        picker.addTarget(
            self,
            action: #selector(dateChanged(_:)),
            for: .valueChanged
        )
        
        let h = UIStackView(arrangedSubviews: [lblTitle, picker])
        h.axis         = .horizontal
        h.distribution = .equalSpacing
        h.alignment    = .center
        h.translatesAutoresizingMaskIntoConstraints = false
        
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 10
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(h)
        NSLayoutConstraint.activate([
            h.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            h.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            h.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            h.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
        ])
        return container
    }
    
    @objc private func dateChanged(_ sender: UIDatePicker) { // первая звездочка
        if sender === startPicker {
            startDate = sender.date
            if startDate > endDate {
                endDate = startDate
                endPicker.setDate(endDate, animated: true)
                endPicker.sendActions(for: .valueChanged)
            }
        } else {
            endDate = sender.date
            if endDate < startDate {
                startDate = endDate
                startPicker.setDate(startDate, animated: true)
                startPicker.sendActions(for: .valueChanged)
            }
        }

        transactions = originalTransactions.filter {
            $0.transactionDate >= startDate && $0.transactionDate <= endDate
        }

        sumLabel?.text = NumberFormatter.currency(
            code: transactions.first?.account.currency ?? "RUB"
        ).string(from: total as NSNumber)

        tableView.reloadData()
    }

    
    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(
                equalTo: sortControl.bottomAnchor, constant: 16 // вторая звездочка
            ),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

extension AnalysisViewController: UITableViewDataSource {
  func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
    breakdown.count
  }
  func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
    let (category, amount, pct) = breakdown[ip.row]
    let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
    cell.textLabel?.text = "\(category.emoji)  \(category.name)"
    let amtStr = NumberFormatter.currency(
      code: transactions.first?.account.currency ?? "RUB"
    ).string(from: amount as NSNumber) ?? "\(amount)"
    cell.detailTextLabel?.text = String(format: "%.0f%%   %@", pct, amtStr)
    cell.accessoryType = .disclosureIndicator
    return cell
  }
}


extension AnalysisViewController: UITableViewDelegate {
    
}
