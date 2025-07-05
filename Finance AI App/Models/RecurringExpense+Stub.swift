import Foundation
import CoreData

@objc(RecurringExpense)
public class RecurringExpense: NSManagedObject {
    @NSManaged public var amount: Double
    @NSManaged public var category: String?
    @NSManaged public var note: String?
    @NSManaged public var date: Date?
    @NSManaged public var isRecurring: Bool
    @NSManaged public var repeatInterval: String?
} 