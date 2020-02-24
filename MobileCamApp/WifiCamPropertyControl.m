//
//  WifiCamPropertyControl.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-23.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamPropertyControl.h"
#include "ICatchCameraConfig.h"

@implementation WifiCamPropertyControl
/*
 - (BOOL)isMediaStreamRecording {
 return [[SDK instance] isMediaStreamRecording];
 }
 
 -(BOOL)isVideoTimelapseOn {
 return [[SDK instance] isVideoTimelapseOn];
 }
 -(BOOL)isStillTimelapseOn {
 return [[SDK instance] isStillTimelapseOn];
 }
 */
- (BOOL)connected {
    __block BOOL retVal = NO;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] isConnected];
    });
    return retVal;
}

- (BOOL)checkSDExist {
    __block BOOL retVal = NO;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] checkSDExist];
    });
    return retVal;
}

- (BOOL)videoStreamEnabled {
    __block BOOL retVal = NO;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[PanCamSDK instance] videoStreamEnabled];
    });
    return retVal;
}

- (BOOL)audioStreamEnabled {
    __block BOOL retVal = NO;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[PanCamSDK instance] audioStreamEnabled];
    });
    return retVal;
}

- (int)changeImageSize:(string)size{
    __block int retVal = -1;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] changeImageSize:size];
    });
    return retVal;
}

- (int)changeVideoSize:(string)size{
    __block int retVal = -1;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] changeVideoSize:size];
    });
    
//    uint cacheTime = [[SDK instance] previewCacheTime];
//    ICatchCameraConfig::getInstance()->setPreviewCacheParam(cacheTime);
    return retVal;
}

-(int)changeDelayedCaptureTime:(unsigned int)time{
    __block int retVal = ICH_UNKNOWN_ERROR;
//    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] changeDelayedCaptureTime:time];
//    });
    return retVal;
}

-(int)changeWhiteBalance:(unsigned int)value{
    __block int retVal = -1;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] changeWhiteBalance:value];
    });
    return retVal;
}

-(int)changeLightFrequency:(unsigned int)value {
    __block int retVal = -1;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] changeLightFrequency:value];
    });
    return retVal;
}
-(int)changeBurstNumber:(unsigned int)value {
    __block int retVal = -1;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] changeBurstNumber:value];
    });
    return retVal;
}
-(int)changeDateStamp:(unsigned int)value {
    __block int retVal = -1;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] changeDateStamp:value];
    });
    return retVal;
}
-(int)changeTimelapseType:(ICatchCamPreviewMode)mode {
    __block int retVal = -1;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] changeTimelapseType:mode];
    });
    return retVal;
}
-(int)changeTimelapseInterval:(unsigned int)value {
    __block int retVal = -1;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] changeTimelapseInterval:value];
    });
    return retVal;
}
-(int)changeTimelapseDuration:(unsigned int)value {
    __block int retVal = -1;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] changeTimelapseDuration:value];
    });
    return retVal;
}

- (int)changeUpsideDown:(uint)value {
    __block int retVal = -1;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] changeUpsideDown:value];
    });
    return retVal;
}

- (int)changeSlowMotion:(uint)value {
    __block int retVal = -1;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] changeSlowMotion:value];
    });
    return retVal;
}

- (BOOL)changeSSID:(NSString *)ssid {
    __block BOOL retVal = NO;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] setCustomizeStringProperty:0xD83C value:ssid];
    });
    return retVal;
}

- (BOOL)changePassword:(NSString *)password {
    __block BOOL retVal = NO;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] setCustomizeStringProperty:0xD83D value:password];
    });
    return retVal;
}



- (unsigned int)retrieveDelayedCaptureTime {
    __block unsigned int retVal = -1;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] retrieveDelayedCaptureTime];
    });
    return retVal;
}

- (unsigned int)retrieveBurstNumber {
    __block unsigned int retVal = -1;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] retrieveBurstNumber];
    });
    return retVal;
}

- (unsigned int)parseDelayCaptureInArray:(NSInteger)index
{
    __block vector<unsigned int> vDCs = vector<unsigned int>();
    dispatch_sync([[SDK instance] sdkQueue], ^{
        vDCs = [[SDK instance] retrieveSupportedCaptureDelays];
    });
    return vDCs.at(index);
    
}

