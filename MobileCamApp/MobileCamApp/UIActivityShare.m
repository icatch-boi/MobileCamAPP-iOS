//
//  UIActivityShare.m
//  WifiCamMobileApp
//
//  Created by zj.feng on 16/7/1.
//  Copyright © 2016年 iCatchTech. All rights reserved.
//

#import "UIActivityShare.h"

@implementation UIActivityShare

- (id)initWithDelegate:(id <ActivityWrapperDelegate>)delegate {
    if ((self = [self init])) {
        _delegate = delegate;
    }
    return self;
}

-(NSString *)activityType
{
    return NSStringFromClass([self class]);
}

-(NSString *)activityTitle
{
    return NSLocalizedString(@"Share", nil);
}

-(UIImage *)_activityImage
{
    return [UIImage imageNamed:@"share"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    return YES;
}

-(void)performActivity
{
    NSLog(@"%s", __func__);
    
    if ([_delegate respondsToSelector:@selector(showShareConfirm)]) {
        [_delegate showShareConfirm];
    }
}

@end
