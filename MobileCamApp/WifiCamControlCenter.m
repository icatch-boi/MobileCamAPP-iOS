//
//  WifiCamControlCenter.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-24.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamControlCenter.h"

@implementation WifiCamControlCenter

@synthesize comCtrl;
@synthesize actCtrl;
@synthesize propCtrl;
@synthesize fileCtrl;
@synthesize pbCtrl;

-(id)initWithParameters:(WifiCamCommonControl *)nComCtrl
     andPropertyControl:(WifiCamPropertyControl *)nPropCtrl
       andActionControl:(WifiCamActionControl *)nActCtrl
         andFileControl:(WifiCamFileControl *)nFileCtrl
     andPlaybackControl:(WifiCamPlaybackControl *)nPBCtrl
{
  WifiCamControlCenter *ctrl = [[WifiCamControlCenter alloc] init];
  ctrl.comCtrl = nComCtrl;
  ctrl.propCtrl = nPropCtrl;
  ctrl.actCtrl = nActCtrl;
  ctrl.fileCtrl = nFileCtrl;
  ctrl.pbCtrl = nPBCtrl;
  return ctrl;
}


@end
