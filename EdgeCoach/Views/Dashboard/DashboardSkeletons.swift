/**
 * DashboardSkeletons.swift
 * Skeletons spécifiques pour les widgets du dashboard
 */

import SwiftUI

struct KPISummarySkeleton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let count: Int
    
    private var columns: [GridItem] {
        if count <= 2 {
            return [GridItem(.flexible()), GridItem(.flexible())]
        } else if count <= 3 {
            return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        } else {
            return [GridItem(.flexible()), GridItem(.flexible())]
        }
    }
    
    var body: some View {
        VStack(spacing: ECSpacing.sm) {
            // Picker skeleton
            SkeletonView(height: 32, width: 150, cornerRadius: 8)
            
            // Grid skeleton
            LazyVGrid(columns: columns, spacing: ECSpacing.sm) {
                ForEach(0..<count, id: \.self) { _ in
                    SkeletonView(height: 80, cornerRadius: 12)
                }
            }
        }
    }
}

struct RecentActivitiesSkeleton: View {
    var body: some View {
        VStack(spacing: ECSpacing.sm) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: ECSpacing.md) {
                    SkeletonView(height: 44, width: 44, cornerRadius: 22) // Circle
                    
                    VStack(alignment: .leading, spacing: 4) {
                        SkeletonView(height: 16, width: 120)
                        HStack {
                            SkeletonView(height: 12, width: 60)
                            SkeletonView(height: 12, width: 60)
                        }
                    }
                    
                    Spacer()
                    
                    SkeletonView(height: 24, width: 40)
                }
                .padding(ECSpacing.md)
                .background(Color.gray.opacity(0.1)) // Placeholder color, will be covered by skeleton logic inside SkeletonView
                .cornerRadius(12)
                // Note: SkeletonView itself has the background color logic
            }
        }
    }
}

struct PlannedSessionsSkeleton: View {
    var body: some View {
        VStack(spacing: ECSpacing.sm) {
            // MacroPlan card skeleton
            SkeletonView(height: 60, cornerRadius: 12)
            
            // Sessions skeletons
            ForEach(0..<2, id: \.self) { _ in
                SkeletonView(height: 50, cornerRadius: 12)
            }
        }
    }
}

struct PerformanceWidgetSkeleton: View {
    var body: some View {
        HStack(spacing: ECSpacing.sm) {
            SkeletonView(height: 100, cornerRadius: 12)
            SkeletonView(height: 100, cornerRadius: 12)
        }
    }
}
