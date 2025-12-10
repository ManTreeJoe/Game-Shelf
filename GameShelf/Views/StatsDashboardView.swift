import SwiftUI

struct StatsDashboardView: View {
    @StateObject private var statsDB = StatsDatabase()
    @EnvironmentObject var viewModel: LibraryViewModel
    @State private var selectedPeriod: StatsPeriod = .week
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView
                
                // Period selector
                periodSelector
                
                // Overview cards
                overviewCards
                
                // Play time chart
                playTimeChart
                
                // Top games
                topGamesSection
                
                // Recent sessions
                recentSessionsSection
            }
            .padding(24)
        }
        .background(Theme.background)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("STATISTICS")
                    .font(.synthwaveDisplay(28))
                    .foregroundStyle(Theme.synthwaveGradient)
                    .neonGlow(Theme.neonPink, radius: 8)
                
                Text("Track your gaming habits")
                    .font(.synthwaveBody(14))
                    .foregroundColor(Theme.textSecondary)
            }
            
            Spacer()
            
            // Currently playing indicator
            if SessionTracker.shared.isTracking {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Theme.neonGreen)
                        .frame(width: 8, height: 8)
                        .neonGlow(Theme.neonGreen, radius: 4)
                    
                    Text("Playing now")
                        .font(.synthwave(12, weight: .medium))
                        .foregroundColor(Theme.neonGreen)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.neonGreen.opacity(0.1))
                .cornerRadius(20)
            }
        }
    }
    
    // MARK: - Period Selector
    
    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.snappy) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.synthwave(12, weight: .medium))
                        .foregroundColor(selectedPeriod == period ? .white : Theme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedPeriod == period ?
                                AnyShapeStyle(Theme.neonPinkGradient) :
                                AnyShapeStyle(Theme.backgroundTertiary)
                        )
                        .cornerRadius(20)
                        .neonGlow(Theme.neonPink, radius: 6, isActive: selectedPeriod == period)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Overview Cards
    
    private var overviewCards: some View {
        HStack(spacing: 16) {
            DashboardCard(
                title: "Play Time",
                value: formattedPlayTime(statsDB.playTime(for: selectedPeriod)),
                subtitle: selectedPeriod.rawValue,
                icon: "clock.fill",
                color: Theme.neonPink
            )
            
            DashboardCard(
                title: "Sessions",
                value: "\(statsDB.sessionsCount(for: selectedPeriod))",
                subtitle: "Games launched",
                icon: "play.circle.fill",
                color: Theme.neonCyan
            )
            
            DashboardCard(
                title: "Games Played",
                value: "\(statsDB.gamesPlayed)",
                subtitle: "Total unique",
                icon: "gamecontroller.fill",
                color: Theme.neonPurple
            )
            
            DashboardCard(
                title: "Total Time",
                value: formattedPlayTime(statsDB.totalPlayTime),
                subtitle: "All time",
                icon: "hourglass",
                color: Theme.warmAmber
            )
        }
    }
    
    // MARK: - Play Time Chart
    
    private var playTimeChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DAILY ACTIVITY")
                .font(.synthwave(11, weight: .bold))
                .foregroundColor(Theme.textTertiary)
                .tracking(2)
            
            // Simple bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(statsDB.dailyPlayTime(days: 7).enumerated()), id: \.offset) { index, data in
                    VStack(spacing: 4) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [Theme.neonPink, Theme.neonCyan],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: barHeight(for: data.duration))
                            .neonGlow(Theme.neonPink, radius: 4, isActive: data.duration > 0)
                        
                        // Day label
                        Text(dayLabel(for: data.date))
                            .font(.synthwave(10))
                            .foregroundColor(Theme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
            .padding(16)
            .background(Theme.backgroundTertiary)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Top Games
    
    private var topGamesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MOST PLAYED")
                .font(.synthwave(11, weight: .bold))
                .foregroundColor(Theme.textTertiary)
                .tracking(2)
            
            VStack(spacing: 8) {
                let topGames = statsDB.topPlayedGames(limit: 5)
                
                if topGames.isEmpty {
                    emptyStateView("No games played yet")
                } else {
                    ForEach(Array(topGames.enumerated()), id: \.offset) { index, game in
                        TopGameRow(
                            rank: index + 1,
                            romPath: game.path,
                            stats: game.stats,
                            rom: viewModel.roms.first { $0.path.path == game.path }
                        )
                    }
                }
            }
            .padding(16)
            .background(Theme.backgroundTertiary)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Recent Sessions
    
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RECENT SESSIONS")
                .font(.synthwave(11, weight: .bold))
                .foregroundColor(Theme.textTertiary)
                .tracking(2)
            
            VStack(spacing: 8) {
                let sessions = statsDB.recentSessions(limit: 10)
                
                if sessions.isEmpty {
                    emptyStateView("No sessions recorded")
                } else {
                    ForEach(sessions) { session in
                        RecentSessionRow(
                            session: session,
                            rom: viewModel.roms.first { $0.path.path == session.romPath }
                        )
                    }
                }
            }
            .padding(16)
            .background(Theme.backgroundTertiary)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helpers
    
    private func emptyStateView(_ message: String) -> some View {
        HStack {
            Spacer()
            Text(message)
                .font(.synthwave(13))
                .foregroundColor(Theme.textTertiary)
            Spacer()
        }
        .padding(.vertical, 20)
    }
    
    private func formattedPlayTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes) min"
        } else {
            return "0 min"
        }
    }
    
    private func barHeight(for duration: TimeInterval) -> CGFloat {
        let maxDuration = statsDB.dailyPlayTime(days: 7).map { $0.duration }.max() ?? 1
        let ratio = maxDuration > 0 ? duration / maxDuration : 0
        return max(4, CGFloat(ratio) * 80)
    }
    
    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Dashboard Card

