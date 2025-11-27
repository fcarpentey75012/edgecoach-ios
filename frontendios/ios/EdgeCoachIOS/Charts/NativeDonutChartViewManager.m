/**
 * Objective-C Bridge pour NativeDonutChartViewManager
 * Expose le composant SwiftUI DonutChart à React Native
 */

#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(NativeDonutChartViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(zones, NSArray)
RCT_EXPORT_VIEW_PROPERTY(innerRadius, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(outerRadius, CGFloat)

@end
