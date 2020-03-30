//
//  ICatchFileTypeView.m
//  MobileCamApp-MPB
//
//  Created by ZJ on 2019/12/31.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import "ICatchFileTypeView.h"

#define kBIGFONT 17
#define kSMALLFONT 14

@interface ICatchFileTypeView ()

@property (weak, nonatomic) IBOutlet UIButton *typeButton;
@property (weak, nonatomic) IBOutlet UIView *underlineView;

@end

@implementation ICatchFileTypeView

+ (instancetype)fileTypeViewWithTitle:(NSString *)title {
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
    
    ICatchFileTypeView *view = [nib instantiateWithOwner:nil options:nil].firstObject;
    
    [view.typeButton setTitle:title forState:UIControlStateNormal];
    
    view.typeButton.titleLabel.font = [UIFont systemFontOfSize:kBIGFONT];
    [view.typeButton.titleLabel sizeToFit];

    view.typeButton.titleLabel.font = [UIFont systemFontOfSize:kSMALLFONT];
    
    return view;
}

// 根据比例改变文字的大小
- (void)setScale:(CGFloat)scale {
    CGFloat max = kBIGFONT * 1.0 / kSMALLFONT - 1;
    
    self.typeButton.transform = CGAffineTransformMakeScale(max * scale + 1, max * scale + 1);
    // 47525E
    [self.typeButton setTitleColor:[UIColor colorWithRed:(71 + 184 * scale)/255.0 green:(1 - scale) * 0x52/255.0 blue:(1 - scale) * 0x5E/255.0 alpha:1] forState:UIControlStateNormal];
    
    self.underlineView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:scale];
}

- (IBAction)typeButtonClick:(id)sender {
    if ([self.delegate respondsToSelector:@selector(clickedActionWithFileTypeView:)]) {
        [self.delegate clickedActionWithFileTypeView:self];
    }
}

@end
