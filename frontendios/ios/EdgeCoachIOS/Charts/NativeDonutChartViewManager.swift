/**
 * ViewManager pour NativeDonutChart
 * Bridge entre React Native et SwiftUI DonutChart (pie chart pour zones FC)
 */

import Foundation
import React
import SwiftUI
import UIKit

@available(iOS 16.0, *)
@objc(NativeDonutChartViewManager)
class NativeDonutChartViewManager: RCTViewManager {

    override func view() -> UIView! {
        return NativeDonutChartContainerView()
    }

    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}

// MARK: - Container View

@available(iOS 16.0, *)
class NativeDonutChartContainerView: UIView {
    private var hostingController: UIHostingController<NativeDonutChartView>?

    // Props
    private var zonesData: [ZoneData] = []
    private var innerRadius: CGFloat = 0.5
    private var outerRadius: CGFloat = 1.0

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

        let chartView = NativeDonutChartView(
            zones: zonesData,
            innerRadius: innerRadius,
            outerRadius: outerRadius
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

    @objc func setZones(_ zones: [[String: Any]]) {
        zonesData = zones.compactMap { item in
            guard let zone = item["zone"] as? Int,
                  let percentage = item["percentage"] as? Double else {
                return nil
            }
            let timeSeconds = item["time_seconds"] as? Int ?? 0
            return ZoneData(
                zone: zone,
                percentage: percentage,
                timeSeconds: timeSeconds,
                color: EdgeCoachColors.zoneColor(for: zone)
            )
        }.sorted { $0.zone < $1.zone }
        updateChart()
    }

    @objc func setInnerRadius(_ radius: CGFloat) {
        innerRadius = radius
        updateChart()
    }

    @objc func setOuterRadius(_ radius: CGFloat) {
        outerRadius = radius
        updateChart()
    }
}
