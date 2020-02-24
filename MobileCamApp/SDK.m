//
//  SDK.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-6.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import "SDK.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#include "ICatchCameraConfig.h"
//#include "WiFiCamH264StreamParameter.h"

#include "CustomerStreamParam.hpp"

@interface SDK ()
@property (nonatomic) shared_ptr<ICatchCameraSession> session1;
//@property (nonatomic) shared_ptr<ICatchPancamPreview> preview;
@property (nonatomic) shared_ptr<ICatchCameraControl> control;
@property (nonatomic) shared_ptr<ICatchCameraProperty> prop;
@property (nonatomic) shared_ptr<ICatchCameraPlayback> playback;
//@property (nonatomic) shared_ptr<ICatchPancamVideoPlayback> vplayback;
@property (nonatomic) shared_ptr<ICatchCameraState> sdkState;
@property (nonatomic) shared_ptr<ICatchCameraInfo> sdkInfo;

@property (nonatomic) shared_ptr<ICatchCameraConfig> config1;
@property (nonatomic) shared_ptr<ICatchCameraAssist> assist;

@property (nonatomic) shared_ptr<ICatchFrameBuffer> videoFrameBufferA;
@property (nonatomic) shared_ptr<ICatchFrameBuffer> videoFrameBufferB;
@property (nonatomic) BOOL curVideoFrameBufferA;
@property (nonatomic) shared_ptr<ICatchFrameBuffer> audioTrackBufferA;
@property (nonatomic) shared_ptr<ICatchFrameBuffer> audioTrackBufferB;
@property (nonatomic) BOOL curAudioTrackBufferA;

@property (nonatomic) NSMutableData *videoData;
@property (nonatomic) NSMutableData *audioData;
@property (nonatomic) NSMutableData *videoPlaybackData;
@property (nonatomic) NSMutableData *audioPlaybackData;

@property (nonatomic) UIImage *autoDownloadImage;
@property (nonatomic) BOOL isStopped;
@property (nonatomic, readwrite) dispatch_queue_t sdkQueue;
@property (nonatomic, readwrite) BOOL isSDKInitialized;
@property (nonatomic, readwrite) BOOL isSupportAutoDownload;

@property (nonatomic) NSRange videoRange;
@property (nonatomic) NSRange audioRange;
@end

@implementation SDK

//@synthesize curPVFileIndex = _curPVFileIndex;

@synthesize downloadArray;
@synthesize downloadedTotalNumber;
@synthesize sdkQueue;
@synthesize isSDKInitialized;
@synthesize isSupportAutoDownload;

#pragma mark - SDK status

+ (SDK *)instance {
    static SDK *instance = nil;
    /*
     @synchronized(self) {
     if(!instance) {
     instance = [[self alloc] init];
     }
     }
     */
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] initSingleton];
        instance.sdkQueue = dispatch_queue_create("WifiCam.GCD.Queue.SDKQ", DISPATCH_QUEUE_SERIAL);
    });
    return instance;
    
}

- (id)init {
    // Forbid calls to –init or +new
    NSAssert(NO, @"Cannot create instance of Singleton");
    
    // You can return nil or [self initSingleton] here,
    // depending on how you prefer to fail.
    return nil;
}

// Real (private) init method
- (id)initSingleton {
    if (self = [super init]) {
        // Init code
    }
    return self;
}

- (BOOL)disablePTPIP {
    bool ret = false;
    ret = self.config1->disablePTPIP();
    
    return ret == true ? YES : NO;
}

- (BOOL)enablePTPIP {
    bool ret = false;
    ret = self.config1->enablePTPIP();
    
    return ret == true ? YES : NO;
}

- (BOOL)initializeSDK {
    __block BOOL ret = NO;
    do {
        AppLog(@"---START INITIALIZE SDK(Data Access Layer)---");
        if (isSDKInitialized) {
            ret = YES;
            break;
        }
        
        self.session1 = ICatchCameraSession::createSession(100);
        
#if (SDK_DEBUG==1)
        auto log = ICatchCameraLog::getInstance();
        log->setDebugMode(true);
        log->setSystemLogOutput( true );
        log->setLog(ICH_CAM_LOG_TYPE_COMMON, true);
        log->setLogLevel(ICH_CAM_LOG_TYPE_COMMON, ICH_CAM_LOG_LEVEL_INFO);
        log->setLog(ICH_CAM_LOG_TYPE_THIRDLIB, true);
        log->setLogLevel(ICH_CAM_LOG_TYPE_THIRDLIB, ICH_CAM_LOG_LEVEL_INFO);
#endif
        
        if (self.session1 == NULL) {
            AppLog(@"Create session failed.");
            break;
        }
        
        AppLog(@"prepareSession");
        auto itrs = make_shared<ICatchINETTransport>([self getCameraIpAddr].UTF8String);
        if (self.session1->prepareSession(itrs) != ICH_SUCCEED)
        {
            AppLog(@"prepareSession failed");
            break;
        } else {
            if (self.session1->checkConnection() == false) {
                AppLog(@"self.session1 check camera connection return false.");
                break;
            }
        }
        AppLog(@"prepareSession done");
        
//        self.preview = self.session1->getPreviewClient();
        self.control = self.session1->getControlClient();
        self.prop = self.session1->getPropertyClient();
        self.playback = self.session1->getPlaybackClient();
//        self.vplayback = self.session1->getVideoPlaybackClient();
        self.sdkState = self.session1->getStateClient();
        self.sdkInfo = self.session1->getInfoClient();
        if (/*!_preview ||*/ !_control || !_prop || !_playback || !_sdkState || !_sdkInfo) {
            AppLog(@"SDK objects were nil");
            break;
        }
        
        self.config1 = self.session1->getCameraConfig(itrs);
        self.assist = self.session1->getCameraAssist(itrs);
        
        self.videoFrameBufferA = make_shared<ICatchFrameBuffer>(640 * 480 * 2);
        self.videoFrameBufferB = make_shared<ICatchFrameBuffer>(640 * 480 * 2);
        self.curVideoFrameBufferA = YES;
        self.audioTrackBufferA = make_shared<ICatchFrameBuffer>(1024 * 50);
        self.audioTrackBufferB = make_shared<ICatchFrameBuffer>(1024 * 50);
        self.curAudioTrackBufferA = YES;
        self.videoRange = NSMakeRange(0, 640 * 480 * 2);
        self.videoData = [[NSMutableData alloc] initWithCapacity:640 * 480 * 2];
        self.audioRange = NSMakeRange(0, 1024 * 50);
        self.audioData = [[NSMutableData alloc] init];
        self.audioPlaybackData = [[NSMutableData alloc] init];
        self.downloadArray = [[NSMutableArray alloc] init];
        ret = YES;
        
    } while (0);
    
    if (ret) {
        @synchronized(self) {
            isSDKInitialized = YES;
        }
        AppLog(@"---End---");
    } else {
        isSDKInitialized = NO;
        AppLog(@"---INITIALIZE SDK Failed---");
        if (self.session1) {
            self.session1 = NULL;
        }
    }
    
    return ret;
}

- (NSString *)getCameraIpAddr
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL enableLive = [defaults boolForKey:@"PreferenceSpecifier:YouTube_Live"];
    NSString *ipAddr = [defaults stringForKey:@"ipAddr"];
    AppLog(@"ipAddr: %@", ipAddr);
    
    if (enableLive && ipAddr) {
        return ipAddr;
    } else {
        return @"192.168.1.1";
    }
}

