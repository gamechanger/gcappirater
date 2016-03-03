//
//  GCAppiraterTests.m
//  GCAppiraterTests
//
//  Created by bernberg11 on 03/01/2016.
//  Copyright (c) 2016 bernberg11. All rights reserved.
//

// https://github.com/kiwi-bdd/Kiwi

#import <Kiwi/Kiwi.h>
#import <GCAppirater/GCAppirater.h>
#import <GCAppirater/GCAppirater+Private.h>

SPEC_BEGIN(InitialTests)

describe(@"GCAppirater", ^{
  __block GCAppirater *appirater;
  __block NSDate *currentDate;
  beforeEach(^{
    appirater = [[GCAppirater alloc] init];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGCAppiraterFirstUseDate];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGCAppiraterUseCount];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGCAppiraterSignificantEventCount];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGCAppiraterUserRated];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGCAppiraterUserDeclinedToRate];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGCAppiraterAskAgainDate];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kGCAppiraterReminderRequestVersion];
    currentDate = [NSDate date];
    [NSDate stub:@selector(date) andReturn:currentDate];
  });
  
  describe(@"migrateAppiraterData", ^{
    __block NSDate *stubDate;
    beforeEach(^{
      stubDate = [NSDate dateWithTimeIntervalSinceNow:kGCAppiraterTimeIntervalUntilPromptingAgain];
      [NSDate stub:@selector(dateWithTimeIntervalSinceNow:) andReturn:stubDate withArguments:any()];
    });
    context(@"User has rated app w/o ask again date", ^{
      beforeEach(^{
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kGCAppiraterUserRated];
      });
      it(@"will set ask again date", ^{
        [appirater migrateAppiraterData];
        NSDate *rateDate = [[NSUserDefaults standardUserDefaults] objectForKey:kGCAppiraterAskAgainDate];
        [[rateDate should] equal:stubDate];
      });
      
    });
    
    context(@"User has declined rating app w/o ask again date", ^{
      beforeEach(^{
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kGCAppiraterUserDeclinedToRate];
      });
      it(@"will set ask again date", ^{
        [appirater migrateAppiraterData];
        NSDate *rateDate = [[NSUserDefaults standardUserDefaults] objectForKey:kGCAppiraterAskAgainDate];
        [[rateDate should] equal:stubDate];
      });
    });
    
    context(@"User has rated but already has ask again date", ^{
      __block NSDate *askAgainDate;
      beforeEach(^{
        askAgainDate = [NSDate date];
        [[NSUserDefaults standardUserDefaults] setObject:askAgainDate forKey:kGCAppiraterAskAgainDate];
      });
      it(@"won't overwrite the ask again date", ^{
        [appirater migrateAppiraterData];
        NSDate *rateDate = [[NSUserDefaults standardUserDefaults] objectForKey:kGCAppiraterAskAgainDate];
        [[rateDate should] equal:askAgainDate];
      });
    });
  });
  
  describe(@"userIsEligibleToRate", ^{
    context(@"No date set for next rating", ^{
      it(@"returns that user is eligible", ^{
        BOOL result = [appirater userIsEligibleToRate];
        [[@(result) should] beTrue];
      });
    });
    context(@"Current date is before Ask Again date", ^{
      beforeEach(^{
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeInterval:100 sinceDate:currentDate] forKey:kGCAppiraterAskAgainDate];
      });
      it(@"returns that user is not eligible", ^{
        BOOL result = [appirater userIsEligibleToRate];
        [[@(result) should] beFalse];
      });
    });
    context(@"Current date is after Ask Again date", ^{
      beforeEach(^{
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate dateWithTimeInterval:-100 sinceDate:currentDate] forKey:kGCAppiraterAskAgainDate];
      });
      it(@"retuns that user is eligible", ^{
        BOOL result = [appirater userIsEligibleToRate];
        [[@(result) should] beTrue];
      });
    });
  });
  
});

SPEC_END