struct DashboardCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                    .neonGlow(color, radius: 4, isActive: isHovered)
                
                Spacer()
            }
            
            Text(value)
                .font(.synthwaveDisplay(24))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.synthwave(12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                
                Text(subtitle)
                    .font(.synthwave(10))
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.backgroundTertiary)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? color.opacity(0.5) : .clear, lineWidth: 1)
        )
        .cornerRadius(12)
        .neonGlow(color, radius: 8, isActive: isHovered)
        .onHover { hovering in
            withAnimation(.quick) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Top Game Row

struct TopGameRow: View {
    let rank: Int
    let romPath: String
    let stats: GameStats
    let rom: ROM?
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(rank)")
                .font(.synthwave(14, weight: .bold))
                .foregroundColor(rankColor)
                .frame(width: 30)
            
            // Game info
            VStack(alignment: .leading, spacing: 2) {
                Text(rom?.displayName ?? URL(fileURLWithPath: romPath).lastPathComponent)
                    .font(.synthwaveBody(14))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let platform = rom?.platform {
                    Text(platform)
                        .font(.synthwave(11))
                        .foregroundColor(Theme.platformColor(for: platform))
                }
            }
            
            Spacer()
            
            // Play time
            VStack(alignment: .trailing, spacing: 2) {
                Text(stats.formattedTotalPlayTime)
                    .font(.synthwave(14, weight: .bold))
                    .foregroundColor(Theme.neonCyan)
                
                Text("\(stats.sessionCount) sessions")
                    .font(.synthwave(10))
                    .foregroundColor(Theme.textTertiary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return Theme.warmAmber
        case 2: return Theme.textSecondary
        case 3: return Color(hex: "cd7f32")
        default: return Theme.textTertiary
        }
    }
}

// MARK: - Recent Session Row

struct RecentSessionRow: View {
    let session: PlaySession
    let rom: ROM?
    
    var body: some View {
        HStack(spacing: 12) {
            // Time indicator
            Circle()
                .fill(Theme.neonCyan)
                .frame(width: 8, height: 8)
                .neonGlow(Theme.neonCyan, radius: 4)
            
            // Game info
            VStack(alignment: .leading, spacing: 2) {
                Text(rom?.displayName ?? URL(fileURLWithPath: session.romPath).lastPathComponent)
                    .font(.synthwaveBody(13))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(session.formattedDate)
                    .font(.synthwave(10))
                    .foregroundColor(Theme.textTertiary)
            }
            
            Spacer()
            
            // Duration
            Text(session.formattedDuration)
                .font(.synthwave(13, weight: .medium))
                .foregroundColor(Theme.neonPink)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    StatsDashboardView()
        .environmentObject(LibraryViewModel(config: AppConfig()))
        .frame(width: 900, height: 700)
}

