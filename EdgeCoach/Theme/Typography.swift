/**
 * Système typographique EdgeCoach
 */

import SwiftUI

// MARK: - Custom Font Styles

extension Font {
    // Headings
    static let ecH1 = Font.system(size: 32, weight: .bold)
    static let ecH2 = Font.system(size: 24, weight: .bold)
    static let ecH3 = Font.system(size: 20, weight: .semibold)
    static let ecH4 = Font.system(size: 18, weight: .semibold)

    // Body
    static let ecBody = Font.system(size: 16, weight: .regular)
    static let ecBodyMedium = Font.system(size: 16, weight: .medium)
    static let ecBodyBold = Font.system(size: 16, weight: .bold)

    // Label
    static let ecLabel = Font.system(size: 14, weight: .medium)
    static let ecLabelBold = Font.system(size: 14, weight: .bold)

    // Caption
    static let ecCaption = Font.system(size: 12, weight: .regular)
    static let ecCaptionMedium = Font.system(size: 12, weight: .medium)
    static let ecCaptionBold = Font.system(size: 12, weight: .bold)

    // Small
    static let ecSmall = Font.system(size: 10, weight: .regular)

    // Button
    static let ecButton = Font.system(size: 16, weight: .semibold)
    static let ecButtonSmall = Font.system(size: 14, weight: .semibold)
}

// MARK: - Text Styles View Modifier

struct ECTextStyle: ViewModifier {
    enum Style {
        case h1, h2, h3, h4
        case body, bodyMedium, bodyBold
        case label, labelBold
        case caption, captionMedium
        case small
        case button, buttonSmall
    }

    let style: Style
    var color: Color = .ecSecondary800

    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
    }

    private var font: Font {
        switch style {
        case .h1: return .ecH1
        case .h2: return .ecH2
        case .h3: return .ecH3
        case .h4: return .ecH4
        case .body: return .ecBody
        case .bodyMedium: return .ecBodyMedium
        case .bodyBold: return .ecBodyBold
        case .label: return .ecLabel
        case .labelBold: return .ecLabelBold
        case .caption: return .ecCaption
        case .captionMedium: return .ecCaptionMedium
        case .small: return .ecSmall
        case .button: return .ecButton
        case .buttonSmall: return .ecButtonSmall
        }
    }
}

extension View {
    func ecTextStyle(_ style: ECTextStyle.Style, color: Color = .ecSecondary800) -> some View {
        modifier(ECTextStyle(style: style, color: color))
    }
}
