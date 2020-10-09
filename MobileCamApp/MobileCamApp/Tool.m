//  Tool.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-19.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "Tool.h"

@implementation Tool

+ (NSString *)translateSecsToString:(NSUInteger)secs {
  NSString *retVal = nil;
  int tempHour = 0;
  int tempMinute = 0;
  int tempSecond = 0;
  
  NSString *hour = @"";
  NSString *minute = @"";
  NSString *second = @"";
  
  tempHour = (int)secs / 3600;
  tempMinute = (int)secs / 60 - tempHour * 60;
  tempSecond = (int)secs - (tempHour * 3600 + tempMinute * 60);
  
  //hour = [[NSNumber numberWithInt:tempHour] stringValue];
  //minute = [[NSNumber numberWithInt:tempMinute] stringValue];
  //second = [[NSNumber numberWithInt:tempSecond] stringValue];
  hour = [@(tempHour) stringValue];
  minute = [@(tempMinute) stringValue];
  second = [@(tempSecond) stringValue];
  
  if (tempHour < 10) {
    hour = [@"0" stringByAppendingString:hour];
  }
  
  if (tempMinute < 10) {
    minute = [@"0" stringByAppendingString:minute];
  }
  
  if (tempSecond < 10) {
    second = [@"0" stringByAppendingString:second];
  }
  
  retVal = [NSString stringWithFormat:@"%@:%@:%@", hour, minute, second];
  
  return retVal;
}

+ (UIImage *) mergedImageOnMainImage:(UIImage *)mainImg
                      WithImageArray:(NSArray *)imgArray
                  AndImagePointArray:(NSArray *)imgPointArray
{
  UIImage *ret = nil;
  UIGraphicsBeginImageContext(mainImg.size);
  
  [mainImg drawInRect:CGRectMake(0, 0, mainImg.size.width, mainImg.size.height)];
  int i = 0;
  for (UIImage *img in imgArray) {
    [img drawInRect:CGRectMake([[imgPointArray objectAtIndex:i] floatValue],
                               [[imgPointArray objectAtIndex:i+1] floatValue],
                               img.size.width/2.0,
                               img.size.height/2.0)];
    
    i+=2;
  }
  
  CGImageRef NewMergeImg = CGImageCreateWithImageInRect(UIGraphicsGetImageFromCurrentImageContext().CGImage,
                                                        CGRectMake(0, 0, mainImg.size.width, mainImg.size.height));
  UIGraphicsEndImageContext();
  
  ret = [UIImage imageWithCGImage:NewMergeImg];
  CGImageRelease(NewMergeImg);
  return ret;
}

+(NSString *)bundlePath:(NSString *)fileName {
    return [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:fileName];
}

+(NSString *)documentsPath:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

@end
