//
//  UIImage+MultiFormat.m
//  ZJDataCache
//
//  Created by ZJ on 2019/8/13.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import "UIImage+MultiFormat.h"
#import "NSData+ImageContentType.h"
#import "UIImage+GIF.h"

@implementation UIImage (MultiFormat)

+ (UIImage *)zj_imageWithData:(NSData *)data {
    UIImage *image = nil;
    ZJImageFormat format = [NSData zj_imageFormatForImageData:data];
    if (format == ZJImageFormatGIF) {
        image = [UIImage zj_imageWithData:data];
    } else {
        image = [[UIImage alloc] initWithData:data];
        UIImageOrientation orientation = [self zj_imageOrientationFromImageData:data];
        if (orientation != UIImageOrientationUp) {
            image = [UIImage imageWithCGImage:image.CGImage
                                        scale:image.scale
                                  orientation:orientation];
        }
    }
    
    return image;
}

+ (UIImageOrientation)zj_imageOrientationFromImageData:(NSData *)imageData {
    UIImageOrientation result = UIImageOrientationUp;
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
    if (imageSource) {
        CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
        if (properties) {
            CFTypeRef val;
            int exifOrientation;
            val = CFDictionaryGetValue(properties, kCGImagePropertyOrientation);
            if (val) {
                CFNumberGetValue((CFNumberRef)val, kCFNumberIntType, &exifOrientation);
                result = [self zj_exifOrientationToiOSOrientation:exifOrientation];
            } // else - if it's not set it remains at up
            CFRelease((CFTypeRef) properties);
        } else {
            //NSLog(@"NO PROPERTIES, FAIL");
        }
        CFRelease(imageSource);
    }
    return result;
}

#pragma mark EXIF orientation tag converter
// Convert an EXIF image orientation to an iOS one.
// reference see here: http://sylvana.net/jpegcrop/exif_orientation.html
+ (UIImageOrientation)zj_exifOrientationToiOSOrientation:(int)exifOrientation {
    UIImageOrientation orientation = UIImageOrientationUp;
    switch (exifOrientation) {
        case 1:
            orientation = UIImageOrientationUp;
            break;
            
        case 3:
            orientation = UIImageOrientationDown;
            break;
            
        case 8:
            orientation = UIImageOrientationLeft;
            break;
            
        case 6:
            orientation = UIImageOrientationRight;
            break;
            
        case 2:
            orientation = UIImageOrientationUpMirrored;
            break;
            
        case 4:
            orientation = UIImageOrientationDownMirrored;
            break;
            
        case 5:
            orientation = UIImageOrientationLeftMirrored;
            break;
            
        case 7:
            orientation = UIImageOrientationRightMirrored;
            break;
        default:
            break;
    }
    return orientation;
}

@end
