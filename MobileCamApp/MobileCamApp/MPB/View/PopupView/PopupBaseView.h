//
//  PopupBaseView.h
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/2.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PopupViewCommonHeader.h"

@interface PopupBaseView : UIView

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *alertView;
@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;
@property (nonatomic, strong) UIView *lineView;
@property (nonatomic, strong) UIButton *cancelButton;

@property (nonatomic, assign) CGFloat alertViewHeight;

- (void)initGUI;
- (void)updateLayout;

- (void)didTapBackgroundView:(UITapGestureRecognizer *)sender;
- (void)clickLeftButton;
- (void)clickRightButton;
- (void)clickCancelButton;

@end
