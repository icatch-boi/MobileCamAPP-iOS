//
//  ICatchPopupCollectionCell.m
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/2.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import "ICatchPopupCollectionCell.h"
#import "PopupViewCommonHeader.h"

@interface ICatchPopupCollectionCell ()

@property (nonatomic, weak) UILabel *titleLabel;

@end

@implementation ICatchPopupCollectionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setupGUI];
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupGUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupGUI];
    }
    return self;
}

- (void)setupGUI {
    self.layer.cornerRadius = CGRectGetHeight(self.bounds) * 0.5;
    self.clipsToBounds = YES;
    self.backgroundColor = RGB_HEX(0xF2F2F2, 1.0f);
    self.userInteractionEnabled = YES;
    
    [self setupTitleLabel];
}

- (void)setupTitleLabel {
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
    titleLabel.textColor = RGB_HEX(0x666666, 1.0f);
    titleLabel.font = [UIFont systemFontOfSize:14.0f];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    
    [self addSubview:titleLabel];
    self.titleLabel = titleLabel;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    
    self.titleLabel.text = title;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    self.titleLabel.textColor = selected ? RGB_HEX(0xFFFFFF, 1.0f) : RGB_HEX(0x666666, 1.0f);
    self.backgroundColor = selected ? RGB_HEX(0xF40C53, 1.0f) : RGB_HEX(0xF2F2F2, 1.0f);
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    
    self.userInteractionEnabled = enabled;
    if (self.selected == NO) {
        self.titleLabel.textColor = enabled ? RGB_HEX(0x666666, 1.0f) : RGB_HEX(0xD2D2D2, 1.0f);
    }
}

@end