- (void)destroySDK
{
    @synchronized(self) {
        isSDKInitialized = NO;
    }
    if (self.session1) {
        AppLog(@"start destory session");
        self.session1->destroySession();
        self.session1 = NULL;
        AppLog(@"destory session done");
    }
    
    if (_videoFrameBufferA) {
        _videoFrameBufferA = NULL;
    }
    if (_videoFrameBufferB) {
        _videoFrameBufferB = NULL;
    }
    if (_audioTrackBufferA) {
        _audioTrackBufferA = NULL;
    }
    if (_audioTrackBufferB) {
        _audioTrackBufferB = NULL;
    }
    
//    self.preview = NULL;
    self.control = NULL;
    self.prop = NULL;
    self.playback = NULL;
//    self.vplayback = NULL;
    self.sdkState = NULL;
    self.sdkInfo = NULL;
    AppLog(@"Over");
}

-(void)cleanUpDownloadDirectory
{
    [self cleanTemp];
}

-(void)enableLogSdkAtDiretctory:(NSString *)directoryName
                         enable:(BOOL)enable
{
    auto log = ICatchCameraLog::getInstance();
    if (enable) {
        log->setFileLogPath(string([directoryName UTF8String]));
        log->setFileLogOutput(true);
        log->setSystemLogOutput(false);
        log->setLog(ICH_CAM_LOG_TYPE_COMMON, true);
        log->setLogLevel(ICH_CAM_LOG_TYPE_COMMON, ICH_CAM_LOG_LEVEL_DEBUG);
        log->setLog(ICH_CAM_LOG_TYPE_THIRDLIB, true);
        log->setLogLevel(ICH_CAM_LOG_TYPE_THIRDLIB, ICH_CAM_LOG_LEVEL_DEBUG);
        log->setDebugMode(true);
    } else {
        log->setFileLogOutput(false);
        log->setSystemLogOutput(false);
        log->setLog(ICH_CAM_LOG_TYPE_COMMON, false);
        log->setLog(ICH_CAM_LOG_TYPE_THIRDLIB, false);
    }
}

-(BOOL)isConnected
{
    BOOL retVal = NO;
    if (self.session1 && self.session1->checkConnection()) {
        retVal = YES;
    }
    return retVal;
}

-(NSString *)retrieveCameraFWVersion
{
    return [NSString stringWithFormat:@"%s", _sdkInfo->getCameraFWVersion().c_str()];
}

-(NSString *)retrieveCameraProductName
{
    return [NSString stringWithFormat:@"%s", _sdkInfo->getCameraProductName().c_str()];
}

#pragma mark - Properties
-(vector<unsigned int>)retrieveSupportedCameraModes
{
    vector<unsigned int> supportedCameraModes;
    if (_control) {
        _control->getSupportedModes(supportedCameraModes);
    }
    
    return supportedCameraModes;
}

-(vector<unsigned int>)retrieveSupportedCameraCapabilities
{
    vector<unsigned int> supportedCameraCapability;
    if (_prop) {
        _prop->getSupportedProperties(supportedCameraCapability);
    }
    
    return supportedCameraCapability;
}

-(vector<unsigned int>)retrieveSupportedWhiteBalances
{
    vector<unsigned int> supportedWhiteBalances;
    if (_prop) {
        _prop->getSupportedWhiteBalances(supportedWhiteBalances);
    }
    return supportedWhiteBalances;
}

-(vector<unsigned int>)retrieveSupportedCaptureDelays
{
    vector<unsigned int> supportedCaptureDelays;
    if (_prop) {
        _prop->getSupportedCaptureDelays(supportedCaptureDelays);
    }
    return supportedCaptureDelays;
}

-(vector<string>)retrieveSupportedImageSizes
{
    vector<string> supportedImageSizes;
    if (_prop) {
        _prop->getSupportedImageSizes(supportedImageSizes);
    }
    return supportedImageSizes;
}

-(vector<string>)retrieveSupportedVideoSizes
{
    vector<string> supportedVideoSizes;
    if (_prop) {
        _prop->getSupportedVideoSizes(supportedVideoSizes);
    }
    return supportedVideoSizes;
}

-(vector<unsigned int>)retrieveSupportedLightFrequencies
{
    vector<unsigned int> supportedLightFrequencies;
    if (_prop) {
        _prop->getSupportedLightFrequencies(supportedLightFrequencies);
    }
    
    // Erase some items within vector
    NSMutableArray *a = [[NSMutableArray alloc] init];
    int i = 0;
    for (vector<unsigned int>::iterator it = supportedLightFrequencies.begin();
         it != supportedLightFrequencies.end();
         ++it, ++i) {
        if (*it == ICH_CAM_LIGHT_FREQUENCY_AUTO || *it == ICH_CAM_LIGHT_FREQUENCY_UNDEFINED) {
            //[a addObject:[NSNumber numberWithInt:i]];
            [a addObject:@(i)];
        }
    }
    for (i=0; i<a.count; ++i) {
        supportedLightFrequencies.erase(supportedLightFrequencies.begin()+i);
    }
    
    AppLog(@"_supportedLightFrequencies.size: %lu", supportedLightFrequencies.size());
    return supportedLightFrequencies;
}

-(vector<unsigned int>)retrieveSupportedBurstNumbers
{
    vector<unsigned int> supportedBurstNumbers;
    if (_prop) {
        _prop->getSupportedBurstNumbers(supportedBurstNumbers);
    }
    //  for(vector<unsigned int>::iterator it = supportedBurstNumbers.begin();
    //      it != supportedBurstNumbers.end();
    //      ++it) {
    //    AppLog(@"%d", *it);
    //  }
    return supportedBurstNumbers;
}

-(vector<unsigned int>)retrieveSupportedDateStamps
{
    vector<unsigned int> supportedDataStamps;
    if (_prop) {
        _prop->getSupportedDateStamps(supportedDataStamps);
    }
    return supportedDataStamps;
}

-(vector<unsigned int>)retrieveSupportedTimelapseInterval
{
    vector<unsigned int> supportedTimelapseIntervals;
    if (_prop) {
        _prop->getSupportedTimeLapseIntervals(supportedTimelapseIntervals);
    }
    AppLog(@"This size of supportedVideoTimelapseIntervals: %lu", supportedTimelapseIntervals.size());
    return supportedTimelapseIntervals;
}

-(vector<unsigned int>)retrieveSupportedTimelapseDuration
{
    vector<unsigned int> supportedTimelapseDurations;
    if (_prop) {
        _prop->getSupportedTimeLapseDurations(supportedTimelapseDurations);
    }
    AppLog(@"This size of supportedVideoTimelapseDurations: %lu", supportedTimelapseDurations.size());
    return supportedTimelapseDurations;
}

-(string)retrieveImageSize {
    string curImageSize="";
    if (_prop) {
        int ret = _prop->getCurrentImageSize(curImageSize);
        AppLog(@"ret: %d, imageSize: %s", ret, curImageSize.c_str());
    }
    return curImageSize;
}
-(string)retrieveVideoSizeByPropertyCode {
    string curVideoSize ="";
    if (_prop) {
        _prop->getCurrentPropertyValue(0xD605, curVideoSize);
    }
    return curVideoSize;
}
-(string)retrieveVideoSize {
    string curVideoSize ="";
    if (_prop) {
        _prop->getCurrentVideoSize(curVideoSize);
    }
    return curVideoSize;
}

