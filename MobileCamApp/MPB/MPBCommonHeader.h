//
//  MPBCommonHeader.h
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/13.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#ifndef MPBCommonHeader_h
#define MPBCommonHeader_h

#import "ICatchFileTable.h"

/// RGB颜色(16进制)
#define RGB_HEX(rgbValue, a) \
[UIColor colorWithRed:((CGFloat)((rgbValue & 0xFF0000) >> 16)) / 255.0 \
green:((CGFloat)((rgbValue & 0xFF00) >> 8)) / 255.0 \
blue:((CGFloat)(rgbValue & 0xFF)) / 255.0 alpha:(a)]

#define iPhoneX [[UIScreen mainScreen] bounds].size.width == 375.0f && [[UIScreen mainScreen] bounds].size.height == 812.0f

typedef NS_ENUM(NSUInteger, MPBDisplayWay) {
    MPBDisplayWayTable,
    MPBDisplayWayNoIconTable,
    MPBDisplayWayCollection,
};

typedef NS_ENUM(NSUInteger, MPBFileType) {
    MPBFileTypeImage,
    MPBFileTypeVideo,
    MPBFileTypeEmergency,
};

typedef void(^ICatchSingleFilePlaybackBlock)(NSIndexPath *indexPath);
typedef void(^ICatchPullupRefreshBlock)();

#endif /* MPBCommonHeader_h */
