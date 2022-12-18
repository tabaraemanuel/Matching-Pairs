public class ConcentrationFactory {
    public static func makeConcentrationGame(cardSymbols: [String], difficulty: GameDifficulty) -> ConcentrationGameProtocol {
        return ConcentrationGame(cardSymbols: cardSymbols, difficulty: difficulty)
    }
}
