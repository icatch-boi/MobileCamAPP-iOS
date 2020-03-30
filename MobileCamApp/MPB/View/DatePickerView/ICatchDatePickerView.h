//
//  ICatchDatePickerView.h
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/6.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define KDatePickerViewHeight 300 //260
#define kTopViewHeight 44

#define SCREEN_BOUNDS [UIScreen mainScreen].bounds
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

/// RGB颜色(16进制)
#define RGB_HEX(rgbValue, a) \
[UIColor colorWithRed:((CGFloat)((rgbValue & 0xFF0000) >> 16)) / 255.0 \
green:((CGFloat)((rgbValue & 0xFF00) >> 8)) / 255.0 \
blue:((CGFloat)(rgbValue & 0xFF)) / 255.0 alpha:(a)]

typedef void(^ICatchDateResultBlock)(NSString *selectValue);

@interface ICatchDatePickerView : UIView

- (instancetype)initWithTitle:(NSString *)title defaultSelValue:(NSString *)defaultSelValue isAutoSelect:(BOOL)isAutoSelect resultBlock:(ICatchDateResultBlock)resultBlock;
+ (void)showDatePickerWithTitle:(NSString *)title defaultSelValue:(NSString *)defaultSelValue isAutoSelect:(BOOL)isAutoSelect resultBlock:(ICatchDateResultBlock)resultBlock;
- (void)showWithAnimation:(BOOL)animation;

@end

NS_ASSUME_NONNULL_END
