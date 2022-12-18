public struct Card: Equatable, Hashable {
    public static func == (lhs: Card, rhs: Card) -> Bool {
        return lhs.symbol == rhs.symbol
    }
    
    public let symbol: String
    public var isFlipped: Bool
    
    init(symbol: String, isFlipped: Bool) {
        self.symbol = symbol
        self.isFlipped = isFlipped
    }
}