-(unsigned int)retrieveDelayedCaptureTime {
    unsigned int curCaptureDelay = 0;
    if (_prop) {
        self.prop->getCurrentCaptureDelay(curCaptureDelay);
    }
    return curCaptureDelay;
}

-(unsigned int)retrieveWhiteBalanceValue {
    unsigned int curWhiteBalance = 0;
    if (_prop) {
        _prop->getCurrentWhiteBalance(curWhiteBalance);
    }
    return curWhiteBalance;
}

-(unsigned int)retrieveLightFrequency {
    unsigned int curLightFrequency = 0;
    if (_prop) {
        _prop->getCurrentLightFrequency(curLightFrequency);
    }
    return curLightFrequency;
}
-(unsigned int)retrieveBurstNumber {
    unsigned int curBurstNumber = 0;
    if (_prop) {
        _prop->getCurrentBurstNumber(curBurstNumber);
    }
    AppLog(@"curBurstNumber: %d", curBurstNumber);
    return curBurstNumber;
}

-(unsigned int)retrieveDateStamp {
    unsigned int curDateStamp = 0 ;
    if (_prop) {
        _prop->getCurrentDateStamp(curDateStamp);
    }
    return curDateStamp;
}

-(unsigned int)retrieveTimelapseInterval {
    unsigned int curVideoTimelapseInterval = 0;
    if (_prop) {
        _prop->getCurrentTimeLapseInterval(curVideoTimelapseInterval);
    }
    AppLog(@"Re-Get timelapse interval[RAW]: %d", curVideoTimelapseInterval);
    return curVideoTimelapseInterval;
}

-(unsigned int)retrieveTimelapseDuration {
    unsigned int curVideoTimelapseDuration = 0;
    if (_prop) {
        _prop->getCurrentTimeLapseDuration(curVideoTimelapseDuration);
    }
    AppLog(@"curVideoTimelapseDuration: %d", curVideoTimelapseDuration);
    return curVideoTimelapseDuration;
}

-(unsigned int)retrieveBatteryLevel {
    unsigned int curBatteryLevel = 0;
    if (_control) {
        _control->getCurrentBatteryLevel(curBatteryLevel);
    }
    
    return curBatteryLevel;
}

-(BOOL)checkstillCapture {
    uint num = 0;
    if (!_control) {
        AppLog(@"SDK doesn't work!!!");
        return NO;
    }
    
    int ret = _control->getFreeSpaceInImages(num);
    if (ret == ICH_SUCCEED && num == 0) {
        return NO;
    } else {
        return  YES;
    }
}

-(unsigned int)retrieveFreeSpaceOfImage {
//    unsigned int photoNum = 0;
//    uint num = 0;
//    int ret = -1;
//    if (_control) {
//        ret = _control->getFreeSpaceInImages(num);
//    }
//    if (ICH_SUCCEED == ret) {
//        photoNum = num;
//    }
//    
//    return photoNum;
    uint num = 0;
    if (!_control) {
        AppLog(@"SDK doesn't work!!!");
        return num;
    }
    
    _control->getFreeSpaceInImages(num);
    return num;
}

-(unsigned int)retrieveFreeSpaceOfVideo {
    unsigned int secs = 0;
    int ret = -1;
    if (_control) {
        ret = _control->getRemainRecordingTime(secs);
    }
    
    if (ret == ICH_SUCCEED) {
        AppLog(@"freeSpace of Video: %d", secs);
    } else {
        AppLog(@"getRemainRecordingTime failed: %d", ret);
    }
    return secs;
}

-(uint)retrieveMaxZoomRatio
{
    uint ratio = 1;
    if (_prop) {
        _prop->getMaxZoomRatio(ratio);
    }
    AppLog(@"max ratio: %d", ratio);
    return ratio;
}

-(uint)retrieveCurrentZoomRatio
{
    uint ratio = 1;
    if (_prop) {
        _prop->getCurrentZoomRatio(ratio);
    }
    return ratio;
}

-(uint)retrieveCurrentUpsideDown
{
    uint curUD = 0;
    if (_prop) {
        _prop->getCurrentUpsideDown(curUD);
    }
    return curUD;
}

-(uint)retrieveCurrentSlowMotion
{
    uint curSM = 0;
    if (_prop) {
        _prop->getCurrentSlowMotion(curSM);
    }
    return curSM;
}


-(unsigned int)retrieveCurrentCameraMode
{
    unsigned int mode = ICH_CAM_MODE_UNDEFINED;
    if (_control) {
        int retVal = _control->getCurrentCameraMode(mode);
        AppLog(@"getCurrentCameraMode is success: %d", retVal);
    }
    return mode;
}

#pragma mark - Change properties
-(int)changeImageSize:(string)size {
    int newSize = ICH_UNKNOWN_ERROR;
    if (_prop) {
        newSize = _prop->setImageSize(size);
    }
    return newSize;
}

-(int)changeVideoSize:(string)size{
    int newSize = ICH_UNKNOWN_ERROR;
    if (_prop) {
        newSize = _prop->setVideoSize(size);
    }
    return newSize;
}

-(int)changeDelayedCaptureTime:(unsigned int)time{
    int newTime = ICH_UNKNOWN_ERROR;
    if (_prop) {
        newTime = _prop->setCaptureDelay(time);
    }
    return newTime;
}

-(int)changeWhiteBalance:(unsigned int)value{
    int newValue = ICH_UNKNOWN_ERROR;
    if (_prop) {
        newValue = _prop->setWhiteBalance(value);
    }
    return newValue;
}

-(int)changeLightFrequency:(unsigned int)value {
    int newValue = ICH_UNKNOWN_ERROR;
    if (_prop) {
        newValue = _prop->setLightFrequency(value);
    }
    return newValue;
}

-(int)changeBurstNumber:(unsigned int)value {
    int newValue = ICH_UNKNOWN_ERROR;
    if (_prop) {
        newValue = _prop->setBurstNumber(value);
    }
    return newValue;
}

-(int)changeDateStamp:(unsigned int)value {
    int newValue = ICH_UNKNOWN_ERROR;
    if (_prop) {
        newValue = _prop->setDateStamp(value);
    }
    return newValue;
}

-(int)changeTimelapseType:(ICatchCamPreviewMode)mode {
    int newValue = ICH_UNKNOWN_ERROR;

    if (_control) {
        newValue = _control->changePreviewMode(mode);
        AppLog(@"changePreviewMode : %d", newValue);
    }

    return newValue;
}

-(int)changeTimelapseInterval:(unsigned int)value {
    int newValue = ICH_UNKNOWN_ERROR;
    if (_prop) {
        newValue = _prop->setTimeLapseInterval(value);
    }
    return newValue;
}

-(int)changeTimelapseDuration:(unsigned int)value {
    int newValue = ICH_UNKNOWN_ERROR;
    if (_prop) {
        newValue = _prop->setTimeLapseDuration(value);
    }
    return newValue;
}

