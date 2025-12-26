/**
 * Animations Premium pour EdgeCoach
 * Phase 3.1 : Synergy Ring
 * Phase 3.2 : Liquid Fill Animation
 * Phase 4.2 : Drag & Drop avec haptique
 */

import SwiftUI

// MARK: - Phase 3.1 : Synergy Ring

/// Indicateur circulaire "vivant" avec animation de respiration
/// Affiche l'état de forme et la charge d'entraînement
struct SynergyRingView: View {
    @EnvironmentObject var themeManager: ThemeManager

    /// Valeur entre 0 et 1 représentant le niveau de synergie/forme
    let value: Double
    /// Couleur dynamique basée sur la fraîcheur (optionnel, sinon calculée automatiquement)
    var overrideColor: Color?
    /// Taille du ring
    var size: CGFloat = 120
    /// Épaisseur du trait
    var lineWidth: CGFloat = 12
    /// Active l'animation de respiration
    var breathingEnabled: Bool = true

    @State private var breatheScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var rotation: Double = 0

    private var ringColor: Color {
        if let override = overrideColor {
            return override
        }
        // Couleur dynamique selon la valeur (fraîcheur/charge)
        if value < 0.3 {
            return themeManager.errorColor // Fatigue
        } else if value < 0.6 {
            return themeManager.warningColor // Attention
        } else {
            return themeManager.successColor // Bonne forme
        }
    }

    var body: some View {
        ZStack {
            // Glow effect (halo lumineux)
            Circle()
                .stroke(ringColor.opacity(glowOpacity), lineWidth: lineWidth + 8)
                .blur(radius: 8)
                .scaleEffect(breatheScale)

            // Background ring
            Circle()
                .stroke(themeManager.elevatedColor, lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: CGFloat(value))
                .stroke(
                    AngularGradient(
                        colors: [ringColor.opacity(0.6), ringColor, ringColor.opacity(0.8)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .scaleEffect(breatheScale)

            // Particle effect at the end of progress
            if value > 0.05 {
                Circle()
                    .fill(ringColor)
                    .frame(width: lineWidth + 4, height: lineWidth + 4)
                    .shadow(color: ringColor, radius: 6)
                    .offset(y: -size / 2 + lineWidth / 2)
                    .rotationEffect(.degrees(360 * value - 90))
                    .scaleEffect(breatheScale * 1.1)
            }

            // Center content
            VStack(spacing: 4) {
                Text("\(Int(value * 100))")
                    .font(.system(size: size * 0.25, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.textPrimary)

                Text("Synergie")
                    .font(.system(size: size * 0.1, weight: .medium))
                    .foregroundColor(themeManager.textSecondary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if breathingEnabled {
                startBreathingAnimation()
            }
        }
    }

    private func startBreathingAnimation() {
        // Animation de respiration continue
        withAnimation(
            .easeInOut(duration: 2.5)
            .repeatForever(autoreverses: true)
        ) {
            breatheScale = 1.03
            glowOpacity = 0.5
        }

        // Rotation subtile du gradient
        withAnimation(
            .linear(duration: 20)
            .repeatForever(autoreverses: false)
        ) {
            rotation = 360
        }
    }
}

// MARK: - Phase 3.2 : Liquid Fill Animation

/// Animation de remplissage fluide pour indiquer la complétion d'une séance
struct LiquidFillView: View {
    @EnvironmentObject var themeManager: ThemeManager

    /// Progression entre 0 et 1
    let progress: Double
    /// Couleur du liquide
    var liquidColor: Color?
    /// Taille du conteneur
    var size: CGFloat = 80
    /// Animation activée
    var animated: Bool = true

    @State private var waveOffset: CGFloat = 0
    @State private var phase: CGFloat = 0

    private var fillColor: Color {
        liquidColor ?? themeManager.accentColor
    }

    var body: some View {
        ZStack {
            // Container circle
            Circle()
                .stroke(themeManager.borderColor, lineWidth: 2)

            // Liquid fill with wave effect
            LiquidWaveShape(progress: progress, waveHeight: 8, phase: phase)
                .fill(
                    LinearGradient(
                        colors: [fillColor, fillColor.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(Circle())

            // Shine effect
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(0.9)
                .offset(x: -size * 0.1, y: -size * 0.1)
                .clipShape(Circle())

            // Percentage text
            if progress > 0.1 {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if animated {
                startWaveAnimation()
            }
        }
    }

    private func startWaveAnimation() {
        withAnimation(
            .linear(duration: 2)
            .repeatForever(autoreverses: false)
        ) {
            phase = .pi * 2
        }
    }
}

/// Shape pour l'effet de vague liquide
struct LiquidWaveShape: Shape {
    var progress: Double
    var waveHeight: CGFloat
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let waterLevel = rect.height * (1 - progress)
        let width = rect.width
        let midWidth = width / 2

        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: waterLevel))

        // Wave curve
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / midWidth
            let sine = sin(relativeX * .pi * 2 + phase)
            let y = waterLevel + sine * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: rect.height))
        path.closeSubpath()

        return path
    }
}

// MARK: - Completion Celebration Animation

/// Animation de célébration lors de la complétion d'une séance
struct CompletionCelebrationView: View {
    @EnvironmentObject var themeManager: ThemeManager

    let isShowing: Bool
    var onComplete: (() -> Void)?

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var checkScale: CGFloat = 0
    @State private var particlesVisible = false

    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(opacity * 0.4)
                .ignoresSafeArea()

            // Expanding rings
            ForEach(0..<3) { index in
                Circle()
                    .stroke(themeManager.successColor.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                    .scaleEffect(ringScale + CGFloat(index) * 0.3)
                    .opacity(opacity)
            }

            // Main circle with liquid fill
            ZStack {
                Circle()
                    .fill(themeManager.successColor)
                    .frame(width: 120, height: 120)
                    .scaleEffect(scale)

                // Checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(checkScale)
            }

            // Particles
            if particlesVisible {
                ForEach(0..<12) { index in
                    ParticleView(
                        color: themeManager.successColor,
                        angle: Double(index) * 30,
                        delay: Double(index) * 0.05
                    )
                }
            }
        }
        .onChange(of: isShowing) { newValue in
            if newValue {
                playAnimation()
            } else {
                resetAnimation()
            }
        }
    }

    private func playAnimation() {
        HapticManager.shared.playSuccess()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            scale = 1.0
            opacity = 1.0
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.5).delay(0.1)) {
            ringScale = 1.5
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.2)) {
            checkScale = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            particlesVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                opacity = 0
                scale = 1.2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onComplete?()
            }
        }
    }

