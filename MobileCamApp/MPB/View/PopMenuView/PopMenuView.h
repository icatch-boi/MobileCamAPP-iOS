//
//  PopMenuView.h
//  QQPopMenuView
//
//  Created by ZJ on 2019/10/12.
//  Copyright © 2019 ZJ. All rights reserved.
//

/**
 *  类似QQ消息页popMenu
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PopMenuAnimationDirection) {
    PopMenuAnimationDirectionUp,
    PopMenuAnimationDirectionDown,
};

@interface PopMenuView : UIView

@property (nonatomic, copy) void (^hideHandle)();

/**
 *  实例化方法
 *
 *  @param array  items，包含字典，字典里面包含标题（title）、图片名（imageName）
 *  @param width  宽度
 *  @param point  三角的顶角坐标（基于window）
 *  @param action 点击回调
 */
- (instancetype)initWithItems:(NSArray <NSDictionary *>*)array
                        width:(CGFloat)width
             triangleLocation:(CGPoint)point
           animationDirection:(PopMenuAnimationDirection)direction
                       action:(void(^)(NSInteger index))action;

/**
 *  类方法展示
 *
 *  @param array  items，包含字典，字典里面包含标题（title）、图片名（imageName）
 *  @param width  宽度
 *  @param point  三角的顶角坐标（基于window）
 *  @param action 点击回调
 */
+ (void)showWithItems:(NSArray <NSDictionary *>*)array
                width:(CGFloat)width
     triangleLocation:(CGPoint)point
   animationDirection:(PopMenuAnimationDirection)direction
               action:(void(^)(NSInteger index))action;

- (void)show;
- (void)hide;

@end

NS_ASSUME_NONNULL_END