-(int)changeUpsideDown:(uint)value {
    int newValue = ICH_UNKNOWN_ERROR;
    if (_prop) {
        newValue = _prop->setUpsideDown(value);
    }
    return newValue;
}

-(int)changeSlowMotion:(uint)value {
    int newValue = ICH_UNKNOWN_ERROR;
    if (_prop) {
        newValue = _prop->setSlowMotion(value);
    }
    return newValue;
}

- (shared_ptr<ICatchVideoFormat>)getCurrentStreamingInfo
{
    ICatchVideoFormat format;
    
    if (_prop) {
        _prop->getCurrentStreamingInfo(format);
        
        AppLog(@"video format: %d", format.getCodec());
        AppLog(@"video w,h: %d, %d", format.getVideoW(), format.getVideoH());
    } else {
        AppLog(@"SDK doesn't work!!!");
    }
    
    return make_shared<ICatchVideoFormat>(format);
}

- (BOOL)isMediaStreamOn {
    BOOL retVal = NO;
    
    if (_sdkState && _sdkState->isStreaming() == true) {
        retVal = YES;
    }
    return retVal;
}

- (BOOL)isMediaStreamRecording {
    BOOL retVal = NO;
    
    if (_sdkState && _sdkState->isMovieRecording() == true) {
        retVal = YES;
    } else {
        AppLog(@"Camera is not recording.");
    }
    return retVal;
}

-(BOOL)isVideoTimelapseOn {
    
    BOOL retVal = NO;
    
    if (_sdkState->isTimeLapseVideoOn() == true) {
        AppLog(@"_sdkState->isTimeLapseVideoOn() == true");
        retVal = YES;
    } else {
        AppLog(@"_sdkState->isTimeLapseVideoOn() == false");
    }
    return retVal;
}

-(BOOL)isStillTimelapseOn {
    BOOL retVal = NO;
    
    if (_sdkState && _sdkState->isTimeLapseStillOn() == true) {
        AppLog(@"_sdkState->isTimeLapseStillOn() == true");
        retVal = YES;
    } else {
        AppLog(@"_sdkState->isTimeLapseStillOn() == false");
    }
    return retVal;
}

#pragma mark - CONTROL
- (WCRetrunType)capturePhoto {
    WCRetrunType retVal = WCRetSuccess;
    
    do {
        if (_sdkState && _sdkState->isCameraBusy() == false) {
            int ret = _control->capturePhoto();
            AppLog(@"capturePhoto: %d", ret);
            
            if (_control && ret != ICH_SUCCEED) {
                retVal = WCRetFail;
                break;
            }
        } else {
            retVal = WCRetFail;
            break;
        }
    } while (0);
    
    return retVal;
}

- (WCRetrunType)triggerCapturePhoto
{
    WCRetrunType retVal = WCRetSuccess;
    
    do {
        if (_sdkState && _sdkState->isCameraBusy() == false) {
            AppLog(@"Trigger capture.");
            if (_control && _control->triggerCapturePhoto() != ICH_SUCCEED) {
                retVal = WCRetFail;
                break;
            }
        } else {
            AppLog(@"Camera Busy!!!");
            retVal = WCRetFail;
            break;
        }
    } while (0);
    
    return retVal;
}

- (BOOL)startMovieRecord {
    if (!_control) {
        AppLog(@"SDK doesn't working.");
        return NO;
    }
    TRACE();
    int retVal = _control->startMovieRecord();
    AppLog(@"%s : retVal: %d", __func__, retVal);
    return retVal==ICH_SUCCEED?YES:NO;
}

- (BOOL)stopMovieRecord {
    if (!_control) {
        AppLog(@"SDK doesn't working.");
        return NO;
    }
    TRACE();
    int retVal = _control->stopMovieRecord();
    AppLog(@"%s : retVal: %d", __func__, retVal);
    return retVal==ICH_SUCCEED?YES:NO;
}

-(BOOL)startTimelapseRecord {
    TRACE();
    if (!_control) {
        AppLog(@"SDK doesn't working.");
        return NO;
    }
    int retVal = ICH_SUCCEED;
    retVal = _control->startTimeLapse();
    return retVal==ICH_SUCCEED?YES:NO;
}

-(BOOL)stopTimelapseRecord {
    TRACE();
    if (!_control) {
        AppLog(@"SDK doesn't working.");
        return NO;
    }
    int retVal = ICH_SUCCEED;
    retVal = _control->stopTimeLapse();
    return retVal==ICH_SUCCEED?YES:NO;
}

- (void)addObserver:(ICatchCamEventID)eventTypeId listener:(shared_ptr<ICatchICameraListener >)listener isCustomize:(BOOL)isCustomize
{
    TRACE();
    if (listener && _control) {
        int ret = ICH_UNKNOWN_ERROR;

        if (isCustomize) {
            ret = _control->addCustomEventListener(eventTypeId, listener);
            if (ret == ICH_SUCCEED) {
                AppLog(@"add customize eventTypeId: 0x%x listener succeed.", eventTypeId);
            } else {
                AppLog(@"add customize eventTypeId: 0x%x listener failed, ret: %d", eventTypeId, ret);
            }
        } else {
            ret = _control->addEventListener(eventTypeId, listener);
            if (ret == ICH_SUCCEED) {
                AppLog(@"add eventTypeId: 0x%x listener succeed.", eventTypeId);
            } else {
                AppLog(@"add eventTypeId: 0x%x listener failed, ret: %d", eventTypeId, ret);
            }
        }
    } else  {
        AppLog(@"listener is null");
    }
    
}

-(void)addObserver:(WifiCamObserver *)observer;
{
    if (observer.listener) {
        if (observer.isGlobal) {
            int ret = ICH_UNKNOWN_ERROR;
            ret = self.assist->addEventListener(observer.eventType, observer.listener, true);
            if (ret == ICH_SUCCEED) {
                AppLog(@"Add global event(0x%x,%p) listener succeed.", observer.eventType, observer);
            } else {
                AppLog(@"Add global event(0x%x,%p) listener failed.", observer.eventType, observer);
            }
            return;
        } else {
            if (_control) {
                int ret = ICH_UNKNOWN_ERROR;

                if (observer.isCustomized) {
                    ret = _control->addCustomEventListener(observer.eventType, observer.listener);
                    if (ret == ICH_SUCCEED) {
                        AppLog(@"add customize eventTypeId: 0x%x listener succeed.", observer.eventType);
                    } else {
                        AppLog(@"add customize eventTypeId: 0x%x listener failed, ret: %d", observer.eventType, ret);
                    }
                } else {
                    ret = _control->addEventListener(observer.eventType, observer.listener);
                    if (ret == ICH_SUCCEED) {
                        AppLog(@"add eventTypeId: 0x%x listener succeed.", observer.eventType);
                    } else {
                        AppLog(@"add eventTypeId: 0x%x listener failed, ret: %d", observer.eventType, ret);
                    }
                }
            } else {
                AppLog(@"SDK isn't working.");
            }
        }
    } else  {
        AppLog(@"listener is null");
    }
}

