/**
 * Objective-C Bridge pour NativeZonesChartViewManager
 * Expose le composant SwiftUI ZonesChart à React Native
 */

#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(NativeZonesChartViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(zones, NSArray)
RCT_EXPORT_VIEW_PROPERTY(showLabels, BOOL)

@end
