//
//  NSData+ImageContentType.h
//  ZJDataCache
//
//  Created by ZJ on 2019/8/13.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ZJImageFormat) {
    ZJImageFormatUndefined = -1,
    ZJImageFormatJPEG = 0,
    ZJImageFormatPNG = 1,
    ZJImageFormatGIF= 2,
    ZJImageFormatTIFF = 3,
    ZJImageFormatWebP = 4,
    ZJImageFormatHEIC = 5,
    ZJImageFormatHEIF = 6,
};

@interface NSData (ImageContentType)

+ (ZJImageFormat)zj_imageFormatForImageData:(nullable NSData *)data;

@end

NS_ASSUME_NONNULL_END
