//
//  UIActivityFacebook.m
//  WifiCamMobileApp
//
//  Created by Sunmedia on 14-10-15.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "UIActivityFacebook.h"
#import "UIActivityItemImage.h"

@interface UIActivityFacebook ()
@property (nonatomic) UIImage *imageForShare;
@property (nonatomic) NSString *messageForShare;
@end

@implementation UIActivityFacebook

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
  return NSLocalizedString(@"Facebook", nil);
}

-(UIImage *)_activityImage
{
  // Note: These images need to have a transparent background and I recommend these sizes:
  // iPadShare@2x should be 126 px, iPadShare should be 53 px, iPhoneShare@2x should be 100
  // px, and iPhoneShare should be 50 px. I found these sizes to work for what I was making.
  
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0") && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return [UIImage imageNamed:@"UMS_facebook_icon"];
  } else {
    return [UIImage imageNamed:@"UMS_facebook_icon"];
  }
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
  //BOOL bins = [WXApi isWXAppInstalled]&& [WXApi isWXAppSupportApi];
  //if (!bins) {
  //  return NO;
  //}
  if (activityItems.count == 0 || activityItems.count > 10 || ![SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
    return NO;
  }
  for (id item in activityItems) {
    if (![item isKindOfClass:[UIActivityItemImage class]]) {
      return NO;
    }
  }
  return YES;
}

-(void)prepareWithActivityItems:(NSArray *)activityItems
{
  for (id item in activityItems) {
    if ([item isKindOfClass:[UIImage class]]) {
      _imageForShare =item;
      
    }
    else if([item isKindOfClass:[NSString class]]) {
      _messageForShare =item;
      
    }
    
  }
}

-(void)performActivity
{
  NSLog(@"%s", __func__);

    
  //[self activityDidFinish:YES];
  
  if ([_delegate respondsToSelector:@selector(showSLComposeViewController:)]) {
    [_delegate showSLComposeViewController:SLServiceTypeFacebook];
  }
  
  
  
  // This is where you can do anything you want, and is the whole reason for creating a custom
  // UIActivity
  
  //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=yourappid"]];
  //[self activityDidFinish:YES];
}

@end
