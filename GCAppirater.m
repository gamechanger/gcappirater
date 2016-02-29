/*
 This file is part of Appirater.
 
 Copyright (c) 2012, Arash Payan
 All rights reserved.
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */
/*
 * Appirater.m
 * appirater
 *
 * Created by Arash Payan on 9/5/09.
 * http://arashpayan.com
 * Copyright 2012 Arash Payan. All rights reserved.
 */

#import "GCAppirater.h"
#import <SystemConfiguration/SCNetworkReachability.h>
#include <netinet/in.h>

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

NSString *const kGCAppiraterFirstUseDate				= @"kGCAppiraterFirstUseDate";
NSString *const kGCAppiraterUseCount					= @"kGCAppiraterUseCount";
NSString *const kGCAppiraterSignificantEventCount		= @"kGCAppiraterSignificantEventCount";
NSString *const kGCAppiraterUserRated		= @"kGCAppiraterRatedCurrentVersion";
NSString *const kGCAppiraterUserDeclinedToRate			= @"kGCAppiraterDeclinedToRate";
NSString *const kGCAppiraterAskAgainDate = @"kGCAppiraterAskAgainDate";
NSString *const kGCAppiraterReminderRequestVersion		= @"kGCAppiraterReminderRequestVersion";

static NSInteger kGCAppiraterTimeIntervalUntilPromptingAgain = 365 * 24 * 60 * 60; // 1 Year

static NSString *templateReviewURL = @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=APP_ID";
static NSString *templateReviewURLiOS7 = @"itms-apps://itunes.apple.com/app/idAPP_ID";
static NSString *templateReviewURLiOS8 = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=APP_ID&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software";

static NSString *_appId;
static double _daysUntilPrompt = 30;
static NSInteger _usesUntilPrompt = 20;
static NSInteger _significantEventsUntilPrompt = -1;
static BOOL _debug = NO;
__weak static id<GCAppiraterDelegate> _delegate;
static UIStatusBarStyle _statusBarStyle;
static BOOL _modalOpen = false;
static BOOL _alwaysUseMainBundle = NO;

typedef enum GCRatingAlertType {
  GCRatingAlertTypeEnjoying = 1000,
  GCRatingAlertTypeBetter,
  GCRatingAlertTypeRate
} GCRatingAlertType;

@interface GCAppirater ()

@property (nonatomic, strong) UIAlertController *alertController;
@property (nonatomic, strong) NSString *lastEventName;

@end

@implementation GCAppirater

+ (void) setAppId:(NSString *)appId {
  _appId = appId;
}

+ (void) setDaysUntilPrompt:(double)value {
  _daysUntilPrompt = value;
}

+ (void) setUsesUntilPrompt:(NSInteger)value {
  _usesUntilPrompt = value;
}

+ (void) setSignificantEventsUntilPrompt:(NSInteger)value {
  _significantEventsUntilPrompt = value;
}

+ (void) setDebug:(BOOL)debug {
  _debug = debug;
}

+ (void)setDelegate:(id<GCAppiraterDelegate>)delegate{
  _delegate = delegate;
}

+ (void)setStatusBarStyle:(UIStatusBarStyle)style {
  _statusBarStyle = style;
}

+ (void)setModalOpen:(BOOL)open {
  _modalOpen = open;
}

+ (void)setAlwaysUseMainBundle:(BOOL)alwaysUseMainBundle {
  _alwaysUseMainBundle = alwaysUseMainBundle;
}

