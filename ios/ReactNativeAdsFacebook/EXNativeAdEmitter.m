#import "EXNativeAdEmitter.h"

@implementation EXNativeAdEmitter

RCT_EXPORT_MODULE(CTKNativeAdEmitter)

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"CTKNativeAdsManagersChanged", @"CTKNativeAdsClicked", @"CTKNativeAdsError"];
}

- (void)sendManagersState:(NSDictionary<NSString *,NSNumber *> *)adManagersState {
    [self sendEventWithName:@"CTKNativeAdsManagersChanged" body:adManagersState];
}

- (void)sendError:(NSDictionary<NSString *,NSString *> *)errorState {
    [self sendEventWithName:(@"CTKNativeAdsError") body:errorState];
}

- (void)sendClickEvent:(NSString *)placementId {
    [self sendEventWithName:(@"CTKNativeAdsClicked") body:placementId];
}

@end
