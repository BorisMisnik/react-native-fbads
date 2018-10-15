#import <React/RCTEventEmitter.h>

@interface EXNativeAdEmitter : RCTEventEmitter

- (void)sendManagersState:(NSDictionary<NSString *,NSNumber *> *)adManagersState;
- (void)sendError:(NSDictionary<NSString *,NSString *> *)error;
- (void)sendClickEvent:(NSString *)placementId;
@end