+ (NSBundle *)bundle
{
  NSBundle *bundle;
  
  if (_alwaysUseMainBundle) {
    bundle = [NSBundle mainBundle];
  } else {
    NSURL *appiraterBundleURL = [[NSBundle mainBundle] URLForResource:@"GCAppirater" withExtension:@"bundle"];
    
    if (appiraterBundleURL) {
      // GCAppirater.bundle will likely only exist when used via CocoaPods
      bundle = [NSBundle bundleWithURL:appiraterBundleURL];
    } else {
      bundle = [NSBundle mainBundle];
    }
  }
  
  return bundle;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)connectedToNetwork {
  // Create zero addy
  struct sockaddr_in zeroAddress;
  bzero(&zeroAddress, sizeof(zeroAddress));
  zeroAddress.sin_len = sizeof(zeroAddress);
  zeroAddress.sin_family = AF_INET;
  
  // Recover reachability flags
  SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
  SCNetworkReachabilityFlags flags;
  
  Boolean didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
  CFRelease(defaultRouteReachability);
  
  if (!didRetrieveFlags)
  {
    NSLog(@"Error. Could not recover network reachability flags");
    return NO;
  }
  
  BOOL isReachable = flags & kSCNetworkFlagsReachable;
  BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
  BOOL nonWiFi = flags & kSCNetworkReachabilityFlagsTransientConnection;
  
  NSURL *testURL = [NSURL URLWithString:@"http://www.apple.com/"];
  NSURLRequest *testRequest = [NSURLRequest requestWithURL:testURL  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
  NSURLConnection *testConnection = [[NSURLConnection alloc] initWithRequest:testRequest delegate:self];
  
  return ((isReachable && !needsConnection) || nonWiFi) ? (testConnection ? YES : NO) : NO;
}

+ (GCAppirater*)sharedInstance {
  static GCAppirater *appirater = nil;
  if (appirater == nil)
  {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      appirater = [[[self class] alloc] init];
      appirater.delegate = _delegate;
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(appWillResignActive)
                                                   name:UIApplicationWillResignActiveNotification
                                                 object:nil];
    });
  }
  
  return appirater;
}

- (void)showAlertOfType:(GCRatingAlertType)alertType {
  id <GCAppiraterDelegate> delegate = _delegate;
  
  if(delegate && [delegate respondsToSelector:@selector(appiraterShouldDisplayAlert:)] && ![delegate appiraterShouldDisplayAlert:self]) {
    return;
  }
  
  switch (alertType) {
    case GCRatingAlertTypeEnjoying:
      self.alertController = [self getEnjoyingAlertController];
      break;
    case GCRatingAlertTypeBetter:
      self.alertController = [self getBetterAlertController];
      break;
    case GCRatingAlertTypeRate:
      self.alertController = [self getRateAlertController];
      break;
    default:
      break;
  }
  
  [[[self class] getRootViewController] presentViewController:self.alertController animated:YES completion:nil];
  
  if (delegate && [delegate respondsToSelector:@selector(appiraterDidDisplayAlert:)]) {
    [delegate appiraterDidDisplayAlert:self];
  }
}

- (void)showRatingAlert
{
  [self showAlertOfType:GCRatingAlertTypeEnjoying];
}

- (BOOL)ratingAlertIsAppropriate {
  [self migrateAppiraterData];
  
  return ([self connectedToNetwork]
          && [self userIsEligibleToRate]
          && !self.alertController.presentingViewController);
}

- (BOOL)ratingConditionsHaveBeenMet {
  if (_debug)
    return YES;
  
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  
  if ( [self ratingAlertIsAppropriate] == NO ) {
    return NO;
  }
  
  NSDate *dateOfFirstLaunch = [NSDate dateWithTimeIntervalSince1970:[userDefaults doubleForKey:kGCAppiraterFirstUseDate]];
  NSTimeInterval timeSinceFirstLaunch = [[NSDate date] timeIntervalSinceDate:dateOfFirstLaunch];
  NSTimeInterval timeUntilRate = 60 * 60 * 24 * _daysUntilPrompt;
  if (timeSinceFirstLaunch < timeUntilRate)
    return NO;
  
  // check if the app has been used enough
  NSInteger useCount = [userDefaults integerForKey:kGCAppiraterUseCount];
  if (useCount < _usesUntilPrompt)
    return NO;
  
  // check if the user has done enough significant events
  NSInteger sigEventCount = [userDefaults integerForKey:kGCAppiraterSignificantEventCount];
  if (sigEventCount < _significantEventsUntilPrompt)
    return NO;
  
  // if the user wanted to be reminded later, is it a new version of the app?
  NSString *remindVersion = [userDefaults stringForKey:kGCAppiraterReminderRequestVersion];
  NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
  if ( [remindVersion isEqualToString:version] ) {
    return NO;
  }
  
  return YES;
}

