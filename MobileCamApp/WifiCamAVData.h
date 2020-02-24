//
//  WifiCamAVData.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-7-2.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WifiCamAVData : NSObject

@property (nonatomic) double time;
@property (nonatomic) NSMutableData *data;
@property (nonatomic) int state;

-(id)initWithData:(NSMutableData *)nData andTime:(double)nTime;

@end