- (string)parseImageSizeInArray:(NSInteger)index
{
    __block vector<string> vISs = vector<string>();
    dispatch_sync([[SDK instance] sdkQueue], ^{
        vISs = [[SDK instance] retrieveSupportedImageSizes];
    });
    return vISs.at(index);
}

- (string)parseTimeLapseVideoSizeInArray:(NSInteger)index
{

    __block vector<string> vVSs = vector<string>();
    dispatch_sync([[SDK instance] sdkQueue], ^{
        long int mask;
        int j=0;
        vVSs = [[SDK instance] retrieveSupportedVideoSizes];
        mask = [[SDK instance] getCustomizePropertyIntValue:0xD7FB];
        if( mask >0){
            for(vector<string>::iterator it = vVSs.begin();
                it != vVSs.end();
                ++it,++j) {
                AppLog(@"%s", (*it).c_str());
                // erase mask size
                if( j==0 ){
                    if( (0x01 & mask ) == 0 ){
                        AppLog(@"remove %s",(*it).c_str() );
                        vVSs.erase(it);
                        --it;
                    }
                }
                else if( ((0x01 << j )&mask) == 0 ){
                    AppLog(@"remove %s",(*it).c_str() );
                    vVSs.erase(it);
                    --it;
                }
            }
        }
    
    });
    return vVSs.at(index);
}
- (string)parseVideoSizeInArray:(NSInteger)index
{
    __block vector<string> vVSs = vector<string>();
    dispatch_sync([[SDK instance] sdkQueue], ^{
        vVSs = [[SDK instance] retrieveSupportedVideoSizes];
    });
    return vVSs.at(index);
}

- (unsigned int)parseWhiteBalanceInArray:(NSInteger)index
{
    __block vector<unsigned int> vWBs = vector<unsigned int>();
    dispatch_sync([[SDK instance] sdkQueue], ^{
        vWBs = [[SDK instance] retrieveSupportedWhiteBalances];
    });
    return vWBs.at(index);
}

- (unsigned int)parsePowerFrequencyInArray:(NSInteger)index
{
    __block vector<unsigned int> vLFs = vector<unsigned int>();
    dispatch_sync([[SDK instance] sdkQueue], ^{
        vLFs = [[SDK instance] retrieveSupportedLightFrequencies];
    });
    return vLFs.at(index);
}

- (unsigned int)parseBurstNumberInArray:(NSInteger)index
{
    __block vector<unsigned int> vBNs = vector<unsigned int>();
    dispatch_sync([[SDK instance] sdkQueue], ^{
        vBNs = [[SDK instance] retrieveSupportedBurstNumbers];
    });
    return vBNs.at(index);
}

- (unsigned int)parseDateStampInArray:(NSInteger)index
{
    __block vector<unsigned int> vDSs = vector<unsigned int>();
    dispatch_sync([[SDK instance] sdkQueue], ^{
        vDSs = [[SDK instance] retrieveSupportedDateStamps];
    });
    return vDSs.at(index);
}

- (unsigned int)parseTimelapseIntervalInArray:(NSInteger)index
{
    __block vector<unsigned int> vVTIs = vector<unsigned int>();
    dispatch_sync([[SDK instance] sdkQueue], ^{
        vVTIs = [[SDK instance] retrieveSupportedTimelapseInterval];
    });
    return vVTIs.at(index);
}

- (unsigned int)parseTimelapseDurationInArray:(NSInteger)index
{
    __block vector<unsigned int> vVTDs = vector<unsigned int>();
    dispatch_sync([[SDK instance] sdkQueue], ^{
        vVTDs = [[SDK instance] retrieveSupportedTimelapseDuration];
    });
    return vVTDs.at(index);
}

/*
 - (NSArray *)prepareDataForStorageSpaceOfImage:(string)imageSize
 {
 NSDictionary *curStaticImageSizeDict = [[WifiCamStaticData instance] imageSizeDict];
 NSString *key = [NSString stringWithFormat:@"%s", imageSize.c_str()];
 NSString *title = [curStaticImageSizeDict objectForKey:key];
 unsigned int n = [[SDK instance] retrieveFreeSpaceOfImage];
 
 return [NSArray arrayWithObjects:title, @(MAX(0, n)), nil];
 }
 */

