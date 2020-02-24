//
//  WifiCamPreview.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-16.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamCamera.h"


@implementation WifiCamCamera

@synthesize ability;
@synthesize cameraMode;
@synthesize curImageSize;
@synthesize curVideoSize;
@synthesize curCaptureDelay;
@synthesize curWhiteBalance;
@synthesize curSlowMotion;
@synthesize curInvertMode;
@synthesize curBurstNumber;
@synthesize storageSpaceForImage;
@synthesize storageSpaceForVideo;
@synthesize curLightFrequency;
@synthesize curDateStamp;
@synthesize curTimelapseInterval;
@synthesize curTimelapseDuration;
@synthesize cameraFWVersion;
@synthesize cameraProductName;
@synthesize ssid;
@synthesize password;
@synthesize previewMode;
@synthesize movieRecording;
@synthesize stillTimelapseOn;
@synthesize videoTimelapseOn;
@synthesize timelapseType;
@synthesize enableAutoDownload;

-(id)initWithParameters:(NSUInteger)nAbility
          andCameraMode:(ICatchCamMode)nCameraMode
           andImageSize:(string)newImageSize
           andVideoSize:(string)newVideoSize
      andDelayedCapture:(unsigned int)nDelayedCapture
        andWhiteBalance:(unsigned int)nWhiteBalance
          andSlowMotion:(unsigned int)nSlowMotion
          andInvertMode:(unsigned int)nInvertMode
         andBurstNumber:(unsigned int)nBurstNumber
andStorageSpaceForImage:(unsigned int)nStorageSpaceForImage
andStorageSpaceForVideo:(unsigned int)nStorageSpaceForVideo
      andLightFrequency:(unsigned int)nLightFrequency
           andDateStamp:(unsigned int)nDateStamp
   andTimelapseInterval:(unsigned int)nTimelapseInterval
   andTimelapseDuration:(unsigned int)nTimelapseDuration
           andFWVersion:(NSString *)nFWVersion
         andProductName:(NSString *)nProductName
                andSSID:(NSString *)nSSID
            andPassword:(NSString *)nPassword
         andPreviewMode:(WifiCamPreviewMode)mode
    andIsMovieRecording:(BOOL)bRec
  andIsStillTimelapseOn:(BOOL)bStillTimelapseOn
  andIsVideoTimelapseOn:(BOOL)bVideoTimelapseOn
       andTimelapseType:(WifiCamTimelapseType)nTimelapseType
  andEnableAutoDownload:(BOOL)bEnableAutoDownload
         andEnableAudio:(BOOL)bEnableAudio
{
  WifiCamCamera *camera = [[WifiCamCamera alloc] init];
  camera.ability = nAbility;
  camera.cameraMode = nCameraMode;
  camera.curImageSize = newImageSize;
  camera.curVideoSize = newVideoSize;
  camera.curCaptureDelay = nDelayedCapture;
  camera.curWhiteBalance = nWhiteBalance;
  camera.curSlowMotion = nSlowMotion;
  camera.curInvertMode = nInvertMode;
  camera.curBurstNumber = nBurstNumber;
  camera.storageSpaceForImage = nStorageSpaceForImage;
  camera.storageSpaceForVideo = nStorageSpaceForVideo;
  camera.curLightFrequency = nLightFrequency;
  camera.curDateStamp = nDateStamp;
  camera.curTimelapseInterval = nTimelapseInterval;
  camera.curTimelapseDuration = nTimelapseDuration;
  camera.cameraFWVersion = nFWVersion;
  camera.cameraProductName = nProductName;
  camera.ssid = nSSID;
  camera.password = nPassword;
  camera.previewMode = mode;
  camera.movieRecording = bRec;
  camera.stillTimelapseOn = bStillTimelapseOn;
  camera.videoTimelapseOn = bVideoTimelapseOn;
  camera.timelapseType = nTimelapseType;
  camera.enableAutoDownload = bEnableAutoDownload;
  camera.enableAudio = bEnableAudio;
  return camera;
}


@end
