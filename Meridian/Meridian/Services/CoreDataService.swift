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
    ///   - entryMode: Optional source mode (physical/digital) used at capture time
    ///   - photoLocalPath: Optional local file path for captured photo proof
    /// - Returns: The created JournalEntry or nil if creation failed
    @discardableResult
    func createEntry(
        content: String,
        sessionType: SessionType,
        morningReferenceID: UUID? = nil,
        entryMode: String? = nil,
        photoLocalPath: String? = nil
    ) -> JournalEntry? {
        let context = viewContext
        let entry = JournalEntry(context: context)

        let id = UUID()
        entry.id = id
        entry.type = sessionType.rawValue
        entry.content = content
        entry.timestamp = Date()
        entry.morningReferenceID = morningReferenceID
        entry.entryMode = entryMode
        entry.photoLocalPath = photoLocalPath

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

// MARK: - Debug Seed Data

#if DEBUG
extension CoreDataService {
    func seedSampleEntries() {
        guard entryCount() == 0 else { return }

        let calendar = Calendar.current
        let now = Date()

        let morningTexts = [
            "I'm grateful for the quiet this morning. My intention today is to stay present in conversations and really listen. The biggest challenge will be staying off my phone during meetings.",
            "Woke up feeling rested for the first time in a while. Today I want to approach my work with patience rather than rushing through tasks. I know the afternoon slump will test me.",
            "Grateful for my health and the ability to move my body. Setting an intention to be kind to myself today, especially if things don't go as planned.",
            "The sunrise was beautiful. I want to carry that sense of wonder into my day. My goal is to find one moment of beauty in something ordinary.",
            "Thankful for the people in my life. Today I'll reach out to someone I haven't spoken to in a while. I want to be more intentional about maintaining relationships.",
            "I slept poorly but I'm choosing to start fresh. My intention is to take breaks when I feel overwhelmed rather than pushing through mindlessly.",
            "Grateful for this practice of reflection. It's becoming easier to notice what matters. Today I want to be generous with my time and attention.",
            "Morning rain outside. There's something peaceful about it. I want to bring that calm energy into a busy day. My challenge will be not over-committing.",
            "Feeling anxious about the week ahead but choosing to focus on just today. One step at a time. Grateful for the structure this app gives my mornings.",
            "Started the day with a walk. The cold air woke me up in a good way. My intention is to speak honestly and gently today."
        ]

        let nightTexts = [
            "Today went better than expected. I noticed a moment of real connection during lunch with a colleague. I'm grateful I was present for it. Where I fell short was getting distracted by news in the evening. Tomorrow I'll set a boundary around that.",
            "A challenging day. I lost my patience in the afternoon and I regret how I spoke. But I also helped someone who was struggling at work and that felt right. I ask for the grace to do better tomorrow.",
            "I noticed how much time I spent worrying about things that never happened. The day itself was fine. The best moment was reading before bed instead of scrolling. I want to do more of that.",
            "Felt aligned for most of the day. I kept my intention from this morning and it showed. The evening was harder as tiredness set in. Grateful for the discipline to still write this reflection.",
            "Mixed feelings today. Good moments with family, but I also avoided a difficult conversation I know I need to have. Tomorrow I'll find the courage. For now, I rest in knowing I tried my best.",
            "A beautiful ordinary day. Nothing dramatic happened and that's okay. I cooked dinner, went for a walk, had a good conversation. Sometimes the quiet days are the most nourishing.",
            "I was tested today and I didn't respond the way I wanted to. But I caught myself and course-corrected. That awareness is growth. Grateful for the patience of those around me.",
            "Productive day but I forgot to pause and breathe. I was so focused on checking boxes that I missed opportunities to be present. Tomorrow I'll schedule real breaks.",
            "The highlight was an unexpected act of kindness from a stranger. It reminded me that goodness is everywhere if I look for it. I want to pay that forward tomorrow.",
            "Ending the day feeling peaceful. I honored my commitments, was honest in my conversations, and made time for what matters. Not every day will be like this but I'm grateful for this one."
        ]

        let anytimeTexts = [
            "Just had a thought during my walk that I wanted to capture. The trees are changing color and it struck me how natural transitions are. Maybe I should stop resisting the changes in my own life.",
            "Feeling overwhelmed but writing this helps. Sometimes just naming the feeling takes away its power.",
            "A moment of unexpected joy today. Small things really do matter the most.",
            "Read something that resonated: the examined life is not about perfection but about awareness. That takes the pressure off."
        ]

        struct SeedEntry {
            let daysAgo: Int
            let type: SessionType
            let hour: Int
            let content: String
        }

        let seeds: [SeedEntry] = [
            SeedEntry(daysAgo: 1, type: .morning, hour: 7, content: morningTexts[0]),
            SeedEntry(daysAgo: 1, type: .night, hour: 22, content: nightTexts[0]),
            SeedEntry(daysAgo: 2, type: .morning, hour: 6, content: morningTexts[1]),
            SeedEntry(daysAgo: 2, type: .night, hour: 21, content: nightTexts[1]),
            SeedEntry(daysAgo: 3, type: .morning, hour: 7, content: morningTexts[2]),
            SeedEntry(daysAgo: 4, type: .night, hour: 23, content: nightTexts[2]),
            SeedEntry(daysAgo: 5, type: .morning, hour: 8, content: morningTexts[3]),
            SeedEntry(daysAgo: 5, type: .night, hour: 22, content: nightTexts[3]),
            SeedEntry(daysAgo: 5, type: .anytime, hour: 14, content: anytimeTexts[0]),
            SeedEntry(daysAgo: 7, type: .morning, hour: 7, content: morningTexts[4]),
            SeedEntry(daysAgo: 7, type: .night, hour: 21, content: nightTexts[4]),
            SeedEntry(daysAgo: 9, type: .morning, hour: 6, content: morningTexts[5]),
            SeedEntry(daysAgo: 10, type: .night, hour: 22, content: nightTexts[5]),
            SeedEntry(daysAgo: 12, type: .morning, hour: 7, content: morningTexts[6]),
            SeedEntry(daysAgo: 12, type: .night, hour: 23, content: nightTexts[6]),
            SeedEntry(daysAgo: 14, type: .anytime, hour: 16, content: anytimeTexts[1]),
            SeedEntry(daysAgo: 16, type: .morning, hour: 8, content: morningTexts[7]),
            SeedEntry(daysAgo: 16, type: .night, hour: 22, content: nightTexts[7]),
            SeedEntry(daysAgo: 20, type: .morning, hour: 7, content: morningTexts[8]),
            SeedEntry(daysAgo: 20, type: .night, hour: 21, content: nightTexts[8]),
            SeedEntry(daysAgo: 23, type: .anytime, hour: 11, content: anytimeTexts[2]),
            SeedEntry(daysAgo: 25, type: .morning, hour: 7, content: morningTexts[9]),
            SeedEntry(daysAgo: 25, type: .night, hour: 22, content: nightTexts[9]),
            SeedEntry(daysAgo: 28, type: .anytime, hour: 19, content: anytimeTexts[3]),
        ]

        let context = viewContext
        for seed in seeds {
            let entry = JournalEntry(context: context)
            let id = UUID()
            entry.id = id
            entry.type = seed.type.rawValue
            entry.content = seed.content

            var components = calendar.dateComponents([.year, .month, .day], from: calendar.date(byAdding: .day, value: -seed.daysAgo, to: now)!)
            components.hour = seed.hour
            components.minute = Int.random(in: 0...59)
            entry.timestamp = calendar.date(from: components)

            entry.entryMode = "digital"
            let position = JournalEntry.generateStarPosition(from: id)
            entry.starPositionX = position.x
            entry.starPositionY = position.y
        }

        coreDataStack.saveContext()
        print("Seeded \(seeds.count) sample journal entries")
    }
}
#endif
