//
//  SpreadsheetViewController.swift
//  TestSpreadSheetView
//
//  Created by Yuan on 2023/7/18.
//

import UIKit
import Combine
import SpreadsheetView

let useDataBinding = true

class SpreadsheetDataItem {
    private var _value: String
    
    private(set) var isUpdate: Bool = false
    
    var value: String {
        get { return _value }
        set {
            _value = newValue
            isUpdate = true
            valueSubject.send(self)
        }
    }
    
    var valuePublisher: AnyPublisher<SpreadsheetDataItem, Never> {
        return valueSubject.eraseToAnyPublisher()
    }
    
    private lazy var valueSubject: CurrentValueSubject<SpreadsheetDataItem, Never> = .init(self)
    
    init(value: String) {
        _value = value
        isUpdate = false
    }
    
    public func markUpdated() {
        isUpdate = false
    }
}

class SpreadsheetViewModel {
    private(set) var items: [[SpreadsheetDataItem]] = []
    
    init() {}
    
    public func updateItems(_ items: [[SpreadsheetDataItem]]) {
        self.items = items
    }
}

class SpreadsheetViewController: UIViewController {
    
    var viewModel: SpreadsheetViewModel = .init()
    var cancellables = Set<AnyCancellable>()
    
    lazy var spreadsheetView: SpreadsheetView = {
        let view = SpreadsheetView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spreadsheetView.dataSource = self
        cellRegister(spreadsheetView)
        view.addSubview(spreadsheetView)
        
        NSLayoutConstraint.activate([
            spreadsheetView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            spreadsheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            spreadsheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            spreadsheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        var fakeItems: [[SpreadsheetDataItem]] = []
        
        // Generate two dimension fake SpreadsheetDataItems
        for _ in 0..<4 {
            var rowItems: [SpreadsheetDataItem] = []
            for _ in 0..<100 {
                let item = SpreadsheetDataItem(value: "0")
                rowItems.append(item)
            }
            fakeItems.append(rowItems)
        }
        
        viewModel.updateItems(fakeItems)
        spreadsheetView.reloadData()
        
        fakeUpdateDataPeriod()
    }
    
    /// cell註冊
    func cellRegister(_ spreadsheetView: SpreadsheetView) {
        spreadsheetView.register(SpreadsheetCell.self, forCellWithReuseIdentifier: SpreadsheetCell.reuseIdentifier)
    }
    
    func fakeUpdateDataPeriod() {
        Timer.publish(every: 0.2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                let newValue = Int.random(in: 0...100)
                let rowItems = self.viewModel.items.randomElement()!
                let columnItems = rowItems.randomElement()!
                columnItems.value = "\(newValue)"
                
                if !useDataBinding {
                    self.spreadsheetView.reloadData()
                }
            }
            .store(in: &cancellables)
    }
}

extension SpreadsheetViewController: SpreadsheetViewDataSource {
    
    public func spreadsheetView(_ spreadsheetView: SpreadsheetView, widthForColumn column: Int) -> CGFloat {
        return 100.0
    }
    
    public func spreadsheetView(_ spreadsheetView: SpreadsheetView, heightForRow column: Int) -> CGFloat {
        return 40
    }
    
    func numberOfColumns(in spreadsheetView: SpreadsheetView) -> Int {
        return viewModel.items.count
    }
    
    func numberOfRows(in spreadsheetView: SpreadsheetView) -> Int {
        return viewModel.items[0].count
    }
    
    func spreadsheetView(_ spreadsheetView: SpreadsheetView, cellForItemAt indexPath: IndexPath) -> Cell? {
        let cell = spreadsheetView.dequeueReusableCell(withReuseIdentifier: "SpreadsheetCell", for: indexPath) as! SpreadsheetCell
        
        let item = viewModel.items[indexPath.section][indexPath.row]
        cell.configure(with: item)
        
        return cell
    }
}

class SpreadsheetCell: Cell, CellReusable {
    var valueLabel: UILabel!
    var cancellables = Set<AnyCancellable>()
    
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        
        valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            valueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            valueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            valueLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            valueLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with item: SpreadsheetDataItem) {
        if !useDataBinding {
            valueLabel.text = item.value
            if item.isUpdate {
                flashAnimation()
                item.markUpdated()
            }
        } else {
            cancellables.removeAll()
            item.valuePublisher
                .sink { [weak self] item in
                    if item.isUpdate {
                        self?.flashAnimation()
                        item.markUpdated()
                    }
                    
                    self?.valueLabel.text = item.value
                }
                .store(in: &cancellables)
        }
    }
    
    private func flashAnimation() {
        let flashAnimation = CABasicAnimation(keyPath: "backgroundColor")
        flashAnimation.fromValue = UIColor.yellow.cgColor
        flashAnimation.toValue = UIColor.clear.cgColor
        flashAnimation.duration = 0.3
        layer.add(flashAnimation, forKey: "flashAnimation")
    }
}

public protocol CellReusable { }

extension CellReusable {
    
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UICollectionReusableView: CellReusable {}
extension UITableViewCell: CellReusable {}
extension UITableViewHeaderFooterView: CellReusable {}
