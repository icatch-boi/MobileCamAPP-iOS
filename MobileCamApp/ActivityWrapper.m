//
//  ActivityWrapper.m
//  WifiCamMobileApp
//
//  Created by Sunmedia on 14-10-16.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "ActivityWrapper.h"

@implementation ActivityWrapper
+(NSArray*)additionShartTargets
{
  //UIActivityWeibo* weibo = [[UIActivityWeibo alloc] init];
  //TencentOpenActivity* tencent = [[TencentOpenActivity alloc] init];
  
  return nil;
}

+(void)share:(NSArray*)items from:(UIViewController<ActivityWrapperDelegate> *)vc
{
  UIActivityViewController *activityVC =
  [[UIActivityViewController alloc] initWithActivityItems:items
                                    applicationActivities:[ActivityWrapper additionShartTargets]];
  activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact,UIActivityTypeMessage,UIActivityTypePrint,UIActivityTypeCopyToPasteboard];
  
  //__weak UIViewController<ShareWarperDelegate>* weakRef = vc;
  
  //activityVC.completionHandler = ^(NSString *activityType, BOOL completed){
  //  [weakRef shareTo:activityType completed:completed];
  //};
  
  [vc presentViewController:activityVC animated:YES completion:nil];
}
@end
