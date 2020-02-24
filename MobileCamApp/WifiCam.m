//
//  WifiCam.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-16.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCam.h"

@implementation WifiCam

@synthesize _id;
@synthesize camera;
@synthesize gallery;
@synthesize controler;

- (id)initWithId:(int)newId
andWifiCamCamera:(WifiCamCamera *)nCamera
andWifiCamPhotoGallery:(WifiCamPhotoGallery *)nGallery
andWifiCamControlCenter:(WifiCamControlCenter *)nController
{
  WifiCam *wifiCam = [[WifiCam alloc] init];
  wifiCam._id = newId;
  wifiCam.camera = nCamera;
  wifiCam.gallery = nGallery;
  wifiCam.controler = nController;
  return wifiCam;
}


@end
