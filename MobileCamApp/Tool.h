//
//  Tool.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-19.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Tool : NSObject
+(NSString *)translateSecsToString:(NSUInteger)secs;
+(UIImage *)mergedImageOnMainImage:(UIImage *)mainImg
                    WithImageArray:(NSArray *)imgArray
                AndImagePointArray:(NSArray *)imgPointArray;
+(NSString *)bundlePath:(NSString *)fileName;
+(NSString *)documentsPath:(NSString *)fileName;
@end
