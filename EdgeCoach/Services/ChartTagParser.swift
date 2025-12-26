/**
 * ChartTagParser
 * Parse les balises [[CHART:id]] dans le contenu des messages
 * et découpe le texte en segments pour le rendu inline des graphiques
 */

import Foundation

// MARK: - Content Segment

/// Un segment de contenu qui peut être du texte ou un graphique
enum ContentSegment: Identifiable {
    case text(String)
    case chart(chartId: String)

    var id: String {
        switch self {
        case .text(let content):
            return "text_\(content.hashValue)"
        case .chart(let chartId):
            return "chart_\(chartId)"
        }
    }

    var isChart: Bool {
        if case .chart = self { return true }
        return false
    }
}

// MARK: - Chart Tag Parser

/// Parse les balises [[CHART:xxx]] dans le texte pour permettre
/// l'insertion inline de graphiques Vega-Lite
struct ChartTagParser {
    /// Pattern regex pour détecter [[CHART:xxx]]
    private static let chartPattern = try! NSRegularExpression(
        pattern: #"\[\[CHART:(\w+)\]\]"#,
        options: []
    )

    /// Extrait tous les IDs de charts présents dans le texte
    /// - Parameter text: Le texte contenant potentiellement des balises [[CHART:id]]
    /// - Returns: Liste ordonnée des IDs de charts trouvés
    static func extractChartIds(from text: String) -> [String] {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = chartPattern.matches(in: text, options: [], range: range)

        return matches.compactMap { match -> String? in
            guard let idRange = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[idRange])
        }
    }

    /// Découpe le texte en segments de texte et de charts
    /// - Parameter text: Le texte contenant des balises [[CHART:id]]
    /// - Returns: Liste de segments dans l'ordre d'apparition
    static func parse(_ text: String) -> [ContentSegment] {
        var segments: [ContentSegment] = []
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = chartPattern.matches(in: text, options: [], range: range)

        var lastIndex = text.startIndex

        for match in matches {
            // Récupérer le range complet de la balise [[CHART:xxx]]
            guard let matchRange = Range(match.range, in: text),
                  let idRange = Range(match.range(at: 1), in: text) else {
                continue
            }

            // Ajouter le texte avant la balise (s'il y en a)
            if lastIndex < matchRange.lowerBound {
                let textBefore = String(text[lastIndex..<matchRange.lowerBound])
                let trimmed = textBefore.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    segments.append(.text(textBefore))
                }
            }

            // Ajouter le segment chart
            let chartId = String(text[idRange])
            segments.append(.chart(chartId: chartId))

            lastIndex = matchRange.upperBound
        }

        // Ajouter le texte restant après la dernière balise
        if lastIndex < text.endIndex {
            let remainingText = String(text[lastIndex..<text.endIndex])
            let trimmed = remainingText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                segments.append(.text(remainingText))
            }
        }

        // Si aucune balise n'a été trouvée, retourner tout le texte
        if segments.isEmpty && !text.isEmpty {
            segments.append(.text(text))
        }

        return segments
    }

    /// Supprime toutes les balises [[CHART:xxx]] du texte
    /// Utile pour obtenir le texte brut sans les placeholders
    static func stripChartTags(from text: String) -> String {
        chartPattern.stringByReplacingMatches(
            in: text,
            options: [],
            range: NSRange(text.startIndex..<text.endIndex, in: text),
            withTemplate: ""
        )
    }

    /// Vérifie si le texte contient des balises chart
    static func containsChartTags(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return chartPattern.firstMatch(in: text, options: [], range: range) != nil
    }
}

// MARK: - Usage Example
/*
 let text = """
 Tu as passé beaucoup de temps en zone haute.
 [[CHART:hr_zones]]
 Voici la répartition de ta puissance:
 [[CHART:power_zones]]
 Continue comme ça!
 """

 let segments = ChartTagParser.parse(text)
 // segments = [
 //   .text("Tu as passé beaucoup de temps en zone haute."),
 //   .chart(chartId: "hr_zones"),
 //   .text("Voici la répartition de ta puissance:"),
 //   .chart(chartId: "power_zones"),
 //   .text("Continue comme ça!")
 // ]

 let chartIds = ChartTagParser.extractChartIds(from: text)
 // chartIds = ["hr_zones", "power_zones"]
 */
