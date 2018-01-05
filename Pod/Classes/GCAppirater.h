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
 * GCAppirater.h
 * GCAppirater
 *
 * Created by Arash Payan on 9/5/09.
 * http://arashpayan.com
 * Copyright 2012 Arash Payan. All rights reserved.
 */

#import <Foundation/Foundation.h>
#import "GCAppiraterDelegate.h"

@interface GCAppirater : NSObject

#if __has_feature(objc_arc_weak)
@property(nonatomic, weak) NSObject <GCAppiraterDelegate> *delegate;
#else
@property(nonatomic, unsafe_unretained) NSObject <GCAppiraterDelegate> *delegate;
#endif

/*!
 Tells Appirater that the app has launched, and on devices that do NOT
 support multitasking, the 'uses' count will be incremented. You should
 call this method at the end of your application delegate's
 application:didFinishLaunchingWithOptions: method.
 
 If the app has been used enough to be rated (and enough significant events),
 you can suppress the rating alert
 by passing NO for canPromptForRating. The rating alert will simply be postponed
 until it is called again with YES for canPromptForRating. The rating alert
 can also be triggered by appEnteredForeground: and userDidSignificantEvent:
 (as long as you pass YES for canPromptForRating in those methods).
 */
+ (void)appLaunched:(BOOL)canPromptForRating;

/*!
 Tells Appirater that the app was brought to the foreground on multitasking
 devices. You should call this method from the application delegate's
 applicationWillEnterForeground: method.
 
 If the app has been used enough to be rated (and enough significant events),
 you can suppress the rating alert
 by passing NO for canPromptForRating. The rating alert will simply be postponed
 until it is called again with YES for canPromptForRating. The rating alert
 can also be triggered by appLaunched: and userDidSignificantEvent:
 (as long as you pass YES for canPromptForRating in those methods).
 */
+ (void)appEnteredForeground:(BOOL)canPromptForRating;

/*!
 Tells Appirater that the user performed a significant event. A significant
 event is whatever you want it to be. If you're app is used to make VoIP
 calls, then you might want to call this method whenever the user places
 a call. If it's a game, you might want to call this whenever the user
 beats a level boss.
 
 If the user has performed enough significant events and used the app enough,
 you can suppress the rating alert by passing NO for canPromptForRating. The
 rating alert will simply be postponed until it is called again with YES for
 canPromptForRating. The rating alert can also be triggered by appLaunched:
 and appEnteredForeground: (as long as you pass YES for canPromptForRating
 in those methods).
 */
+ (void)userDidSignificantEvent:(BOOL)canPromptForRating;
+ (void)userDidSignificantEvent:(BOOL)canPromptForRating eventName:(NSString *)eventName;

/*!
 Tells Appirater to try and show the prompt (a rating alert). The prompt will be showed
 if there is connection available, the user hasn't declined to rate
 or hasn't rated current version.
 
 You could call to show the prompt regardless Appirater settings,
 e.g., in case of some special event in your app.
 */
+ (void)tryToShowPrompt;

/*!
 Tells Appirater to show the prompt (a rating alert).
 Similar to tryToShowPrompt, but without checks (the prompt is always displayed).
 Passing false will hide the rate later button on the prompt.
 
 The only case where you should call this is if your app has an
 explicit "Rate this app" command somewhere. This is similar to rateApp,
 but instead of jumping to the review directly, an intermediary prompt is displayed.
 */
+ (void)forceShowPrompt;

/*!
 Tells Appirater to open the App Store page where the user can specify a
 rating for the app. Also records the fact that this has happened, so the
 user won't be prompted again to rate the app.
 
 The only case where you should call this directly is if your app has an
 explicit "Rate this app" command somewhere.  In all other cases, don't worry
 about calling this -- instead, just call the other functions listed above,
 and let Appirater handle the bookkeeping of deciding when to ask the user
 whether to rate the app.
 */
+ (void)rateApp;

@end

@interface GCAppirater(Configuration)

/*!
 Set your Apple generated software id here.
 */
+ (void) setAppId:(NSString*)appId;

/*!
 Users will need to have the same version of your app installed for this many
 days before they will be prompted to rate it.
 */
+ (void) setDaysUntilPrompt:(double)value;

/*!
 An example of a 'use' would be if the user launched the app. Bringing the app
 into the foreground (on devices that support it) would also be considered
 a 'use'. You tell Appirater about these events using the two methods:
 [Appirater appLaunched:]
 [Appirater appEnteredForeground:]
 
 Users need to 'use' the same version of the app this many times before
 before they will be prompted to rate it.
 */
+ (void) setUsesUntilPrompt:(NSInteger)value;

/*!
 Only works when using Apple's pop up. As we don't know what they user
 answered or even if the user saw a prompt we limit the time between
 consecutive prompts
 */
+ (void) setMinutesBetweenPrompts:(NSInteger)value;

/*!
 A significant event can be anything you want to be in your app. In a
 telephone app, a significant event might be placing or receiving a call.
 In a game, it might be beating a level or a boss. This is just another
 layer of filtering that can be used to make sure that only the most
 loyal of your users are being prompted to rate you on the app store.
 If you leave this at a value of -1, then this won't be a criterion
 used for rating. To tell Appirater that the user has performed
 a significant event, call the method:
 [Appirater userDidSignificantEvent:];
 */
+ (void) setSignificantEventsUntilPrompt:(NSInteger)value;

/*!
 'YES' will show the Appirater alert everytime. Useful for testing how your message
 looks and making sure the link to your app's review page works.
 */
+ (void) setDebug:(BOOL)debug;

/*!
 Set the delegate if you want to know when Appirater does something
 */
+ (void)setDelegate:(id<GCAppiraterDelegate>)delegate;

/*!
 If set to YES, the main bundle will always be used to load localized strings.
 Set this to YES if you have provided your own custom localizations in GCAppiraterLocalizable.strings
 in your main bundle.  Default is NO.
 */
+ (void)setAlwaysUseMainBundle:(BOOL)useMainBundle;

@end


/*!
 Methods in this interface are public out of necessity, but may change without notice
 */
@interface GCAppirater(Unsafe)

/*!
 The bundle localized strings will be loaded from.
 */
+(NSBundle *)bundle;

@end
