//
//  CoreDataService.swift
//  Meridian
//
//  Service for managing JournalEntry CRUD operations.
//

import CoreData
import Foundation

/// Service for managing journal entry persistence
final class CoreDataService {
    // MARK: - Singleton

    static let shared = CoreDataService()

    // MARK: - Properties

    private let coreDataStack: CoreDataStack

    private var viewContext: NSManagedObjectContext {
        coreDataStack.viewContext
    }

    // MARK: - Initialization

    init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }

    // MARK: - Create

    /// Create a new journal entry
    /// - Parameters:
    ///   - content: The journal entry text
    ///   - sessionType: The type of session (morning, night, anytime)
    ///   - morningReferenceID: Optional ID of the morning entry to reference (for night entries)
    /// - Returns: The created JournalEntry or nil if creation failed
    @discardableResult
    func createEntry(
        content: String,
        sessionType: SessionType,
        morningReferenceID: UUID? = nil
    ) -> JournalEntry? {
        let context = viewContext
        let entry = JournalEntry(context: context)

        let id = UUID()
        entry.id = id
        entry.type = sessionType.rawValue
        entry.content = content
        entry.timestamp = Date()
        entry.morningReferenceID = morningReferenceID

        // Generate and cache star position
        let position = JournalEntry.generateStarPosition(from: id)
        entry.starPositionX = position.x
        entry.starPositionY = position.y

        coreDataStack.saveContext()

        // Record for rate limiting
        SettingsService.shared.recordEntryCreated(for: sessionType)
        SettingsService.shared.recordEntryCreation()

        return entry
    }

    // MARK: - Read

    /// Fetch all journal entries
    /// - Parameter limit: Maximum number of entries to fetch (nil for all)
    /// - Returns: Array of JournalEntry objects
    func fetchAllEntries(limit: Int? = nil) -> [JournalEntry] {
        let request = JournalEntry.fetchRequest()
        if let limit = limit {
            request.fetchLimit = limit
        }

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching entries: \(error)")
            return []
        }
    }

    /// Fetch entries by session type
    /// - Parameters:
    ///   - type: The session type to filter by
    ///   - limit: Maximum number of entries to fetch
    /// - Returns: Array of JournalEntry objects
    func fetchEntries(ofType type: SessionType, limit: Int? = nil) -> [JournalEntry] {
        let request = JournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", type.rawValue)
        if let limit = limit {
            request.fetchLimit = limit
        }

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching entries by type: \(error)")
            return []
        }
    }

    /// Fetch entry by ID
    /// - Parameter id: The UUID of the entry
    /// - Returns: The JournalEntry or nil if not found
    func fetchEntry(byID id: UUID) -> JournalEntry? {
        let request = JournalEntry.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Error fetching entry by ID: \(error)")
            return nil
        }
    }

    /// Fetch today's morning entry
    /// - Returns: The morning JournalEntry for today or nil
    func fetchTodaysMorningEntry() -> JournalEntry? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        let request = JournalEntry.fetchRequest()
        request.predicate = NSPredicate(
            format: "type == %@ AND timestamp >= %@ AND timestamp < %@",
            SessionType.morning.rawValue,
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.fetchLimit = 1

        do {
            return try viewContext.fetch(request).first
        } catch {
            print("Error fetching today's morning entry: \(error)")
            return nil
        }
    }

    /// Fetch entries within a date range
    /// - Parameters:
    ///   - startDate: Start of the range (inclusive)
    ///   - endDate: End of the range (inclusive)
    ///   - type: Optional session type filter
    /// - Returns: Array of JournalEntry objects
    func fetchEntries(
        from startDate: Date,
        to endDate: Date,
        ofType type: SessionType? = nil
    ) -> [JournalEntry] {
        let request = JournalEntry.fetchRequest()

        var predicates: [NSPredicate] = [
            NSPredicate(format: "timestamp >= %@ AND timestamp <= %@", startDate as NSDate, endDate as NSDate)
        ]

        if let type = type {
            predicates.append(NSPredicate(format: "type == %@", type.rawValue))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching entries by date range: \(error)")
            return []
        }
    }

    /// Search entries by content
    /// - Parameters:
    ///   - query: The search query
    ///   - type: Optional session type filter
    /// - Returns: Array of matching JournalEntry objects
    func searchEntries(query: String, ofType type: SessionType? = nil) -> [JournalEntry] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return type != nil ? fetchEntries(ofType: type!) : fetchAllEntries()
        }

        let request = JournalEntry.fetchRequest()

        var predicates: [NSPredicate] = [
            NSPredicate(format: "content CONTAINS[cd] %@", query)
        ]

        if let type = type {
            predicates.append(NSPredicate(format: "type == %@", type.rawValue))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error searching entries: \(error)")
            return []
        }
    }

    /// Get total entry count
    /// - Returns: Number of entries in the database
    func entryCount() -> Int {
        let request = JournalEntry.fetchRequest()
        do {
            return try viewContext.count(for: request)
        } catch {
            print("Error counting entries: \(error)")
            return 0
        }
    }

    // MARK: - Update

    /// Update an existing entry's content
    /// - Parameters:
    ///   - id: The UUID of the entry to update
    ///   - newContent: The new content
    /// - Returns: True if update was successful
    @discardableResult
    func updateEntry(id: UUID, newContent: String) -> Bool {
        guard let entry = fetchEntry(byID: id) else {
            return false
        }

        entry.content = newContent
        coreDataStack.saveContext()
        return true
    }

    // MARK: - Delete

    /// Delete an entry by ID
    /// - Parameter id: The UUID of the entry to delete
    /// - Returns: True if deletion was successful
    @discardableResult
    func deleteEntry(byID id: UUID) -> Bool {
        guard let entry = fetchEntry(byID: id) else {
            return false
        }

        viewContext.delete(entry)
        coreDataStack.saveContext()
        return true
    }

    /// Delete all entries (use with caution!)
    func deleteAllEntries() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "JournalEntry")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try viewContext.execute(deleteRequest)
            coreDataStack.saveContext()
        } catch {
            print("Error deleting all entries: \(error)")
        }
    }

    // MARK: - Utilities

    /// Check if a morning entry exists for today
    var hasTodaysMorningEntry: Bool {
        fetchTodaysMorningEntry() != nil
    }

    /// Get the most recent entry of a specific type
    func mostRecentEntry(ofType type: SessionType) -> JournalEntry? {
        fetchEntries(ofType: type, limit: 1).first
    }

    /// Refresh all managed objects in the view context
    func refresh() {
        viewContext.refreshAllObjects()
    }
}