- (NSArray *)prepareDataForStorageSpaceOfVideo:(string)videoSize
{
    __block NSArray *a = nil;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        NSDictionary *curStaticVideoSizeDict = [[WifiCamStaticData instance] videoSizeDict];
        NSString *key = [NSString stringWithFormat:@"%s", videoSize.c_str()];
        NSArray *curStaticVideoSizeArray = [curStaticVideoSizeDict objectForKey:key];
        NSString *title = curStaticVideoSizeArray ? [curStaticVideoSizeArray firstObject] : key;
        unsigned int iStorage = [[SDK instance] retrieveFreeSpaceOfVideo];
        
        a = [NSArray arrayWithObjects:title, @(MAX(0, iStorage)), nil];
    });
    
    return a;
}


//
- (WifiCamAlertTable *)prepareDataForDelayCapture:(unsigned int)curDelayCapture
{
    WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
    dispatch_sync([[SDK instance] sdkQueue], ^{
        int i = 0;
        SDK *sdk = [SDK instance];
        vector <unsigned int> v = [sdk retrieveSupportedCaptureDelays];
        NSDictionary *dict = [[WifiCamStaticData instance] captureDelayDict];
        
        TAA.array = [[NSMutableArray alloc] initWithCapacity:v.size()];
        [TAA.array removeAllObjects];
        
        
        for (vector <unsigned int>::iterator it = v.begin();
             it != v.end();
             ++it, ++i) {
            NSString *s = [dict objectForKey:@(*it)];
            
            if (s) {
                [TAA.array addObject:s];
            }
            
            if (*it == curDelayCapture) {
                TAA.lastIndex = i;
            }
        }
        
        AppLog(@"TAA.lastIndex: %lu", (unsigned long)TAA.lastIndex);
    });
    return TAA;
}

// Modify by Allen.Chuang 2014.10.3
// parse imagesize string from camera and calucate as M size
- (WifiCamAlertTable *)prepareDataForImageSize:(string)curImageSize
{
    WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
    dispatch_sync([[SDK instance] sdkQueue], ^{
        int i = 0;
        NSString *images = nil;
        NSString *sizeString = nil;
        SDK *sdk = [SDK instance];
        
        vector<string> vISs = [sdk retrieveSupportedImageSizes];
        for(vector<string>::iterator it = vISs.begin(); it != vISs.end(); ++it) {
            AppLog(@"%s", (*it).c_str());
        }
        
        
        TAA.array = [[NSMutableArray alloc] initWithCapacity:vISs.size()];
        
        for (vector <string>::iterator it = vISs.begin();
             it != vISs.end();
             ++it, ++i) {
            images = [NSString stringWithFormat:@"%s",(*it).c_str()];
            sizeString = [self calcImageSizeToNum:images];
            [TAA.array addObject:sizeString];
            if (*it == curImageSize) {
                TAA.lastIndex = i;
            }
        }
    });
    return TAA;
}


- (NSArray *)prepareDataForStorageSpaceOfImage:(string)imageSize
{
    __block NSArray *a = nil;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        unsigned int freeSpace = [[SDK instance] retrieveFreeSpaceOfImage];
        NSString *images = [NSString stringWithFormat:@"%s",imageSize.c_str()];
        NSString *sizeString = [self calcImageSizeToNum:images];
        a = [NSArray arrayWithObjects:sizeString, @(MAX(0, freeSpace)), nil];
    });
    return a;
}

-(NSString *)calcImageSizeToNum:(NSString *)size
{
    NSArray *xyArray = [size componentsSeparatedByString:@"x"];
    float imgX = [[xyArray objectAtIndex:0] floatValue];
    float imgY = [[xyArray objectAtIndex:1] floatValue];
    float numberToRound =(imgX*imgY/1000000);
    int sizeNum = (int) round(numberToRound);
    AppLog(@"roundf(%.2f) = %d",numberToRound, sizeNum);
    
    return sizeNum == 0 ? @"VGA" : [NSString stringWithFormat:@"%dM",sizeNum];
}

