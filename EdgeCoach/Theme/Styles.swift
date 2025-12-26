import SwiftUI

/// Style de bouton "Premium" avec effet de pression et retour haptique.
struct PremiumButtonStyle: ButtonStyle {
    let scale: CGFloat
    let haptic: Bool
    
    init(scale: CGFloat = 0.96, haptic: Bool = true) {
        self.scale = scale
        self.haptic = haptic
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed && haptic {
                    HapticManager.shared.playTap()
                }
            }
    }
}

extension ButtonStyle where Self == PremiumButtonStyle {
    static var premium: PremiumButtonStyle { PremiumButtonStyle() }
    static func premium(scale: CGFloat = 0.96) -> PremiumButtonStyle {
        PremiumButtonStyle(scale: scale)
    }
}

// MARK: - View Modifiers

struct PremiumCardModifier: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .fill(themeManager.cardColor)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
    }
}

extension View {
    func premiumCardStyle() -> some View {
        self.modifier(PremiumCardModifier())
    }

    /// Applique le style de bouton premium à une vue cliquable
    func premiumTapStyle(scale: CGFloat = 0.96) -> some View {
        self.buttonStyle(PremiumButtonStyle(scale: scale))
    }
}

// MARK: - ECButton - Bouton Premium Réutilisable

/// Bouton avec style premium, haptique et animation intégrés
struct ECButton<Label: View>: View {
    let action: () -> Void
    let hapticStyle: HapticStyle
    @ViewBuilder let label: () -> Label

    enum HapticStyle {
        case tap      // Interaction légère
        case impact   // Action significative
        case success  // Validation réussie
        case none     // Pas d'haptique
    }

    init(
        haptic: HapticStyle = .tap,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.hapticStyle = haptic
        self.action = action
        self.label = label
    }

    var body: some View {
        Button {
            playHaptic()
            action()
        } label: {
            label()
        }
        .buttonStyle(PremiumButtonStyle())
    }

    private func playHaptic() {
        switch hapticStyle {
        case .tap:
            HapticManager.shared.playTap()
        case .impact:
            HapticManager.shared.playImpact()
        case .success:
            HapticManager.shared.playSuccess()
        case .none:
            break
        }
    }
}

// MARK: - ECActionButton - Bouton d'Action Principal (CTA)

/// Bouton d'action principal avec style premium complet
struct ECActionButton: View {
    @EnvironmentObject var themeManager: ThemeManager

    let title: String
    let icon: String?
    let style: ActionStyle
    let isLoading: Bool
    let action: () -> Void

    enum ActionStyle {
        case primary    // Accent color, fond plein
        case secondary  // Bordure, fond transparent
        case destructive // Rouge, pour actions dangereuses
    }

    init(
        _ title: String,
        icon: String? = nil,
        style: ActionStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        ECButton(haptic: style == .destructive ? .impact : .tap, action: action) {
            HStack(spacing: ECSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.ecBodyMedium)
            }
            .foregroundColor(textColor)
            .padding(.horizontal, ECSpacing.lg)
            .padding(.vertical, ECSpacing.md)
            .frame(maxWidth: .infinity)
            .background(background)
            .cornerRadius(ECRadius.md)
        }
        .disabled(isLoading)
    }

    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return themeManager.accentColor
        case .destructive:
            return .white
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:
            themeManager.accentColor
        case .secondary:
            RoundedRectangle(cornerRadius: ECRadius.md)
                .stroke(themeManager.accentColor, lineWidth: 1.5)
                .background(Color.clear)
        case .destructive:
            Color.red
        }
    }
}

// MARK: - ECCardButton - Bouton en forme de Carte

/// Bouton en forme de carte avec ombre et animation premium
struct ECCardButton<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager

    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ECButton(haptic: .tap, action: action) {
            content()
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(themeManager.cardColor)
                .cornerRadius(ECRadius.lg)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - ECIconButton - Bouton Icône Compact

/// Petit bouton avec icône uniquement
struct ECIconButton: View {
    @EnvironmentObject var themeManager: ThemeManager

    let icon: String
    let size: CGFloat
    let color: Color?
    let action: () -> Void

    init(
        icon: String,
        size: CGFloat = 44,
        color: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.action = action
    }

    var body: some View {
        ECButton(haptic: .tap, action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(color ?? themeManager.accentColor)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill((color ?? themeManager.accentColor).opacity(0.1))
                )
        }
    }
}

// MARK: - Haptic View Modifier

/// Modificateur pour ajouter un feedback haptique à n'importe quelle action
struct HapticTapModifier: ViewModifier {
    let style: UIImpactFeedbackGenerator.FeedbackStyle

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    let generator = UIImpactFeedbackGenerator(style: style)
                    generator.impactOccurred()
                }
            )
    }
}

extension View {
    /// Ajoute un retour haptique au tap
    func hapticOnTap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.modifier(HapticTapModifier(style: style))
    }
}
