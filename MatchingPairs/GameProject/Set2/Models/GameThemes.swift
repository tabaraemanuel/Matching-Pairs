enum GameThemes {
    case Halloween
    case Ballons
    func description() -> String {
        switch self {
        case .Halloween:
            return "Halloween".localized()
        case .Ballons:
            return "Ballons".localized()
        }
    }
}
