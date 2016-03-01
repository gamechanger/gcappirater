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

SPEC_BEGIN(InitialTests)

describe(@"GCAppirater", ^{
  __block GCAppirater *appirater;
  beforeAll(^{
    appirater = [[GCAppirater alloc] init];
  });
  
  context(@"User has rated app w/o ask again date", ^{
    beforeEach(^{
      [[NSUserDefaults standardUserDefaults] objectForKey:kGCAppirater]
    });
    it(@"will set ask again date", ^{
      
      
    });
    
  });
  
  context(@"will fail", ^{

    
      it(@"can do maths", ^{
          [[@1 should] equal:@2];
      });

      it(@"can read", ^{
          [[@"number" should] equal:@"string"];
      });
    
      it(@"will wait and fail", ^{
          NSObject *object = [[NSObject alloc] init];
          [[expectFutureValue(object) shouldEventually] receive:@selector(autoContentAccessingProxy)];
      });
  });

  context(@"will pass", ^{
    
      it(@"can do maths", ^{
        [[@1 should] beLessThan:@23];
      });
    
      it(@"can read", ^{
          [[@"team" shouldNot] containString:@"I"];
      });  
  });
  
});

SPEC_END
