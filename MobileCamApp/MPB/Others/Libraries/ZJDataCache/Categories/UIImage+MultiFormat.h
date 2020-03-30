//
//  UIImage+MultiFormat.h
//  ZJDataCache
//
//  Created by ZJ on 2019/8/13.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (MultiFormat)

+ (UIImage *)zj_imageWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
