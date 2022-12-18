import UIKit
import Foundation

public protocol ConcentrationGameProtocol {
    var delegate: ConcentrationGameDelegate? { get set }
    func startTimer()
    func createDeck() -> [Card?]
    func shuffle() -> [Card?]
    func selectCard(cardIndex: Int)
}

class ConcentrationGame: ConcentrationGameProtocol {
    private var timer: Timer?
    private var score: Int = 0 {
        didSet {
            delegate?.scoreChangedTo(score: score)
        }
    }
    
    private struct Constants {
        static let timeInSecondsForGame = 45
    }
    
    private(set) var deck: [Card?] = []
    private var timeScore: Int = 45 {
        didSet {
            delegate?.timeChangedTo(seconds: timeScore)
            if difficulty == .Hard, timeScore > 0, timeScore % 10 == 0 {
                moveCardsOneIndexUp()
            }
        }
    }
    private var cardSymbols: [String]
    private let difficulty: GameDifficulty
    
    public weak var delegate: ConcentrationGameDelegate?
    
    init(cardSymbols: [String], difficulty: GameDifficulty) {
        self.cardSymbols = cardSymbols
        self.difficulty = difficulty
    }
    
    public func startTimer() {
        delegate?.timeChangedTo(seconds: timeScore)
        self.timer = Timer(timeInterval: 1, repeats: true, block: {[weak self] _ in
            guard (self?.timeScore ?? 0) > 0 else {
                self?.delegate?.gameFinished(score: self?.score ?? 0, didWin: false)
                self?.timer?.invalidate()
                return
            }
            self?.timeScore -= 1
        })
        if let safeTimer = timer {
            RunLoop.current.add(safeTimer, forMode: .common)
        }
    }
    
    public func createDeck() -> [Card?] {
        var builtDeck: [Card] = []
        for symbol in cardSymbols {
                let card = Card(symbol: symbol, isFlipped: false)
                builtDeck.append(contentsOf: [card, card])
        }
        var intermediateDeck: [Card] = []
        for _ in 0 ..< builtDeck.count{
            intermediateDeck.append(builtDeck.remove(at: Int.random(in: 0..<builtDeck.count)))
        }
        deck = intermediateDeck
        return deck
    }
        
    public func selectCard(cardIndex: Int) {
        let selectedCount = deck.filter({$0?.isFlipped ?? false}).count
        switch selectedCount {
        case 0:
                deck[cardIndex]?.isFlipped = true
                delegate?.didSelectCard(atIndex: cardIndex)
        case 1:
            guard let firstSelectedIndex = deck.firstIndex(where: {$0?.isFlipped ?? false}), cardIndex != firstSelectedIndex else { return }
            deck[cardIndex]?.isFlipped = true
            delegate?.didSelectCard(atIndex: cardIndex)
            checkMatching(firstCardIndex: firstSelectedIndex, secondCardIndex: cardIndex)
        default:
            for index in 0..<deck.count {
                deck[index]?.isFlipped = false
            }
        }
    }
    
    public func shuffle() -> [Card?] {
        var intermediateDeck: [Card?] = []
        for _ in 0 ..< deck.count{
            intermediateDeck.append(deck.remove(at: Int.random(in: 0..<deck.count)))
        }
        deck = intermediateDeck
        return deck
    }
    
    private func checkMatching(firstCardIndex: Int, secondCardIndex: Int) {
        if deck[firstCardIndex] == deck[secondCardIndex] {
            score += 3
            deck[firstCardIndex] = nil
            deck[secondCardIndex] = nil
            delegate?.matchSuccesful(firstCardIndex: firstCardIndex, secondCardIndex: secondCardIndex)
            if deck.filter({$0 != nil}).count == 0 {
                timer?.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
                    self?.delegate?.gameFinished(score: (self?.score ?? 0) + (self?.timeScore ?? 0), didWin: true)
                })
            }
        } else {
            score -= 1
            deck[firstCardIndex]?.isFlipped = false
            deck[secondCardIndex]?.isFlipped = false
            delegate?.matchFailed(firstCardIndex: firstCardIndex, secondCardIndex: secondCardIndex)
        }
    }
    
    private func moveCardsOneIndexUp() {
        var intermediryDeck: [Card?] = []
        intermediryDeck.append(deck.popLast() ?? nil)
        for card in deck {
            intermediryDeck.append(card)
        }
        deck = intermediryDeck
        delegate?.cardPositionsChangedTo(deck: deck)
    }
}

public protocol ConcentrationGameDelegate: AnyObject {
    func timeChangedTo(seconds: Int)
    func scoreChangedTo(score: Int)
    func didSelectCard(atIndex: Int)
    func cardPositionsChangedTo(deck: [Card?])
    func matchSuccesful(firstCardIndex: Int, secondCardIndex: Int)
    func matchFailed(firstCardIndex: Int, secondCardIndex: Int)
    func gameFinished(score: Int, didWin: Bool)
}
