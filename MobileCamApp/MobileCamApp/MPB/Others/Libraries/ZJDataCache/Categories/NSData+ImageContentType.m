//
//  NSData+ImageContentType.m
//  ZJDataCache
//
//  Created by ZJ on 2019/8/13.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import "NSData+ImageContentType.h"

@implementation NSData (ImageContentType)

+ (ZJImageFormat)zj_imageFormatForImageData:(nullable NSData *)data {
    if (data == nil) {
        return ZJImageFormatUndefined;
    }
    
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return ZJImageFormatJPEG;
        case 0x89:
            return ZJImageFormatPNG;
        case 0x47:
            return ZJImageFormatGIF;
        case 0x49:
        case 0x4D:
            return ZJImageFormatTIFF;
        case 0x52: {
            if ([data length] >= 12) {
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
                if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                    return ZJImageFormatWebP;
                }
            }
            break;
        }
        case 0x00: {
            if (data.length >= 12) {
                //....ftypheic ....ftypheix ....ftyphevc ....ftyphevx
                NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(4, 8)] encoding:NSASCIIStringEncoding];
                if ([testString isEqualToString:@"ftypheic"]
                    || [testString isEqualToString:@"ftypheix"]
                    || [testString isEqualToString:@"ftyphevc"]
                    || [testString isEqualToString:@"ftyphevx"]) {
                    return ZJImageFormatHEIC;
                }
                //....ftypmif1 ....ftypmsf1
                if ([testString isEqualToString:@"ftypmif1"] || [testString isEqualToString:@"ftypmsf1"]) {
                    return ZJImageFormatHEIF;
                }
            }
            break;
        }
    }
    return ZJImageFormatUndefined;
}

@end
