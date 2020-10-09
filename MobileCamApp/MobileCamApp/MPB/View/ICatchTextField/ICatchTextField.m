//
//  ICatchTextField.m
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/8.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import "ICatchTextField.h"

static void * ICatchTextFieldContext = &ICatchTextFieldContext;

@interface ICatchTextField ()

@property (nonatomic, strong) UIView *tapView;

@end

@implementation ICatchTextField

#pragma mark - Init
- (instancetype)init {
    self = [super init];
    if (self) {
        [self addObserver];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addObserver];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self addObserver];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver];
}

#pragma mark - Observer
- (void)addObserver {
    [self addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:ICatchTextFieldContext];
}

- (void)removeObserver {
    [self removeObserver:self forKeyPath:@"bounds" context:ICatchTextFieldContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == ICatchTextFieldContext) {
        if ([keyPath isEqualToString:@"bounds"]) {
            self.tapView.frame = self.bounds;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setTapActionBlock:(ICatchTapActionBlock)tapActionBlock {
    _tapActionBlock = tapActionBlock;
    self.tapView.hidden = NO;
}

- (UIView *)tapView {
    if (_tapView == nil) {
        _tapView = [[UIView alloc] initWithFrame:self.bounds];
        _tapView.backgroundColor = [UIColor clearColor];
        [self addSubview:_tapView];
        _tapView.userInteractionEnabled = YES;
        UITapGestureRecognizer *myTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(didTapTextField)];
        [_tapView addGestureRecognizer:myTap];
    }
    
    return _tapView;
}

- (void)didTapTextField {
    // 响应点击事件时，隐藏键盘
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow endEditing:YES];
    NSLog(@"点击了textField，执行点击回调");
    if (self.tapActionBlock) {
        self.tapActionBlock();
    }
}

@end
