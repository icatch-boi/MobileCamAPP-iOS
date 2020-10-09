//
//  PreviewZoomSlider.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-8-28.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "PreviewZoomSlider.h"

@implementation PreviewZoomSlider

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


-(CGRect)trackRectForBounds:(CGRect)bounds
{
  CGRect result = [super trackRectForBounds:bounds];
  result.size.height = 8.0;
  return result;
}

/*
-(UIImage *)thumbImageForState:(UIControlState)state
{
  return [UIImage imageNamed:@"play_icon_volume_ball"];
}
 */
@end
