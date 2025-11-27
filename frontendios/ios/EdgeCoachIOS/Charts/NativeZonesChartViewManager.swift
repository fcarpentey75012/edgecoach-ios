/**
 * ViewManager pour NativeZonesChart
 * Bridge entre React Native et SwiftUI ZonesChart (barres horizontales)
 */

import Foundation
import React
import SwiftUI
import UIKit

@available(iOS 16.0, *)
@objc(NativeZonesChartViewManager)
class NativeZonesChartViewManager: RCTViewManager {

    override func view() -> UIView! {
        return NativeZonesChartContainerView()
    }

    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}

// MARK: - Container View

@available(iOS 16.0, *)
class NativeZonesChartContainerView: UIView {
    private var hostingController: UIHostingController<NativeZonesChartView>?

    // Props
    private var zonesData: [ZoneData] = []
    private var showLabels: Bool = true

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

        let chartView = NativeZonesChartView(
            zones: zonesData,
            showLabels: showLabels
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

    @objc func setShowLabels(_ show: Bool) {
        showLabels = show
        updateChart()
    }
}
