/**
 * VegaChartView
 * Composant SwiftUI pour afficher des graphiques Vega-Lite
 * Utilise WKWebView avec vega-embed pour le rendu
 */

import SwiftUI
import WebKit

// MARK: - Chart Spec

/// Spécification d'un graphique Vega-Lite
struct ChartSpec: Identifiable {
    let id: String
    let title: String?
    let specData: [String: Any]

    init(id: String, title: String? = nil, specData: [String: Any]) {
        self.id = id
        self.title = title
        self.specData = specData
    }

    /// Convertit la spec en JSON string pour Vega-Lite
    var vegaLiteJSON: String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: specData, options: .fragmentsAllowed) else {
            return nil
        }
        return String(data: jsonData, encoding: .utf8)
    }

    /// Crée une spec vide (placeholder)
    static func placeholder(id: String) -> ChartSpec {
        ChartSpec(id: id, specData: [:])
    }

    /// Crée une spec exemple pour les tests
    static var example: ChartSpec {
        let spec: [String: Any] = [
            "$schema": "https://vega.github.io/schema/vega-lite/v5.json",
            "description": "A simple bar chart",
            "data": [
                "values": [
                    ["zone": "Z1", "percentage": 20],
                    ["zone": "Z2", "percentage": 35],
                    ["zone": "Z3", "percentage": 25],
                    ["zone": "Z4", "percentage": 15],
                    ["zone": "Z5", "percentage": 5]
                ]
            ],
            "mark": "bar",
            "encoding": [
                "x": ["field": "zone", "type": "nominal"],
                "y": ["field": "percentage", "type": "quantitative"]
            ]
        ]
        return ChartSpec(id: "example", title: "Example Chart", specData: spec)
    }
}

// MARK: - Vega Chart View

/// Vue SwiftUI pour afficher un graphique Vega-Lite
/// Charge vega-embed depuis CDN et injecte la spec JSON
struct VegaChartView: UIViewRepresentable {
    let spec: ChartSpec
    let height: CGFloat

    @EnvironmentObject var themeManager: ThemeManager

    init(spec: ChartSpec, height: CGFloat = 220) {
        self.spec = spec
        self.height = height
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        // Setup console logging
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "logger")
        
