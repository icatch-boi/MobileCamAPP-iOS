//
//  UIImage+MemoryCacheCost.h
//  ZJDataCache
//
//  Created by ZJ on 2019/8/9.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (MemoryCacheCost)

@property (nonatomic, assign) NSUInteger zj_memoryCost;

@end

NS_ASSUME_NONNULL_END
