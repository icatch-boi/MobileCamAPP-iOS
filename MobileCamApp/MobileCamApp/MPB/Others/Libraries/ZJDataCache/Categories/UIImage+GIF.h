//
//  UIImage+GIF.h
//  ZJDataCache
//
//  Created by ZJ on 2019/8/13.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (GIF)

+ (UIImage *)zj_animatedGIFNamed:(NSString *)name;

+ (UIImage *)zj_animatedGIFWithData:(NSData *)data;

- (UIImage *)zj_animatedImageByScalingAndCroppingToSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
