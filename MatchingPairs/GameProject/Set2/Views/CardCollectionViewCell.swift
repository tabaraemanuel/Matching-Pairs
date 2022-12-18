import UIKit

class CardCollectionViewCell: UICollectionViewCell {
    
    public static let reuseIdentifier: String = "cardCollectionViewCell"
    private var customConstraints = [NSLayoutConstraint]()
    private var symbol: String = ""
    private var backSymbol: String = ""
    
    private var symbolLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(symbolLabel)
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(symbol: String, backSymbol: String, shouldShowFront: Bool) {
        self.symbol = symbol
        self.backSymbol = backSymbol
        symbolLabel.text = shouldShowFront ? symbol : backSymbol
    }
    
    private func setConstraints() {
        guard customConstraints.isEmpty else { return }
        
        customConstraints.append(symbolLabel.centerXAnchor.constraint(equalTo: self.centerXAnchor))
        customConstraints.append(symbolLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor))
        
        NSLayoutConstraint.activate(customConstraints)
    }
    
    public func showBack() {
        UIView.transition(with: self, duration: 0.3, options: .transitionFlipFromRight, animations: { [weak self] in
            self?.symbolLabel.text = self?.backSymbol
        })
    }
    
    public func showFront() {
        UIView.transition(with: self, duration: 0.3, options: .transitionFlipFromLeft, animations: { [weak self] in
            self?.symbolLabel.text = self?.symbol
        })
    }
}
