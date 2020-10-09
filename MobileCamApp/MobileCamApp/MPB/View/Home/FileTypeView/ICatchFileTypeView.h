//
//  ICatchFileTypeView.h
//  MobileCamApp-MPB
//
//  Created by ZJ on 2019/12/31.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class ICatchFileTypeView;
@protocol ICatchFileTypeViewDelegate <NSObject>

- (void)clickedActionWithFileTypeView:(ICatchFileTypeView *)fileTypeView;

@end

@interface ICatchFileTypeView : UIView

@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, weak) id<ICatchFileTypeViewDelegate> delegate;

+ (instancetype)fileTypeViewWithTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
