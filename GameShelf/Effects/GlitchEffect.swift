import SwiftUI

// MARK: - VHS Glitch Effect

struct VHSGlitchEffect: ViewModifier {
    let isActive: Bool
    let intensity: CGFloat
    
    @State private var offset1: CGFloat = 0
    @State private var offset2: CGFloat = 0
    @State private var sliceOffset: CGFloat = 0
    @State private var showSlice = false
    
    func body(content: Content) -> some View {
        TimelineView(.animation(minimumInterval: 0.05)) { timeline in
            ZStack {
                // Red channel
                content
                    .colorMultiply(Color(red: 1, green: 0.2, blue: 0.2))
                    .opacity(isActive ? 0.6 : 0)
                    .offset(x: isActive ? offset1 : 0)
                    .blendMode(.screen)
                
                // Blue channel
                content
                    .colorMultiply(Color(red: 0.2, green: 0.2, blue: 1))
                    .opacity(isActive ? 0.6 : 0)
                    .offset(x: isActive ? offset2 : 0)
                    .blendMode(.screen)
                
                // Main content
                content
                
                // Horizontal slice glitch
                if showSlice && isActive {
                    content
                        .clipShape(
                            Rectangle()
                                .offset(y: sliceOffset)
                                .size(width: 1000, height: 10)
                        )
                        .offset(x: CGFloat.random(in: -10...10))
                }
            }
            .onChange(of: timeline.date) { _, _ in
                if isActive {
                    updateGlitch()
                }
            }
        }
    }
    
    private func updateGlitch() {
        // Random RGB split
        if Bool.random() {
            offset1 = CGFloat.random(in: -intensity...intensity)
            offset2 = CGFloat.random(in: -intensity...intensity)
        } else {
            offset1 = 0
            offset2 = 0
        }
        
        // Random slice
        showSlice = Double.random(in: 0...1) < 0.1
        sliceOffset = CGFloat.random(in: -50...50)
    }
}

extension View {
    func vhsGlitch(isActive: Bool, intensity: CGFloat = 3) -> some View {
        modifier(VHSGlitchEffect(isActive: isActive, intensity: intensity))
    }
}

// MARK: - Screen Flicker Effect

struct ScreenFlicker: ViewModifier {
    let isActive: Bool
    @State private var opacity: CGFloat = 1
    
    func body(content: Content) -> some View {
        content
            .opacity(isActive ? opacity : 1)
            .onAppear {
                if isActive {
                    startFlicker()
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    startFlicker()
                }
            }
    }
    
    private func startFlicker() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if !isActive {
                timer.invalidate()
                opacity = 1
                return
            }
            
            // Random flicker
            if Double.random(in: 0...1) < 0.05 {
                opacity = CGFloat.random(in: 0.85...1.0)
            } else {
                opacity = 1
            }
        }
    }
}

extension View {
    func screenFlicker(isActive: Bool) -> some View {
        modifier(ScreenFlicker(isActive: isActive))
    }
}

// MARK: - Tracking Lines Effect (VHS-style horizontal distortion)

struct TrackingLines: View {
    @State private var linePositions: [CGFloat] = []
    @State private var phase: CGFloat = 0
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.1)) { timeline in
            GeometryReader { geo in
                Canvas { context, size in
                    // Draw tracking lines
                    for position in linePositions {
                        let adjustedY = (position + phase).truncatingRemainder(dividingBy: size.height)
                        
                        // Main distortion line
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: adjustedY))
                        path.addLine(to: CGPoint(x: size.width, y: adjustedY))
                        
                        context.stroke(
                            path,
                            with: .linearGradient(
                                Gradient(colors: [
                                    .clear,
                                    Theme.neonCyan.opacity(0.2),
                                    Theme.neonPink.opacity(0.3),
                                    Theme.neonCyan.opacity(0.2),
                                    .clear
                                ]),
                                startPoint: CGPoint(x: 0, y: adjustedY),
                                endPoint: CGPoint(x: size.width, y: adjustedY)
                            ),
                            lineWidth: 2
                        )
                    }
                }
                .onAppear {
                    // Initialize random line positions
                    linePositions = (0..<3).map { _ in CGFloat.random(in: 0...geo.size.height) }
                    
                    // Animate lines moving down
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        phase = geo.size.height
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Chromatic Aberration Effect

struct ChromaticAberration: ViewModifier {
    let amount: CGFloat
    let isActive: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            if isActive && amount > 0 {
                content
                    .colorMultiply(.red)
                    .opacity(0.4)
                    .offset(x: -amount, y: -amount / 2)
                    .blendMode(.screen)
                
                content
                    .colorMultiply(.green)
                    .opacity(0.4)
                    .blendMode(.screen)
                
                content
                    .colorMultiply(.blue)
                    .opacity(0.4)
                    .offset(x: amount, y: amount / 2)
                    .blendMode(.screen)
            }
            
            content
        }
    }
}

