//
//  UIActivityTencentWeibo.m
//  WifiCamMobileApp
//
//  Created by Sunmedia on 14-10-15.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "UIActivityTencentWeibo.h"
#import "UIActivityItemImage.h"

@implementation UIActivityTencentWeibo
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
  return NSLocalizedString(@"TencentWeibo", nil);
}

-(UIImage *)_activityImage
{
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0") && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return [UIImage imageNamed:@"UMS_tencent_icon"];
  } else {
    return [UIImage imageNamed:@"UMS_tencent_icon"];
  }
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
  //BOOL bins = [WXApi isWXAppInstalled]&& [WXApi isWXAppSupportApi];
  //if (!bins) {
  //  return NO;
  //}
  if (activityItems.count != 1) {
    return NO;
  }
  for (id item in activityItems) {
    if (![item isKindOfClass:[UIActivityItemImage class]]) {
      return NO;
    }
  }
  return YES;
}

-(void)performActivity
{
  NSLog(@"%s", __func__);
  //if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTencentWeibo]) {
    
    //[self activityDidFinish:YES];
    
    if ([_delegate respondsToSelector:@selector(showSLComposeViewController:)]) {
      [_delegate showSLComposeViewController:SLServiceTypeTencentWeibo];
    }
  //}
}

@end