/*
 - (WifiCamAlertTable *)prepareDataForImageSize:(string)curImageSize
 {
 int i = 0;
 SDK *sdk = [SDK instance];
 
 vector<string> vISs = [sdk retrieveSupportedImageSizes];
 for(vector<string>::iterator it = vISs.begin(); it != vISs.end(); ++it) {
 AppLog(@"%s", (*it).c_str());
 }
 
 WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
 TAA.array = [[NSMutableArray alloc] initWithCapacity:vISs.size()];
 NSDictionary *imageSizeDict = [[WifiCamStaticData instance] imageSizeDict];
 
 for (vector <string>::iterator it = vISs.begin();
 it != vISs.end();
 ++it, ++i) {
 NSString *key = [NSString stringWithFormat:@"%s", (*it).c_str()];
 NSString *size = [imageSizeDict objectForKey:key];
 size = [size stringByAppendingFormat:@"(%@)", key];
 [TAA.array addObject:size];
 if (*it == curImageSize) {
 TAA.lastIndex = i;
 }
 }
 
 return TAA;
 }
 */

- (WifiCamAlertTable *)prepareDataForTimeLapseVideoSize:(string)curVideoSize
{
    WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
    dispatch_sync([[SDK instance] sdkQueue], ^{
        int i = 0;
        int j = 0;
        SDK *sdk = [SDK instance];
        
        vector<string> vVSs = [sdk retrieveSupportedVideoSizes];
        
        // fetch mask value for timelapse video size
        int mask = [sdk getCustomizePropertyIntValue:0xD7FB];
        int umask = 0x0001;
        if( mask >0){
            AppLog(@"%s TimeLapse mask : %d",__func__, mask);
            for(vector<string>::iterator it = vVSs.begin();
                it != vVSs.end();
                it++,j++) {
                AppLog(@"%s", (*it).c_str());
                // erase mask size
                if( j==0 ){
                    if( (umask & mask) == 0){
                        AppLog(@"remove %s",(*it).c_str() );
                        vVSs.erase(it);
                        it--;
                    }
                }
                else if( ((umask << j ) & mask) == 0 ){
                    AppLog(@"remove %s",(*it).c_str() );
                    vVSs.erase(it);
                    it--;
                }
            }

        }
        
        TAA.array = [[NSMutableArray alloc] initWithCapacity:vVSs.size()];
        NSDictionary *videoSizeDict = [[WifiCamStaticData instance] videoSizeDict];
        
        for (vector <string>::iterator it = vVSs.begin();
             it != vVSs.end();
             ++it, ++i) {
            NSString *key = [NSString stringWithFormat:@"%s", (*it).c_str()];
            NSArray   *a = [videoSizeDict objectForKey:key];
            NSString  *first = [a firstObject];
            NSString  *last = [a lastObject];
            
            if (last != nil) {
                NSString *s = [first stringByAppendingFormat:@" %@", last]; // Customize
                
                if (s != nil) {
                    [TAA.array addObject:s];
                }
                
                if (*it == curVideoSize) {
                    TAA.lastIndex = i;
                }
            } else {
                [TAA.array addObject:key];
                
                if (*it == curVideoSize) {
                     TAA.lastIndex = i;
                 }
            }
        }
    });
    return TAA;
}


- (WifiCamAlertTable *)prepareDataForVideoSize:(string)curVideoSize
{
    WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
    dispatch_sync([[SDK instance] sdkQueue], ^{
        int i = 0;
        SDK *sdk = [SDK instance];
        
        vector<string> vVSs = [sdk retrieveSupportedVideoSizes];
        //vVSs.push_back("3840x2160 10");
        //vVSs.push_back("2704x1524 15");
        for(vector<string>::iterator it = vVSs.begin();
            it != vVSs.end();
            ++it) {
            AppLog(@"%s", (*it).c_str());
        }
        
        
        TAA.array = [[NSMutableArray alloc] initWithCapacity:vVSs.size()];
        NSDictionary *videoSizeDict = [[WifiCamStaticData instance] videoSizeDict];
        
        for (vector <string>::iterator it = vVSs.begin();
             it != vVSs.end();
             ++it, ++i) {
            NSString *key = [NSString stringWithFormat:@"%s", (*it).c_str()];
            NSArray   *a = [videoSizeDict objectForKey:key];
            NSString  *first = [a firstObject];
            NSString  *last = [a lastObject];
            
            if (last != nil) {
                NSString *s = [first stringByAppendingFormat:@" %@", last]; // Customize
                
                if (s != nil) {
                    [TAA.array addObject:s];
                }
                
                if (*it == curVideoSize) {
                    TAA.lastIndex = i;
                }
            } else {
                [TAA.array addObject:key];
                
                if (*it == curVideoSize) {
                     TAA.lastIndex = i;
                 }
            }
        }
    });
    return TAA;
}

