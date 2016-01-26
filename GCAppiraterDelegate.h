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
-(void)appiraterChoseYesForBetterAlert:(GCAppirater *)appirater;

@optional
-(BOOL)appiraterShouldDisplayAlert:(GCAppirater *)appirater;
-(void)appiraterDidDisplayAlert:(GCAppirater *)appirater;

-(void)appiraterChoseYesForEnjoyingAlert:(GCAppirater *)appirater;
-(void)appiraterChoseNoForEnjoyingAlert:(GCAppirater *)appirater;

-(void)appiraterChoseNoForBetterAlert:(GCAppirater *)appirater;

-(void)appiraterChoseYesForRatingAlert:(GCAppirater *)appirater;
-(void)appiraterChoseLaterForRatingAlert:(GCAppirater *)appirater;
-(void)appiraterChoseNoForRatingAlert:(GCAppirater *)appirater;

@end
