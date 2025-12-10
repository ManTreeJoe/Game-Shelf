import SwiftUI

// MARK: - Animation Presets

extension Animation {
    /// Snappy spring animation for hover states
    static var snappy: Animation {
        .spring(response: 0.3, dampingFraction: 0.7)
    }
    
    /// Bouncy spring animation for button presses
    static var bouncy: Animation {
        .spring(response: 0.25, dampingFraction: 0.6)
    }
    
    /// Smooth spring for larger movements
    static var smooth: Animation {
        .spring(response: 0.5, dampingFraction: 0.8)
    }
    
    /// Quick animation for micro-interactions
    static var quick: Animation {
        .easeOut(duration: 0.15)
    }
    
    /// Stagger animation with custom delay
    static func staggered(index: Int, baseDelay: Double = 0, stagger: Double = 0.03) -> Animation {
        .spring(response: 0.5, dampingFraction: 0.7).delay(baseDelay + Double(index) * stagger)
    }
}

// MARK: - Appear Animation Modifier

struct AppearAnimation: ViewModifier {
    let delay: Double
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .scaleEffect(hasAppeared ? 1 : 0.95)
            .onAppear {
                withAnimation(.smooth.delay(delay)) {
                    hasAppeared = true
                }
            }
    }
}

extension View {
    func appearAnimation(delay: Double = 0) -> some View {
        modifier(AppearAnimation(delay: delay))
    }
}

// MARK: - Staggered Grid Animation

struct StaggeredAppear: ViewModifier {
    let index: Int
    let baseDelay: Double
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 30)
            .scaleEffect(hasAppeared ? 1 : 0.9)
            .onAppear {
                withAnimation(.staggered(index: index, baseDelay: baseDelay)) {
                    hasAppeared = true
                }
            }
    }
}

extension View {
    func staggeredAppear(index: Int, baseDelay: Double = 0.2) -> some View {
        modifier(StaggeredAppear(index: index, baseDelay: baseDelay))
    }
}

// MARK: - Hover Scale Effect

struct HoverScale: ViewModifier {
    let scale: CGFloat
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .animation(.snappy, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func hoverScale(_ scale: CGFloat = 1.05) -> some View {
        modifier(HoverScale(scale: scale))
    }
}

// MARK: - Press Effect

struct PressEffect: ViewModifier {
    let scale: CGFloat
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.bouncy, value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    func pressEffect(scale: CGFloat = 0.95) -> some View {
        modifier(PressEffect(scale: scale))
    }
}

// MARK: - Pulse Animation

struct PulseAnimation: ViewModifier {
    let color: Color
    let isActive: Bool
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color, lineWidth: isPulsing ? 0 : 2)
                    .scaleEffect(isPulsing ? 1.1 : 1.0)
                    .opacity(isPulsing ? 0 : 0.8)
            )
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.easeOut(duration: 0.4)) {
                        isPulsing = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        isPulsing = false
                    }
                }
            }
    }
}

extension View {
    func pulseOnChange(color: Color, isActive: Bool) -> some View {
        modifier(PulseAnimation(color: color, isActive: isActive))
    }
}

// MARK: - Shake Animation

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 5
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(
            translationX: amount * sin(animatableData * .pi * shakesPerUnit),
            y: 0
        ))
    }
}

extension View {
    func shake(trigger: Bool) -> some View {
        modifier(ShakeModifier(trigger: trigger))
    }
}

struct ShakeModifier: ViewModifier {
    let trigger: Bool
    @State private var shakeAmount: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .modifier(ShakeEffect(animatableData: shakeAmount))
            .onChange(of: trigger) { _, _ in
                withAnimation(.linear(duration: 0.4)) {
                    shakeAmount = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    shakeAmount = 0
                }
            }
    }
}

// MARK: - Glow Pulse Animation

struct GlowPulse: ViewModifier {
    let color: Color
    let isActive: Bool
    @State private var glowRadius: CGFloat = 5
    
    func body(content: Content) -> some View {
        content
            .shadow(color: isActive ? color.opacity(0.5) : .clear, radius: glowRadius)
            .shadow(color: isActive ? color.opacity(0.3) : .clear, radius: glowRadius * 1.5)
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        glowRadius = 15
                    }
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        glowRadius = 15
                    }
                } else {
                    glowRadius = 5
                }
            }
    }
}

extension View {
    func glowPulse(color: Color, isActive: Bool = true) -> some View {
        modifier(GlowPulse(color: color, isActive: isActive))
    }
}

// MARK: - Slide Transition

extension AnyTransition {
    static var slideFromBottom: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    static var slideFromTop: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
    
    static var scaleAndFade: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        )
    }
    
    static var glitchIn: AnyTransition {
        .asymmetric(
            insertion: .modifier(
                active: GlitchTransitionModifier(isActive: true),
                identity: GlitchTransitionModifier(isActive: false)
            ),
            removal: .opacity
        )
    }
}

struct GlitchTransitionModifier: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 0 : 1)
            .offset(x: isActive ? CGFloat.random(in: -5...5) : 0)
            .scaleEffect(isActive ? 0.98 : 1.0)
    }
}

// MARK: - Typewriter Text Animation

struct TypewriterText: View {
    let text: String
    let speed: Double
    @State private var displayedText = ""
    @State private var currentIndex = 0
    
    init(_ text: String, speed: Double = 0.05) {
        self.text = text
        self.speed = speed
    }
    
    var body: some View {
        Text(displayedText)
            .onAppear {
                typeNextCharacter()
            }
    }
    
    private func typeNextCharacter() {
        guard currentIndex < text.count else { return }
        
        let index = text.index(text.startIndex, offsetBy: currentIndex)
        displayedText += String(text[index])
        currentIndex += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + speed) {
            typeNextCharacter()
        }
    }
}

// MARK: - Loading Dots Animation

struct LoadingDots: View {
    @State private var dotCount = 0
    let color: Color
    
    init(color: Color = Theme.neonPink) {
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .opacity(dotCount > index ? 1 : 0.3)
                    .neonGlow(color, radius: 4, isActive: dotCount > index)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                withAnimation(.quick) {
                    dotCount = (dotCount + 1) % 4
                }
            }
        }
    }
}

#Preview("Animations") {
    VStack(spacing: 30) {
        Text("LOADING")
            .font(.synthwave(14, weight: .bold))
            .foregroundColor(.white)
        
        LoadingDots()
        
        TypewriterText("GAME SHELF", speed: 0.1)
            .font(.synthwaveDisplay(24))
            .foregroundStyle(Theme.synthwaveGradient)
    }
    .frame(width: 300, height: 200)
    .background(Theme.background)
}