- (WifiCamAlertTable *)prepareDataForLightFrequency:(unsigned int)curLightFrequency
{
    WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
    dispatch_sync([[SDK instance] sdkQueue], ^{
        int i = 0;
        SDK *sdk = [SDK instance];
        BOOL InvalidSelectedIndex = NO;
        vector<unsigned int> vLFs = [sdk retrieveSupportedLightFrequencies];
        vector<ICatchCamLightFrequency> supportedEnumedLightFrequencies;
        ICatchCameraUtil::convertLightFrequencies(vLFs, supportedEnumedLightFrequencies);
        NSDictionary *dict = [[WifiCamStaticData instance] powerFrequencyDict];
        
        TAA.array = [[NSMutableArray alloc] initWithCapacity:supportedEnumedLightFrequencies.size()];
        
        for (vector <ICatchCamLightFrequency>::iterator it = supportedEnumedLightFrequencies.begin();
             it != supportedEnumedLightFrequencies.end();
             ++it, ++i) {
            NSString *s = [dict objectForKey:@(*it)];
            
            if (s != nil && ![s isEqualToString:@""]) {
                [TAA.array addObject:s];
            }
            
            if (*it == curLightFrequency && !InvalidSelectedIndex) {
                TAA.lastIndex = i;
                InvalidSelectedIndex = YES;
            }
        }
        if (!InvalidSelectedIndex) {
            TAA.lastIndex = UNDEFINED_NUM;
        }
    });
    return TAA;
}

- (WifiCamAlertTable *)prepareDataForWhiteBalance:(unsigned int)curWhiteBalance
{
    WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
    dispatch_sync([[SDK instance] sdkQueue], ^{
        SDK *sdk = [SDK instance];
        BOOL InvalidSelectedIndex = NO;
        vector<unsigned int> vWBs = [sdk retrieveSupportedWhiteBalances];
        vector<ICatchCamWhiteBalance> supportedEnumedWhiteBalances;
        ICatchCameraUtil::convertWhiteBalances(vWBs, supportedEnumedWhiteBalances);
        
        TAA.array = [[NSMutableArray alloc] initWithCapacity:supportedEnumedWhiteBalances.size()];
        int i = 0;
        NSDictionary *dict = [[WifiCamStaticData instance] whiteBalanceDict];
        
        for (vector <ICatchCamWhiteBalance>::iterator it = supportedEnumedWhiteBalances.begin();
             it != supportedEnumedWhiteBalances.end();
             ++it, ++i) {
            NSString *s = [dict objectForKey:@(*it)];
            
            if (s != nil) {
                [TAA.array addObject:s];
            }
            
            if (*it == curWhiteBalance && !InvalidSelectedIndex) {
                TAA.lastIndex = i;
                InvalidSelectedIndex = YES;
            }
        }
        if (!InvalidSelectedIndex) {
            AppLog(@"Undefined Number");
            TAA.lastIndex = UNDEFINED_NUM;
        }
    });
    return TAA;
}

