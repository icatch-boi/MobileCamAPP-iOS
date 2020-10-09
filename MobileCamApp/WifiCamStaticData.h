//
//  WifiCamStaticData.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-24.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WifiCamStaticData : NSObject

+ (WifiCamStaticData *)instance;

#pragma mark - Gloabl static table
@property(nonatomic, readonly) NSDictionary *captureDelayDict;
@property(nonatomic, readonly) NSDictionary *videoSizeDict;
@property(nonatomic, readonly) NSDictionary *imageSizeDict;
@property(nonatomic, readonly) NSDictionary *awbDict;
@property(nonatomic, readonly) NSDictionary *burstNumberDict;
@property(nonatomic, readonly) NSDictionary *delayCaptureDict;
@property(nonatomic, readonly) NSDictionary *whiteBalanceDict;
//@property(nonatomic, readonly) NSDictionary *whiteBalanceDict2;
@property(nonatomic, readonly) NSDictionary *burstNumberStringDict;
@property(nonatomic, readonly) NSDictionary *powerFrequencyDict;
@property(nonatomic, readonly) NSDictionary *dateStampDict;
@property(nonatomic, readonly) NSDictionary *noFileNoticeDict;
//@property(nonatomic, readonly) NSDictionary *videoTimelapseIntervalDict;
@property(nonatomic, readonly) NSDictionary *timelapseIntervalDict;
//@property(nonatomic, readonly) NSDictionary *videoTimelapseDurationDict;
@property(nonatomic, readonly) NSDictionary *timelapseDurationDict;

@property(nonatomic, readonly) NSDictionary *liveSizeDict;

+ (NSString *)deviceInfo;
@end
