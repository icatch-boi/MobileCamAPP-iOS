//
//  SDKPrivate.h
//  WifiCamMobileApp
//
//  Created by ZJ on 2017/3/8.
//  Copyright © 2017年 iCatchTech. All rights reserved.
//

#ifndef SDKPrivate_h
#define SDKPrivate_h

#include "gl/ICatchIPancamGL.h"
#include "gl/ICatchIPancamGLTransform.h"
//#include "gl/surface/ICatchISurfaceContext.h"

#include "ICatchIPancamControl.h"
#include "ICatchIPancamImage.h"
#include "ICatchIPancamListener.h"
#include "ICatchIPancamPreview.h"
#include "ICatchIPancamRender.h"
#include "ICatchIPancamVideoPlayback.h"
#include "ICatchPancamInfo.h"
#include "ICatchPancamLog.h"
#include "ICatchPancamSession.h"
#include "ICatchPancamConfig.h"

#include "type/CredentialSDK.h"
#include "type/ICatchGLColor.h"
#include "type/ICatchGLDisplayPPI.h"
#include "type/ICatchGLEvent.h"
#include "type/ICatchGLEventID.h"
#include "type/ICatchGLImage.h"
#include "type/ICatchGLLogLevel.h"
#include "type/ICatchGLLogType.h"
#include "type/ICatchGLPanoramaType.h"
#include "type/ICatchGLPoint.h"
#include "type/ICatchGLRotation.h"
#include "type/ICatchGLSurfaceType.h"

#include "surface/ICatchSurfaceContext.h"
#include "surface/ICatchSurfaceContext_IOS.h"
#include "surface/ICatchSurfaceRender.h"

#include "stream/ICatchIStreamControl.h"
#include "stream/ICatchIStreamPublish.h"
#include "stream/ICatchIStreamProvider.h"

using namespace com::icatchtek::pancam;

typedef NS_ENUM(NSInteger, PTPDpcBurstNumber) {
    PTPDpcBurstNumber_HS = 0x0000,
    PTPDpcBurstNumber_OFF,
    PTPDpcBurstNumber_3,
    PTPDpcBurstNumber_5,
    PTPDpcBurstNumber_10,
    PTPDpcBurstNumber_7,
    PTPDpcBurstNumber_15,
    PTPDpcBurstNumber_30,
};


typedef NS_ENUM(NSInteger, PTPDpcWhiteBalance) {
    PTPDpcWhiteBalance_AUTO = 0x0001,
    PTPDpcWhiteBalance_DAYLIGHT,
    PTPDpcWhiteBalance_CLOUDY,
    /*
     原本sdk 定義的與FW 不同
    PTPDpcWhiteBalance_FLUORESCENT,
    PTPDpcWhiteBalance_TUNGSTEN,
     */
    PTPDpcWhiteBalance_FLUORESCENT,
    PTPDpcWhiteBalance_TUNGSTEN,
    

    PTPDpcWhiteBalance_UNDERWATER,
};

typedef NS_ENUM(NSInteger, CustomizePropertyID) {
    CustomizePropertyID_ScreenSaver = 0xd720,
    CustomizePropertyID_AutoPowerOff,
    CustomizePropertyID_PowerOnAutoRecord,
    CustomizePropertyID_EXposureCompensation,
    CustomizePropertyID_ImageStabilization,
    CustomizePropertyID_VideoFileLength,
    CustomizePropertyID_FastMotionMovie,
    CustomizePropertyID_WindNoiseReduction,
};

#endif /* SDKPrivate_h */