extension View {
    func chromaticAberration(amount: CGFloat = 2, isActive: Bool = true) -> some View {
        modifier(ChromaticAberration(amount: amount, isActive: isActive))
    }
}

// MARK: - Static Noise Overlay (TV static)

struct StaticNoise: View {
    let intensity: CGFloat
    
    init(intensity: CGFloat = 0.03) {
        self.intensity = intensity
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { _ in
            Canvas { context, size in
                for _ in 0..<Int(size.width * size.height * intensity / 10) {
                    let x = CGFloat.random(in: 0..<size.width)
                    let y = CGFloat.random(in: 0..<size.height)
                    let brightness = CGFloat.random(in: 0...1)
                    
                    context.fill(
                        Path(CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(.white.opacity(brightness * intensity))
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Glitch Block Effect

struct GlitchBlocks: View {
    let isActive: Bool
    @State private var blocks: [(rect: CGRect, color: Color)] = []
    
    var body: some View {
        GeometryReader { geo in
            if isActive {
                TimelineView(.animation(minimumInterval: 0.1)) { _ in
                    Canvas { context, size in
                        for block in blocks {
                            context.fill(Path(block.rect), with: .color(block.color))
                        }
                    }
                    .onChange(of: isActive) { _, _ in
                        generateBlocks(in: geo.size)
                    }
                    .onAppear {
                        generateBlocks(in: geo.size)
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
    
    private func generateBlocks(in size: CGSize) {
        guard isActive else {
            blocks = []
            return
        }
        
        let count = Int.random(in: 1...5)
        blocks = (0..<count).map { _ in
            let width = CGFloat.random(in: 20...100)
            let height = CGFloat.random(in: 2...8)
            let x = CGFloat.random(in: 0..<size.width - width)
            let y = CGFloat.random(in: 0..<size.height - height)
            
            let colors: [Color] = [Theme.neonPink, Theme.neonCyan, .white]
            let color = colors.randomElement()!.opacity(Double.random(in: 0.2...0.5))
            
            return (CGRect(x: x, y: y, width: width, height: height), color)
        }
    }
}

// MARK: - Scanline Sweep Effect

struct ScanlineSweep: View {
    @State private var position: CGFloat = -50
    let duration: Double
    let color: Color
    
    init(duration: Double = 3, color: Color = Theme.neonCyan) {
        self.duration = duration
        self.color = color
    }
    
    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            color.opacity(0.1),
                            color.opacity(0.3),
                            color.opacity(0.1),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 50)
                .offset(y: position)
                .onAppear {
                    withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                        position = geo.size.height + 50
                    }
                }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Combined VHS Effect Overlay

struct VHSOverlay: View {
    let isActive: Bool
    
    var body: some View {
        ZStack {
            // Scanlines
            ScanlineOverlay(spacing: 2, opacity: 0.05)
            
            // Tracking lines
            if isActive {
                TrackingLines()
                    .opacity(0.5)
            }
            
            // Static noise
            StaticNoise(intensity: isActive ? 0.02 : 0.01)
            
            // Occasional scanline sweep
            ScanlineSweep(duration: 4, color: Theme.neonCyan)
                .opacity(0.3)
        }
        .allowsHitTesting(false)
    }
}

#Preview("Glitch Effects") {
    ZStack {
        Theme.backgroundGradient
        
        VStack(spacing: 20) {
            Text("VHS EFFECT")
                .font(.synthwaveDisplay(32))
                .foregroundStyle(Theme.synthwaveGradient)
                .vhsGlitch(isActive: true, intensity: 4)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Theme.neonPink.opacity(0.3))
                .frame(width: 200, height: 100)
                .overlay(
                    Text("GLITCH")
                        .font(.synthwave(16, weight: .bold))
                        .foregroundColor(.white)
                )
                .chromaticAberration(amount: 3)
        }
        
        VHSOverlay(isActive: true)
    }
    .frame(width: 400, height: 300)
}

