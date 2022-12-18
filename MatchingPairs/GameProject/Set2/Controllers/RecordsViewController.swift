import CoreData
import ConcentrationLibrary
import UIKit

class RecordsViewController: UITableViewController {
    
    private var records: [Records] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    private let theme: Theme
    
    init(context: NSManagedObjectContext, theme: Theme, difficulty: GameDifficulty) {
        self.theme = theme
        super.init(nibName: nil, bundle: nil)
        title = "\(theme.title.localized()) \(difficulty.description().localized()) \("Records".localized())"
        getRecords(context: context, themeName: theme.title, difficultyDescription: difficulty.description())
    }
    
    private func getRecords(context: NSManagedObjectContext, themeName: String, difficultyDescription: String) {
        do {
            let items = try context.fetch(Records.fetchRequest())
            let filteredItems = items.filter({$0.theme == themeName && $0.difficulty == difficultyDescription})
            let sortedItems = filteredItems.sorted(by: {$0.score > $1.score})
            records = sortedItems
        } catch {
            print(error)
        }
    }
    
    override func viewDidLoad() {
        tableView.register(RecordsTableViewCell.self, forCellReuseIdentifier: RecordsTableViewCell.reuseIdentifier)
        tableView.rowHeight = 60
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RecordsViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RecordsTableViewCell.reuseIdentifier, for: indexPath) as! RecordsTableViewCell
        cell.configure(score: Int(records[indexPath.item].score))
        cell.backgroundColor = UIColor(red: theme.card_color.red, green: theme.card_color.green, blue: theme.card_color.blue, alpha: 0.9)
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}