-(void)removeObserver:(WifiCamObserver *)observer {
    if (observer.listener) {
        if (observer.isGlobal) {
            int ret = ICH_UNKNOWN_ERROR;
            ret = self.assist->removeEventListener(observer.eventType, observer.listener, true);
            if (ret == ICH_SUCCEED) {
                AppLog(@"Remove global event(0x%x,%p) listener succeed.", observer.eventType, observer);
            } else {
                AppLog(@"Remove global event(0x%x,%p) listener failed.", observer.eventType, observer);
            }
            return;
        } else {
            if (_control) {
                int ret = ICH_UNKNOWN_ERROR;

                if (observer.isCustomized) {
                    ret = _control->removeCustomEventListener(observer.eventType, observer.listener);
                    if (ret == ICH_SUCCEED) {
                        AppLog(@"Remove customize eventTypeId: 0x%x listener succeed.", observer.eventType);
                    } else {
                        AppLog(@"Remove customize eventTypeId: 0x%x listener failed, ret: %d", observer.eventType, ret);
                    }
                } else {
                    ret = _control->removeEventListener(observer.eventType, observer.listener);
                    if (ret == ICH_SUCCEED) {
                        AppLog(@"Remove eventTypeId: 0x%x listener succeed.", observer.eventType);
                    } else {
                        AppLog(@"Remove eventTypeId: 0x%x listener failed, ret: %d", observer.eventType, ret);
                    }
                }
            } else {
                AppLog(@"SDK isn't working.");
            }
            
        }
    } else  {
        AppLog(@"listener is null");
    }
}

- (void)removeObserver:(ICatchCamEventID)eventTypeId listener:(shared_ptr<ICatchICameraListener >)listener isCustomize:(BOOL)isCustomize
{
    TRACE();
    if (listener && _control) {
        int ret = ICH_UNKNOWN_ERROR;

        if (isCustomize) {
            ret = _control->removeCustomEventListener(eventTypeId, listener);
            if (ret == ICH_SUCCEED) {
                AppLog(@"Remove customize eventTypeId: 0x%x listener succeed.", eventTypeId);
            } else {
                AppLog(@"Remove customize eventTypeId: 0x%x listener failed, ret: %d", eventTypeId, ret);
            }
        } else {
            ret = _control->removeEventListener(eventTypeId, listener);
            if (ret == ICH_SUCCEED) {
                AppLog(@"Remove eventTypeId: 0x%x listener succeed.", eventTypeId);
            } else {
                AppLog(@"Remove eventTypeId: 0x%x listener failed, ret: %d", eventTypeId, ret);
            }
        }
    } else  {
        AppLog(@"listener is null");
    }
}

- (BOOL)formatSD {
    if (!_control) {
        AppLog(@"SDK doesn't working.");
        return NO;
    }
    int retVal = ICH_SUCCEED;
    retVal = _control->formatStorage();
    return retVal == ICH_SUCCEED ? YES : NO;
}

- (BOOL)checkSDExist {
//    BOOL retVal = YES;
//    
//    if (_control && _control->isSDCardExist() == false) {
//        retVal = NO;
//        AppLog(@"Please insert an SD card");
//    }
//    
//    return retVal;
    bool retVal;
    
    if (!_control) {
        AppLog(@"SDK doesn't working.");
        return NO;
    }
    
    int ret = _control->isSDCardExist(retVal);
    if (ret == ICH_SUCCEED) {
        return retVal;
    } else {
        AppLog(@"CheckSDExist failed. %d", ret);
        return NO;
    }
}

- (BOOL)zoomIn {
    if (!_control) {
        AppLog(@"SDK doesn't working.");
        return NO;
    }
    int ret = _control->zoomIn();
    if (ret != ICH_SUCCEED) {
        AppLog(@"ZoomIn failed. %d", ret);
        return NO;
    } else {
        return YES;
    }
    
}

- (BOOL)zoomOut {
    if (!_control) {
        AppLog(@"SDK doesn't working.");
        return NO;
    }
    int ret = _control->zoomOut();
    if (ret != ICH_SUCCEED) {
        AppLog(@"ZoomOut failed. %d", ret);
        return NO;
    } else {
        return YES;
    }
    
}

- (int)changePreviewMode:(ICatchCamPreviewMode)mode {
    int newValue = ICH_UNKNOWN_ERROR;
    
    if (_control) {
        newValue = _control->changePreviewMode(mode);
        AppLog(@"changePreviewMode : %d", newValue);
    }
    
    return newValue;
}

#pragma mark - PLAYBACK
- (vector<shared_ptr<ICatchFile>>)requestFileListOfType:(WCFileType)fileType
{
    int ret = -1;
    vector<shared_ptr<ICatchFile>> list;
    if (_playback) {
        switch (fileType) {
            case WCFileTypeImage:
                ret = _playback->listFiles(ICH_FILE_TYPE_IMAGE, list);
                if (ret != ICH_SUCCEED) {
                    AppLog(@"Get Image ListFiles failed, ret: %d", ret);
                }
                break;
                
            case WCFileTypeVideo:
                ret = _playback->listFiles(ICH_FILE_TYPE_VIDEO, list);
                if (ret != ICH_SUCCEED) {
                    AppLog(@"Get Video ListFiles failed, ret: %d", ret);
                }
                break;
                
            case WCFileTypeAll:
                ret = _playback->listFiles(ICH_FILE_TYPE_ALL, list);
                if (ret != ICH_SUCCEED) {
                    AppLog(@"Get All ListFiles failed, ret: %d", ret);
                }
                break;
                
            case WCFileTypeAudio:
            case WCFileTypeText:
            case WCFileTypeUnknow:
            default:
                break;
        }
    } else {
        AppLog(@"SDK doesn't working.");
    }
    
    AppLog(@"listSize: %lu", list.size());
    return list;
}

- (UIImage *)requestThumbnail:(shared_ptr<ICatchFile>)f {
    UIImage *retImg = nil;
    do {
        if (!f || !_playback) {
            AppLog(@"Invalid ICatchFile pointer used for download thumbnail. / SDK doesn't working.");
            break;
        }
        auto thumbBuf = make_shared<ICatchFrameBuffer>(640*360*2);
        if (thumbBuf == NULL) {
            AppLog(@"new failed");
            break;
        }
        
        int ret = _playback->getThumbnail(f, thumbBuf);
        if (ICH_BUF_TOO_SMALL == ret) {
            AppLog(@"ICH_BUF_TOO_SMALL");
            break;
        }
        if (thumbBuf->getFrameSize() <=0) {
            AppLog(@"thumbBuf's data size <= 0, ret: %d", ret);
            break;
        }
        NSData *imageData = [NSData dataWithBytes:thumbBuf->getBuffer()
                                           length:thumbBuf->getFrameSize()];
        
        
        UIImage *thumbnail = [UIImage imageWithData:imageData];
        
        if (f->getFileType() == ICH_FILE_TYPE_VIDEO
            && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIImage *videoIcon = [UIImage imageNamed:@"image_video"];
            NSArray *imgArray = [[NSArray alloc] initWithObjects:videoIcon, nil];
            NSArray *imgPointArray = [[NSArray alloc] initWithObjects:@(5.0), @(thumbnail.size.height - videoIcon.size.height/2.0 - 5.0), nil];
            retImg = [Tool mergedImageOnMainImage:thumbnail WithImageArray:imgArray AndImagePointArray:imgPointArray];
        } else {
            retImg = thumbnail;
        }
        
        thumbBuf = NULL;
    } while (0);
    

//    [self writeImageDataToFile:retImg andName:[NSString stringWithFormat:@"%s" ,f->getFileName().c_str()]];
    return retImg;
}

