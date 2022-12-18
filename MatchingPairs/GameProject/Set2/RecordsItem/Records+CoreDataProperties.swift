import Foundation
import CoreData


extension Records {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Records> {
        return NSFetchRequest<Records>(entityName: "Records")
    }

    @NSManaged public var score: Int64
    @NSManaged public var theme: String?
    @NSManaged public var difficulty: String?

}

extension Records : Identifiable {

}
