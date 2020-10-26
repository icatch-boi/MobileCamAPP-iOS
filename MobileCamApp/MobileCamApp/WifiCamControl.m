//
//  WifiCamControl.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-30.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamControl.h"
#import "WifiCamFileTable.h"


@implementation WifiCamControl


+(void)scan
{
    WifiCamManager *app = [WifiCamManager instance];
    WifiCam *wifiCam1 = [self findOneWifiCam];
    [app.wifiCams removeAllObjects];
    [app.wifiCams addObject:wifiCam1];
}

+(WifiCam *)findOneWifiCam
{
    WifiCamCommonControl *comCtrl = [[WifiCamCommonControl alloc] init];
    WifiCamPropertyControl *propCtrl = [[WifiCamPropertyControl alloc] init];
    WifiCamActionControl *actCtrl = [[WifiCamActionControl alloc] init];
    WifiCamFileControl *fileCtrl = [[WifiCamFileControl alloc] init];
    WifiCamPlaybackControl *pbCtrl = [[WifiCamPlaybackControl alloc] init];
    WifiCamControlCenter *ctrl = [[WifiCamControlCenter alloc] initWithParameters:comCtrl
                                                               andPropertyControl:propCtrl
                                                                 andActionControl:actCtrl
                                                                   andFileControl:fileCtrl
                                                               andPlaybackControl:pbCtrl];
    
    // Package this WifiCam object using serverl components
    WifiCam *wifiCam1 = [[WifiCam alloc] initWithId:1
                                   andWifiCamCamera:nil
                             andWifiCamPhotoGallery:nil
                            andWifiCamControlCenter:ctrl];
    return wifiCam1;
    
}

+(WifiCamCamera *)createOneCamera {
    WifiCamCamera *camera = nil;
    SDK *sdk = [SDK instance];
//    NSUInteger abilities = 0;
//    abilities = [self scanAbility];
    NSArray *abilities = [self scanAbility];
    AppLog(@"ssid: %@", [sdk getCustomizePropertyStringValue:0xD83C]);
    AppLog(@"password: %@", [sdk getCustomizePropertyStringValue:0xD83D]);
    //unsigned int temp = [sdk retrieveDelayedCaptureTime];
    camera = [[WifiCamCamera alloc] initWithParameters:abilities
                                         andCameraMode:(ICatchCamMode)[sdk retrieveCurrentCameraMode]
                                          andImageSize:[sdk retrieveImageSize]
                                          andVideoSize:[sdk retrieveVideoSize]
                                     andDelayedCapture:[sdk retrieveDelayedCaptureTime]
                                       andWhiteBalance:[sdk retrieveWhiteBalanceValue]
                                         andSlowMotion:[sdk retrieveCurrentSlowMotion]
                                         andInvertMode:[sdk retrieveCurrentUpsideDown]
                                        andBurstNumber:[sdk retrieveBurstNumber]
                               andStorageSpaceForImage:[sdk retrieveFreeSpaceOfImage]
                               andStorageSpaceForVideo:[sdk retrieveFreeSpaceOfVideo]
                                     andLightFrequency:[sdk retrieveLightFrequency]
                                          andDateStamp:[sdk retrieveDateStamp]
                                  andTimelapseInterval:[sdk retrieveTimelapseInterval]
                                  andTimelapseDuration:[sdk retrieveTimelapseDuration]
                                          andFWVersion:[sdk retrieveCameraFWVersion]
                                        andProductName:[sdk retrieveCameraProductName]
                                               andSSID:[sdk getCustomizePropertyStringValue:0xD83C]
                                           andPassword:[sdk getCustomizePropertyStringValue:0xD83D]
                                        andPreviewMode:WifiCamPreviewModeVideoOff
                                   andIsMovieRecording:[sdk isMediaStreamRecording]
                                 andIsStillTimelapseOn:[sdk isStillTimelapseOn]
                                 andIsVideoTimelapseOn:[sdk isVideoTimelapseOn]
                                      andTimelapseType:WifiCamTimelapseTypeVideo
                                 andEnableAutoDownload:YES
                                        andEnableAudio:YES];
    
    return camera;
}

+ (BOOL)capableOf:(WifiCamAbility)ability
{
    WifiCamManager *app = [WifiCamManager instance];
    WifiCam *wifiCam = [app.wifiCams objectAtIndex:0];
//    return (wifiCam.camera.ability & ability) == ability ? YES : NO;
    return [wifiCam.camera.ability containsObject:@(ability)];
}

