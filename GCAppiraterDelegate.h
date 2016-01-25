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

@optional
-(BOOL)appiraterShouldDisplayAlert:(GCAppirater *)appirater;
-(void)appiraterDidDisplayAlert:(GCAppirater *)appirater;
-(void)appiraterDidDeclineToRate:(GCAppirater *)appirater;
-(void)appiraterDidOptToRate:(GCAppirater *)appirater;
-(void)appiraterDidOptToRemindLater:(GCAppirater *)appirater;
-(void)appiraterWillPresentModalView:(GCAppirater *)appirater animated:(BOOL)animated;
-(void)appiraterDidDismissModalView:(GCAppirater *)appirater animated:(BOOL)animated;
@end
