import CoreData
import ConcentrationLibrary
import UIKit

class GameViewController: UIViewController {
    
    private struct Constants {
        static let cardSize: CGSize = CGSize(width: 100, height: 150)
        static let maxNumberOfSymbols = 4
        static let minimumCellSpacing: CGFloat = 5
        static let collectionViewSectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        static let stackViewHorizontalSpacing: CGFloat = 30
        static let stackViewVerticalSpacing: CGFloat = 10
        static let themeLabelTopPadding: CGFloat = 20
    }

    
    private var cards: [Card?] = []
    private var score: Int = 0
    private var offset: Int = 0
    private let theme: Theme
    private var game: ConcentrationGameProtocol
    private let context: NSManagedObjectContext
    private let difficulty: GameDifficulty
    private var customConstraints: [NSLayoutConstraint] = []
    private var didInitialShuffleRun: Bool = false
    
    private lazy var collectionView: UICollectionView = {
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.itemSize = Constants.cardSize
        flowLayout.sectionInset = Constants.collectionViewSectionInset
        flowLayout.minimumInteritemSpacing = Constants.minimumCellSpacing
        flowLayout.minimumLineSpacing = Constants.minimumCellSpacing
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(CardCollectionViewCell.self, forCellWithReuseIdentifier: CardCollectionViewCell.reuseIdentifier)
        collectionView.isUserInteractionEnabled = false
        return collectionView
    }()
    
    private lazy var winAlert: UIAlertController = {
        let alert = UIAlertController(title: "You won!".localized(), message: nil, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        return alert
    }()
    
    private lazy var themeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = theme.title.localized()
        label.textColor = UIColor(red: theme.card_color.red, green: theme.card_color.green, blue: theme.card_color.blue, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var scoreLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Score".localized() + ": " + String(0)
        label.textColor = UIColor(red: theme.card_color.red, green: theme.card_color.green, blue: theme.card_color.blue, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()
    
    private lazy var timeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.text = "Time".localized()
        label.textColor = UIColor(red: theme.card_color.red, green: theme.card_color.green, blue: theme.card_color.blue, alpha: 1)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()
    
    private lazy var horizontalStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [ scoreLabel, timeLabel])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = Constants.stackViewHorizontalSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    init(theme: Theme, difficulty: GameDifficulty, context: NSManagedObjectContext) {
        self.theme = theme
        self.difficulty = difficulty
        var truncatedSymbols: [String] = []
        for index in 0..<min(theme.symbols.count, Constants.maxNumberOfSymbols) {
            truncatedSymbols.append(theme.symbols[index])
        }
        self.game = ConcentrationFactory.makeConcentrationGame(cardSymbols: truncatedSymbols, difficulty: difficulty)
        self.context = context
        super.init(nibName: nil, bundle: nil)
        game.delegate = self
        cards = game.createDeck()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(themeLabel)
        view.addSubview(collectionView)
        view.addSubview(horizontalStackView)
        setConstraints()
        initialShowAndShuffle()
    }
    
    private func setConstraints() {
        guard customConstraints.isEmpty else { return }
        
        customConstraints.append(themeLabel.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor))
        customConstraints.append(themeLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: Constants.themeLabelTopPadding))
        
        customConstraints.append(collectionView.topAnchor.constraint(equalTo: themeLabel.bottomAnchor, constant: Constants.stackViewVerticalSpacing))
        customConstraints.append(collectionView.bottomAnchor.constraint(equalTo: horizontalStackView.topAnchor, constant: -Constants.stackViewVerticalSpacing))
        customConstraints.append(collectionView.widthAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.widthAnchor))
        customConstraints.append(collectionView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor))
        
        customConstraints.append(horizontalStackView.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor))
        customConstraints.append(horizontalStackView.widthAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.widthAnchor))
        customConstraints.append(horizontalStackView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -Constants.stackViewVerticalSpacing))
        
        NSLayoutConstraint.activate(customConstraints)
    }
    
    private func saveOrUpdateScore(score: Int) {
        do {
            let items = try context.fetch(Records.fetchRequest())
            let filteredItems = items.filter({$0.theme == theme.title && difficulty.description() == $0.difficulty})
            if filteredItems.count < 50 {
                saveScore(score: score)
            } else {
                let sortedScores = filteredItems.sorted(by: {$0.score < $1.score})
                if score > Int(sortedScores[0].score) {
                    deleteItem(item: sortedScores[0])
                    saveScore(score: score)
                }
            }
        } catch {
            print(error)
        }
    }
    
    private func saveScore(score: Int) {
        do {
            let item = Records(context: context)
            item.score = Int64(score)
            item.theme = theme.title
            item.difficulty = difficulty.description()
            try context.save()
        } catch {
            print(error)
        }
    }
    
    private func deleteItem(item: Records) {
        do {
            context.delete(item)
            try context.save()
        } catch {
            print(error)
        }
    }
    
    private func initialShowAndShuffle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            [weak self] in
            if let safeCollection = self?.collectionView {
                for cell in safeCollection.visibleCells {
                    if let safeCell = cell as? CardCollectionViewCell {
                        safeCell.showBack()
                    }
                }
                self?.didInitialShuffleRun = true
                self?.cards = self?.game.shuffle() ?? []
                self?.collectionView.isUserInteractionEnabled = true
                self?.collectionView.reloadData()
                self?.game.startTimer()
            }
            })
        }
}

