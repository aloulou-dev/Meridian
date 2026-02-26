//
//  CoreDataStack.swift
//  Meridian
//
//  Core Data persistent container setup and configuration.
//

import CoreData
import Foundation

/// Core Data stack configuration and management
final class CoreDataStack {
    // MARK: - Singleton

    static let shared = CoreDataStack()

    // MARK: - Properties

    /// The model name for the Core Data store
    private let modelName = "Meridian"

    /// The persistent container
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)

        // Configure for persistent history tracking
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        // Enable data protection
        description?.setOption(
            FileProtectionType.complete as NSObject,
            forKey: NSPersistentStoreFileProtectionKey
        )

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, handle this more gracefully
                fatalError("Failed to load Core Data store: \(error), \(error.userInfo)")
            }

            print("Core Data store loaded: \(storeDescription.url?.absoluteString ?? "unknown")")
        }

        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    /// The main view context for UI operations
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Context Management

    /// Create a new background context for heavy operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Perform work on a background context
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }

    // MARK: - Save Operations

    /// Save the view context if there are changes
    func saveContext() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving Core Data context: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    /// Save a specific context if there are changes
    func save(context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving Core Data context: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    // MARK: - For Testing

    /// Create an in-memory Core Data stack for testing
    static func inMemoryStack() -> CoreDataStack {
        let stack = CoreDataStack()
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType

        stack.persistentContainer.persistentStoreDescriptions = [description]
        stack.persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }

        return stack
    }
}

// MARK: - JournalEntry Entity

/*
 NOTE: Create the Meridian.xcdatamodeld in Xcode with the following entity:

 Entity: JournalEntry
 Attributes:
   - id: UUID (required, indexed)
   - type: String (required, indexed) - "morning", "night", "anytime"
   - content: String (required)
   - timestamp: Date (required, indexed)
   - morningReferenceID: UUID (optional) - Links night entry to morning entry
   - starPositionX: Double (required) - Cached star X position (0.0-1.0)
   - starPositionY: Double (required) - Cached star Y position (0.0-1.0)

 Indexes:
   - id
   - type
   - timestamp

 No relationships needed (denormalized for performance).
*/

/// NSManagedObject subclass for JournalEntry
/// Generate this in Xcode: Editor > Create NSManagedObject Subclass
@objc(JournalEntry)
public class JournalEntry: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var type: String
    @NSManaged public var content: String
    @NSManaged public var timestamp: Date
    @NSManaged public var morningReferenceID: UUID?
    @NSManaged public var starPositionX: Double
    @NSManaged public var starPositionY: Double
}

extension JournalEntry: Identifiable {
    /// The session type for this entry
    var sessionType: SessionType {
        SessionType(rawValue: type) ?? .anytime
    }

    /// Whether this is a morning entry
    var isMorning: Bool {
        sessionType == .morning
    }

    /// Whether this is a night entry
    var isNight: Bool {
        sessionType == .night
    }

    /// Whether this is an anytime entry
    var isAnytime: Bool {
        sessionType == .anytime
    }

    /// The star position as a tuple
    var starPosition: (x: Double, y: Double) {
        (starPositionX, starPositionY)
    }

    /// Word count of the entry content
    var wordCount: Int {
        content.split(separator: " ").count
    }

    /// Preview text (first 100 characters)
    var previewText: String {
        if content.count <= 100 {
            return content
        }
        return String(content.prefix(100)) + "..."
    }
}

extension JournalEntry {
    /// Generate deterministic star position from entry ID
    static func generateStarPosition(from id: UUID) -> (x: Double, y: Double) {
        // Use the UUID to seed a deterministic random position
        let hash = id.hashValue
        let seed1 = abs(hash)
        let seed2 = abs(hash &* 31)

        // Generate positions between 0.1 and 0.9 to keep stars away from edges
        let x = 0.1 + (Double(seed1 % 1000) / 1000.0) * 0.8
        let y = 0.1 + (Double(seed2 % 1000) / 1000.0) * 0.8

        return (x, y)
    }

    /// Fetch request for all entries, sorted by timestamp descending
    @nonobjc public class func fetchRequest() -> NSFetchRequest<JournalEntry> {
        let request = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.timestamp, ascending: false)]
        return request
    }
}