+(WifiCamPhotoGallery *)createOnePhotoGallery {
    vector<shared_ptr<ICatchFile>> allList;
    unsigned long long allKBytes = 0;
    
    vector<shared_ptr<ICatchFile>> photoList;
    unsigned long long totalPhotoKBytes = 0;
    //  NSMutableDictionary *splitedPhotoDict = [[NSMutableDictionary alloc] init];
    
    vector<shared_ptr<ICatchFile>> videoList;
    unsigned long long totalVideoKBytes = 0;
    //  NSMutableDictionary *splitedVideoDict = [[NSMutableDictionary alloc] init];
    
#if 0
#if 0
    allList = [[SDK instance] requestFileListOfType:WCFileTypeAll];
#else
    allList = [[SDK instance] requestHugeFileListOfType:WCFileTypeAll maxNum:800];
#endif

#else
    if ([self capableOf:WifiCamAbilityDefaultToPlayback] && [self capableOf:WifiCamAbilityGetFileByPagination]) {
        allList = [[SDK instance] requestHugeFileListOfType:WCFileTypeAll maxNum:800];
    } else {
        allList = [[SDK instance] requestFileListOfType:WCFileTypeAll];
    }
#endif
    unsigned long long fileSize = 0;
    //  NSUInteger allListSize = allList.size();
    for(vector<shared_ptr<ICatchFile>>::iterator it = allList.begin();
        it != allList.end();
        ++it) {
        auto f = *it;
        switch (f->getFileType()) {
            case ICH_FILE_TYPE_IMAGE:
                photoList.push_back(f);
                fileSize = f->getFileSize()>>10;;
                allKBytes += fileSize;
                totalPhotoKBytes += fileSize;
                break;
            case ICH_FILE_TYPE_VIDEO:
                videoList.push_back(f);
                fileSize = f->getFileSize()>>10;
                allKBytes += fileSize;
                totalVideoKBytes += fileSize;
                break;
            default:
                break;
        }
    }
    
    WifiCamFileTable *imageTable = [[WifiCamFileTable alloc] initWithParameters:photoList
                                                                 andFileStorage:totalPhotoKBytes];
    WifiCamFileTable *videoTable = [[WifiCamFileTable alloc] initWithParameters:videoList
                                                                 andFileStorage:totalVideoKBytes];
    WifiCamFileTable *allFileTable = [[WifiCamFileTable alloc] initWithParameters:allList
                                                                   andFileStorage:allKBytes];
    WifiCamPhotoGallery *gallery = [[WifiCamPhotoGallery alloc] initWithFileTables:imageTable
                                                                     andVideoTable:videoTable
                                                                   andAllFileTable:allFileTable];
    
    
    return gallery;
}