extension GameViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        game.selectCard(cardIndex: indexPath.item)
    }
}

extension GameViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cards.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: CardCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: CardCollectionViewCell.reuseIdentifier, for: indexPath) as! CardCollectionViewCell
        if let safeCard = cards[indexPath.item] {
            cell.configure(symbol: safeCard.symbol, backSymbol:theme.card_symbol, shouldShowFront: safeCard.isFlipped || !didInitialShuffleRun)
            cell.backgroundColor = UIColor(red: theme.card_color.red, green: theme.card_color.green, blue: theme.card_color.blue, alpha: 1)
            cell.isHidden = false
        } else {
            cell.isHidden = true
        }
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}

extension GameViewController: ConcentrationGameDelegate {
    func timeChangedTo(seconds: Int) {
        timeLabel.text = "Time".localized() + ": " + String(seconds)
    }
    
    func scoreChangedTo(score: Int) {
        scoreLabel.text = "Score".localized() + ": " + String(score)
    }
    
    func didSelectCard(atIndex: Int) {
        if let safeCell = collectionView.cellForItem(at: IndexPath(item: atIndex, section: 0)) as? CardCollectionViewCell {
            safeCell.showFront()
        }
    }
    
    func cardPositionsChangedTo(deck: [Card?]) {
        cards = deck
        collectionView.reloadData()
    }
    
    func matchSuccesful(firstCardIndex: Int, secondCardIndex: Int) {
        didSelectCard(atIndex: secondCardIndex)
        cards[firstCardIndex] = nil
        cards[secondCardIndex] = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: { [weak self] in
            self?.collectionView.reloadData()
        })
    }
    
    func matchFailed(firstCardIndex: Int, secondCardIndex: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: { [weak self] in
            if let firstSafeCell = self?.collectionView.cellForItem(at: IndexPath(item: firstCardIndex, section: 0)) as? CardCollectionViewCell {
                firstSafeCell.showBack()
            }
            if let secondSafeCell = self?.collectionView.cellForItem(at: IndexPath(item: secondCardIndex, section: 0)) as? CardCollectionViewCell {
                secondSafeCell.showBack()
            }
        })
    }
    
    func gameFinished(score: Int, didWin: Bool) {
        collectionView.isUserInteractionEnabled = false
        scoreLabel.text = "Score".localized() + ": " + String(score)
        game.delegate = nil
        saveOrUpdateScore(score: score)
        if didWin {
            self.navigationController?.present(winAlert, animated: true)
        } else {
            for cell in collectionView.visibleCells {
                if let safeCell = cell as? CardCollectionViewCell {
                    safeCell.showFront()
                }
            }
        }
    }
    
    
}
