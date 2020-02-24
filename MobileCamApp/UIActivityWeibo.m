//
//  UIActivityWeibo.m
//  WifiCamMobileApp
//
//  Created by Sunmedia on 14-10-15.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "UIActivityWeibo.h"
#import "UIActivityItemImage.h"

@interface UIActivityWeibo ()
@property (nonatomic) UIImage *imageForShare;
@property (nonatomic) NSString *messageForShare;
@end

@implementation UIActivityWeibo

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
  return NSLocalizedString(@"Weibo", nil);
}

-(UIImage *)_activityImage
{
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0") && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return [UIImage imageNamed:@"UMS_sina_icon"];
  } else {
    return [UIImage imageNamed:@"UMS_sina_icon"];
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
  //if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeSinaWeibo]) {
    
    //[self activityDidFinish:YES];

    if ([_delegate respondsToSelector:@selector(showSLComposeViewController:)]) {
      [_delegate showSLComposeViewController:SLServiceTypeSinaWeibo];
    }
  //}
}

@end
