//  Tool.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-19.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "Tool.h"
#import <SystemConfiguration/CaptiveNetwork.h>

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

+ (NSString *)sysSSID
{
    NSString *ssid = nil;
    //NSString *bssid = @"";
    CFArrayRef ifs = CNCopySupportedInterfaces();
    AppLog(@"Supported interfaces: %@", ifs);
    if (ifs) {
        /*
         CNCopyCurrentNetworkInfo
         Returns the network information for the specified interface when the requesting application meets one of following 4 requirements -.
            1. application is using CoreLocation API and has the user's authorization to access location.
            2. application has used the NEHotspotConfiguration API to configure the current Wi-Fi network.
            3. application has active VPN configurations installed.
            4. application has active NEDNSSettingsManager configurations installed.
         */
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo((CFStringRef)CFArrayGetValueAtIndex(ifs, 0));
        /*
         Core Foundation functions have names that indicate when you own a returned object:
         
         Object-creation functions that have “Create” embedded in the name;
         Object-duplication functions that have “Copy” embedded in the name.
         If you own an object, it is your responsibility to relinquish ownership (using CFRelease) when you have finished with it.
         
         */
        CFRelease(ifs);
        if (myDict) {
            NSDictionary *dict = (NSDictionary *)CFBridgingRelease(myDict);
            AppLog(@"The first interface => %@", dict);
            ssid = [dict valueForKey:@"SSID"];
            //bssid = [dict valueForKey:@"BSSID"];
        } else {
            AppLog(@"Supported interface is null");
        }
    }
    AppLog(@"SSID: %@", ssid);
    //AppLog(@"bssid: %@", bssid);
    
    if(!ssid) {
        ssid = @"camera";
    }
    return ssid;
}

@end
