//
//  ICatchTypeSelectReusableView.m
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/3.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import "ICatchTypeSelectReusableView.h"

@interface ICatchTypeSelectReusableView ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation ICatchTypeSelectReusableView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setupLocalizedString];
}

- (void)setupLocalizedString {
    _titleLabel.text = NSLocalizedString(@"kCameraType", nil);
}

@end
