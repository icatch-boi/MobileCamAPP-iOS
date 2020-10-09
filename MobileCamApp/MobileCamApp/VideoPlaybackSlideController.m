//
//  VideoPlaybackProgressView.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-4-11.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "VideoPlaybackSlideController.h"

@implementation VideoPlaybackSlideController

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

}
*/

-(CGRect)trackRectForBounds:(CGRect)bounds
{
  CGRect result = [super trackRectForBounds:bounds];
  result.size.height = 11.0;
  return result;
    
//    bounds.origin.x=15;
//    bounds.origin.y=bounds.size.height/3;
//    bounds.size.height=bounds.size.height/5;
//    bounds.size.width=bounds.size.width-30;
//    return bounds;
}

- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value
{
    rect.origin.x = rect.origin.x - 10 ;
    rect.size.width = rect.size.width +20;
    return CGRectInset ([super thumbRectForBounds:bounds trackRect:rect value:value], 10 , 10);
}


@end
