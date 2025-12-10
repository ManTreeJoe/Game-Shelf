import SwiftUI

struct ArtworkFetcherView: View {
    @ObservedObject var fetcher: BatchArtworkFetcher
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FETCHING ARTWORK")
                        .font(.synthwaveDisplay(20))
                        .foregroundColor(.white)
                    
                    Text("Downloading cover art from LibRetro")
                        .font(.synthwaveBody(13))
                        .foregroundColor(Theme.textSecondary)
                }
                
                Spacer()
                
                if !fetcher.isRunning {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Theme.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .background(Theme.backgroundSecondary)
            
            Divider()
                .background(Theme.textTertiary.opacity(0.3))
            
            // Content
            VStack(spacing: 24) {
                // Progress ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Theme.backgroundTertiary, lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    // Progress ring
                    Circle()
                        .trim(from: 0, to: fetcher.progress)
                        .stroke(
                            LinearGradient(
                                colors: [Theme.neonPink, Theme.neonCyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: fetcher.progress)
                    
                    // Percentage
                    VStack(spacing: 2) {
                        Text("\(Int(fetcher.progress * 100))%")
                            .font(.synthwaveDisplay(28))
                            .foregroundColor(.white)
                        
                        if fetcher.isRunning {
                            Text("fetching")
                                .font(.synthwave(10))
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                }
                .neonGlow(Theme.neonPink, radius: 10, isActive: fetcher.isRunning)
                
                // Current game
                if fetcher.isRunning {
                    VStack(spacing: 4) {
                        Text("Current:")
                            .font(.synthwave(11))
                            .foregroundColor(Theme.textTertiary)
                        
                        Text(fetcher.currentGame)
                            .font(.synthwaveBody(14))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(maxWidth: 300)
                    }
                    .padding(.horizontal)
                }
                
                // Stats
                HStack(spacing: 32) {
                    StatBadge(
                        value: "\(fetcher.successCount)",
                        label: "Found",
                        color: Theme.neonGreen
                    )
                    
                    StatBadge(
                        value: "\(fetcher.failCount)",
                        label: "Not Found",
                        color: Theme.warmAmber
                    )
                }
                
                // Completion message
                if !fetcher.isRunning && fetcher.progress >= 1.0 {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Theme.neonGreen)
                            .neonGlow(Theme.neonGreen, radius: 8)
                        
                        Text("Complete!")
                            .font(.synthwaveDisplay(18))
                            .foregroundColor(.white)
                        
                        Text("Found artwork for \(fetcher.successCount) games")
                            .font(.synthwave(13))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(24)
            
            Divider()
                .background(Theme.textTertiary.opacity(0.3))
            
            // Actions
            HStack {
                if fetcher.isRunning {
                    Button {
                        fetcher.cancel()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "stop.fill")
                            Text("Cancel")
                        }
                        .font(.synthwave(14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Theme.backgroundTertiary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.synthwave(14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Theme.neonPinkGradient)
                            .cornerRadius(8)
                            .neonGlow(Theme.neonPink, radius: 6)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
            }
            .padding(16)
            .background(Theme.backgroundSecondary)
        }
        .frame(width: 400, height: 420)
        .background(Theme.background)
    }
}

struct StatBadge: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.synthwaveDisplay(24))
                .foregroundColor(color)
                .neonGlow(color, radius: 4)
            
            Text(label)
                .font(.synthwave(11))
                .foregroundColor(Theme.textTertiary)
        }
        .frame(width: 80)
    }
}

#Preview {
    let fetcher = BatchArtworkFetcher()
    
    return ArtworkFetcherView(fetcher: fetcher)
}

