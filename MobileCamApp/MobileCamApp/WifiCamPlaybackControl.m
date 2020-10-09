//
//  WifiCamPlaybackControl.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-7-2.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamPlaybackControl.h"

@implementation WifiCamPlaybackControl

- (double)play:(shared_ptr<ICatchFile>)f
{
  return [[PanCamSDK instance] play:(shared_ptr<ICatchFile>)f];
}

- (BOOL)pause
{
  return [[PanCamSDK instance] pause];
}

- (BOOL)resume
{
  return [[PanCamSDK instance] resume];
}

- (BOOL)stop
{
  return [[PanCamSDK instance] stop];
}

- (BOOL)seek:(double)point
{
  return [[PanCamSDK instance] seek:point];
}

- (BOOL)videoPlaybackStreamEnabled {
  return [[PanCamSDK instance] videoPlaybackStreamEnabled];
}

- (BOOL)audioPlaybackStreamEnabled {
  return [[PanCamSDK instance] audioPlaybackStreamEnabled];
}

@end