- (WifiCamAlertTable *)prepareDataForBurstNumber:(unsigned int)curBurstNumber
{
    WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
    dispatch_sync([[SDK instance] sdkQueue], ^{
        SDK *sdk = [SDK instance];
        
        BOOL InvalidSelectedIndex = NO;
        vector<unsigned int> vBNs = [sdk retrieveSupportedBurstNumbers];
        AppLog(@"vBNs.size(): %lu", vBNs.size());
        vector<ICatchCamBurstNumber> supportedEnumedBurstNumbers;
        ICatchCameraUtil::convertBurstNumbers(vBNs, supportedEnumedBurstNumbers);
        
        TAA.array = [[NSMutableArray alloc] initWithCapacity:supportedEnumedBurstNumbers.size()];
        AppLog("supportedEnumedBurstNumbers.size(): %lu", supportedEnumedBurstNumbers.size());
        int i = 0;
        NSDictionary *dict = [[WifiCamStaticData instance] burstNumberStringDict];
        
        for (vector <ICatchCamBurstNumber>::iterator it = supportedEnumedBurstNumbers.begin();
             it != supportedEnumedBurstNumbers.end();
             ++it, ++i) {
            NSString *s = [[dict objectForKey:@(*it)] firstObject];
            
            if (s != nil) {
                [TAA.array addObject:s];
            }
            
            if (*it == curBurstNumber && !InvalidSelectedIndex) {
                TAA.lastIndex = i;
                InvalidSelectedIndex = YES;
            }
        }
        if (!InvalidSelectedIndex) {
            AppLog(@"Undefined Number");
            TAA.lastIndex = UNDEFINED_NUM;
        }
    });
    return TAA;
}

- (WifiCamAlertTable *)prepareDataForDateStamp:(unsigned int)curDateStamp
{
    WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
    dispatch_sync([[SDK instance] sdkQueue], ^{
        SDK *sdk = [SDK instance];
        
        BOOL InvalidSelectedIndex = NO;
        vector<unsigned int> vDSs = [sdk retrieveSupportedDateStamps];
        vector<ICatchCamDateStamp> supportedEnumedDataStamps;
        ICatchCameraUtil::convertDateStamps(vDSs, supportedEnumedDataStamps);
        
        TAA.array = [[NSMutableArray alloc] initWithCapacity:supportedEnumedDataStamps.size()];
        int i =0;
        NSDictionary *dict = [[WifiCamStaticData instance] dateStampDict];
        
        for(vector<ICatchCamDateStamp>::iterator it = supportedEnumedDataStamps.begin();
            it != supportedEnumedDataStamps.end();
            ++it, ++i) {
            NSString *s = [dict objectForKey:@(*it)];
            
            if (s != nil) {
                [TAA.array addObject:s];
            }
            
            if (*it == curDateStamp && !InvalidSelectedIndex) {
                TAA.lastIndex = i;
                InvalidSelectedIndex = YES;
            }
        }
        
        if (!InvalidSelectedIndex) {
            AppLog(@"Undefined Number");
            TAA.lastIndex = UNDEFINED_NUM;
        }
    });
    return TAA;
}

- (WifiCamAlertTable *)prepareDataForTimelapseInterval:(unsigned int)curTimelapseInterval
{
    WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
    dispatch_sync([[SDK instance] sdkQueue], ^{
        SDK *sdk = [SDK instance];
        
        BOOL InvalidSelectedIndex = NO;
        
        vector<unsigned int> vTIs = [sdk retrieveSupportedTimelapseInterval];
        
        
        TAA.array = [[NSMutableArray alloc] initWithCapacity:vTIs.size()];
        int i =0;
        //    NSDictionary *dict = [[WifiCamStaticData instance] timelapseIntervalDict];
        
        AppLog(@"curTimelapseInterval: %d", curTimelapseInterval);
        for(vector<unsigned int>::iterator it = vTIs.begin();
            it != vTIs.end();
            ++it, ++i) {
            AppLog(@"Interval Item Value: %u", *it);
            //        NSString *s = [dict objectForKey:@(*it)];
            NSString *s = nil;
            
            if (0 == *it) {
                s = NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_OFF", nil);
            }else if( *it >= 0xFFFE){
                s = NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_0.5_S", nil);
            }else if (*it >= 60 && *it < 3600) {
                s = [NSString stringWithFormat:@"%dm", (*it/60)];
            } else if (*it >= 3600) {
                s = [NSString stringWithFormat:@"%dhr", (*it/3600)];
            } else {
                s = [NSString stringWithFormat:@"%ds", *it];
            }
            
            if (s != nil) {
                [TAA.array addObject:s];
            }
            
            if (*it == curTimelapseInterval && !InvalidSelectedIndex) {
                TAA.lastIndex = i;
                InvalidSelectedIndex = YES;
            }
        }
        
        if (!InvalidSelectedIndex) {
            AppLog(@"Undefined Number");
            TAA.lastIndex = UNDEFINED_NUM;
        }
    });
    return TAA;
}


