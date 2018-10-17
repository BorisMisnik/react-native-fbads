#import "EXNativeAdManager.h"
#import "EXNativeAdView.h"
#import "EXNativeAdEmitter.h"

#import <React/RCTUtils.h>
#import <React/RCTAssert.h>
#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTUIManager.h>
#import <React/RCTBridgeModule.h>
@implementation RCTConvert (EXNativeAdView)

RCT_ENUM_CONVERTER(FBNativeAdsCachePolicy, (@{
  @"none": @(FBNativeAdsCachePolicyNone),
  @"all": @(FBNativeAdsCachePolicyAll),
}), FBNativeAdsCachePolicyNone, integerValue)

@end

@interface EXNativeAdManager () <FBNativeAdDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString*, FBNativeAd*> *adsManagers;
@property (nonatomic, strong) NSString *myAdChoiceViewPlacementId;
@property (readwrite) NSInteger errorCode;
@property (readwrite) NSString *placementId;
@property (readwrite) FBNativeAd *adv;
@property (nonatomic, strong) NSMutableArray *queue;
@property (readwrite) BOOL isFetching;
@property (nonatomic, strong) NSString *indificator;


@end

@implementation EXNativeAdManager

RCT_EXPORT_MODULE(CTKNativeAdManager)

@synthesize bridge = _bridge;

- (instancetype)init
{
  self = [super init];
  if (self) {
      _adsManagers = [NSMutableDictionary new];
      _queue = [NSMutableArray array];
  }
  return self;
}

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

RCT_EXPORT_METHOD(registerViewsForInteraction:(nonnull NSNumber *)nativeAdViewTag
                            mediaViewTag:(nonnull NSNumber *)mediaViewTag
                            adIconViewTag:(nonnull NSNumber *)adIconViewTag
                            clickableViewsTags:(nonnull NSArray *)tags
                            resolve:(RCTPromiseResolveBlock)resolve
                            reject:(RCTPromiseRejectBlock)reject)
{
  [_bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    FBMediaView *mediaView = nil;
    FBAdIconView *adIconView = nil;
    EXNativeAdView *nativeAdView = nil;
    
    if ([viewRegistry objectForKey:mediaViewTag] == nil) {
      reject(@"E_NO_VIEW_FOR_TAG", @"Could not find mediaView", nil);
      return;
    }
    
    if ([viewRegistry objectForKey:nativeAdViewTag] == nil) {
      reject(@"E_NO_NATIVEAD_VIEW", @"Could not find nativeAdView", nil);
      return;
    }
    
    if ([[viewRegistry objectForKey:mediaViewTag] isKindOfClass:[FBMediaView class]]) {
      mediaView = (FBMediaView *)[viewRegistry objectForKey:mediaViewTag];
    } else {
      reject(@"E_INVALID_VIEW_CLASS", @"View returned for passed media view tag is not an instance of FBMediaView", nil);
      return;
    }
    
    if ([[viewRegistry objectForKey:nativeAdViewTag] isKindOfClass:[EXNativeAdView class]]) {
      nativeAdView = (EXNativeAdView *)[viewRegistry objectForKey:nativeAdViewTag];
    } else {
      reject(@"E_INVALID_VIEW_CLASS", @"View returned for passed native ad view tag is not an instance of EXNativeAdView", nil);
      return;
    }
    
    if ([viewRegistry objectForKey:adIconViewTag]) {
      if ([[viewRegistry objectForKey:adIconViewTag] isKindOfClass:[FBAdIconView class]]) {
        adIconView  = (FBAdIconView *)[viewRegistry objectForKey:adIconViewTag];
      } else {
        reject(@"E_INVALID_VIEW_CLASS", @"View returned for passed ad icon view tag is not an instance of FBAdIconView", nil);
        return;
      }
    }
    
    NSMutableArray<UIView *> *clickableViews = [NSMutableArray new];
    for (id tag in tags) {
      if ([viewRegistry objectForKey:tag]) {
        [clickableViews addObject:[viewRegistry objectForKey:tag]];
      } else {
        reject(@"E_INVALID_VIEW_TAG", [NSString stringWithFormat:@"Could not find view for tag:  %@", [tag stringValue]], nil);
        return;
      }
    }
    
    [nativeAdView registerViewsForInteraction:mediaView adIcon:adIconView clickableViews:clickableViews];
    resolve(@[]);
  }];
}

