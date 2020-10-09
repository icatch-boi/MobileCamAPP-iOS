//
//  UIActivityShare.h
//  WifiCamMobileApp
//
//  Created by zj.feng on 16/7/1.
//  Copyright © 2016年 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIActivityShare : UIActivity

@property(nonatomic, weak) id<ActivityWrapperDelegate> delegate;
- (id)initWithDelegate:(id <ActivityWrapperDelegate>)delegate;
@end
