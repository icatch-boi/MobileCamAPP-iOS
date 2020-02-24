//
//  UIActivityTencentWeibo.h
//  WifiCamMobileApp
//
//  Created by Sunmedia on 14-10-15.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ActivityWrapper.h"

@interface UIActivityTencentWeibo : UIActivity
@property(nonatomic, weak) id<ActivityWrapperDelegate> delegate;
- (id)initWithDelegate:(id <ActivityWrapperDelegate>)delegate;
@end
