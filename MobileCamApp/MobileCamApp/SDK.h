//
//  SDK.h - Data Access Layer
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-6.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "ICatchtekControl.h"
#include "ICatchtekReliant.h"
#include "ICatchCameraAssist.h"
#import "WifiCamAVData.h"
#import "WifiCamObserver.h"
#include <vector>
#import <Photos/Photos.h>

//#import "PanCamSDK.h"

using namespace std;
//using namespace ipancam;

enum WCFileType {
  WCFileTypeImage  = ICH_FILE_TYPE_IMAGE,
  WCFileTypeVideo  = ICH_FILE_TYPE_VIDEO,
  WCFileTypeAudio  = ICH_FILE_TYPE_AUDIO,
  WCFileTypeText   = ICH_FILE_TYPE_TEXT,
  WCFileTypeAll    = ICH_FILE_TYPE_ALL,
  WCFileTypeUnknow = ICH_FILE_TYPE_UNKNOWN,
};

enum WCRetrunType {
  WCRetSuccess = ICH_SUCCEED,
  WCRetFail,
  WCRetNoSD,
  WCRetSDFUll,
};


@interface SDK : NSObject

@property (nonatomic, readonly) uint previewCacheTime;

#pragma mark - Global
@property (nonatomic) NSMutableArray *downloadArray;
@property (nonatomic) BOOL isBusy;
@property (nonatomic) NSUInteger downloadedTotalNumber;
@property (nonatomic) BOOL connected;
@property (nonatomic, readonly) dispatch_queue_t sdkQueue;
@property (nonatomic, readonly) BOOL isSDKInitialized;
@property (nonatomic, readonly) BOOL isSupportAutoDownload;

//- (ICatchCameraSession *)session;
//- (ICatchCameraConfig *)config;
#pragma mark - API adapter layer
// SDK
+(SDK *)instance;
- (BOOL)disablePTPIP;
- (BOOL)enablePTPIP;
-(BOOL)initializeSDK;
-(void)destroySDK;
-(void)cleanUpDownloadDirectory;
-(void)enableLogSdkAtDiretctory:(NSString *)directoryName enable:(BOOL)enable;
-(BOOL)isConnected;

// MEDIA
- (shared_ptr<ICatchVideoFormat>)getCurrentStreamingInfo;
-(BOOL)isMediaStreamOn;

// CONTROL
-(WCRetrunType)capturePhoto;
-(WCRetrunType)triggerCapturePhoto;
-(BOOL)startMovieRecord;
-(BOOL)stopMovieRecord;
-(BOOL)startTimelapseRecord;
-(BOOL)stopTimelapseRecord;
-(BOOL)formatSD;
-(WCRetrunType)checkSDExist;
-(void)addObserver:(ICatchCamEventID)eventTypeId
          listener:(shared_ptr<ICatchICameraListener>)listener
       isCustomize:(BOOL)isCustomize;
-(void)removeObserver:(ICatchCamEventID)eventTypeId
             listener:(shared_ptr<ICatchICameraListener>)listener
          isCustomize:(BOOL)isCustomize;
-(void)addObserver:(WifiCamObserver *)observer;
-(void)removeObserver:(WifiCamObserver *)observer;
-(BOOL)zoomIn;
-(BOOL)zoomOut;
- (int)changePreviewMode:(ICatchCamPreviewMode)mode;

// Photo gallery
- (BOOL)setFileListAttribute:(NSUInteger)type order:(NSUInteger)order takenBy:(NSUInteger)takenBy;
- (NSUInteger)requestFileCount;
- (vector<shared_ptr<ICatchFile>>)requestFileListOfType:(WCFileType)fileType startIndex:(int)startIndex endIndex:(int)endIndex;
-(vector<shared_ptr<ICatchFile>>)requestFileListOfType:(WCFileType)fileType;
- (vector<shared_ptr<ICatchFile>>)requestHugeFileListOfType:(WCFileType)fileType maxNum:(int)maxNum;
-(UIImage *)requestThumbnail:(shared_ptr<ICatchFile>)file;
-(UIImage *)requestImage:(shared_ptr<ICatchFile>)file;
-(NSString *)p_downloadFile:(shared_ptr<ICatchFile>)f;
-(BOOL)downloadFile:(shared_ptr<ICatchFile>)f;
-(void)cancelDownload;
-(BOOL)deleteFile:(shared_ptr<ICatchFile>)f;
- (BOOL)openFileTransChannel;
- (NSString *)p_downloadFile2:(shared_ptr<ICatchFile>)f;
- (BOOL)closeFileTransChannel;
-(BOOL)downloadFile2:(shared_ptr<ICatchFile>)f;

// Video playback
-(BOOL)videoPlaybackEnabled;
#if 0
-(WifiCamAVData *)getPlaybackFrameData;
-(WifiCamAVData *)getPlaybackAudioData;
- (ICatchFrameBuffer *)getPlaybackAudioData1;
-(NSData *)getPlaybackAudioData2;
-(ICatchVideoFormat)getPlaybackVideoFormat;
-(ICatchAudioFormat)getPlaybackAudioFormat;
-(BOOL)videoPlaybackStreamEnabled;
-(BOOL)audioPlaybackStreamEnabled;
-(double)play:(shared_ptr<ICatchFile>)file;
- (double)play:(shared_ptr<ICatchFile>)file enableAudio:(BOOL)enableAudio isRemote:(BOOL)isRemote;
- (double)playFile:(NSURL *)fileURL enableAudio:(BOOL)enableAudio isRemote:(BOOL)isRemote;
-(BOOL)pause;
-(BOOL)resume;
-(BOOL)stop;
-(BOOL)seek:(double)point;
#endif
//
-(BOOL)isMediaStreamRecording;
-(BOOL)isVideoTimelapseOn;
-(BOOL)isStillTimelapseOn;