RCT_EXPORT_METHOD(init:(NSString *)placementId withAdsToRequest:(nonnull NSNumber *)adsToRequest adIndificator:(NSString *)indificator)
{
    if (_isFetching) {
        __weak typeof(self) weakSelf = self;
        [_queue addObject:^{
            [weakSelf loadAd: placementId indificator: indificator];
        }];
    } else {
        [self loadAd: placementId indificator: indificator];
    }
}


-(void) loadAd:(NSString *)placementId indificator: (NSString *)indificator {
    _isFetching = YES;
    _indificator = indificator;
    
    FBNativeAd *adsManager = [[FBNativeAd alloc] initWithPlacementID:placementId];
    adsManager.delegate = self;
    [adsManager loadAd];
}

-(void) getNextAd {
    _isFetching = NO;
    id firstObj = [_queue firstObject];
    
    if (firstObj != nil) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:firstObj];
        [_queue removeObject:firstObj];
    }
}


RCT_EXPORT_METHOD(setMediaCachePolicy:(NSString*)placementId cachePolicy:(FBNativeAdsCachePolicy)cachePolicy)
{
//  [_adsManagers[placementId] setMediaCachePolicy:cachePolicy];
}

RCT_EXPORT_METHOD(disableAutoRefresh:(NSString*)placementId)
{
//  [_adsManagers[placementId] disableAutoRefresh];
}

- (FBNativeAd *) getFBAdsManager:(NSString *)placementId
{
    return _adsManagers[placementId];
}

- (void) nativeAdDidLoad:(FBNativeAd *)nativeAd
{
    NSMutableDictionary<NSString*, NSNumber*> *adsManagersState = [NSMutableDictionary new];
    
    if ([nativeAd isAdValid] == NO) {
        [adsManagersState setValue:@(NO) forKey:_indificator];
    } else {
        _adv = nativeAd;
        [adsManagersState setValue:@(YES) forKey:_indificator];
    }
    
    EXNativeAdEmitter *nativeAdEmitter = [_bridge moduleForClass:[EXNativeAdEmitter class]];
    [nativeAdEmitter sendManagersState:adsManagersState];
    [self getNextAd];
}

- (void)nativeAd:(FBNativeAd *)nativeAd didFailWithError:(NSError *)error
{
    
    NSMutableDictionary<NSString*, NSString*> *errorState = [NSMutableDictionary new];
    EXNativeAdEmitter *nativeAdEmitter = [_bridge moduleForClass:[EXNativeAdEmitter class]];
    
    _errorCode = error.code;
    _placementId = [nativeAd placementID];
    
    [errorState setValue:[NSString stringWithFormat:@"%li", (long)_errorCode] forKey:@"error"];
    [errorState setValue:_placementId forKey:@"placementId"];
    [errorState setValue:_indificator forKey:@"indificator"];
    
    [nativeAdEmitter sendError:errorState];
    [self getNextAd];
    
}

- (void)nativeAdDidClick:(FBNativeAd *)nativeAd
{
    EXNativeAdEmitter *nativeAdEmitter = [_bridge moduleForClass:[EXNativeAdEmitter class]];
    [nativeAdEmitter sendClickEvent: [nativeAd placementID]];
}

- (UIView *)view
{
      return [[EXNativeAdView alloc] initWithBridge:_bridge];
}

RCT_EXPORT_VIEW_PROPERTY(onAdLoaded, RCTBubblingEventBlock)
RCT_CUSTOM_VIEW_PROPERTY(adsManager, NSString, EXNativeAdView)
{
    if (_adv) {
        view.nativeAd = _adv;
    }
    [self getNextAd];
}

@end