- (WifiCamAlertTable *)prepareDataForTimelapseDuration:(unsigned int)curTimelapseDuration
{
    WifiCamAlertTable *TAA = [[WifiCamAlertTable alloc] init];
    dispatch_sync([[SDK instance] sdkQueue], ^{
        SDK *sdk = [SDK instance];
        
        BOOL InvalidSelectedIndex = NO;
        vector<unsigned int> vTDs = [sdk retrieveSupportedTimelapseDuration];
        
        
        TAA.array = [[NSMutableArray alloc] initWithCapacity:vTDs.size()];
        int i =0;
        //    NSDictionary *dict = [[WifiCamStaticData instance] timelapseDurationDict];
        
        AppLog(@"curTimelapseDuration: %d",curTimelapseDuration);
        for(vector<unsigned int>::iterator it = vTDs.begin();
            it != vTDs.end();
            ++it, ++i) {
            //AppLog(@"Duration Item Value:%d", *it);
            //        NSString *s = [dict objectForKey:@(*it)];
            NSString *s = nil;
            if (0xFFFF == *it) {
                s = NSLocalizedString(@"SETTING_CAP_TL_DURATION_Unlimited", nil);
            } else if (*it >= 60 && *it < 3600) {
                s = [NSString stringWithFormat:@"%dhr", (*it/60)];
            } else {
                s = [NSString stringWithFormat:@"%dm", *it];
            }
            
            if (s != nil) {
                [TAA.array addObject:s];
            }
            
            if (*it == curTimelapseDuration && !InvalidSelectedIndex) {
                TAA.lastIndex = i;
                InvalidSelectedIndex = YES;
            }
        }
        
        if (!InvalidSelectedIndex) {
            AppLog(@"Undefined Number");
            TAA.lastIndex = UNDEFINED_NUM;
        }
    });
    return TAA;
}

- (shared_ptr<ICatchVideoFormat>)retrieveVideoFormat
{
    return [[PanCamSDK instance] getVideoFormat];
}

- (shared_ptr<ICatchAudioFormat>)retrieveAudioFormat {
    return [[PanCamSDK instance] getAudioFormat];
}

- (WifiCamAVData *)prepareDataForPlaybackVideoFrame
{
    return [[PanCamSDK instance] getPlaybackVideoData];
}

- (WifiCamAVData *)prepareDataForPlaybackAudioTrack
{
    return [[PanCamSDK instance] getPlaybackAudioData];
}

- (shared_ptr<ICatchFrameBuffer>)prepareDataForPlaybackAudioTrack1
{
    return [[PanCamSDK instance] getPlaybackAudioData1];
}

- (shared_ptr<ICatchVideoFormat>)retrievePlaybackVideoFormat
{
    return [[PanCamSDK instance] getPlaybackVideoFormat];
}

- (shared_ptr<ICatchAudioFormat>)retrievePlaybackAudioFormat {
    return [[PanCamSDK instance] getPlaybackAudioFormat];
}

- (NSString *)prepareDataForBatteryLevel
{
    __block uint level = -1;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        level = [[SDK instance] retrieveBatteryLevel];
    });
    return [self transBatteryLevel2NStr:level];
}

- (NSString *)transBatteryLevel2NStr:(unsigned int)value
{
    NSString *retVal = nil;
    
    if (value < 10) {
        retVal = @"battery_0";
    } else if (value < 40) {
        retVal = @"battery_1";
    } else if (value < 70) {
        retVal = @"battery_2";
    } else if (value <= 100) {
        retVal = @"battery_3";
    } else {
        AppLog(@"battery raw value: %d", value);
        retVal = @"battery_4";
    }
    
    return retVal;
}

//

-(uint)retrieveMaxZoomRatio
{
    __block uint retVal = 0;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] retrieveMaxZoomRatio];
    });
    return retVal;
}

-(uint)retrieveCurrentZoomRatio
{
    __block uint retVal = 0;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] retrieveCurrentZoomRatio];
    });
    return retVal;
}

-(uint)retrieveCurrentUpsideDown {
    __block uint retVal = 0;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] retrieveCurrentUpsideDown];
    });
    return retVal;
}