        // Inject JS console override
        let jsLogger = """
        function log(type, message) {
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.logger) {
                window.webkit.messageHandlers.logger.postMessage({
                    "type": type,
                    "message": message
                });
            }
        }
        console.log = function(msg) { log("log", msg); };
        console.error = function(msg) { log("error", msg); };
        console.warn = function(msg) { log("warn", msg); };
        """
        let script = WKUserScript(source: jsLogger, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        contentController.addUserScript(script)
        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        
        // Web Inspector (Debugging)
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let isDarkMode = themeManager.preferredColorScheme == .dark

        guard let specJSON = spec.vegaLiteJSON else {
            print("[VegaChartView] ❌ Failed to generate JSON for spec: \(spec.id)")
            let errorHTML = generateErrorHTML(
                message: "Erreur de conversion JSON",
                chartId: spec.id,
                isDarkMode: isDarkMode,
                height: height
            )
            webView.loadHTMLString(errorHTML, baseURL: nil)
            return
        }

        print("[VegaChartView] ✅ Loading chart: \(spec.id) with JSON length: \(specJSON.count)")
        let html = generateHTML(specJSON: specJSON, isDarkMode: isDarkMode, height: height)
        // Utiliser nil pour baseURL pour éviter les problèmes de sécurité mixtes si nécessaire, 
        // ou un URL générique, mais ici absolu CDN URL devrait marcher.
        // On le change à nil pour tester.
        webView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Chart loaded successfully
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("[VegaChartView] ❌ WebView navigation error: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("[VegaChartView] ❌ WebView provisional navigation error: \(error.localizedDescription)")
        }
        
        // MARK: - WKScriptMessageHandler
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "logger",
                  let body = message.body as? [String: Any],
                  let type = body["type"] as? String,
                  let logMessage = body["message"] as? String else {
                return
            }
            
            let emoji = type == "error" ? "❌" : (type == "warn" ? "⚠️" : "📝")
            print("[VegaJS] \(emoji) \(logMessage)")
        }
    }

    // MARK: - Error HTML Generation

    private func generateErrorHTML(message: String, chartId: String, isDarkMode: Bool, height: CGFloat) -> String {
        let backgroundColor = isDarkMode ? "#1C1C1E" : "#FFFFFF"
        let textColor = isDarkMode ? "#AAAAAA" : "#666666"

        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body {
                    background-color: \(backgroundColor);
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                    align-items: center;
                    min-height: \(Int(height))px;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    color: \(textColor);
                    margin: 0;
                    padding: 16px;
                    box-sizing: border-box;
                }
                .icon { font-size: 32px; margin-bottom: 8px; }
                .message { font-size: 14px; margin-bottom: 4px; }
                .chart-id { font-size: 10px; opacity: 0.6; font-family: monospace; }
            </style>
        </head>
        <body>
            <div class="icon">⚠️</div>
            <div class="message">\(message)</div>
            <div class="chart-id">\(chartId)</div>
        </body>
        </html>
        """
    }

    // MARK: - HTML Generation

    private func generateHTML(specJSON: String, isDarkMode: Bool, height: CGFloat) -> String {
        let backgroundColor = isDarkMode ? "#1C1C1E" : "#FFFFFF"
        let textColor = isDarkMode ? "#FFFFFF" : "#000000"
        let errorColor = isDarkMode ? "#FF6B6B" : "#FF3B30"

        // Charger les scripts Vega depuis le bundle local
        let vegaScript = loadLocalScript(named: "vega.min")
        let vegaLiteScript = loadLocalScript(named: "vega-lite.min")
        let vegaEmbedScript = loadLocalScript(named: "vega-embed.min")

        // Si les scripts locaux ne sont pas disponibles, utiliser CDN comme fallback
        let useLocalScripts = !vegaScript.isEmpty && !vegaLiteScript.isEmpty && !vegaEmbedScript.isEmpty

        if useLocalScripts {
            print("[VegaChartView] 📦 Using bundled Vega scripts")
            return generateHTMLWithInlineScripts(
                specJSON: specJSON,
                isDarkMode: isDarkMode,
                height: height,
                vegaScript: vegaScript,
                vegaLiteScript: vegaLiteScript,
                vegaEmbedScript: vegaEmbedScript,
                backgroundColor: backgroundColor,
                textColor: textColor,
                errorColor: errorColor
            )
        } else {
            print("[VegaChartView] ⚠️ Local scripts not found, falling back to CDN")
            return generateHTMLWithCDN(
                specJSON: specJSON,
                isDarkMode: isDarkMode,
                height: height,
                backgroundColor: backgroundColor,
                textColor: textColor,
                errorColor: errorColor
            )
        }
    }

    /// Charge un script JavaScript depuis le bundle de l'app
    private func loadLocalScript(named name: String) -> String {
        guard let url = Bundle.main.url(forResource: name, withExtension: "js"),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            print("[VegaChartView] ❌ Could not load local script: \(name).js")
            return ""
        }
        return content
    }

    /// Génère le HTML avec les scripts Vega inlinés (pas de dépendance réseau)
    private func generateHTMLWithInlineScripts(
        specJSON: String,
        isDarkMode: Bool,
        height: CGFloat,
        vegaScript: String,
        vegaLiteScript: String,
        vegaEmbedScript: String,
        backgroundColor: String,
        textColor: String,
        errorColor: String
    ) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    background-color: \(backgroundColor);
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                    align-items: center;
                    min-height: \(Int(height))px;
                    overflow: hidden;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                }
                #vis { width: 100%; max-width: 100%; }
                .vega-embed { width: 100% !important; }
                .vega-embed .marks { width: 100% !important; }
                .vega-embed .vega-actions { display: none !important; }
                #loading { color: \(textColor); font-size: 14px; opacity: 0.6; }
                #error {
                    color: \(errorColor);
                    font-size: 12px;
                    padding: 16px;
                    text-align: center;
                    display: none;
                    flex-direction: column;
                    align-items: center;
                }
                .error-icon { font-size: 24px; margin-bottom: 8px; }
                .error-details { font-size: 10px; opacity: 0.7; margin-top: 4px; max-width: 90%; word-break: break-word; }
            </style>
            <script>\(vegaScript)</script>
            <script>\(vegaLiteScript)</script>
            <script>\(vegaEmbedScript)</script>
        </head>
        <body>
            <div id="loading">Chargement...</div>
            <div id="vis"></div>
            <div id="error">
                <div class="error-icon">⚠️</div>
                <div class="error-message"></div>
                <div class="error-details"></div>
            </div>

            <script>
                function log(msg) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.logger) {
                        window.webkit.messageHandlers.logger.postMessage({ "type": "log", "message": msg });
                    }
                }
                function errorLog(msg) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.logger) {
                        window.webkit.messageHandlers.logger.postMessage({ "type": "error", "message": msg });
                    }
                }
                function showError(message, details) {
                    document.getElementById('loading').style.display = 'none';
                    document.getElementById('vis').style.display = 'none';
                    var errorDiv = document.getElementById('error');
                    errorDiv.style.display = 'flex';
                    errorDiv.querySelector('.error-message').textContent = message;
                    if (details) errorDiv.querySelector('.error-details').textContent = details;
                }

                (function() {
                    var spec;
                    try {
                        spec = \(specJSON);
                        log("Chart spec parsed for ID: " + (spec.id || 'unknown'));
                    } catch(e) {
                        errorLog("JSON Parse Error: " + e.message);
                        showError('Erreur de parsing JSON', e.message);
                        return;
                    }

                    if (typeof vegaEmbed === 'undefined') {
                        errorLog("vegaEmbed not defined");
                        showError('Vega non disponible', 'Scripts non chargés');
                        return;
                    }

                    // Theme config
                    spec.config = spec.config || {};
                    spec.config.background = '\(backgroundColor)';
                    spec.config.axis = spec.config.axis || {};
                    spec.config.axis.labelColor = '\(textColor)';
                    spec.config.axis.titleColor = '\(textColor)';
                    spec.config.legend = spec.config.legend || {};
                    spec.config.legend.labelColor = '\(textColor)';
                    spec.config.legend.titleColor = '\(textColor)';
                    spec.config.title = spec.config.title || {};
                    spec.config.title.color = '\(textColor)';

                    spec.width = 'container';
                    spec.autosize = { type: 'fit', contains: 'padding' };

                    log("Rendering chart with vegaEmbed (bundled scripts)...");
                    vegaEmbed('#vis', spec, {
                        actions: false,
                        renderer: 'svg',
                        theme: '\(isDarkMode ? "dark" : "default")'
                    }).then(function(result) {
                        log("Chart rendered successfully");
                        document.getElementById('loading').style.display = 'none';
                    }).catch(function(error) {
                        errorLog("Vega Embed Error: " + error.message);
                        showError('Erreur Vega-Lite', error.message);
                    });
                })();
            </script>
        </body>
        </html>
        """
    }

    /// Fallback: génère le HTML avec chargement CDN (si scripts locaux non disponibles)
    private func generateHTMLWithCDN(
        specJSON: String,
        isDarkMode: Bool,
        height: CGFloat,
        backgroundColor: String,
        textColor: String,
        errorColor: String
    ) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    background-color: \(backgroundColor);
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                    align-items: center;
                    min-height: \(Int(height))px;
                    overflow: hidden;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                }
                #vis { width: 100%; max-width: 100%; }
                .vega-embed { width: 100% !important; }
                .vega-embed .marks { width: 100% !important; }
                .vega-embed .vega-actions { display: none !important; }
                #loading { color: \(textColor); font-size: 14px; opacity: 0.6; }
                #error {
                    color: \(errorColor);
                    font-size: 12px;
                    padding: 16px;
                    text-align: center;
                    display: none;
                    flex-direction: column;
                    align-items: center;
                }
                .error-icon { font-size: 24px; margin-bottom: 8px; }
                .error-details { font-size: 10px; opacity: 0.7; margin-top: 4px; max-width: 90%; word-break: break-word; }
            </style>
        </head>
        <body>
            <div id="loading">Chargement...</div>
            <div id="vis"></div>
            <div id="error">
                <div class="error-icon">⚠️</div>
                <div class="error-message"></div>
                <div class="error-details"></div>
            </div>

            <script>
                var scriptsLoaded = 0;
                var totalScripts = 3;
                var loadTimeout;
                var spec;

                function showError(message, details) {
                    document.getElementById('loading').style.display = 'none';
                    document.getElementById('vis').style.display = 'none';
                    var errorDiv = document.getElementById('error');
                    errorDiv.style.display = 'flex';
                    errorDiv.querySelector('.error-message').textContent = message;
                    if (details) errorDiv.querySelector('.error-details').textContent = details;
                }

                function onScriptLoad() {
                    scriptsLoaded++;
                    if (scriptsLoaded === totalScripts) {
                        clearTimeout(loadTimeout);
                        renderChart();
                    }
                }

                function onScriptError(scriptName) {
                    clearTimeout(loadTimeout);
                    showError('Erreur de chargement', 'Impossible de charger ' + scriptName);
                }

                function log(msg) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.logger) {
                        window.webkit.messageHandlers.logger.postMessage({ "type": "log", "message": msg });
                    }
                }
                function errorLog(msg) {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.logger) {
                        window.webkit.messageHandlers.logger.postMessage({ "type": "error", "message": msg });
                    }
                }

                function renderChart() {
                    try {
                        spec = \(specJSON);
                        log("Chart spec loaded for ID: " + (spec.id || 'unknown'));
                    } catch(e) {
                        errorLog("JSON Parse Error: " + e.message);
                        showError('Erreur de parsing JSON', e.message);
                        return;
                    }

                    if (typeof vegaEmbed === 'undefined') {
                        errorLog("Vega Embed not defined");
                        showError('Vega non disponible', 'Les bibliothèques ne sont pas chargées');
                        return;
                    }

                    spec.config = spec.config || {};
                    spec.config.background = '\(backgroundColor)';
                    spec.config.axis = spec.config.axis || {};
                    spec.config.axis.labelColor = '\(textColor)';
                    spec.config.axis.titleColor = '\(textColor)';
                    spec.config.legend = spec.config.legend || {};
                    spec.config.legend.labelColor = '\(textColor)';
                    spec.config.legend.titleColor = '\(textColor)';
                    spec.config.title = spec.config.title || {};
                    spec.config.title.color = '\(textColor)';

                    spec.width = 'container';
                    spec.autosize = { type: 'fit', contains: 'padding' };

                    log("Embedding with vegaEmbed (CDN fallback)...");
                    vegaEmbed('#vis', spec, {
                        actions: false,
                        renderer: 'svg',
                        theme: '\(isDarkMode ? "dark" : "default")'
                    }).then(function(result) {
                        log("Chart rendered successfully");
                        document.getElementById('loading').style.display = 'none';
                    }).catch(function(error) {
                        errorLog("Vega Embed Error: " + error.message);
                        showError('Erreur Vega-Lite', error.message);
                    });
                }

                loadTimeout = setTimeout(function() {
                    if (scriptsLoaded < totalScripts) {
                        showError('Timeout', 'Chargement trop long (' + scriptsLoaded + '/' + totalScripts + ' scripts)');
                    }
                }, 15000);

                function loadScript(src, name, callback) {
                    var script = document.createElement('script');
                    script.src = src;
                    script.onload = function() { onScriptLoad(); if (callback) callback(); };
                    script.onerror = function() { onScriptError(name); };
                    document.head.appendChild(script);
                }

                loadScript('https://cdn.jsdelivr.net/npm/vega@5', 'vega', function() {
                    loadScript('https://cdn.jsdelivr.net/npm/vega-lite@5', 'vega-lite', function() {
                        loadScript('https://cdn.jsdelivr.net/npm/vega-embed@6', 'vega-embed');
                    });
                });
            </script>
        </body>
        </html>
        """
    }
}

// MARK: - Chart Container View

/// Conteneur stylisé pour un graphique avec titre optionnel
struct ChartContainerView: View {
    @EnvironmentObject var themeManager: ThemeManager

    let spec: ChartSpec
    let title: String?
    let height: CGFloat

    init(spec: ChartSpec, title: String? = nil, height: CGFloat = 220) {
        self.spec = spec
        self.title = title
        self.height = height
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ECSpacing.sm) {
            if let title = title {
                HStack(spacing: ECSpacing.xs) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                        .foregroundColor(themeManager.accentColor)

                    Text(title)
                        .font(.ecCaption)
                        .foregroundColor(themeManager.textSecondary)
                }
            }

            VegaChartView(spec: spec, height: height)
                .frame(height: height)
                .background(themeManager.cardColor)
                .cornerRadius(ECRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: ECRadius.md)
                        .stroke(themeManager.borderColor, lineWidth: 1)
                )
        }
    }
}

// MARK: - Chart Placeholder (Loading/Error)

/// Placeholder affiché pendant le chargement ou en cas d'erreur
struct ChartPlaceholderView: View {
    @EnvironmentObject var themeManager: ThemeManager

    let chartId: String
    let isError: Bool
    let height: CGFloat

    init(chartId: String, isError: Bool = false, height: CGFloat = 180) {
        self.chartId = chartId
        self.isError = isError
        self.height = height
    }

    var body: some View {
        VStack(spacing: ECSpacing.sm) {
            if isError {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)

                Text("Graphique non disponible")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())

                Text("Chargement du graphique...")
                    .font(.ecCaption)
                    .foregroundColor(themeManager.textSecondary)
            }

            Text(chartId)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(themeManager.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(themeManager.cardColor)
        .cornerRadius(ECRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: ECRadius.md)
                .stroke(themeManager.borderColor.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Placeholder
        ChartPlaceholderView(chartId: "hr_zones")

        // Error state
        ChartPlaceholderView(chartId: "power_zones", isError: true)
    }
    .padding()
    .environmentObject(ThemeManager.shared)
}
