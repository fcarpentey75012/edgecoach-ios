/**
 * Système d'espacement EdgeCoach
 */

import SwiftUI

// MARK: - Spacing Constants

enum ECSpacing {
    static let none: CGFloat = 0
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Border Radius

enum ECRadius {
    static let none: CGFloat = 0
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let xxl: CGFloat = 24
    static let full: CGFloat = 9999
}

// MARK: - Card Style Modifier

struct ECCardStyle: ViewModifier {
    var padding: CGFloat = ECSpacing.md
    var cornerRadius: CGFloat = ECRadius.lg
    var shadowRadius: CGFloat = 8
    var shadowOpacity: Double = 0.06

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.ecCard)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: 2)
    }
}

extension View {
    func ecCard(
        padding: CGFloat = ECSpacing.md,
        cornerRadius: CGFloat = ECRadius.lg,
        shadowRadius: CGFloat = 8,
        shadowOpacity: Double = 0.06
    ) -> some View {
        modifier(ECCardStyle(
            padding: padding,
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius,
            shadowOpacity: shadowOpacity
        ))
    }
}

// MARK: - Button Styles

struct ECPrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            }
            configuration.label
        }
        .font(.ecButton)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: ECRadius.lg)
                .fill(isDisabled ? Color.ecGray300 : Color.ecPrimary)
        )
        .opacity(configuration.isPressed ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ECSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.ecButton)
            .foregroundColor(.ecPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: ECRadius.lg)
                    .stroke(Color.ecPrimary, lineWidth: 2)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

extension ButtonStyle where Self == ECPrimaryButtonStyle {
    static var ecPrimary: ECPrimaryButtonStyle { ECPrimaryButtonStyle() }
    static func ecPrimary(isLoading: Bool = false, isDisabled: Bool = false) -> ECPrimaryButtonStyle {
        ECPrimaryButtonStyle(isLoading: isLoading, isDisabled: isDisabled)
    }
}

extension ButtonStyle where Self == ECSecondaryButtonStyle {
    static var ecSecondary: ECSecondaryButtonStyle { ECSecondaryButtonStyle() }
}