+ (NSArray *)scanAbility {
//    NSUInteger abilities = 0;
    NSMutableArray *abilities = [NSMutableArray array];
    
    SDK *sdk = [SDK instance];
    
    vector<unsigned int>::iterator mit;
    vector <unsigned int>::iterator pit;
    
    vector<unsigned int> vModes = [sdk retrieveSupportedCameraModes];
    for (mit = vModes.begin(); mit != vModes.end(); ++mit) {
        switch (*mit) {
            case ICH_CAM_MODE_CAMERA:
//                abilities |= WifiCamAbilityStillCapture;
                [abilities addObject:@(WifiCamAbilityStillCapture)];
                break;
            case ICH_CAM_MODE_VIDEO:
//                abilities |= WifiCamAbilityMovieRecord;
                [abilities addObject:@(WifiCamAbilityMovieRecord)];
                break;
            case ICH_CAM_MODE_TIMELAPSE:
                AppLog(@"ICATCH_MODE_TIMELAPSE");
//                abilities |= WifiCamAbilityTimeLapse;
                [abilities addObject:@(WifiCamAbilityTimeLapse)];
                break;
                
            default:
                break;
        }
    }
    vector <unsigned int> vCaps = [sdk retrieveSupportedCameraCapabilities];
    for (pit = vCaps.begin(); pit != vCaps.end(); ++pit) {
        switch (*pit) {
            case ICH_CAM_WHITE_BALANCE:
//                abilities |= WifiCamAbilityWhiteBalance;
                [abilities addObject:@(WifiCamAbilityWhiteBalance)];
                break;
                
            case ICH_CAM_CAPTURE_DELAY:
//                if ((abilities & WifiCamAbilityStillCapture) == WifiCamAbilityStillCapture) {
//                    abilities |= WifiCamAbilityDelayCapture;
//                }
                if ([abilities containsObject:@(WifiCamAbilityStillCapture)]) {
                    [abilities addObject:@(WifiCamAbilityDelayCapture)];
                }
                break;
                
            case ICH_CAM_IMAGE_SIZE:
//                if ((abilities & WifiCamAbilityStillCapture) == WifiCamAbilityStillCapture) {
//                    abilities |= WifiCamAbilityImageSize;
//                }
                if ([abilities containsObject:@(WifiCamAbilityStillCapture)]) {
                    [abilities addObject:@(WifiCamAbilityImageSize)];
                }
                break;
                
            case ICH_CAM_VIDEO_SIZE:
//                if ((abilities & WifiCamAbilityMovieRecord) == WifiCamAbilityMovieRecord) {
//                    abilities |= WifiCamAbilityVideoSize;
//                }
                if ([abilities containsObject:@(WifiCamAbilityMovieRecord)]) {
                    [abilities addObject:@(WifiCamAbilityVideoSize)];
                }
                break;
                
            case ICH_CAM_LIGHT_FREQUENCY:
//                abilities |= WifiCamAbilityLightFrequency;
                [abilities addObject:@(WifiCamAbilityLightFrequency)];
                break;
                
            case ICH_CAM_BATTERY_LEVEL:
//                abilities |= WifiCamAbilityBatteryLevel;
                [abilities addObject:@(WifiCamAbilityBatteryLevel)];
                break;
                
            case ICH_CAM_PRODUCT_NAME:
//                abilities |= WifiCamAbilityProductName;
                [abilities addObject:@(WifiCamAbilityProductName)];
                break;
                
            case ICH_CAM_FW_VERSION:
//                abilities |= WifiCamAbilityFWVersion;
                [abilities addObject:@(WifiCamAbilityFWVersion)];
                break;
                
            case ICH_CAM_BURST_NUMBER:
//                abilities |= WifiCamAbilityBurstNumber;
                [abilities addObject:@(WifiCamAbilityBurstNumber)];
                break;
                
            case ICH_CAM_DATE_STAMP:
//                abilities |= WifiCamAbilityDateStamp;
                [abilities addObject:@(WifiCamAbilityDateStamp)];
                break;
                
            case ICH_CAM_UPSIDE_DOWN:
                AppLog(@"ICH_CAP_UPSIDE_DOWN");
//                abilities |= WifiCamAbilityUpsideDown;
                [abilities addObject:@(WifiCamAbilityUpsideDown)];
                break;
                
            case ICH_CAM_SLOW_MOTION:
                AppLog(@"ICH_CAP_SLOW_MOTION");
//                abilities |= WifiCamAbilitySlowMotion;
                [abilities addObject:@(WifiCamAbilitySlowMotion)];
                break;
                
            case ICH_CAM_DIGITAL_ZOOM:
//                abilities |= WifiCamAbilityZoom;
                [abilities addObject:@(WifiCamAbilityZoom)];
                break;
                
            case ICH_CAM_TIMELAPSE_STILL:
//                abilities |= WifiCamAbilityStillTimelapse;
                [abilities addObject:@(WifiCamAbilityStillTimelapse)];
                break;
                
            case ICH_CAM_TIMELAPSE_VIDEO:
//                abilities |= WifiCamAbilityVideoTimelapse;
                [abilities addObject:@(WifiCamAbilityVideoTimelapse)];
                break;
                
            case ICH_CAM_UNDEFINED:
            default:
//                abilities |= [self catCustomAbility:abilities prop:(ICatchCamProperty)*pit];
                [self catCustomAbility:abilities prop:(ICatchCamProperty)*pit];
                break;
        }
        
    }
    
    return abilities.copy;
}