-(uint)retrieveCurrentSlowMotion {
    __block uint retVal = 0;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] retrieveCurrentSlowMotion];
    });
    return retVal;
}

-(uint)retrieveCurrentMovieRecordElapsedTime {
    __block uint retVal = 0;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] getCustomizePropertyIntValue:0xD7FD];
    });
    return retVal;
}

-(uint)retrieveCurrentTimelapseInterval {
    __block uint retVal = 0;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        retVal = [[SDK instance] retrieveTimelapseInterval];
    });
    return retVal;
}

//add by allen
-(string) retrieveCurrentVideoSize2{
    __block string videoSize="";
    dispatch_sync([[SDK instance] sdkQueue], ^{
        videoSize = [[SDK instance] retrieveVideoSizeByPropertyCode];
    });
    return videoSize;
}

-(BOOL)isSupportMethod2ChangeVideoSize {
    __block BOOL retVal = NO;
    dispatch_sync([[SDK instance] sdkQueue], ^{
        if (([[SDK instance] getCustomizePropertyIntValue:0xD7FC] & 0x0001) == 1) {
            AppLog(@"D7FC is ON");
            retVal = YES;
        } else if (([[SDK instance] getCustomizePropertyIntValue:0xD7FC] & 0x0001) == 0){
            retVal = NO;
        } else {
            retVal = NO;
        }
    });
    
    return retVal;
}

-(BOOL)isSupportPV {
    __block BOOL retVal = NO;
    
    dispatch_sync([[SDK instance] sdkQueue], ^{
        int value = [[SDK instance] getCustomizePropertyIntValue:0xD7FF];
        AppLog(@"Support PV: %d", value);
        if (value == 1) {
            retVal = YES;
        } else {
            retVal = NO;
        }
    });
    return retVal;
}

-(void)updateAllProperty:(WifiCamCamera *)camera {
    
    dispatch_sync([[SDK instance] sdkQueue], ^{
        SDK *sdk = [SDK instance];
        
        camera.cameraMode = (ICatchCamMode)[sdk retrieveCurrentCameraMode];
        camera.curImageSize = [sdk retrieveImageSize];
        if (camera.cameraMode != ICH_CAM_MODE_CAMERA) {
            camera.curVideoSize = [sdk retrieveVideoSize];
        }
        AppLog(@"video Size: %@", [NSString stringWithFormat:@"%s",camera.curVideoSize.c_str()]);
        camera.curCaptureDelay = [sdk retrieveDelayedCaptureTime];
        camera.curWhiteBalance = [sdk retrieveWhiteBalanceValue];
        camera.curSlowMotion = [sdk retrieveCurrentSlowMotion];
        camera.curInvertMode = [sdk retrieveCurrentUpsideDown];
        camera.curBurstNumber = [sdk retrieveBurstNumber];
        camera.storageSpaceForImage = [sdk retrieveFreeSpaceOfImage];
        camera.storageSpaceForVideo = [sdk retrieveFreeSpaceOfVideo];
        camera.curLightFrequency = [sdk retrieveLightFrequency];
        camera.curDateStamp = [sdk retrieveDateStamp];
        AppLog(@"date-stamp: %d", camera.curDateStamp);
        
        camera.curTimelapseInterval = [sdk retrieveTimelapseInterval];
        AppLog(@"timelapse-interval: %d", camera.curTimelapseInterval);
        
        camera.curTimelapseDuration = [sdk retrieveTimelapseDuration];
//        camera.cameraFWVersion = [sdk retrieveCameraFWVersion];
//        camera.cameraProductName = [sdk retrieveCameraProductName];
//        camera.ssid = [sdk getCustomizePropertyStringValue:0xD83C];
//        camera.password = [sdk getCustomizePropertyStringValue:0xD83D];
        //camera.previewMode = WifiCamPreviewModeVideoOff;
        camera.movieRecording = [sdk isMediaStreamRecording];
        camera.stillTimelapseOn = [sdk isStillTimelapseOn];
        camera.videoTimelapseOn = [sdk isVideoTimelapseOn];
        //camera.timelapseType = WifiCamTimelapseTypeVideo;
    });
}

@end
