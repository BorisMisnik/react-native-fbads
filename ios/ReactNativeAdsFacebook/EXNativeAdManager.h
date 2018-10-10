#import <React/RCTViewManager.h>
#import <FBAudienceNetwork/FBAudienceNetwork.h>

@interface EXNativeAdManager : RCTViewManager

- (FBNativeAd *) getFBAdsManager:(NSString *)placementId;

@end
