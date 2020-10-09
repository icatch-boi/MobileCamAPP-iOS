//
//  PopupBaseView.m
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/2.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import "PopupBaseView.h"

@implementation PopupBaseView

- (void)initGUI {
    self.frame = SCREEN_BOUNDS;
    self.alertViewHeight = KAlertViewHeight;

    [self addSubview:self.backgroundView];
    [self addSubview:self.alertView];
    [self.alertView addSubview:self.cancelButton];
    [self.alertView addSubview:self.bottomView];
    [self.bottomView addSubview:self.lineView];
    [self.bottomView addSubview:self.leftButton];
    [self.bottomView addSubview:self.rightButton];
}

#pragma mark - 背景遮罩图层
- (UIView *)backgroundView {
    if (_backgroundView == nil) {
        _backgroundView = [[UIView alloc] initWithFrame:SCREEN_BOUNDS];
        _backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        _backgroundView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapBackgroundView:)];
        [_backgroundView addGestureRecognizer:tap];
    }
    
    return _backgroundView;
}

#pragma mark - 弹出视图
- (UIView *)alertView {
    if (_alertView == nil) {
        _alertView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - _alertViewHeight - kBottomViewHeight, SCREEN_WIDTH, _alertViewHeight + kBottomViewHeight)];
        _alertView.backgroundColor = [UIColor whiteColor];
    }
    
    return _alertView;
}

#pragma mark - 底部工具栏视图
- (UIView *)bottomView {
    if (_bottomView == nil) {
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, _alertViewHeight - 0.5, SCREEN_WIDTH, kBottomViewHeight + 0.5)];
        _bottomView.backgroundColor = RGB_HEX(0xFDFDFD, 1.0f);
    }
    
    return _bottomView;
}

#pragma mark - 左边按钮
- (UIButton *)leftButton {
    if (_leftButton == nil) {
        _leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _leftButton.frame = CGRectMake(0, 0, SCREEN_WIDTH * 0.5, kBottomViewHeight);
        _leftButton.backgroundColor = [UIColor clearColor];
        _leftButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
        [_leftButton setTitleColor:RGB_HEX(0xFF7998, 1.0) forState:UIControlStateNormal];
        [_leftButton setTitle:NSLocalizedString(@"kReset", nil) forState:UIControlStateNormal];
        [_leftButton addTarget:self action:@selector(clickLeftButton) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _leftButton;
}

#pragma mark - 右边按钮
- (UIButton *)rightButton {
    if (_rightButton == nil) {
        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _rightButton.frame = CGRectMake(SCREEN_WIDTH * 0.5, 0, SCREEN_WIDTH * 0.5, kBottomViewHeight);
        _rightButton.backgroundColor = RGB_HEX(0xFF7998, 1.0);
        _rightButton.titleLabel.font = [UIFont systemFontOfSize:15.0f];
        [_rightButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_rightButton setTitle:NSLocalizedString(@"kDetermine", nil) forState:UIControlStateNormal];
        [_rightButton addTarget:self action:@selector(clickRightButton) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _rightButton;
}

#pragma mark - 分割线
- (UIView *)lineView {
    if (!_lineView) {
        _lineView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0.5)];
        _lineView.backgroundColor  = [UIColor colorWithRed:225 / 255.0 green:225 / 255.0 blue:225 / 255.0 alpha:1.0];
    }
    
    return _lineView;
}

#pragma mark - 取消按钮
- (UIButton *)cancelButton {
    if (_cancelButton == nil) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _cancelButton.frame = CGRectMake(SCREEN_WIDTH - kTopCancelBtnMargin - kTopCancelBtnHeight, kTopCancelBtnMargin, kTopCancelBtnHeight, kTopCancelBtnHeight);
        [_cancelButton setBackgroundImage:[UIImage imageNamed:@"close@3x"] forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(clickCancelButton) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _cancelButton;
}

#pragma mark - 点击背景遮罩图层事件
- (void)didTapBackgroundView:(UITapGestureRecognizer *)sender {
    
}

#pragma mark - 重置按钮的点击事件
- (void)clickLeftButton {
    
}

#pragma mark - 确定按钮的点击事件
- (void)clickRightButton {
    
}

#pragma mark -  取消按钮的点击事件
- (void)clickCancelButton {
    
}

- (void)setAlertViewHeight:(CGFloat)alertViewHeight {
    if (alertViewHeight > KAlertViewHeight || alertViewHeight <= 0) {
        return;
    }
    
    _alertViewHeight = alertViewHeight;
    
    [self updateSubviewsLayout];
}

- (void)updateSubviewsLayout {
    self.alertView.frame = CGRectMake(0, SCREEN_HEIGHT - _alertViewHeight - kBottomViewHeight, SCREEN_WIDTH, _alertViewHeight + kBottomViewHeight);
    self.bottomView.frame = CGRectMake(0, _alertViewHeight - 0.5, SCREEN_WIDTH, kBottomViewHeight + 0.5);
}

- (void)updateLayout {
    self.frame = SCREEN_BOUNDS;
    self.backgroundView.frame = SCREEN_BOUNDS;
    self.leftButton.frame = CGRectMake(0, 0, SCREEN_WIDTH * 0.5, kBottomViewHeight);
    self.rightButton.frame = CGRectMake(SCREEN_WIDTH * 0.5, 0, SCREEN_WIDTH * 0.5, kBottomViewHeight);
    self.lineView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 0.5);
    self.cancelButton.frame = CGRectMake(SCREEN_WIDTH - kTopCancelBtnMargin - kTopCancelBtnHeight, kTopCancelBtnMargin, kTopCancelBtnHeight, kTopCancelBtnHeight);
}

@end
