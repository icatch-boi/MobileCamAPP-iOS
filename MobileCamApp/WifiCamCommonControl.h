//
//  WifiCamCommonControl.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-23.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MBProgressHUD.h"

@interface WifiCamCommonControl : NSObject


-(void)addObserver:(ICatchCamEventID)eventTypeId
          listener:(shared_ptr<ICatchICameraListener>)listener
       isCustomize:(BOOL)isCustomize;
-(void)removeObserver:(ICatchCamEventID)eventTypeId
             listener:(shared_ptr<ICatchICameraListener>)listener
          isCustomize:(BOOL)isCustomize;
-(void)scheduleLocalNotice:(NSString *)message;
-(double)freeDiskSpaceInKBytes;
-(NSString *)translateSize:(unsigned long long)sizeInKB;

//-
-(void)updateFW:(string)fwPath;
@end
