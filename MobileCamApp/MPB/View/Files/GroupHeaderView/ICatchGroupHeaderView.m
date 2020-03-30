// ICatchGroupHeaderView.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2019 by iCatch Technology, Inc.
 *
 *  This software is copyrighted by and is the property of iCatch
 *  Technology, Inc.. All rights are reserved by iCatch Technology, Inc..
 *  This software may only be used in accordance with the corresponding
 *  license agreement. Any unauthorized use, duplication, distribution,
 *  or disclosure of this software is expressly forbidden.
 *
 *  This Copyright notice MUST not be removed or modified without prior
 *  written consent of iCatch Technology, Inc..
 *
 *  iCatch Technology, Inc. reserves the right to modify this software
 *  without notice.
 *
 *  iCatch Technology, Inc.
 *  19-1, Innovation First Road, Science-Based Industrial Park,
 *  Hsin-Chu, Taiwan, R.O.C.
 *
 **************************************************************************/
 
 // Created by zj on 2019/7/24 10:23 AM.
    

#import "ICatchGroupHeaderView.h"
#import "MPBCommonHeader.h"

@interface ICatchGroupHeaderView ()

@property (nonatomic, weak) UIButton *btnGroupTitle;

@property (nonatomic, weak) UILabel *lblCount;

@end

@implementation ICatchGroupHeaderView

// 重写initWithReuseIdentifier方法, 在创建headerView的时候, 同时创建子控件
- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithReuseIdentifier:reuseIdentifier]) {
        // 创建按钮
        UIButton *btnGroupTitle = [[UIButton alloc] init];
        // 设置按钮的图片(三角图片)
        [btnGroupTitle setImage:[UIImage imageNamed:@"buddy_header_arrow"] forState:UIControlStateNormal];
        // 设置按钮的文字颜色
        [btnGroupTitle setTitleColor:RGB_HEX(0x333333, 0.85) forState:UIControlStateNormal];
        // 设置按钮默认的背景图片和高亮时的背景图片
        [btnGroupTitle setBackgroundImage:[UIImage imageNamed:@"buddy_header_bg"] forState:UIControlStateNormal];
        // 设置按钮高亮的背景图片和高亮时的背景图片
        [btnGroupTitle setBackgroundImage:[UIImage imageNamed:@"buddy_header_bg_highlighted"] forState:UIControlStateHighlighted];
        // 设置按钮中内容整体左对齐
        btnGroupTitle.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        // 设置按钮的内容的内边距
        btnGroupTitle.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
        // 设置按钮标题距离左边的边距
        btnGroupTitle.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 0);
        
        // 为按钮增加一个点击事件
        [btnGroupTitle addTarget:self action:@selector(btnGroupTitleClicked) forControlEvents:UIControlEventTouchUpInside];
        
        // 设置按钮中图片的现实模式
        btnGroupTitle.imageView.contentMode = UIViewContentModeCenter;
        // 设置图片框超出的部分不要截掉
        btnGroupTitle.imageView.clipsToBounds = NO;
        btnGroupTitle.titleLabel.font = [UIFont boldSystemFontOfSize:17.0];
        
        [self.contentView addSubview:btnGroupTitle];
        self.btnGroupTitle = btnGroupTitle;
        
        // 创建lable
        UILabel *lblCount = [[UILabel alloc] init];
        lblCount.font = [UIFont systemFontOfSize:16.0];
        lblCount.textColor = RGB_HEX(0x333333, 0.85);
        [self.contentView addSubview:lblCount];
        self.lblCount = lblCount;
    }
    
    return self;
}

// 组标题按钮的点击事件
- (void)btnGroupTitleClicked
{
    // 1. 设置组的状态
    self.group.visible = !self.group.isVisible;
    
    //    // 2.刷新tableView
    // 通过代理来实现
    if ([self.delegate respondsToSelector:@selector(groupHeaderViewDidClickTitleButton:)]) {
        // 调用代理方法
        [self.delegate groupHeaderViewDidClickTitleButton:self];
    }
}

// 当一个新的header view 已经加到某个父控件中的时候执行这个方法。
- (void)didMoveToSuperview {
    if (self.group.isVisible) {
        // 3. 让按钮中的图片实现旋转
        self.btnGroupTitle.imageView.transform = CGAffineTransformMakeRotation(M_PI_2);
    } else {
        self.btnGroupTitle.imageView.transform = CGAffineTransformMakeRotation(0);
    }
}

// 重写group属性的set方法
- (void)setGroup:(ICatchFileGroup *)group
{
    _group = group;
    // 设置数据
    
    // 设置按钮上的文字
    [self.btnGroupTitle setTitle:group.title forState:UIControlStateNormal];
    // 设置 lblCount商的文字
    NSString *subTitle = @(group.fileInfos.count).stringValue;
    if (group.editState) {
        subTitle = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)group.selectedCount, (unsigned long)group.fileInfos.count];
    }
    self.lblCount.text = subTitle;
    
    // 设置按钮中的图片旋转问题
    if (self.group.isVisible) {
        // 3. 让按钮中的图片实现旋转
        self.btnGroupTitle.imageView.transform = CGAffineTransformMakeRotation(M_PI_2);
    } else {
        self.btnGroupTitle.imageView.transform = CGAffineTransformMakeRotation(0);
    }
    
    // 设置frame不要写在这里, 因为在这里获取的当前控件(self)的宽和高都是0
}

// 当当前控件的frame发生改变的时候会调用这个方法
- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // 设置按钮的frame
    self.btnGroupTitle.frame = self.bounds;
    
    // 设置lable的frame
    CGFloat lblW = [self stringSizeWithString:self.lblCount.text font:self.lblCount.font].width;
    CGFloat lblH = CGRectGetHeight(self.bounds);
    CGFloat lblX = CGRectGetWidth(self.bounds) - 10 - lblW;
    CGFloat lblY = 0;
    self.lblCount.frame = CGRectMake(lblX, lblY, lblW, lblH);
}

- (CGSize)stringSizeWithString:(NSString *)str font:(UIFont *)font {
    return [str boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size;
}

@end
