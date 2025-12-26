/**
 * SkeletonView.swift
 * Composant d'effet de chargement (shimmer)
 */

import SwiftUI

struct SkeletonView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var phase: CGFloat = 0
    
    var height: CGFloat = 20
    var width: CGFloat = .infinity
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        Rectangle()
            .fill(themeManager.elevatedColor)
            .cornerRadius(cornerRadius)
            .overlay(
                GeometryReader { geo in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(30))
                        .offset(x: -geo.size.width + (geo.size.width * 2 * phase))
                }
            )
            .mask(Rectangle().cornerRadius(cornerRadius))
            .frame(height: height)
            .frame(maxWidth: width)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// Extension pour modifier l'apparence facilement
extension View {
    @ViewBuilder
    func skeleton(active: Bool, height: CGFloat = 20, cornerRadius: CGFloat = 8) -> some View {
        if active {
            SkeletonView(height: height, cornerRadius: cornerRadius)
        } else {
            self
        }
    }
}
