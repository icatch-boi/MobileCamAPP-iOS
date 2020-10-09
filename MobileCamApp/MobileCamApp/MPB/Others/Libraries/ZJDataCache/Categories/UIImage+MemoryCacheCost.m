//
//  UIImage+MemoryCacheCost.m
//  ZJDataCache
//
//  Created by ZJ on 2019/8/9.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import "UIImage+MemoryCacheCost.h"
#import "objc/runtime.h"

FOUNDATION_STATIC_INLINE NSUInteger ZJMemoryCacheCostForImage(UIImage *image) {
    CGImageRef imageRef = image.CGImage;
    if (!imageRef) {
        return 0;
    }
    
    NSUInteger bytesPerFrame = CGImageGetBytesPerRow(imageRef) * CGImageGetHeight(imageRef);
    NSUInteger frameCount;
    frameCount = image.images.count > 0 ? image.images.count : 1;
    NSUInteger cost = bytesPerFrame * frameCount;
    return cost;
}

@implementation UIImage (MemoryCacheCost)

- (NSUInteger)zj_memoryCost {
    NSNumber *value = objc_getAssociatedObject(self, @selector(zj_memoryCost));
    NSUInteger memoryCost;
    if (value != nil) {
        memoryCost = [value unsignedIntegerValue];
    } else {
        memoryCost = ZJMemoryCacheCostForImage(self);
    }
    return memoryCost;
}

- (void)setZj_memoryCost:(NSUInteger)zj_memoryCost {
    objc_setAssociatedObject(self, @selector(zj_memoryCost), @(zj_memoryCost), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
