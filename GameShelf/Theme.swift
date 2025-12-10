import SwiftUI

// MARK: - Synthwave Color Palette

struct Theme {
    // Core colors
    static let background = Color(hex: "0a0a0f")
    static let backgroundSecondary = Color(hex: "12121a")
    static let backgroundTertiary = Color(hex: "1a1a24")
    
    // Neon accents
    static let neonPink = Color(hex: "ff2a6d")
    static let neonCyan = Color(hex: "05d9e8")
    static let neonPurple = Color(hex: "7b2cbf")
    static let neonBlue = Color(hex: "01012b")
    static let warmAmber = Color(hex: "f9a825")
    static let neonGreen = Color(hex: "39ff14")
    
    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.4)
    
    // Gradients
    static let backgroundGradient = LinearGradient(
        colors: [
            Color(hex: "0a0a0f"),
            Color(hex: "0f0f1a"),
            Color(hex: "12121a"),
            Color(hex: "0a0a0f")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let neonPinkGradient = LinearGradient(
        colors: [neonPink, Color(hex: "d4145a")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let neonCyanGradient = LinearGradient(
        colors: [neonCyan, Color(hex: "00b4d8")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let synthwaveGradient = LinearGradient(
        colors: [neonPink, neonPurple, neonCyan],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let sunsetGradient = LinearGradient(
        colors: [
            Color(hex: "ff2a6d"),
            Color(hex: "ff6b2a"),
            Color(hex: "f9a825")
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Platform-specific colors (neon versions)
    static func platformColor(for platform: String) -> Color {
        switch platform {
        case "NES": return Color(hex: "ff2a6d")
        case "SNES": return Color(hex: "9d4edd")
        case "Game Boy": return Color(hex: "39ff14")
        case "Game Boy Color": return Color(hex: "7b2cbf")
        case "Game Boy Advance": return Color(hex: "5a5eff")
        case "Nintendo 64": return Color(hex: "00ff87")
        case "GameCube": return Color(hex: "9d4edd")
        case "Wii": return Color(hex: "05d9e8")
        case "Nintendo DS": return Color(hex: "888888")
        case "Nintendo 3DS": return Color(hex: "ff2a6d")
        case "Nintendo Switch": return Color(hex: "ff2a6d")
        case "PlayStation", "PlayStation 2": return Color(hex: "0077ff")
        case "PSP": return Color(hex: "05d9e8")
        case "Sega Genesis", "Sega Master System": return Color(hex: "05d9e8")
        case "Dreamcast": return Color(hex: "ff6b2a")
        case "Steam": return Color(hex: "66c0f4")  // Steam's light blue
        default: return neonPink
        }
    }
    
    // Glow effect colors
    static func glowColor(for platform: String) -> Color {
        platformColor(for: platform).opacity(0.6)
    }
}

// MARK: - Custom Font Extension

extension Font {
    static func synthwave(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        // Use SF Mono for that retro-tech feel, or system font with monospace design
        .system(size: size, weight: weight, design: .monospaced)
    }
    
    static func synthwaveDisplay(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }
    
    static func synthwaveBody(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }
}

// MARK: - Glow Effect Modifier

struct NeonGlow: ViewModifier {
    let color: Color
    let radius: CGFloat
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .shadow(color: isActive ? color.opacity(0.7) : .clear, radius: radius / 2)
            .shadow(color: isActive ? color.opacity(0.5) : .clear, radius: radius)
            .shadow(color: isActive ? color.opacity(0.3) : .clear, radius: radius * 1.5)
    }
}

extension View {
    func neonGlow(_ color: Color, radius: CGFloat = 12, isActive: Bool = true) -> some View {
        modifier(NeonGlow(color: color, radius: radius, isActive: isActive))
    }
}

// MARK: - CRT Vignette Effect

struct CRTVignette: ViewModifier {
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RadialGradient(
                    colors: [
                        .clear,
                        .clear,
                        Color.black.opacity(intensity * 0.3),
                        Color.black.opacity(intensity * 0.6)
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 300
                )
            )
    }
}

extension View {
    func crtVignette(intensity: CGFloat = 1.0) -> some View {
        modifier(CRTVignette(intensity: intensity))
    }
}

// MARK: - Noise/Grain Texture Overlay

struct NoiseOverlay: View {
    let opacity: CGFloat
    @State private var phase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1)) { timeline in
            Canvas { context, size in
                // Simple noise pattern
                for _ in 0..<Int(size.width * size.height / 100) {
                    let x = CGFloat.random(in: 0..<size.width)
                    let y = CGFloat.random(in: 0..<size.height)
                    let brightness = CGFloat.random(in: 0...1)
                    
                    context.fill(
                        Path(CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(.white.opacity(brightness * opacity))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Scanline Overlay

struct ScanlineOverlay: View {
    let spacing: CGFloat
    let opacity: CGFloat
    
    init(spacing: CGFloat = 2, opacity: CGFloat = 0.08) {
        self.spacing = spacing
        self.opacity = opacity
    }
    
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                for y in stride(from: 0, to: size.height, by: spacing) {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    context.fill(Path(rect), with: .color(.black.opacity(opacity)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Grid Background

struct RetroGridBackground: View {
    let lineColor: Color
    let lineOpacity: CGFloat
    
    init(lineColor: Color = Theme.neonPink, lineOpacity: CGFloat = 0.1) {
        self.lineColor = lineColor
        self.lineOpacity = lineOpacity
    }
    
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let gridSize: CGFloat = 40
                
                // Vertical lines
                for x in stride(from: 0, to: size.width, by: gridSize) {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: size.height))
                    context.stroke(path, with: .color(lineColor.opacity(lineOpacity)), lineWidth: 0.5)
                }
                
                // Horizontal lines - with perspective effect (closer together at top)
                var currentY: CGFloat = size.height
                var spacing: CGFloat = gridSize
                while currentY > 0 {
                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: currentY))
                    path.addLine(to: CGPoint(x: size.width, y: currentY))
                    context.stroke(path, with: .color(lineColor.opacity(lineOpacity)), lineWidth: 0.5)
                    currentY -= spacing
                    spacing = max(spacing * 0.95, 10) // Lines get closer at top
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Animated Gradient Background

struct AnimatedSynthwaveBackground: View {
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 10) / 10
            
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [
                        Color(hex: "0a0a0f"),
                        Color(hex: "0f0f1a"),
                        Color(hex: "12121a")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Subtle color shift overlay
                RadialGradient(
                    colors: [
                        Theme.neonPink.opacity(0.05 + sin(phase * .pi * 2) * 0.02),
                        Theme.neonPurple.opacity(0.03),
                        .clear
                    ],
                    center: UnitPoint(x: 0.3 + cos(phase * .pi * 2) * 0.1, y: 0.2),
                    startRadius: 100,
                    endRadius: 600
                )
                
                RadialGradient(
                    colors: [
                        Theme.neonCyan.opacity(0.04 + cos(phase * .pi * 2) * 0.02),
                        .clear
                    ],
                    center: UnitPoint(x: 0.7 + sin(phase * .pi * 2) * 0.1, y: 0.8),
                    startRadius: 50,
                    endRadius: 400
                )
                
                // Grid
                RetroGridBackground(lineColor: Theme.neonPink, lineOpacity: 0.05)
                
                // Scanlines
                ScanlineOverlay(spacing: 3, opacity: 0.04)
            }
        }
    }
}

// MARK: - Card Background with CRT Effect

struct CRTCardBackground: View {
    let platformColor: Color
    @State private var noisePhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    platformColor.opacity(0.3),
                    platformColor.opacity(0.1),
                    Theme.backgroundTertiary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle pattern
            GeometryReader { geo in
                Canvas { context, size in
                    let patternSize: CGFloat = 20
                    for x in stride(from: 0, to: size.width, by: patternSize) {
                        for y in stride(from: 0, to: size.height, by: patternSize) {
                            if Int((x + y) / patternSize) % 2 == 0 {
                                let rect = CGRect(x: x, y: y, width: patternSize, height: patternSize)
                                context.fill(Path(rect), with: .color(.white.opacity(0.015)))
                            }
                        }
                    }
                }
            }
            
            // CRT vignette
            RadialGradient(
                colors: [
                    .clear,
                    .clear,
                    Color.black.opacity(0.2),
                    Color.black.opacity(0.4)
                ],
                center: .center,
                startRadius: 30,
                endRadius: 150
            )
            
            // Scanlines
            ScanlineOverlay(spacing: 2, opacity: 0.06)
        }
    }
}

#Preview("Theme Preview") {
    ZStack {
        AnimatedSynthwaveBackground()
        
        VStack(spacing: 20) {
            Text("GAME SHELF")
                .font(.synthwaveDisplay(32))
                .foregroundStyle(Theme.synthwaveGradient)
                .neonGlow(Theme.neonPink, radius: 15)
            
            HStack(spacing: 12) {
                ForEach(["NES", "SNES", "N64", "PS1"], id: \.self) { platform in
                    Text(platform)
                        .font(.synthwave(12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Theme.platformColor(for: platform))
                        .cornerRadius(6)
                        .neonGlow(Theme.platformColor(for: platform), radius: 8)
                }
            }
        }
    }
    .frame(width: 600, height: 400)
}

