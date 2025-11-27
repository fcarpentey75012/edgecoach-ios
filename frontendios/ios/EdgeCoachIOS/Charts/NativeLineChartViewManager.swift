/**
 * ViewManager pour NativeLineChart
 * Bridge entre React Native et SwiftUI LineChart
 */

import Foundation
import React
import SwiftUI
import UIKit

@available(iOS 16.0, *)
@objc(NativeLineChartViewManager)
class NativeLineChartViewManager: RCTViewManager {

    override func view() -> UIView! {
        return NativeLineChartContainerView()
    }

    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}

// MARK: - Container View

@available(iOS 16.0, *)
class NativeLineChartContainerView: UIView {
    private var hostingController: UIHostingController<NativeLineChartView>?

    // Props
    private var chartData: [ChartDataPoint] = []
    private var chartColor: Color = EdgeCoachColors.primary
    private var showGradient: Bool = true
    private var chartHeight: CGFloat = 150
    private var showInteraction: Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        updateChart()
    }

    private func updateChart() {
        // Supprimer l'ancien hosting controller
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()

        // Créer la nouvelle vue SwiftUI
        let chartView = NativeLineChartView(
            data: chartData,
            color: chartColor,
            showGradient: showGradient,
            height: chartHeight,
            showInteraction: showInteraction
        )

        let hostingVC = UIHostingController(rootView: chartView)
        hostingVC.view.backgroundColor = .clear
        hostingVC.view.translatesAutoresizingMaskIntoConstraints = false

        addSubview(hostingVC.view)
        NSLayoutConstraint.activate([
            hostingVC.view.topAnchor.constraint(equalTo: topAnchor),
            hostingVC.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingVC.view.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingVC.view.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        hostingController = hostingVC
    }

    // MARK: - Props setters

    @objc func setData(_ data: [[String: Any]]) {
        chartData = data.enumerated().compactMap { index, item in
            guard let value = item["value"] as? Double else { return nil }
            return ChartDataPoint(index: index, value: value)
        }
        updateChart()
    }

    @objc func setColor(_ colorHex: String) {
        chartColor = Color(hex: colorHex) ?? EdgeCoachColors.primary
        updateChart()
    }

    @objc func setShowGradient(_ show: Bool) {
        showGradient = show
        updateChart()
    }

    @objc func setChartHeight(_ height: CGFloat) {
        chartHeight = height
        updateChart()
    }

    @objc func setShowInteraction(_ show: Bool) {
        showInteraction = show
        updateChart()
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r, g, b, a: Double
        switch hexSanitized.count {
        case 6:
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        case 8:
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        default:
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
