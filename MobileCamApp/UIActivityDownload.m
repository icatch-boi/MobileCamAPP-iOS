//
//  UIActivityDownload.m
//  WifiCamMobileApp
//
//  Created by Sunmedia on 14-10-16.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "UIActivityDownload.h"

@implementation UIActivityDownload
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
  return NSLocalizedString(@"Download", nil);
}

-(UIImage *)_activityImage
{
  return [UIImage imageNamed:@"UMS_sms_icon"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
  //BOOL bins = [WXApi isWXAppInstalled]&& [WXApi isWXAppSupportApi];
  //if (!bins) {
  //  return NO;
  //}
  /*
  for (id item in activityItems) {
    if ([item isKindOfClass:[UIImage class]]) {
      return YES;
    }
  }
  return NO;
   */
  return YES;
}

-(void)performActivity
{
  NSLog(@"%s", __func__);

  //[self activityDidFinish:YES];
  
  if ([_delegate respondsToSelector:@selector(showDownloadConfirm)]) {
    [_delegate showDownloadConfirm];
  }

}
@end
