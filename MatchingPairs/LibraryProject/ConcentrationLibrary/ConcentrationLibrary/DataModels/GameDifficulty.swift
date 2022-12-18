public enum GameDifficulty {
    case Easy
    case Hard
    public func description() -> String {
        switch self {
        case .Easy:
            return "Easy"
        case .Hard:
            return "Hard"
        }
    }
}

