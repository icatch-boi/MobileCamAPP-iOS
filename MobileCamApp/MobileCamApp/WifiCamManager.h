//
//  WifiCamManager.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-18.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WifiCam.h"
#import "Tool.h"

@interface WifiCamManager : NSObject


@property (nonatomic) NSMutableArray *wifiCams;

+(id)instance;

@end