    private func resetAnimation() {
        scale = 0.5
        opacity = 0
        ringScale = 0.8
        checkScale = 0
        particlesVisible = false
    }
}

/// Particule individuelle pour l'animation de célébration
struct ParticleView: View {
    let color: Color
    let angle: Double
    let delay: Double

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 1

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(x: offset * cos(angle * .pi / 180), y: offset * sin(angle * .pi / 180))
            .onAppear {
                withAnimation(.easeOut(duration: 0.8).delay(delay)) {
                    offset = 100
                    opacity = 0
                    scale = 0.3
                }
            }
    }
}

// MARK: - Phase 4.2 : Drag & Drop Components

/// Wrapper pour rendre une vue draggable avec feedback haptique
struct DraggableSessionCard<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager

    let session: PlannedSession
    let content: Content
    var onDragStarted: (() -> Void)?
    var onDragEnded: (() -> Void)?

    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero

    init(session: PlannedSession, onDragStarted: (() -> Void)? = nil, onDragEnded: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.session = session
        self.onDragStarted = onDragStarted
        self.onDragEnded = onDragEnded
        self.content = content()
    }

    var body: some View {
        content
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .shadow(color: isDragging ? themeManager.accentColor.opacity(0.3) : .clear, radius: 10)
            .offset(dragOffset)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
            .onDrag {
                isDragging = true
                HapticManager.shared.playImpact()
                onDragStarted?()
                return NSItemProvider(object: session.id as NSString)
            }
            .onChange(of: isDragging) { newValue in
                if !newValue {
                    HapticManager.shared.playTap()
                    onDragEnded?()
                }
            }
    }
}

/// Zone de drop pour les séances avec animation
struct SessionDropZone: View {
    @EnvironmentObject var themeManager: ThemeManager

    let date: Date
    let isTargeted: Bool
    var onDrop: ((PlannedSession) -> Void)?

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        RoundedRectangle(cornerRadius: ECRadius.md)
            .strokeBorder(
                isTargeted ? themeManager.accentColor : themeManager.borderColor,
                style: StrokeStyle(lineWidth: isTargeted ? 2 : 1, dash: [8])
            )
            .background(
                RoundedRectangle(cornerRadius: ECRadius.md)
                    .fill(isTargeted ? themeManager.accentColorLight : Color.clear)
            )
            .scaleEffect(isTargeted ? pulseScale : 1.0)
            .animation(.spring(response: 0.3), value: isTargeted)
            .onChange(of: isTargeted) { newValue in
                if newValue {
                    HapticManager.shared.playSelection()
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        pulseScale = 1.02
                    }
                } else {
                    pulseScale = 1.0
                }
            }
    }
}

// MARK: - Staggered Animation Modifier

/// Modificateur pour créer des animations en cascade
struct StaggeredAnimationModifier: ViewModifier {
    let index: Int
    let totalCount: Int
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                let delay = Double(index) * 0.05
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension View {
    /// Applique une animation d'entrée en cascade
    func staggeredAnimation(index: Int, totalCount: Int) -> some View {
        modifier(StaggeredAnimationModifier(index: index, totalCount: totalCount))
    }
}

// MARK: - Previews

#Preview("Synergy Ring") {
    VStack(spacing: 40) {
        SynergyRingView(value: 0.75)
        SynergyRingView(value: 0.45, size: 80)
        SynergyRingView(value: 0.2, size: 60)
    }
    .padding()
    .background(Color.black)
    .environmentObject(ThemeManager.shared)
}

#Preview("Liquid Fill") {
    HStack(spacing: 20) {
        LiquidFillView(progress: 0.3)
        LiquidFillView(progress: 0.6)
        LiquidFillView(progress: 0.9)
    }
    .padding()
    .background(Color.black)
    .environmentObject(ThemeManager.shared)
}