- (void)incrementUseCount {
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  
  // check if the first use date has been set. if not, set it.
  NSTimeInterval timeInterval = [userDefaults doubleForKey:kGCAppiraterFirstUseDate];
  if (timeInterval == 0)
  {
    timeInterval = [[NSDate date] timeIntervalSince1970];
    [userDefaults setDouble:timeInterval forKey:kGCAppiraterFirstUseDate];
  }
  
  // increment the use count
  NSInteger useCount = [userDefaults integerForKey:kGCAppiraterUseCount];
  useCount++;
  [userDefaults setInteger:useCount forKey:kGCAppiraterUseCount];
  if (_debug)
    NSLog(@"APPIRATER Use count: %@", @(useCount));
  
  [userDefaults synchronize];
}

- (void)incrementSignificantEventCount {
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  
  // check if the first use date has been set. if not, set it.
  NSTimeInterval timeInterval = [userDefaults doubleForKey:kGCAppiraterFirstUseDate];
  if (timeInterval == 0)
  {
    timeInterval = [[NSDate date] timeIntervalSince1970];
    [userDefaults setDouble:timeInterval forKey:kGCAppiraterFirstUseDate];
  }
  
  // increment the significant event count
  NSInteger sigEventCount = [userDefaults integerForKey:kGCAppiraterSignificantEventCount];
  sigEventCount++;
  [userDefaults setInteger:sigEventCount forKey:kGCAppiraterSignificantEventCount];
  if (_debug)
    NSLog(@"APPIRATER Significant event count: %@", @(sigEventCount));
  
  [userDefaults synchronize];
}

- (void)incrementAndRate:(BOOL)canPromptForRating {
  [self incrementUseCount];
  
  if ( canPromptForRating &&
      [self ratingConditionsHaveBeenMet] )
  {
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                     [self showRatingAlert];
                   });
  }
}

- (void)incrementSignificantEventAndRate:(BOOL)canPromptForRating {
  [self incrementSignificantEventCount];
  
  if ( canPromptForRating &&
      [self ratingConditionsHaveBeenMet] )
  {
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                     [self showRatingAlert];
                   });
  }
}

#pragma GCC diagnostic pop

+ (void)appLaunched:(BOOL)canPromptForRating {
  [[self class] sharedInstance].lastEventName = nil;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                 ^{
                   GCAppirater *a = [[self class] sharedInstance];
                   if (_debug) {
                     dispatch_async(dispatch_get_main_queue(),
                                    ^{
                                      [a showRatingAlert];
                                    });
                   } else {
                     [a incrementAndRate:canPromptForRating];
                   }
                 });
}

- (void)hideRatingAlert {
  if (self.alertController.parentViewController) {
    if (_debug)
      NSLog(@"APPIRATER Hiding Alert");
    [self.alertController dismissViewControllerAnimated:YES completion:nil];
  }
}

+ (void)appWillResignActive {
  if (_debug)
    NSLog(@"APPIRATER appWillResignActive");
  [[[self class] sharedInstance] hideRatingAlert];
}

+ (void)appEnteredForeground:(BOOL)canPromptForRating {
  [[self class] sharedInstance].lastEventName = nil;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                 ^{
                   [[[self class] sharedInstance] incrementAndRate:canPromptForRating];
                 });
}

+ (void)userDidSignificantEvent:(BOOL)canPromptForRating {
  [[self class] userDidSignificantEvent:canPromptForRating eventName:nil];
}

+ (void)userDidSignificantEvent:(BOOL)canPromptForRating eventName:(NSString *)eventName {
  [[self class] sharedInstance].lastEventName = eventName;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0),
                 ^{
                   [[[self class] sharedInstance] incrementSignificantEventAndRate:canPromptForRating];
                 });
}

#pragma GCC diagnostic pop

+ (void)tryToShowPrompt {
  [[self class] sharedInstance].lastEventName = nil;
  [[[self class] sharedInstance] showPromptWithChecks:true];
}