// Properties
-(vector<unsigned int>)retrieveSupportedCameraModes;
-(vector<unsigned int>)retrieveSupportedCameraCapabilities;
-(vector<unsigned int>)retrieveSupportedWhiteBalances;
-(vector<unsigned int>)retrieveSupportedCaptureDelays;
-(vector<string>)retrieveSupportedImageSizes;
-(vector<string>)retrieveSupportedVideoSizes;
-(vector<unsigned int>)retrieveSupportedLightFrequencies;
-(vector<unsigned int>)retrieveSupportedBurstNumbers;
-(vector<unsigned int>)retrieveSupportedDateStamps;
-(vector<unsigned int>)retrieveSupportedTimelapseInterval;
-(vector<unsigned int>)retrieveSupportedTimelapseDuration;
-(string)retrieveImageSize;
-(string)retrieveVideoSize;
-(string)retrieveVideoSizeByPropertyCode;
-(unsigned int)retrieveDelayedCaptureTime;
-(unsigned int)retrieveWhiteBalanceValue;
-(unsigned int)retrieveLightFrequency;
-(unsigned int)retrieveBurstNumber;
-(unsigned int)retrieveDateStamp;
-(unsigned int)retrieveTimelapseInterval;
-(unsigned int)retrieveTimelapseDuration;
-(unsigned int)retrieveBatteryLevel;
-(BOOL)checkstillCapture;
-(unsigned int)retrieveFreeSpaceOfImage;
-(unsigned int)retrieveFreeSpaceOfVideo;
-(NSString *)retrieveCameraFWVersion;
-(NSString *)retrieveCameraProductName;
-(uint)retrieveMaxZoomRatio;
-(uint)retrieveCurrentZoomRatio;
-(uint)retrieveCurrentUpsideDown;
-(uint)retrieveCurrentSlowMotion;
-(unsigned int)retrieveCurrentCameraMode;

// Customize Property
- (vector<uint>)retrieveSupportedScreenSaver;
- (uint)retrieveCurrentScreenSaver;
- (vector<uint>)retrieveSupportedAutoPowerOff;
- (uint)retrieveCurrentAutoPowerOff;
- (vector<uint>)retrieveSupportedPowerOnAutoRecord;
- (BOOL)retrieveCurrentPowerOnAutoRecord;
- (vector<uint>)retrieveSupportedExposureCompensation;
- (uint)retrieveCurrentExposureCompensation;
- (vector<uint>)retrieveSupportedImageStabilization;
- (BOOL)retrieveCurrentImageStabilization;
- (vector<uint>)retrieveSupportedVideoFileLength;
- (uint)retrieveCurrentVideoFileLength;
- (vector<uint>)retrieveSupportedFastMotionMovie;
- (uint)retrieveCurrentFastMotionMovie;
- (vector<uint>)retrieveSupportedWindNoiseReduction;
- (BOOL)retrieveCurrentWindNoiseReduction;

// Change properties
-(int)changeImageSize:(string)size;
-(int)changeVideoSize:(string)size;
-(int)changeDelayedCaptureTime:(unsigned int)time;
-(int)changeWhiteBalance:(unsigned int)value;
-(int)changeLightFrequency:(unsigned int)value;
-(int)changeBurstNumber:(unsigned int)value;
-(int)changeDateStamp:(unsigned int)value;
-(int)changeTimelapseType:(ICatchCamPreviewMode)mode;
-(int)changeTimelapseInterval:(unsigned int)value;
-(int)changeTimelapseDuration:(unsigned int)value;
-(int)changeUpsideDown:(uint)value;
-(int)changeSlowMotion:(uint)value;

// Customize property stuff
-(int)getCustomizePropertyIntValue:(int)propid;
-(NSString *)getCustomizePropertyStringValue:(int)propid;
-(BOOL)setCustomizeIntProperty:(int)propid value:(uint)value;
-(BOOL)setCustomizeStringProperty:(int)propid value:(NSString *)value;
-(BOOL)isValidCustomerID:(int)customerid;


// --

-(UIImage *)getAutoDownloadImage;
-(void)updateFW:(string)fwPath;

- (PHFetchResult *)retrieveCameraRollAssetsResult;
- (BOOL)addNewAssetWithURL:(NSURL *)fileURL toAlbum:(NSString *)albumName andFileType:(ICatchFileType)fileType;
- (BOOL)savetoAlbum:(NSString *)albumName andAlbumAssetNum:(uint)assetNum andShareNum:(uint)shareNum;

- (NSArray *)createMediaDirectory;
- (void)writeImageDataToFile:(UIImage *)image andName:(NSString *)fileName;

- (uint)numberOfSensors;
- (BOOL)checkCameraCapabilities:(unsigned int)featureID;

@end

