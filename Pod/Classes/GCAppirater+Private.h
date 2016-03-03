//
//  GCAppirater+Private.h
//  GameChanger
//
//  Created by Brian Bernberg on 3/3/16
//  Copyright (c) 2016 GameChanger. All rights reserved.
//

#import "GCAppirater.h"

extern NSString *const kGCAppiraterFirstUseDate;
extern NSString *const kGCAppiraterUseCount;
extern NSString *const kGCAppiraterSignificantEventCount;
extern NSString *const kGCAppiraterUserRated;
extern NSString *const kGCAppiraterUserDeclinedToRate;
extern NSString *const kGCAppiraterAskAgainDate;
extern NSString *const kGCAppiraterReminderRequestVersion;

extern NSInteger const kGCAppiraterTimeIntervalUntilPromptingAgain;

@interface GCAppirater (Private)

- (void)migrateAppiraterData;
- (BOOL)userIsEligibleToRate;
- (BOOL)ratingConditionsHaveBeenMet;
@end