//+ (NSUInteger)catCustomAbility: (NSUInteger)mainAbility prop:(ICatchCamProperty)prop {
+ (void)catCustomAbility:(NSMutableArray *)abilities prop:(ICatchCamProperty)prop {
    SDK *sdk = [SDK instance];
    AppLog(@"prop: 0x%x", prop);
    
    // Customize property
    // Date-Time Synchronization
    if (prop == 0x5011) {
        NSDate *date = [NSDate date];
        NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
        [dateformatter setDateFormat:@"yyyyMMdd"];
        NSString *dateTime = [dateformatter stringFromDate:date];
        [dateformatter setDateFormat:@"HHmmss.S"];
        dateTime = [dateTime stringByAppendingString:@"T"];
        dateTime = [dateTime stringByAppendingString:[dateformatter stringFromDate:date]];
        AppLog(@"current data & time : %@", dateTime);
        
        [sdk setCustomizeStringProperty:0x5011 value:dateTime];
        
    } else if (prop == 0xD83C) {
        AppLog(@"Enable to change SSID string.");
//        abilities |= WifiCamAbilityChangeSSID;
        [abilities addObject:@(WifiCamAbilityChangeSSID)];
    } else if (prop == 0xD83D) {
        AppLog(@"Enable to change Wi-Fi Password.");
//        abilities |= WifiCamAbilityChangePwd;
        [abilities addObject:@(WifiCamAbilityChangePwd)];
    } else if (prop == 0xD7F0) {
        AppLog(@"Choose the latest delay capture method");
//        abilities |= WifiCamAbilityLatestDelayCapture;
        [abilities addObject:@(WifiCamAbilityLatestDelayCapture)];
        [sdk setCustomizeIntProperty:prop value:1];
    } else if (prop == 0xD7FD) {
        AppLog(@"Get movie recorded time");
//        abilities |= WifiCamAbilityGetMovieRecordedTime;
        [abilities addObject:@(WifiCamAbilityGetMovieRecordedTime)];
    } else if (prop == 0xD720) {  // add - 2017.3.17
        AppLog(@"Get screen saver time");
        [abilities addObject:@(WifiCamAbilityGetScreenSaverTime)];
    } else if (prop == 0xD721) {
        AppLog(@"Get auto power off time");
        [abilities addObject:@(WifiCamAbilityGetAutoPowerOffTime)];
    } else if (prop == 0xD722) {
        AppLog(@"Get power on auto record");
        [abilities addObject:@(WifiCamAbilityGetPowerOnAutoRecord)];
    } else if (prop == 0xD723) {
        AppLog(@"Get exposure compensation");
        [abilities addObject:@(WifiCamAbilityGetExposureCompensation)];
    } else if (prop == 0xD724) {
        AppLog(@"Get image stabilization");
        [abilities addObject:@(WifiCamAbilityGetImageStabilization)];
    } else if (prop == 0xD725) {
        AppLog(@"Get video file length");
        [abilities addObject:@(WifiCamAbilityGetVideoFileLength)];
    } else if (prop == 0xD726) {
        AppLog(@"Get fast motion movie");
        [abilities addObject:@(WifiCamAbilityGetFastMotionMovie)];
    } else if (prop == 0xD727) {
        AppLog(@"Get wind noise reduction");
        [abilities addObject:@(WifiCamAbilityGetWindNoiseReduction)];
    } else if (prop == 0xD704) { //add - 2017.6.21
        AppLog(@"New Capture Way");
        [abilities addObject:@(WifiCamAbilityNewCaptureWay)];
    } else if( prop == 0xD83E) { //add - 2018.1.22 update current TimeZone . +0800 = GCM +8 = Taipei Time
        NSTimeZone *timeZone = [NSTimeZone localTimeZone];
        NSString *TimeString;
        int t = (int)(timeZone.secondsFromGMT/3600);
        if( timeZone.secondsFromGMT >0 ){
            TimeString = [NSString stringWithFormat:@"+%02d00", t];
        }else{
            TimeString = [NSString stringWithFormat:@"-%02d00", -t];
        }
        AppLog(@"%@",TimeString);
        [sdk setCustomizeStringProperty:0xD83E value:TimeString];
    } else if( prop == 0xD72A ){
        AppLog(@"Get PIV feature");
        [abilities addObject:@(WifiCamAbilityPIV)];
    } else if (prop == 0xD72C) {
        AppLog(@"Default to Playback");
//        abilities |= WifiCamAbilityDefaultToPlayback;
        [abilities addObject:@(WifiCamAbilityDefaultToPlayback)];
    } else if (prop == 0xD83F) {
        AppLog(@"Get file by Pagination.");
//        abilities |= WifiCamAbilityGetFileByPagination;
        [abilities addObject:@(WifiCamAbilityGetFileByPagination)];
    }
    
//    return abilities;
}

@end
