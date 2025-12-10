import SwiftUI

// MARK: - Enhanced Scanline Overlay

struct EnhancedScanlineOverlay: View {
    let spacing: CGFloat
    let opacity: CGFloat
    let animated: Bool
    
    @State private var phase: CGFloat = 0
    
    init(spacing: CGFloat = 2, opacity: CGFloat = 0.08, animated: Bool = false) {
        self.spacing = spacing
        self.opacity = opacity
        self.animated = animated
    }
    
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let adjustedPhase = animated ? phase : 0
                
                for y in stride(from: adjustedPhase, to: size.height, by: spacing) {
                    // Main scanline
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    context.fill(Path(rect), with: .color(.black.opacity(opacity)))
                    
                    // Subtle bright line above (CRT phosphor effect)
                    if y > 0 {
                        let brightRect = CGRect(x: 0, y: y - 1, width: size.width, height: 0.5)
                        context.fill(Path(brightRect), with: .color(.white.opacity(opacity * 0.3)))
                    }
                }
            }
            .onAppear {
                if animated {
                    withAnimation(.linear(duration: 0.1).repeatForever(autoreverses: false)) {
                        phase = spacing
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - CRT Screen Effect

struct CRTScreenEffect: ViewModifier {
    let curvature: CGFloat
    let vignetteIntensity: CGFloat
    let scanlineOpacity: CGFloat
    
    init(curvature: CGFloat = 0.02, vignetteIntensity: CGFloat = 0.4, scanlineOpacity: CGFloat = 0.08) {
        self.curvature = curvature
        self.vignetteIntensity = vignetteIntensity
        self.scanlineOpacity = scanlineOpacity
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    // Scanlines
                    EnhancedScanlineOverlay(spacing: 2, opacity: scanlineOpacity)
                    
                    // Vignette
                    RadialGradient(
                        colors: [
                            .clear,
                            .clear,
                            Color.black.opacity(vignetteIntensity * 0.5),
                            Color.black.opacity(vignetteIntensity)
                        ],
                        center: .center,
                        startRadius: 100,
                        endRadius: 500
                    )
                    
                    // Corner shadows for curved effect
                    cornerShadows
                    
                    // Subtle screen reflection
                    LinearGradient(
                        colors: [
                            .white.opacity(0.02),
                            .clear,
                            .clear,
                            .white.opacity(0.01)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
    }
    
    private var cornerShadows: some View {
        GeometryReader { geo in
            ZStack {
                // Top-left corner
                RadialGradient(
                    colors: [Color.black.opacity(0.3), .clear],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: min(geo.size.width, geo.size.height) * 0.3
                )
                
                // Top-right corner
                RadialGradient(
                    colors: [Color.black.opacity(0.3), .clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: min(geo.size.width, geo.size.height) * 0.3
                )
                
                // Bottom-left corner
                RadialGradient(
                    colors: [Color.black.opacity(0.3), .clear],
                    center: .bottomLeading,
                    startRadius: 0,
                    endRadius: min(geo.size.width, geo.size.height) * 0.3
                )
                
                // Bottom-right corner
                RadialGradient(
                    colors: [Color.black.opacity(0.3), .clear],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: min(geo.size.width, geo.size.height) * 0.3
                )
            }
        }
    }
}

extension View {
    func crtScreen(curvature: CGFloat = 0.02, vignetteIntensity: CGFloat = 0.4, scanlineOpacity: CGFloat = 0.08) -> some View {
        modifier(CRTScreenEffect(curvature: curvature, vignetteIntensity: vignetteIntensity, scanlineOpacity: scanlineOpacity))
    }
}

// MARK: - Phosphor Glow Effect

struct PhosphorGlow: ViewModifier {
    let color: Color
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        ZStack {
            // Outer glow
            content
                .blur(radius: 8)
                .opacity(intensity * 0.3)
            
            // Inner glow
            content
                .blur(radius: 2)
                .opacity(intensity * 0.5)
            
            // Sharp content
            content
        }
    }
}

extension View {
    func phosphorGlow(color: Color = .white, intensity: CGFloat = 1.0) -> some View {
        modifier(PhosphorGlow(color: color, intensity: intensity))
    }
}

// MARK: - Interlace Effect

struct InterlaceEffect: View {
    @State private var showEvenLines = true
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1/30)) { timeline in
            GeometryReader { geo in
                Canvas { context, size in
                    let lineHeight: CGFloat = 2
                    let startOffset: CGFloat = showEvenLines ? 0 : lineHeight
                    
                    for y in stride(from: startOffset, to: size.height, by: lineHeight * 2) {
                        let rect = CGRect(x: 0, y: y, width: size.width, height: lineHeight)
                        context.fill(Path(rect), with: .color(.black.opacity(0.15)))
                    }
                }
            }
            .onChange(of: timeline.date) { _, _ in
                showEvenLines.toggle()
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Bloom Effect

struct BloomEffect: ViewModifier {
    let radius: CGFloat
    let intensity: CGFloat
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: radius)
                .opacity(intensity)
                .blendMode(.screen)
            
            content
        }
    }
}

extension View {
    func bloom(radius: CGFloat = 10, intensity: CGFloat = 0.3) -> some View {
        modifier(BloomEffect(radius: radius, intensity: intensity))
    }
}

// MARK: - Full CRT Monitor Effect

struct CRTMonitorEffect: View {
    @State private var powerOn = false
    
    var body: some View {
        ZStack {
            // Scanlines
            EnhancedScanlineOverlay(spacing: 2.5, opacity: 0.06)
            
            // Subtle RGB subpixel pattern
            RGBSubpixelPattern()
                .opacity(0.02)
            
            // Vignette
            RadialGradient(
                colors: [
                    .clear,
                    .clear,
                    .clear,
                    Color.black.opacity(0.2),
                    Color.black.opacity(0.5)
                ],
                center: .center,
                startRadius: 200,
                endRadius: 600
            )
            
            // Screen curvature illusion (corner darkening)
            CRTCorners()
            
            // Subtle flicker
            Color.white
                .opacity(Double.random(in: 0...0.01))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - RGB Subpixel Pattern

struct RGBSubpixelPattern: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let pixelWidth: CGFloat = 3
                
                for x in stride(from: 0, to: size.width, by: pixelWidth * 3) {
                    for y in stride(from: 0, to: size.height, by: 3) {
                        // R
                        context.fill(
                            Path(CGRect(x: x, y: y, width: pixelWidth, height: 3)),
                            with: .color(.red.opacity(0.1))
                        )
                        // G
                        context.fill(
                            Path(CGRect(x: x + pixelWidth, y: y, width: pixelWidth, height: 3)),
                            with: .color(.green.opacity(0.1))
                        )
                        // B
                        context.fill(
                            Path(CGRect(x: x + pixelWidth * 2, y: y, width: pixelWidth, height: 3)),
                            with: .color(.blue.opacity(0.1))
                        )
                    }
                }
            }
        }
    }
}

// MARK: - CRT Corners

struct CRTCorners: View {
    var body: some View {
        GeometryReader { geo in
            let cornerSize = min(geo.size.width, geo.size.height) * 0.15
            
            ZStack {
                // Corners
                ForEach(0..<4, id: \.self) { corner in
                    let alignment: Alignment = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing][corner]
                    let center: UnitPoint = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing][corner]
                    
                    RadialGradient(
                        colors: [Color.black.opacity(0.4), .clear],
                        center: center,
                        startRadius: 0,
                        endRadius: cornerSize
                    )
                    .frame(width: cornerSize, height: cornerSize)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                }
            }
        }
    }
}

#Preview("Scanline Effects") {
    ZStack {
        Theme.backgroundGradient
        
        VStack(spacing: 20) {
            Text("CRT DISPLAY")
                .font(.synthwaveDisplay(28))
                .foregroundStyle(Theme.synthwaveGradient)
                .phosphorGlow(intensity: 0.8)
            
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.neonPink)
                .frame(width: 150, height: 40)
                .overlay(
                    Text("PLAY")
                        .font(.synthwave(14, weight: .bold))
                        .foregroundColor(.white)
                )
                .bloom(radius: 8, intensity: 0.4)
        }
        
        CRTMonitorEffect()
    }
    .frame(width: 400, height: 300)
}

