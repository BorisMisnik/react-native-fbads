#import "EXNativeAdView.h"
#import <FBAudienceNetwork/FBAudienceNetwork.h>
#import <React/RCTUtils.h>

@interface EXNativeAdView ()

@property (nonatomic, strong) RCTBridge *bridge;

@end

@implementation EXNativeAdView

- (instancetype)initWithBridge:(RCTBridge *)bridge
{
  if (self = [super init]) {
    _bridge = bridge;
  }
  return self;
}

- (void)setOnAdLoaded:(RCTBubblingEventBlock)onAdLoaded
{
  _onAdLoaded = onAdLoaded;
  
  if (_nativeAd != nil) {
    [self callOnAdLoadedWithAd:_nativeAd];
  }
}

- (void)setNativeAd:(FBNativeAd *)nativeAd
{
  _nativeAd = nativeAd;
  [self callOnAdLoadedWithAd:_nativeAd];
}

- (void)callOnAdLoadedWithAd:(FBNativeAd *)nativeAd
{
  if (_onAdLoaded != nil) {
    _onAdLoaded(@{
                  @"advertiserName": nativeAd.advertiserName,
                  @"sponsoredTranslation": nativeAd.sponsoredTranslation,
                  @"bodyText": nativeAd.bodyText,
                  @"socialContext": nativeAd.socialContext,
                  @"callToActionText": nativeAd.callToAction,
                  @"translation": nativeAd.adTranslation,
                  @"linkDescription": nativeAd.linkDescription,
                  @"promotedTranslation": nativeAd.promotedTranslation,
                  @"adChoiceLinkUrl": nativeAd.adChoicesLinkURL ? [_nativeAd.adChoicesLinkURL absoluteString] : [NSNull null],
                  @"adChoiceIconUrl": nativeAd.adChoicesIcon ? [_nativeAd.adChoicesIcon.url absoluteString] : [NSNull null],
                  });
  }
}

- (void)registerViewsForInteraction:(FBMediaView *)mediaView adIcon:(FBAdIconView *)adIconView clickableViews:(NSArray<UIView *> *)clickable
{
  [_nativeAd registerViewForInteraction:self
                                  mediaView:mediaView
                                   iconView:adIconView
                             viewController:RCTKeyWindow().rootViewController
                             clickableViews:clickable];
}

@end