+ (void)forceShowPrompt {
  [[self class] sharedInstance].lastEventName = nil;
  [[[self class] sharedInstance] showPromptWithChecks:false];
}

- (void)showPromptWithChecks:(BOOL)withChecks {
  if (withChecks == NO || [self ratingAlertIsAppropriate]) {
    [self showRatingAlert];
  }
}

+ (id)getRootViewController {
  UIWindow *window = [[UIApplication sharedApplication] keyWindow];
  if (window.windowLevel != UIWindowLevelNormal) {
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for(window in windows) {
      if (window.windowLevel == UIWindowLevelNormal) {
        break;
      }
    }
  }
  
  return [[self class] iterateSubViewsForViewController:window]; // iOS 8+ deep traverse
}

+ (id)iterateSubViewsForViewController:(UIView *) parentView {
  for (UIView *subView in [parentView subviews]) {
    UIResponder *responder = [subView nextResponder];
    if([responder isKindOfClass:[UIViewController class]]) {
      return [self topMostViewController: (UIViewController *) responder];
    }
    id found = [[self class] iterateSubViewsForViewController:subView];
    if( nil != found) {
      return found;
    }
  }
  return nil;
}

+ (UIViewController *) topMostViewController: (UIViewController *) controller {
  BOOL isPresenting = NO;
  do {
    // this path is called only on iOS 6+, so -presentedViewController is fine here.
    UIViewController *presented = [controller presentedViewController];
    isPresenting = presented != nil;
    if(presented != nil) {
      controller = presented;
    }
    
  } while (isPresenting);
  
  return controller;
}

+ (void)rateApp {
  
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setBool:YES forKey:kGCAppiraterUserRated];
  [userDefaults setObject:[NSDate dateWithTimeIntervalSinceNow:kGCAppiraterTimeIntervalUntilPromptingAgain]
                   forKey:kGCAppiraterAskAgainDate];
  [userDefaults synchronize];
  
#if TARGET_IPHONE_SIMULATOR
  NSLog(@"APPIRATER NOTE: iTunes App Store is not supported on the iOS simulator. Unable to open App Store page.");
#else
  NSString *reviewURL = [templateReviewURL stringByReplacingOccurrencesOfString:@"APP_ID" withString:[NSString stringWithFormat:@"%@", _appId]];
  
  // iOS 8 needs a different templateReviewURL also @see https://github.com/arashpayan/appirater/issues/182
  if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)
  {
    reviewURL = [templateReviewURLiOS8 stringByReplacingOccurrencesOfString:@"APP_ID" withString:[NSString stringWithFormat:@"%@", _appId]];
  }
  
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
#endif
  
}

- (UIAlertController *)getEnjoyingAlertController {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Are you enjoying GameChanger?"
                                                                 message:nil
                                                          preferredStyle:UIAlertControllerStyleAlert];
  __weak GCAppirater *weakSelf = self;
  
  UIAlertAction *notReallyAction = [UIAlertAction actionWithTitle:@"Not Really."
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *action) {
                                                            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                                                            [userDefaults setBool:YES forKey:kGCAppiraterUserDeclinedToRate];
                                                            [userDefaults setObject:[NSDate distantFuture] forKey:kGCAppiraterAskAgainDate];
                                                            [userDefaults synchronize];
                                                            if ( [weakSelf.delegate respondsToSelector:@selector(appiraterChoseNoForEnjoyingAlert:eventName:)] ) {
                                                              [weakSelf.delegate appiraterChoseNoForEnjoyingAlert:weakSelf eventName:self.lastEventName];
                                                            }
                                                            [weakSelf showAlertOfType:GCRatingAlertTypeBetter];
                                                          }];
  UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes!"
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction *action) {
                                                      if ( [weakSelf.delegate respondsToSelector:@selector(appiraterChoseYesForEnjoyingAlert:eventName:)] ) {
                                                        [weakSelf.delegate appiraterChoseYesForEnjoyingAlert:weakSelf eventName:self.lastEventName];
                                                      }
                                                      [weakSelf showAlertOfType:GCRatingAlertTypeRate];
                                                    }];
  
  [alert addAction:notReallyAction];
  [alert addAction:yesAction];
  
  return alert;
}

