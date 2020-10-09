//
//  Cell.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-5.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import "MpbCollectionViewCell.h"

@interface MpbCollectionViewCell ()
@property(weak, nonatomic) IBOutlet UIImageView *selectedComfirmIcon;
@property(weak, nonatomic) IBOutlet UIImageView *videoStaticIcon;
@end

@implementation MpbCollectionViewCell
- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];

  return self;
}

- (void)setVideoStaticIconHidden:(BOOL)value
{
  [self.videoStaticIcon setHidden:value];
}

- (void)setSelectedConfirmIconHidden:(BOOL)value
{
  [self.selectedComfirmIcon setHidden:value];
}
/*
-(void)setSelectedConfirmIconRect:(CGRect)rect
{
  self.selectedComfirmIcon.frame = rect;
}
*/
@end
