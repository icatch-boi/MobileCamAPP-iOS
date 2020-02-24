//
//  WifiCamControl.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-30.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WifiCamControl : NSObject

+(void)scan;

+(WifiCamCamera *)createOneCamera;
+(WifiCamPhotoGallery *)createOnePhotoGallery;

@end
