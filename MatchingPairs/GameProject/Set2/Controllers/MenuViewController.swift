import ConcentrationLibrary
import UIKit

class MenuViewController: UIViewController {
    
    private struct Constants {
        static let stackViewVerticalSpacing: CGFloat = 8
        static let stackViewHorizontalSpacing: CGFloat = 8
        static let activityIndicatorTopPadding: CGFloat = 8
        static let gameTitleLabelTopPadding: CGFloat = 60
        static let buttonStackViewTopPadding: CGFloat = 130
    }
    
    private var customConstraints: [NSLayoutConstraint] = []
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    private var themes: [Theme] = []
    private var difficultyOptions: [GameDifficulty] = [.Easy, .Hard]
    
    private var selectedThemeIndex = 0
    private var selectedDifficultyIndex = 0
    
    private let gameTitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 40, weight: .bold)
        label.text = "Matching Pairs".localized()
        label.textColor = .red
        label.backgroundColor = .orange
        return label
    }()
    
    private lazy var themeFetcher: ThemeFetcher = {
        let fetcher = ThemeFetcher()
        fetcher.delegate = self
        return fetcher
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.backgroundColor = .white
        indicator.layer.cornerRadius = 10
        return indicator
    }()
    
    private lazy var startGameButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        button.setTitle("Start".localized(), for: .normal)
        button.addTarget(self, action: #selector(onStartGameButtonPressed(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var recordsButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        button.setTitle("Records".localized(), for: .normal)
        button.addTarget(self, action: #selector(onRecordsButtonPressed(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var themeButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        button.setTitle("Theme".localized(), for: .normal)
        button.menu = generateThemeMenu()
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    private lazy var difficultyButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        button.setTitle("Difficulty".localized(), for: .normal)
        button.menu = generateDifficultyMenu()
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    private lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [ themeButton, difficultyButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = Constants.stackViewHorizontalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var verticalStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [startGameButton, recordsButton, horizontalStackView])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = Constants.stackViewVerticalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var hardDifficultyAlert: UIAlertController = {
        let alert = UIAlertController(title: "Hard Difficulty".localized(), message: "With this difficulty selected cards will move one position to the right every 10 seconds.".localized(), preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        return alert
    }()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        themeFetcher.fetchData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(gameTitleLabel)
        view.addSubview(verticalStackView)
        verticalStackView.isUserInteractionEnabled = themes.count == 0 ? false : true
        view.addSubview(activityIndicator)
        themes.count == 0 ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
        applyConstraints()
    }
    
    private func applyConstraints() {
        guard customConstraints.isEmpty else { return }
        customConstraints.append(gameTitleLabel.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor))
        customConstraints.append(gameTitleLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: Constants.gameTitleLabelTopPadding))
        
        customConstraints.append(verticalStackView.topAnchor.constraint(equalTo: gameTitleLabel.bottomAnchor, constant: Constants.buttonStackViewTopPadding))
        customConstraints.append(verticalStackView.widthAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.widthAnchor))
        customConstraints.append(verticalStackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor))
        
        customConstraints.append(activityIndicator.centerXAnchor.constraint(equalTo: self.view.centerXAnchor))
        customConstraints.append(activityIndicator.topAnchor.constraint(equalTo: verticalStackView.bottomAnchor, constant: Constants.activityIndicatorTopPadding))
        NSLayoutConstraint.activate(customConstraints)
    }
    
    private func generateThemeMenu() -> UIMenu {
        var actions: [UIMenuElement] = []
        for (index, theme) in themes.enumerated() {
            let state: UIAction.State = index == selectedThemeIndex ? .on : .off
            let action = UIAction(title: theme.title.localized() + " " + theme.card_symbol, image: nil, state: state, handler: {[weak self] _ in
                self?.selectedThemeIndex = index
                self?.themeButton.menu = self?.generateThemeMenu()
            })
            actions.append(action)
        }
        let menu = UIMenu(children: actions)
        return menu
    }
    
    private func generateDifficultyMenu() -> UIMenu {
        var actions: [UIMenuElement] = []
        for (index, difficulty) in difficultyOptions.enumerated() {
            let state: UIAction.State = index == selectedDifficultyIndex ? .on : .off
            let action = UIAction(title: difficulty.description().localized(), image: nil, state: state, handler: {[weak self] _ in
                self?.selectedDifficultyIndex = index
                self?.difficultyButton.menu = self?.generateDifficultyMenu()
                guard self?.difficultyOptions[index] == .Hard, let safeAlert = self?.hardDifficultyAlert else { return }
                self?.navigationController?.present(safeAlert, animated: true)
            })
            actions.append(action)
        }
        let menu = UIMenu(children: actions)
        return menu
    }
    
    @objc private func onStartGameButtonPressed(_ sender: UIButton) {
        let controller = GameViewController(theme: themes[selectedThemeIndex], difficulty: difficultyOptions[selectedDifficultyIndex], context: context)
        self.navigationController?.pushViewController(controller, animated: false)
    }
    
    @objc private func onRecordsButtonPressed(_ sender: UIButton) {
        let controller = RecordsViewController(context: context, theme: themes[selectedThemeIndex], difficulty: difficultyOptions[selectedDifficultyIndex])
        self.navigationController?.pushViewController(controller, animated: false)
    }
}

extension MenuViewController: ThemeFetcherDelegate {
    func themesUpdated(themes: [Theme]) {
        self.themes = themes
        activityIndicator.stopAnimating()
        verticalStackView.isUserInteractionEnabled = true
        themeButton.menu = generateThemeMenu()
    }
}

extension String {
    func localized() -> String {
        return NSLocalizedString(self,
                                 tableName: "Localizable",
                                 bundle: .main,
                                 value: self,
                                 comment: "")
    }
}

