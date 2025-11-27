/**
 * ViewManager pour NativeBarChart
 * Bridge entre React Native et SwiftUI BarChart (pour les laps/splits)
 */

import Foundation
import React
import SwiftUI
import UIKit

@available(iOS 16.0, *)
@objc(NativeBarChartViewManager)
class NativeBarChartViewManager: RCTViewManager {

    override func view() -> UIView! {
        return NativeBarChartContainerView()
    }

    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}

// MARK: - Container View

@available(iOS 16.0, *)
class NativeBarChartContainerView: UIView {
    private var hostingController: UIHostingController<NativeBarChartView>?

    // Props
    private var chartData: [ChartDataPoint] = []
    private var chartColor: Color = EdgeCoachColors.running
    private var avgValue: Double? = nil
    private var chartHeight: CGFloat = 80

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
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()

        let chartView = NativeBarChartView(
            data: chartData,
            color: chartColor,
            avgValue: avgValue,
            height: chartHeight
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
        chartColor = Color(hex: colorHex) ?? EdgeCoachColors.running
        updateChart()
    }

    @objc func setAvgValue(_ avg: Double) {
        avgValue = avg > 0 ? avg : nil
        updateChart()
    }

    @objc func setChartHeight(_ height: CGFloat) {
        chartHeight = height
        updateChart()
    }
}