- (UIAlertController *)getBetterAlertController {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Would you take a moment to tell us what we can do better?"
                                                                 message:nil
                                                          preferredStyle:UIAlertControllerStyleAlert];
  __weak GCAppirater *weakSelf = self;
  
  UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No, thanks."
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                     if ( [weakSelf.delegate respondsToSelector:@selector(appiraterChoseNoForBetterAlert:eventName:)] ) {
                                                       [weakSelf.delegate appiraterChoseNoForBetterAlert:weakSelf eventName:self.lastEventName];
                                                     }
                                                   }];
  UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"Sure."
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                       [weakSelf.delegate appiraterChoseYesForBetterAlert:weakSelf eventName:self.lastEventName];
                                                     }];
  
  [alert addAction:noAction];
  [alert addAction:sureAction];
  return alert;
}

- (UIAlertController *)getRateAlertController {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Would you take a moment to rate us in the App Store?"
                                                                 message:nil
                                                          preferredStyle:UIAlertControllerStyleAlert];
  __weak GCAppirater *weakSelf = self;
  
  UIAlertAction *sureAction = [UIAlertAction actionWithTitle:@"Sure!"
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *action) {
                                                       [[self class] rateApp];
                                                       if ( [weakSelf.delegate respondsToSelector:@selector(appiraterChoseYesForRatingAlert:eventName:)] ) {
                                                         [weakSelf.delegate appiraterChoseYesForRatingAlert:weakSelf eventName:self.lastEventName];
                                                       }
                                                     }];
  UIAlertAction *remindAction = [UIAlertAction actionWithTitle:@"Remind me later."
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                                                         NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                                                         NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
                                                         [userDefaults setObject:version forKey:kGCAppiraterReminderRequestVersion];
                                                         [userDefaults synchronize];
                                                         if ( [weakSelf.delegate respondsToSelector:@selector(appiraterChoseLaterForRatingAlert:eventName:)] ) {
                                                           [weakSelf.delegate appiraterChoseLaterForRatingAlert:weakSelf eventName:self.lastEventName];
                                                         }
                                                       }];
  UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No, thanks."
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                     NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                                                     [userDefaults setBool:YES forKey:kGCAppiraterUserDeclinedToRate];
                                                     [userDefaults setObject:[NSDate dateWithTimeIntervalSinceNow:kGCAppiraterTimeIntervalUntilPromptingAgain]
                                                                      forKey:kGCAppiraterAskAgainDate];
                                                     [userDefaults synchronize];
                                                     if ( [weakSelf.delegate respondsToSelector:@selector(appiraterChoseNoForRatingAlert:eventName:)] ) {
                                                       [weakSelf.delegate appiraterChoseNoForRatingAlert:weakSelf eventName:self.lastEventName];
                                                     }
                                                   }];
  
  [alert addAction:sureAction];
  [alert addAction:remindAction];
  [alert addAction:noAction];
  return alert;
}

- (BOOL)userIsEligibleToRate {
  NSDate *nextRatingDate = [[NSUserDefaults standardUserDefaults] objectForKey:kGCAppiraterAskAgainDate];
  if ( ! nextRatingDate ) {
    return YES;
  } else {
    return [[NSDate date] compare:nextRatingDate] == NSOrderedDescending;
  }
}

- (void)migrateAppiraterData {
  
  if ( ([[NSUserDefaults standardUserDefaults] objectForKey:kGCAppiraterUserRated] ||
        [[NSUserDefaults standardUserDefaults] objectForKey:kGCAppiraterUserDeclinedToRate]) &&
      ! [[NSUserDefaults standardUserDefaults] objectForKey:kGCAppiraterAskAgainDate] ) {
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeIntervalSinceNow:kGCAppiraterTimeIntervalUntilPromptingAgain]
                                              forKey:kGCAppiraterAskAgainDate];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
  
}

@end
