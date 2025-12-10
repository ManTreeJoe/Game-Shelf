import SwiftUI

struct StatsView: View {
    let rom: ROM
    @StateObject private var tracker = SessionTracker.shared
    
    private var stats: GameStats {
        tracker.getStats(for: rom)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(Theme.neonCyan)
                
                Text("PLAY STATS")
                    .font(.synthwave(12, weight: .bold))
                    .foregroundColor(Theme.textSecondary)
                    .tracking(2)
            }
            
            // Stats grid
            HStack(spacing: 20) {
                StatBox(
                    title: "Total Time",
                    value: stats.formattedTotalPlayTime,
                    icon: "clock.fill",
                    color: Theme.neonPink
                )
                
                StatBox(
                    title: "Sessions",
                    value: "\(stats.sessionCount)",
                    icon: "play.circle.fill",
                    color: Theme.neonCyan
                )
                
                StatBox(
                    title: "Avg Session",
                    value: stats.formattedAverageSession,
                    icon: "timer",
                    color: Theme.neonPurple
                )
            }
            
            // Last played
            if let lastPlayed = stats.formattedLastPlayed {
                HStack {
                    Text("Last played:")
                        .font(.synthwave(12))
                        .foregroundColor(Theme.textTertiary)
                    
                    Text(lastPlayed)
                        .font(.synthwave(12, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            
            // Recent sessions
            if !stats.sessions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Sessions")
                        .font(.synthwave(11, weight: .bold))
                        .foregroundColor(Theme.textTertiary)
                        .tracking(1)
                    
                    ForEach(stats.sessions.suffix(5).reversed()) { session in
                        HStack {
                            Text(session.formattedDate)
                                .font(.synthwave(11))
                                .foregroundColor(Theme.textTertiary)
                            
                            Spacer()
                            
                            Text(session.formattedDuration)
                                .font(.synthwave(11, weight: .medium))
                                .foregroundColor(Theme.neonCyan)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.backgroundTertiary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.neonCyan.opacity(0.2), lineWidth: 1)
        )
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .neonGlow(color, radius: 6)
            
            Text(value)
                .font(.synthwave(16, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.synthwave(10))
                .foregroundColor(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.backgroundSecondary)
        .cornerRadius(8)
    }
}

#Preview {
    let rom = ROM(
        id: "test",
        name: "Super Mario Bros. 3",
        path: URL(fileURLWithPath: "/test/game.nes"),
        fileExtension: ".nes",
        platform: "NES",
        fileSize: 524288,
        dateAdded: Date()
    )
    
    return StatsView(rom: rom)
        .frame(width: 400)
        .padding()
        .background(Theme.background)
}

