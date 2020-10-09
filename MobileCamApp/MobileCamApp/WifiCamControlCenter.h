//
//  WifiCamControlCenter.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-24.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WifiCamCommonControl.h"
#import "WifiCamPropertyControl.h"
#import "WifiCamActionControl.h"
#import "WifiCamFileControl.h"
#import "WifiCamPlaybackControl.h"

@interface WifiCamControlCenter : NSObject


#pragma mark - Controler
@property (nonatomic) WifiCamCommonControl *comCtrl;
@property (nonatomic) WifiCamPropertyControl *propCtrl;
@property (nonatomic) WifiCamActionControl *actCtrl;
@property (nonatomic) WifiCamFileControl *fileCtrl;
@property (nonatomic) WifiCamPlaybackControl *pbCtrl;

-(id)initWithParameters:(WifiCamCommonControl *)nComCtrl
     andPropertyControl:(WifiCamPropertyControl *)nPropCtrl
       andActionControl:(WifiCamActionControl *)nActCtrl
         andFileControl:(WifiCamFileControl *)nFileCtrl
     andPlaybackControl:(WifiCamPlaybackControl *)nPBCtrl;

@end
