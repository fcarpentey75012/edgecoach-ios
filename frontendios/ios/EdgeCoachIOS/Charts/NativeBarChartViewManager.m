/**
 * Objective-C Bridge pour NativeBarChartViewManager
 * Expose le composant SwiftUI BarChart à React Native
 */

#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(NativeBarChartViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(data, NSArray)
RCT_EXPORT_VIEW_PROPERTY(color, NSString)
RCT_EXPORT_VIEW_PROPERTY(avgValue, double)
RCT_EXPORT_VIEW_PROPERTY(chartHeight, CGFloat)

@end
