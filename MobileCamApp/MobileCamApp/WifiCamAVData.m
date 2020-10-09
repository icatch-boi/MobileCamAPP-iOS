//
//  WifiCamAVData.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-7-2.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamAVData.h"

@implementation WifiCamAVData

@synthesize data;
@synthesize time;
@synthesize state;

-(id)initWithData:(NSMutableData *)nData andTime:(double)nTime
{
  WifiCamAVData *avData = [[WifiCamAVData alloc] init];
  avData.data = nData;
  avData.time = nTime;
  return avData;
}

@end