/*********************** Write UIImage to local *************************/
- (void)writeImageDataToFile:(UIImage *)image andName:(NSString *)fileName {
    // Create paths to output images
    NSString  *pngPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.png" , fileName]];
    //NSString  *jpgPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.jpg", fileName]];
    
    // Write a UIImage to JPEG with minimum compression (best quality)
    // The value 'image' must be a UIImage object
    // The value '1.0' represents image compression quality as value from 0.0 to 1.0
    //[UIImageJPEGRepresentation(image, 1.0) writeToFile:jpgPath atomically:YES];
    
    // Write image to PNG
    [UIImagePNGRepresentation(image) writeToFile:pngPath atomically:YES];
    
    // Let's check to see if files were successfully written...
    
    // Create file manager
    NSError *error;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    // Point to Document directory
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    // Write out the contents of home directory to console
    NSLog(@"Documents directory: %@", [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:&error]);
}

- (UIImage *)requestImage:(shared_ptr<ICatchFile>)f
{
    if (!f || !_playback) {
        AppLog(@"Invalid ICatchFile pointer used for downloading. / SDK doesn't working.");
        return nil;
    }
    UIImage* image = nil;
    BOOL compression = NO;
    
//    ICatchFrameBuffer *picBuf = new ICatchFrameBuffer(3648*2736/2);
    auto picBuf = make_shared<ICatchFrameBuffer>(640*480);
    if (picBuf == NULL) {
        AppLog(@"new failed");
        return nil;
    }
    //int ret = _playback->downloadFile(f, picBuf);
    int ret = _playback->getQuickview(f, picBuf);
    
    if (ret == ICH_BUF_TOO_SMALL || ret == ICH_CAM_MTP_GET_OBJECTS_ERROR) {
        picBuf = NULL;
        picBuf = make_shared<ICatchFrameBuffer>(3648*2736);
        if (picBuf == NULL) {
            AppLog(@"New failed");
            return nil;
        }
        _playback->downloadFile(f, picBuf);
        compression = YES;
    }
    
    if (picBuf->getFrameSize() <=0) {
        AppLog(@"picBuf is empty");
        return nil;
    }
    NSData *imageData = [NSData dataWithBytes:picBuf->getBuffer()
                                       length:picBuf->getFrameSize()];
    picBuf = NULL;
    image = [UIImage imageWithData:imageData];
    
    if (compression) {
        uint w = f->getFileWidth();
        uint h = f->getFileHeight();
        
        CGSize size = CGSizeMake(w * 0.5, h * 0.5);
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    return image;
}

-(BOOL)deleteFile:(shared_ptr<ICatchFile>)f
{
    int ret = -1;
    if (!f || !_playback) {
        AppLog(@"Invalid ICatchFile pointer used for deleting. / SDK doesn't working.");
        return NO;
    }
    switch (f->getFileType()) {
        case ICH_FILE_TYPE_IMAGE:
            ret = _playback->deleteFile(f);
            break;
            
        case ICH_FILE_TYPE_VIDEO:
            ret = _playback->deleteFile(f);
            break;
            
        case ICH_FILE_TYPE_AUDIO:
        case ICH_FILE_TYPE_TEXT:
        case ICH_FILE_TYPE_ALL:
        case ICH_FILE_TYPE_UNKNOWN:
        default:
            break;
    }
    
    if (ret != ICH_SUCCEED) {
        AppLog(@"Delete failed.");
        return NO;
    } else {
        return YES;
    }
}

- (void)timerFireMethod:(NSTimer*)theTimer//弹出框
{
    UIAlertView *promptAlert = (UIAlertView*)[theTimer userInfo];
    [promptAlert dismissWithClickedButtonIndex:0 animated:NO];
    promptAlert = nil;
}

-(void)cleanTemp
{
    NSArray *tmpDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
    for (NSString *file in  tmpDirectoryContents) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:nil];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSString *logFilePath = nil;
    for (NSString *fileName in  documentsDirectoryContents) {
        if (![fileName isEqualToString:@"Camera.sqlite"] && ![fileName isEqualToString:@"Camera.sqlite-shm"] && ![fileName isEqualToString:@"Camera.sqlite-wal"]) {
            
            logFilePath = [documentsDirectory stringByAppendingPathComponent:fileName];
            [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:nil];
        }
    }
    
//    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"应用空间已清理完成 !" message:nil delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
//    
//    [NSTimer scheduledTimerWithTimeInterval:1.0f
//                                     target:self
//                                   selector:@selector(timerFireMethod:)
//                                   userInfo:alert
//                                    repeats:YES];
//    
//    [alert show];
}

- (void)               image: (UIImage *) image
    didFinishSavingWithError: (NSError *) error
                 contextInfo: (void *) contextInfo;
{
    if (error) {
        AppLog("Error: %@", [error userInfo]);
    } else {
        AppLog(@"image Saved");
        
        
    }
}

- (void)               video: (NSString *) videoPath
    didFinishSavingWithError: (NSError *) error
                 contextInfo: (void *) contextInfo;
{
    
    if (error) {
        AppLog("Error: %@", [error userInfo]);
    } else {
        AppLog(@"video Saved");
        
        AppLog(@"Delete temp video: %@", videoPath);
        [[NSFileManager defaultManager] removeItemAtPath:videoPath error:nil];
    }
}

- (void)cancelDownload
{
    if (_playback) {
        _playback->cancelFileDownload();
        AppLog(@"Downloading Canceled");
    } else {
        AppLog(@"Downloading failed to cancel.");
    }
    
}

- (NSString *)p_downloadFile:(shared_ptr<ICatchFile>)f {
    if (!f || !_playback) {
        AppLog(@"f is NULL or SDK doesn't working.");
        return nil;
    }
    NSString *fileName = [NSString stringWithUTF8String:f->getFileName().c_str()];
    NSString *locatePath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), fileName];
    int ret = _playback->downloadFile(f, [locatePath cStringUsingEncoding:NSUTF8StringEncoding]);
    
    AppLog(@"Download File, ret : %d", ret);
    if (ret != ICH_SUCCEED) {
        locatePath = nil;
    } else {
        
        AppLog(@"locatePath: %@", locatePath);
        
        NSString *filePath = [NSString stringWithFormat:@"%s", f->getFilePath().c_str()];
        AppLog(@"set file path %@ to 0xD83B", filePath);
        [self setCustomizeStringProperty:0xD83B value:filePath];
        
    }
    
    return locatePath;
}

