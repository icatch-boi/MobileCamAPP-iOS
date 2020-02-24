//
//  WifiCam.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-16.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//
// Model classes should reference only other model classes. They should never
// reference views or controllers.
// A model class might have a delegate that happens to be a controller.

#import <Foundation/Foundation.h>
#import "WifiCamCamera.h"
#import "WifiCamPhotoGallery.h"
#import "WifiCamControlCenter.h"


@interface WifiCam : NSObject

@property int _id;

// Camera
@property (nonatomic) WifiCamCamera *camera;
// Photo gallery
@property (nonatomic) WifiCamPhotoGallery *gallery;
// Controler
@property (nonatomic) WifiCamControlCenter *controler;


- (id)initWithId:(int)newId 
andWifiCamCamera:(WifiCamCamera *)nCamera
andWifiCamPhotoGallery:(WifiCamPhotoGallery *)nGallery
andWifiCamControlCenter:(WifiCamControlCenter *)nController;


@end
