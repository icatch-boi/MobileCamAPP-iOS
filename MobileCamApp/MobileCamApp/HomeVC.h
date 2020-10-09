//
//  HomeVC.h
//  WifiCamMobileApp
//
//  Created by Guo on 5/19/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
@interface HomeVC : UIViewController<AppDelegateProtocol>{
    NSString * current_ssid;
}
-(void)showReconnectAlert;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSTimer *theTimer;
@end