-(BOOL)downloadFile:(shared_ptr<ICatchFile>)f
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self createNewAssetCollection];
    });
    BOOL retVal = NO;
    NSURL *fileURL = nil;
    NSString *locatePath = [self p_downloadFile:f];
    if (locatePath) {
//        fileURL = [NSURL URLWithString:locatePath];
        fileURL = [NSURL fileURLWithPath:locatePath];
    } else {
        return retVal;
    }
    switch (f->getFileType()) {
        case ICH_FILE_TYPE_IMAGE:
            if (locatePath) {
                self.autoDownloadImage = [UIImage imageWithContentsOfFile:locatePath];
                retVal = [self addNewAssetWithURL:fileURL toAlbum:@"MobileCamApp"/*@"SBCapp"*//*@"WiFiCam"*/ andFileType:ICH_FILE_TYPE_IMAGE];
                ++self.downloadedTotalNumber;
            }
            break;
            
        case ICH_FILE_TYPE_VIDEO:
            if (locatePath && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(locatePath)) {
                retVal = [self addNewAssetWithURL:fileURL toAlbum:@"MobileCamApp"/*@"SBCapp"*//*@"WiFiCam"*/ andFileType:ICH_FILE_TYPE_VIDEO];
                ++self.downloadedTotalNumber;
            } else {
                AppLog(@"The specified video can not be saved to user’s Camera Roll album");
            }
            break;
            
        case ICH_FILE_TYPE_AUDIO:
        case ICH_FILE_TYPE_TEXT:
        case ICH_FILE_TYPE_ALL:
        case ICH_FILE_TYPE_UNKNOWN:
        default:
            AppLog(@"Unsupported file type to download right now!!");
            break;
    }
    
    return retVal;
}

- (BOOL)openFileTransChannel
{
    if (!_playback) {
        AppLog(@"SDK doesn't work!!!");
        return NO;
    }
    
    int retVal = _playback->openFileTransChannel();
    if (retVal == ICH_SUCCEED) {
        AppLog(@"openFileTransChannel succeed.");
        return YES;
    } else {
        AppLog(@"openFileTransChannel failed: %d", retVal);
        return NO;
    }
}

- (BOOL)closeFileTransChannel
{
    if (!_playback) {
        AppLog(@"SDK doesn't work!!!");
        return NO;
    }
    
    int retVal = _playback->closeFileTransChannel();
    if (retVal == ICH_SUCCEED) {
        AppLog(@"closeFileTransChannel succeed.");
        return YES;
    } else {
        AppLog(@"closeFileTransChannel failed: %d", retVal);
        return NO;
    }
}

- (NSArray *)createMediaDirectory
{
    BOOL isDir = NO;
    BOOL isDirExist= NO;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *mediaDirectory = [documentsDirectory stringByAppendingPathComponent:@"MobileCamApp-Medias"];
    
    isDirExist = [[NSFileManager defaultManager] fileExistsAtPath:mediaDirectory isDirectory:&isDir];
    if (!(isDir && isDirExist)) {
        BOOL bCreateDir = [[NSFileManager defaultManager] createDirectoryAtPath:mediaDirectory withIntermediateDirectories:NO attributes:nil error:nil];
        if(!bCreateDir){
            AppLog(@"Create MobileCamApp-Medias Directory Failed.");
        } else
            AppLog(@"Create MobileCamApp-Medias Directory path: %@",mediaDirectory);
    }
    
    NSString *photoDirectory = [mediaDirectory stringByAppendingPathComponent:@"Photos"];
    isDirExist = [[NSFileManager defaultManager] fileExistsAtPath:photoDirectory isDirectory:&isDir];
    if (!(isDir && isDirExist)) {
        BOOL bCreateDir = [[NSFileManager defaultManager] createDirectoryAtPath:photoDirectory withIntermediateDirectories:NO attributes:nil error:nil];
        if(!bCreateDir){
            AppLog(@"Create MobileCamApp-Medias/Photos Directory Failed.");
        } else
            AppLog(@"Create MobileCamApp-Medias/Photos Directory path: %@",photoDirectory);
    }
    
    NSString *videoDirectory = [mediaDirectory stringByAppendingPathComponent:@"Videos"];
    isDirExist = [[NSFileManager defaultManager] fileExistsAtPath:videoDirectory isDirectory:&isDir];
    if (!(isDir && isDirExist)) {
        BOOL bCreateDir = [[NSFileManager defaultManager] createDirectoryAtPath:videoDirectory withIntermediateDirectories:NO attributes:nil error:nil];
        if(!bCreateDir){
            AppLog(@"Create MobileCamApp-Medias/Videos Directory Failed.");
        } else
            AppLog(@"Create MobileCamApp-Medias/Videos Directory path: %@",videoDirectory);
    }
    
    return @[mediaDirectory, photoDirectory, videoDirectory];
}

- (NSString *)p_downloadFile2:(shared_ptr<ICatchFile>)f {
    if (!f || !_playback) {
        AppLog(@"f is NULL or SDK doesn't working.");
        return nil;
    }
    NSString *fileName = [NSString stringWithUTF8String:f->getFileName().c_str()];
    //NSString *locatePath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), fileName];
    
    NSString *fileDirectory = nil;
    if ([fileName hasSuffix:@".MP4"] || [fileName hasSuffix:@".MOV"]) {
        fileDirectory = [self createMediaDirectory][2];
    } else {
        fileDirectory = [self createMediaDirectory][1];
    }
    
    NSString *locatePath = [fileDirectory stringByAppendingPathComponent:fileName];
    //  /var/mobile/Containers/Data/Application/CC575D71-6CD3-4E28-A0F5-ECF271CEF3BC/Documents/MobileCamApp-Media/20161026_140204.MP4
    //  /VIDEO/20161026_140204.MP4
    int ret = _playback->downloadFileQuick(f, [locatePath cStringUsingEncoding:NSUTF8StringEncoding]);
    
    AppLog(@"Download File, ret : %d", ret);
    if (ret != ICH_SUCCEED) {
        locatePath = nil;
    } else {
        
        AppLog(@"locatePath: %@", locatePath);
        
        NSString *filePath = [NSString stringWithFormat:@"%s", f->getFilePath().c_str()];
        AppLog(@"set file path %@ to 0xD83B", filePath);
        [self setCustomizeStringProperty:0xD83B value:filePath];
        
    }
    
    return locatePath;
}

-(BOOL)downloadFile2:(shared_ptr<ICatchFile>)f
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self createNewAssetCollection];
    });
    BOOL retVal = NO;
    NSURL *fileURL = nil;
    NSString *locatePath = [self p_downloadFile2:f];
    if (locatePath) {
        //        fileURL = [NSURL URLWithString:locatePath];
        fileURL = [NSURL fileURLWithPath:locatePath];
    } else {
        return retVal;
    }
    switch (f->getFileType()) {
        case ICH_FILE_TYPE_IMAGE:
            if (locatePath) {
                self.autoDownloadImage = [UIImage imageWithContentsOfFile:locatePath];
                retVal = [self addNewAssetWithURL:fileURL toAlbum:@"MobileCamApp"/*@"SBCapp"*//*@"WiFiCam"*/ andFileType:ICH_FILE_TYPE_IMAGE];
                ++self.downloadedTotalNumber;
            }
            break;
            
        case ICH_FILE_TYPE_VIDEO:
            if (locatePath && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(locatePath)) {
                retVal = [self addNewAssetWithURL:fileURL toAlbum:@"MobileCamApp"/*@"SBCapp"*//*@"WiFiCam"*/ andFileType:ICH_FILE_TYPE_VIDEO];
                ++self.downloadedTotalNumber;
            } else {
                AppLog(@"The specified video can not be saved to user’s Camera Roll album");
            }
            break;
            
        case ICH_FILE_TYPE_AUDIO:
        case ICH_FILE_TYPE_TEXT:
        case ICH_FILE_TYPE_ALL:
        case ICH_FILE_TYPE_UNKNOWN:
        default:
            AppLog(@"Unsupported file type to download right now!!");
            break;
    }
    
    return retVal;
}

