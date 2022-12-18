import UIKit

class RecordsTableViewCell: UITableViewCell {
    private var customConstraints = [NSLayoutConstraint]()
    public static let reuseIdentifier: String = "recordsTableViewCell"
    
    private lazy var scoreLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(scoreLabel)
        setConstraints()
    }
    
    public func configure(score: Int) {
        scoreLabel.text = String(score)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setConstraints() {
        guard customConstraints.isEmpty else { return }
        
        customConstraints.append(scoreLabel.topAnchor.constraint(equalTo: self.topAnchor))
        customConstraints.append(scoreLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor))
        customConstraints.append(scoreLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor))
        customConstraints.append(scoreLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor))
        
        NSLayoutConstraint.activate(customConstraints)
    }
}
