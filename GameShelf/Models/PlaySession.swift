import Foundation

struct PlaySession: Codable, Identifiable {
    let id: UUID
    let romPath: String
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval {
        (endTime ?? Date()).timeIntervalSince(startTime)
    }
    
    init(romPath: String, startTime: Date = Date()) {
        self.id = UUID()
        self.romPath = romPath
        self.startTime = startTime
        self.endTime = nil
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "<1m"
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
}

// MARK: - Game Statistics

struct GameStats: Codable {
    let romPath: String
    var totalPlayTime: TimeInterval
    var sessionCount: Int
    var lastPlayed: Date?
    var sessions: [PlaySession]
    
    init(romPath: String) {
        self.romPath = romPath
        self.totalPlayTime = 0
        self.sessionCount = 0
        self.lastPlayed = nil
        self.sessions = []
    }
    
    var formattedTotalPlayTime: String {
        let hours = Int(totalPlayTime) / 3600
        let minutes = (Int(totalPlayTime) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "< 1 min"
        }
    }
    
    var averageSessionLength: TimeInterval {
        guard sessionCount > 0 else { return 0 }
        return totalPlayTime / Double(sessionCount)
    }
    
    var formattedAverageSession: String {
        let minutes = Int(averageSessionLength) / 60
        if minutes > 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes) min"
    }
    
    var formattedLastPlayed: String? {
        guard let lastPlayed = lastPlayed else { return nil }
        
        let now = Date()
        let diff = now.timeIntervalSince(lastPlayed)
        
        if diff < 60 {
            return "Just now"
        } else if diff < 3600 {
            let minutes = Int(diff / 60)
            return "\(minutes) min ago"
        } else if diff < 86400 {
            let hours = Int(diff / 3600)
            return "\(hours)h ago"
        } else if diff < 604800 {
            let days = Int(diff / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: lastPlayed)
        }
    }
    
    mutating func addSession(_ session: PlaySession) {
        sessions.append(session)
        sessionCount += 1
        totalPlayTime += session.duration
        lastPlayed = session.startTime
        
        // Keep only last 100 sessions
        if sessions.count > 100 {
            sessions = Array(sessions.suffix(100))
        }
    }
}

// MARK: - Statistics Database

class StatsDatabase: ObservableObject {
    @Published private var stats: [String: GameStats] = [:]
    
    private static var databaseURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("GameShelf", isDirectory: true)
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        return appFolder.appendingPathComponent("stats.json")
    }
    
    init() {
        load()
    }
    
    func load() {
        guard FileManager.default.fileExists(atPath: Self.databaseURL.path),
              let data = try? Data(contentsOf: Self.databaseURL),
              let decoded = try? JSONDecoder().decode([String: GameStats].self, from: data) else {
            return
        }
        stats = decoded
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(stats) else { return }
        try? data.write(to: Self.databaseURL)
    }
    
    func getStats(forRomPath path: String) -> GameStats {
        stats[path] ?? GameStats(romPath: path)
    }
    
    func recordSession(_ session: PlaySession) {
        var gameStats = getStats(forRomPath: session.romPath)
        gameStats.addSession(session)
        stats[session.romPath] = gameStats
        save()
        objectWillChange.send()
    }
    
    // MARK: - Aggregate Statistics
    
    var totalPlayTime: TimeInterval {
        stats.values.reduce(0) { $0 + $1.totalPlayTime }
    }
    
    var totalSessionCount: Int {
        stats.values.reduce(0) { $0 + $1.sessionCount }
    }
    
    var gamesPlayed: Int {
        stats.values.filter { $0.sessionCount > 0 }.count
    }
    
    func topPlayedGames(limit: Int = 10) -> [(path: String, stats: GameStats)] {
        stats
            .map { ($0.key, $0.value) }
            .sorted { $0.1.totalPlayTime > $1.1.totalPlayTime }
            .prefix(limit)
            .map { $0 }
    }
    
    func recentSessions(limit: Int = 10) -> [PlaySession] {
        stats.values
            .flatMap { $0.sessions }
            .sorted { $0.startTime > $1.startTime }
            .prefix(limit)
            .map { $0 }
    }
    
    // Play time by period
    func playTime(for period: StatsPeriod) -> TimeInterval {
        let cutoff = period.startDate
        return stats.values
            .flatMap { $0.sessions }
            .filter { $0.startTime >= cutoff }
            .reduce(0) { $0 + $1.duration }
    }
    
    func sessionsCount(for period: StatsPeriod) -> Int {
        let cutoff = period.startDate
        return stats.values
            .flatMap { $0.sessions }
            .filter { $0.startTime >= cutoff }
            .count
    }
    
    // Daily play time for charts
    func dailyPlayTime(days: Int = 7) -> [(date: Date, duration: TimeInterval)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var result: [(Date, TimeInterval)] = []
        
        for dayOffset in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date)!
            
            let duration = stats.values
                .flatMap { $0.sessions }
                .filter { $0.startTime >= date && $0.startTime < nextDate }
                .reduce(0) { $0 + $1.duration }
            
            result.append((date, duration))
        }
        
        return result
    }
}

enum StatsPeriod: String, CaseIterable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case allTime = "All Time"
    
    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now)!
        case .allTime:
            return Date.distantPast
        }
    }
}

