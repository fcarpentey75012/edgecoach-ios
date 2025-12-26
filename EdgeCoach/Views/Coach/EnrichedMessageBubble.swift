/**
 * EnrichedMessageBubble
 * Vue de message enrichi supportant les graphiques Vega-Lite inline
 *
 * Utilise ChartTagParser pour découper le contenu en segments
 * et VegaChartView pour rendre les graphiques aux emplacements [[CHART:id]]
 */

import SwiftUI

// MARK: - Enriched Message Bubble

struct EnrichedMessageBubble: View {
    @EnvironmentObject var themeManager: ThemeManager

    let message: ChatMessage
    var coachAvatar: String = "JF"
    var coachIcon: String = "trophy"
    var coachColor: Color = .blue

    // Hauteur par défaut des charts inline
    private let chartHeight: CGFloat = 200

    var body: some View {
        HStack(alignment: .top, spacing: ECSpacing.sm) {
            if message.isUser {
                Spacer(minLength: 40)
            } else {
                coachAvatarView
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: ECSpacing.xs) {
                if message.isLoading && message.content.isEmpty {
                    TypingIndicatorBubble(sportIcon: coachIcon, sportColor: coachColor)
                } else {
                    messageContent
                }

                if let timestamp = message.timestamp, !message.isLoading {
                    timestampView(timestamp)
                }
            }

            if !message.isUser {
                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Coach Avatar

    private var coachAvatarView: some View {
        ZStack {
            Circle()
                .fill(coachColor.opacity(0.15))
                .frame(width: 32, height: 32)

            Image(systemName: coachIcon)
                .font(.system(size: 16))
                .foregroundColor(coachColor)
        }
    }

    // MARK: - Message Content

    @ViewBuilder
    private var messageContent: some View {
        let segments = ChartTagParser.parse(message.content)
        let hasChartTags = segments.contains(where: { $0.isChart })

        if hasChartTags {
            // Message avec charts inline (même si les specs ne sont pas encore disponibles)
            // Affichera les charts disponibles ou des placeholders pour les manquants
            enrichedContentView(segments: segments)
        } else {
            // Message texte simple (avec streaming support)
            simpleTextBubble
        }
    }

    // MARK: - Simple Text Bubble (standard)

    private var simpleTextBubble: some View {
        HStack(spacing: 0) {
            Text(message.content)
                .font(.ecBody)
                .foregroundColor(message.isUser ? .white : themeManager.textPrimary)

            // Streaming cursor
            if message.isLoading && !message.content.isEmpty {
                StreamingCursor()
            }
        }
        .padding(.horizontal, ECSpacing.md)
        .padding(.vertical, ECSpacing.sm)
        .background(
            message.isUser ? themeManager.accentColor : themeManager.surfaceColor
        )
        .clipShape(RoundedRectangle(cornerRadius: ECRadius.lg))
    }

    // MARK: - Enriched Content (avec charts)

    private func enrichedContentView(segments: [ContentSegment]) -> some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            ForEach(segments) { segment in
                segmentView(segment)
            }

            // Streaming cursor à la fin si en cours
            if message.isLoading {
                HStack {
                    Spacer()
                    StreamingCursor()
                }
            }
        }
        .padding(ECSpacing.md)
        .background(themeManager.surfaceColor)
        .clipShape(RoundedRectangle(cornerRadius: ECRadius.lg))
    }

    // MARK: - Segment View

    @ViewBuilder
    private func segmentView(_ segment: ContentSegment) -> some View {
        switch segment {
        case .text(let content):
            Text(content)
                .font(.ecBody)
                .foregroundColor(themeManager.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

        case .chart(let chartId):
            chartView(for: chartId)
        }
    }

    // MARK: - Chart View

    @ViewBuilder
    private func chartView(for chartId: String) -> some View {
        // Chart placeholder - les specs seront injectées via une propriété dédiée
        ChartPlaceholderView(chartId: chartId, isError: false, height: 120)
    }

    // MARK: - Timestamp

    private func timestampView(_ date: Date) -> some View {
        Text(formatTime(date))
            .font(.ecSmall)
            .foregroundColor(themeManager.textTertiary)
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func chartIconFor(_ chartId: String) -> String {
        switch chartId {
        case "hr_zones":
            return "heart.fill"
        case "power_zones", "power_timeline":
            return "bolt.fill"
        case "pace_splits", "pace_hr_dual":
            return "figure.run"
        case "negative_split":
            return "arrow.up.right"
        default:
            return "chart.bar.fill"
        }
    }

    private func chartTitleFor(_ chartId: String) -> String {
        switch chartId {
        case "hr_zones":
            return "Zones cardiaques"
        case "power_zones":
            return "Zones de puissance"
        case "power_timeline":
            return "Évolution de la puissance"
        case "pace_splits":
            return "Allures par kilomètre"
        case "pace_hr_dual":
            return "Allure & Fréquence cardiaque"
        case "negative_split":
            return "Analyse negative split"
        default:
            return chartId.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Message simple
            EnrichedMessageBubble(
                message: ChatMessage(
                    role: .assistant,
                    content: "Voici mon analyse de ta séance."
                )
            )

            // Message utilisateur
            EnrichedMessageBubble(
                message: ChatMessage(
                    role: .user,
                    content: "Analyse ma séance de vélo d'hier"
                )
            )

            // Message avec placeholder chart (pas de spec)
            EnrichedMessageBubble(
                message: ChatMessage(
                    role: .assistant,
                    content: "Tu as passé du temps en zone haute.\n[[CHART:hr_zones]]\nBonne séance !"
                )
            )
        }
        .padding()
    }
    .environmentObject(ThemeManager.shared)
}
