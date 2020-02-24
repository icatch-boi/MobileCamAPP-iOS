//
//  SettingDetailViewController.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-19.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
typedef enum SettingDetailType{
  SettingDetailTypeWhiteBalance = 0,
  SettingDetailTypePowerFrequency,
  SettingDetailTypeBurstNumber,
  SettingDetailTypeAbout,
  SettingDetailTypeDateStamp,
  SettingDetailTypeTimelapseType,
  SettingDetailTypeTimelapseInterval,
  SetttngDetailTypeTimelapseDuration,
  SettingDetailTypeUpsideDown,
  SettingDetailTypeSlowMotion,
  SettingDetailTypeImageSize,
  SettingDetailTypeVideoSize,
  SettingDetailTypeCaptureDelay,
  SettingDetailTypeLiveSize,
  
}SettingDetailType;

@interface SettingDetailViewController : UITableViewController <AppDelegateProtocol>

@property NSArray *subMenuTable;
@property NSInteger curSettingDetailType;
@property NSInteger curSettingDetailItem;

@end
