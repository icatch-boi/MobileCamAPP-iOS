//
//  SettingViewController.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-11.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#import "DiskSpaceTool.h"

typedef enum SettingTableInfo {
  SettingTableTextLabel,
  SettingTableDetailTextLabel,
  SettingTableDetailType,
  SettingTableDetailData,
  SettingTableDetailLastItem,
  
}SettingTableInfo;

@protocol SettingDelegate <NSObject>

-(void)goHome;

@end

@interface SettingViewController : UITableViewController <UIAlertViewDelegate, AppDelegateProtocol>
@property (nonatomic, weak) IBOutlet id<SettingDelegate> delegate;
-(void)updateFWCompleted;
-(void)updateFWPowerOff;

@end
