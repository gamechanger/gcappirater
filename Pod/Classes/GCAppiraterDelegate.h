//
//  GCAppiraterDelegate.h
//  Banana Stand
//
//  Created by Robert Haining on 9/25/12.
//  Copyright (c) 2012 News.me. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GCAppirater;

@protocol GCAppiraterDelegate <NSObject>
@required
-(void)appiraterChoseYesForBetterAlert:(GCAppirater *)appirater eventName:(NSString *)eventName;

@optional
-(BOOL)appiraterShouldDisplayAlert:(GCAppirater *)appirater;
-(void)appiraterDidDisplayAlert:(GCAppirater *)appirater;

-(void)appiraterChoseYesForEnjoyingAlert:(GCAppirater *)appirater eventName:(NSString *)eventName;
-(void)appiraterChoseNoForEnjoyingAlert:(GCAppirater *)appirater eventName:(NSString *)eventName;

-(void)appiraterChoseNoForBetterAlert:(GCAppirater *)appirater eventName:(NSString *)eventName;

-(void)appiraterChoseYesForRatingAlert:(GCAppirater *)appirater eventName:(NSString *)eventName;
-(void)appiraterChoseLaterForRatingAlert:(GCAppirater *)appirater eventName:(NSString *)eventName;
-(void)appiraterChoseNoForRatingAlert:(GCAppirater *)appirater eventName:(NSString *)eventName;

@end
