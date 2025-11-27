/**
 * Objective-C Bridge pour NativeLineChartViewManager
 * Expose le composant SwiftUI LineChart à React Native
 */

#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(NativeLineChartViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(data, NSArray)
RCT_EXPORT_VIEW_PROPERTY(color, NSString)
RCT_EXPORT_VIEW_PROPERTY(showGradient, BOOL)
RCT_EXPORT_VIEW_PROPERTY(chartHeight, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(showInteraction, BOOL)

@end
