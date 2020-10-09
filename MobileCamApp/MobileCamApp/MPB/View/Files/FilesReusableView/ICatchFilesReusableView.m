//
//  ICatchFilesReusableView.m
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/13.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import "ICatchFilesReusableView.h"
#import "MPBCommonHeader.h"

@interface ICatchFilesReusableView ()

@property (weak, nonatomic) IBOutlet UIButton *titleButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation ICatchFilesReusableView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.backgroundColor = RGB_HEX(0xDFDFDF, 1.0);
    // 设置按钮中图片的现实模式
    _titleButton.imageView.contentMode = UIViewContentModeCenter;
    // 设置图片框超出的部分不要截掉
    _titleButton.imageView.clipsToBounds = NO;
}

- (void)setGroup:(ICatchFileGroup *)group {
    _group = group;
    // 设置数据
    
    // 设置按钮上的文字
    [self.titleButton setTitle:group.title forState:UIControlStateNormal];
    // 设置 lblCount商的文字
    NSString *subTitle = @(group.fileInfos.count).stringValue;
    if (group.editState) {
        subTitle = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)group.selectedCount, (unsigned long)group.fileInfos.count];
    }
    self.titleLabel.text = subTitle;
    
    // 设置按钮中的图片旋转问题
    if (self.group.isVisible) {
        // 3. 让按钮中的图片实现旋转
        self.titleButton.imageView.transform = CGAffineTransformMakeRotation(M_PI_2);
    } else {
        self.titleButton.imageView.transform = CGAffineTransformMakeRotation(0);
    }
}

- (IBAction)titleButtonClick:(id)sender {
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
        self.titleButton.imageView.transform = CGAffineTransformMakeRotation(M_PI_2);
    } else {
        self.titleButton.imageView.transform = CGAffineTransformMakeRotation(0);
    }
}

@end
