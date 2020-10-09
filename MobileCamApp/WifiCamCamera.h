//
//  WifiCamPreview.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-16.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_OPTIONS(NSUInteger, WifiCamPreviewMode) {
  WifiCamPreviewModeCameraOff = 1<<0,
  WifiCamPreviewModeCameraOn = 1<<1,
  WifiCamPreviewModeVideoOff = 1<<2,
  WifiCamPreviewModeVideoOn = 1<<3,
  WifiCamPreviewModeTimelapseOff = 1<<4,
  WifiCamPreviewModeTimelapseOn = 1<<5,
};

typedef NS_OPTIONS(NSUInteger, WifiCamTimelapseType) {
  WifiCamTimelapseTypeStill = 1<<0,
  WifiCamTimelapseTypeVideo = 1<<1,
};

typedef NS_OPTIONS(NSUInteger, WifiCamAbility) {
//  WifiCamAbilityStillCapture = 1<<0,
//  WifiCamAbilityMovieRecord = 1<<1,
//  WifiCamAbilityTimeLapse = 1<<2,
//
//  WifiCamAbilityWhiteBalance = 1<<3,
//  WifiCamAbilityDelayCapture = 1<<4,
//  WifiCamAbilityImageSize = 1<<5,
//  WifiCamAbilityVideoSize = 1<<6,
//  WifiCamAbilityLightFrequency = 1<<7,
//  WifiCamAbilityBatteryLevel = 1<<8,
//  WifiCamAbilityProductName = 1<<9,
//  WifiCamAbilityFWVersion = 1<<10,
//  WifiCamAbilityBurstNumber = 1<<11,
//  WifiCamAbilityDateStamp = 1<<12,
//  WifiCamAbilityChangeSSID = 1<<13,
//  WifiCamAbilityChangePwd = 1<<14,
//  WifiCamAbilityUpsideDown = 1<<15,
//  WifiCamAbilitySlowMotion = 1<<16,
//  WifiCamAbilityZoom = 1<<17,
//  WifiCamAbilityStillTimelapse = 1<<18,
//  WifiCamAbilityVideoTimelapse = 1<<19,
//  WifiCamAbilityLatestDelayCapture = 1<<20,
//  WifiCamAbilityGetMovieRecordedTime = 1<<21,
//  WifiCamAbilityDefaultToPlayback = 1<<22,
//  WifiCamAbilityGetFileByPagination = 1<<23,
//    //add - 2017.3.17
//    WifiCamAbilityGetScreenSaverTime = 1<<24,
//    WifiCamAbilityGetAutoPowerOffTime = 1<<25,
//    WifiCamAbilityGetPowerOnAutoRecord = 1<<26,
//    WifiCamAbilityGetExposureCompensation = 1<<27,
//    WifiCamAbilityGetImageStabilization = 1<<28,
//    WifiCamAbilityGetVideoFileLength = 1<<29,
//    WifiCamAbilityGetFastMotionMovie = 1<<30,
//    WifiCamAbilityGetWindNoiseReduction = 1<<31,
//    //add - 2017.6.21
//    WifiCamAbilityNewCaptureWay = 1 <<32,
    WifiCamAbilityStillCapture = 1,
    WifiCamAbilityMovieRecord,
    WifiCamAbilityTimeLapse,
    WifiCamAbilityWhiteBalance,
    WifiCamAbilityDelayCapture,
    WifiCamAbilityImageSize,
    WifiCamAbilityVideoSize,
    WifiCamAbilityLightFrequency,
    WifiCamAbilityBatteryLevel,
    WifiCamAbilityProductName,
    WifiCamAbilityFWVersion,
    WifiCamAbilityBurstNumber,
    WifiCamAbilityDateStamp,
    WifiCamAbilityChangeSSID,
    WifiCamAbilityChangePwd,
    WifiCamAbilityUpsideDown,
    WifiCamAbilitySlowMotion,
    WifiCamAbilityZoom,
    WifiCamAbilityStillTimelapse,
    WifiCamAbilityVideoTimelapse,
    WifiCamAbilityLatestDelayCapture,
    WifiCamAbilityGetMovieRecordedTime,
    WifiCamAbilityDefaultToPlayback,
    WifiCamAbilityGetFileByPagination,
    //add - 2017.3.17
    WifiCamAbilityGetScreenSaverTime,       //0xD720
    WifiCamAbilityGetAutoPowerOffTime,      //0xD721
    WifiCamAbilityGetPowerOnAutoRecord,     //0xD722
    WifiCamAbilityGetExposureCompensation,  //0xD723
    WifiCamAbilityGetImageStabilization,    //0xD724
    WifiCamAbilityGetVideoFileLength,       //0xD725
    WifiCamAbilityGetFastMotionMovie,       //0xD726
    WifiCamAbilityGetWindNoiseReduction,    //0xD727
    //add - 2017.6.21
    WifiCamAbilityNewCaptureWay,
    WifiCamAbilityPIV,
};

@interface WifiCamCamera : NSObject

@property (nonatomic) BOOL exceptionOccured;

@property (nonatomic) NSArray *ability;
@property (nonatomic) ICatchCamMode cameraMode;
@property (nonatomic) string curImageSize;
@property (nonatomic) string curVideoSize;
@property (nonatomic) unsigned int curCaptureDelay;
@property (nonatomic) unsigned int curWhiteBalance;
@property (nonatomic) unsigned int curSlowMotion;
@property (nonatomic) unsigned int curInvertMode;
@property (nonatomic) unsigned int curBurstNumber;
@property (nonatomic) unsigned int storageSpaceForImage;
@property (nonatomic) unsigned int storageSpaceForVideo;
@property (nonatomic) unsigned int curLightFrequency;
@property (nonatomic) unsigned int curDateStamp;
@property (nonatomic) unsigned int curTimelapseInterval;
@property (nonatomic) unsigned int curTimelapseDuration;
@property (nonatomic) NSString *cameraFWVersion;
@property (nonatomic) NSString *cameraProductName;
@property (nonatomic) NSString *ssid;
@property (nonatomic) NSString *password;
@property (nonatomic) WifiCamPreviewMode previewMode;
@property (nonatomic) BOOL movieRecording;
@property (nonatomic) BOOL stillTimelapseOn;
@property (nonatomic) BOOL videoTimelapseOn;
@property (nonatomic) WifiCamTimelapseType timelapseType;
@property (nonatomic) BOOL enableAutoDownload;
@property (nonatomic) BOOL enableAudio;

-(id)initWithParameters:(NSArray *)nAbility
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
         andEnableAudio:(BOOL)bEnableAudio;


@end
