import Foundation

struct CardColor: Hashable, Codable {
    let blue: Double
    let green: Double
    let red: Double
}

struct Theme: Hashable, Codable {
    let card_color: CardColor
    let card_symbol: String
    let symbols: [String]
    let title: String
}

class ThemeFetcher {
    
    public var delegate: ThemeFetcherDelegate?
    
    public func fetchData() {
        guard let url = URL(string: "https://firebasestorage.googleapis.com/v0/b/concentrationgame-20753.appspot.com/o/themes.json?alt=media&token=6898245a-0586-4fed-b30e-5078faeba078)") else { return }
        let task = URLSession.shared.dataTask(with: url, completionHandler: { [weak self] data, _, error in
            guard let safeData = data, error == nil else { return }
            do {
                let themes: [Theme] = try JSONDecoder().decode([Theme].self, from: safeData)
                DispatchQueue.main.async {
                    self?.delegate?.themesUpdated(themes: themes)
                }
            }
            catch {
                print(error)
            }
        })
        task.resume()
    }
}

protocol ThemeFetcherDelegate: AnyObject {
    func themesUpdated(themes: [Theme])
}