- (BOOL)videoPlaybackEnabled
{
    return (_control && _control->supportVideoPlayback() == true) ? YES : NO;
}

#pragma mark - Customize properties
//------------------- modify by allen.chuang 20140703 -----------------
/*
 guo.jiang[20140918]
 
 */
// support customer property code
-(int)getCustomizePropertyIntValue:(int)propid {
    unsigned int value = 0;
    if (_prop) {
        _prop->getCurrentPropertyValue(propid, value);
        printf("\nproperty int value: %d\n", value);
    } else {
        AppLog(@"SDK doesn't working.");
    }
    
    return value;
}

-(NSString *)getCustomizePropertyStringValue:(int)propid {
    string value;
    
    if (_prop) {
        _prop->getCurrentPropertyValue(propid, value);
        printf("property string value: %s\n", value.c_str());
    } else {
        AppLog(@"SDK doesn't working.");
    }
    return [NSString stringWithFormat:@"%s", value.c_str()];
}

-(BOOL)setCustomizeIntProperty:(int)propid value:(uint)value {
    int ret = 1;
    if (_prop) {
        ret = _prop->setPropertyValue(propid, value);
    } else {
        AppLog(@"SDK doesn't working.");
    }
    AppLog(@"setProperty id:%d, value:%d",propid,value);
    return ret == ICH_SUCCEED ? YES : NO;
}

-(BOOL)setCustomizeStringProperty:(int)propid value:(NSString *)value {
    string stringValue = [value cStringUsingEncoding:NSUTF8StringEncoding];
    printf("set customized string property to : %s\n", stringValue.c_str());
    int ret = 1;
    if (_prop) {
        ret = _prop->setPropertyValue(propid, stringValue);
    } else {
        AppLog(@"SDK doesn't working.");
    }
    
    AppLog(@"setProperty id:%d, value:%@, ret : %d",propid,value, ret);
    return ret == ICH_SUCCEED ? YES : NO;
}

// check the customerid is valid or not
-(BOOL)isValidCustomerID:(int)customerid {
    int retid = [self getCustomizePropertyIntValue:0xD613];
    return (retid & 0xFF00) == (customerid & 0xFF00) ? YES : NO;
}



#pragma mark -
-(UIImage *)getAutoDownloadImage {
    return self.autoDownloadImage;
}

-(void)updateFW:(string)fwPath {
    printf("%s\n", fwPath.c_str());
    int ret = self.assist->updateFw(self.session1, fwPath);
    AppLog(@"updateFw ret: %d", ret);
}

#pragma mark - Photo Album

- (void)createNewAssetCollection
{
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    for (int i=0; i<topLevelUserCollections.count; ++i) {
        PHCollection *collection = [topLevelUserCollections objectAtIndex:i];
        if ([collection.localizedTitle isEqualToString:@"MobileCamApp"/*@"SBCapp"*//*@"WiFiCam"*/]) {
            return;
        }
    }
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:@"MobileCamApp"/*@"SBCapp"*//*@"WiFiCam"*/];
    } completionHandler:^(BOOL success, NSError *error) {
        NSLog(@"Finished adding asset collection. %@", (success ? @"Success" : error));
    }];
}

- (BOOL)addNewAssetWithURL:(NSURL *)fileURL toAlbum:(NSString *)albumName andFileType:(ICatchFileType)fileType
{
    NSError *error;
    BOOL retVal = [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        // Request creating an asset from the image.
        PHAssetChangeRequest *createAssetRequest = nil;
        if (fileType == ICH_FILE_TYPE_IMAGE) {
            createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:fileURL];
        } else if (fileType == ICH_FILE_TYPE_VIDEO) {
            createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL];
        } else {
            AppLog(@"Unknown file type to save.");
            return;
        }
        
        PHAssetCollection *myAssetCollection = nil;
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        for (int i=0; i<topLevelUserCollections.count; ++i) {
            PHCollection *collection = [topLevelUserCollections objectAtIndex:i];
            if ([collection.localizedTitle isEqualToString:albumName]) {
                PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
                myAssetCollection = assetCollection;
                break;
            }
        }
        if (myAssetCollection && createAssetRequest) {
            // Request editing the album.
            PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:myAssetCollection];
            // Get a placeholder for the new asset and add it to the album editing request.
            PHObjectPlaceholder *assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
            [albumChangeRequest addAssets:@[ assetPlaceholder ]];
        }
        
    } error:&error];
    
    if (!retVal) {
        AppLog(@"Failed to save. %@", error.localizedDescription);
    }
    return retVal;
}

- (BOOL)savetoAlbum:(NSString *)albumName andAlbumAssetNum:(uint)assetNum andShareNum:(uint)shareNum
{
    /*static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self createNewAssetCollection];
    });*/
    [self createNewAssetCollection];

    NSUInteger cameraTotalNum = 0;
    while (assetNum + shareNum != cameraTotalNum) {
        @autoreleasepool {
            [NSThread sleepForTimeInterval:0.5];
            cameraTotalNum = [self retrieveCameraRollAssetsResult].count;
            AppLog(@"cameraTotalNum: %ld", (unsigned long)cameraTotalNum);
        }
    }
    
    return [self addNewAssettoAlbum:albumName andNumber:shareNum];
}

- (BOOL)addNewAssettoAlbum:(NSString *)albumName andNumber:(int)num
{
    NSError *error;
    BOOL retVal = [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        
        PHAssetCollection *myAssetCollection = nil;
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        for (int i=0; i<topLevelUserCollections.count; ++i) {
            PHCollection *collection = [topLevelUserCollections objectAtIndex:i];
            if ([collection.localizedTitle isEqualToString:albumName]) {
                PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
                myAssetCollection = assetCollection;
                break;
            }
        }
        
        // 获得相机胶卷
        PHAssetCollection *cameraRoll = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].lastObject;
        
        PHFetchResult *assetResult = [PHAsset fetchAssetsInAssetCollection:cameraRoll options:[PHFetchOptions new]];
        for (int i = 0; i < num; i++) {
            [assetResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    //获取相册的照片
                    if (idx == [assetResult count] - (num - i)) {
                        if (myAssetCollection && obj) {
                            // Request editing the album.
                            PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:myAssetCollection];
                            // Get a placeholder for the new asset and add it to the album editing request.
                            [albumChangeRequest addAssets:@[obj]];
                        }
                    }
                } completionHandler:^(BOOL success, NSError *error) {
                    // NSLog(@"Error: %@", error);
                }];
            }];
        }
    } error:&error];
    
    if (!retVal) {
        AppLog(@"Failed to save. %@", error.localizedDescription);
    }
    
    return retVal;
}

- (PHFetchResult *)retrieveCameraRollAssetsResult
{
    PHAssetCollection *cameraRoll = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].lastObject;
    return  [PHAsset fetchAssetsInAssetCollection:cameraRoll options:[PHFetchOptions new]];
}

#pragma mark - READONLY
-(uint)previewCacheTime {
    uint cacheTime = 0;
    if (_prop) {
        _prop->getPreviewCacheTime(cacheTime);
    } else {
        AppLog(@"SDK isn't working");
    }
    
    return cacheTime;
}

-(BOOL)isSupportAutoDownload {
    return _sdkState->supportImageAutoDownload()==true ? YES : NO;
}

@end
