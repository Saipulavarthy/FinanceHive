import UserNotifications
import CoreData

class NotificationService: UNNotificationServiceExtension {
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    // Core Data stack for the extension
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Finance_AI_App") // Use your model name
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
        }
        return container
    }()

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let bestAttemptContent = bestAttemptContent {
            // Try to parse Apple Pay notification
            if let body = bestAttemptContent.body as String? {
                if let (amount, merchant) = parseApplePayNotification(body: body) {
                    saveExpense(amount: amount, merchant: merchant)
                }
            }
            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    // MARK: - Regex Parsing
    /// Example Apple Pay notification: "You spent $12.34 at Starbucks."
    func parseApplePayNotification(body: String) -> (Double, String)? {
        let pattern = #"\\$([0-9]+(?:\\.[0-9]{2})?)\\s+at\\s+([A-Za-z0-9 &\\-']+)"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(body.startIndex..., in: body)
            if let match = regex.firstMatch(in: body, options: [], range: range),
               let amountRange = Range(match.range(at: 1), in: body),
               let merchantRange = Range(match.range(at: 2), in: body) {
                let amountString = String(body[amountRange])
                let merchant = String(body[merchantRange])
                if let amount = Double(amountString) {
                    return (amount, merchant)
                }
            }
        }
        return nil
    }

    // MARK: - Core Data Storage
    func saveExpense(amount: Double, merchant: String) {
        let context = persistentContainer.viewContext
        let expense = NSEntityDescription.insertNewObject(forEntityName: "RecurringExpense", into: context)
        expense.setValue(amount, forKey: "amount")
        expense.setValue(merchant, forKey: "category") // Or use a separate merchant field if you have one
        expense.setValue(Date(), forKey: "date")
        expense.setValue(false, forKey: "isRecurring")
        expense.setValue(nil, forKey: "repeatInterval")
        do {
            try context.save()
        } catch {
            print("Failed to save expense: \(error)")
        }
    }
} 