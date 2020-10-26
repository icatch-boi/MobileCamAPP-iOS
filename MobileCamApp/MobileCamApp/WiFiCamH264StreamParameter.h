//
//  WiFiCamH264StreamParameter.h
//  WifiCamMobileApp
//
//  Created by Guo on 6/16/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#ifndef WiFiCamH264StreamParameter_H_
#define WiFiCamH264StreamParameter_H_

#include "ICatchStreamParam.h"
class WiFiCamH264StreamParameter : public ICatchStreamParam
{
public:
    WiFiCamH264StreamParameter(int codec, int width = 640, int height = 360, int bitrate = 5000000, int framerate = 30);
    ~WiFiCamH264StreamParameter();

    string getCmdLineParam();
    int getCodec();
    int getWidth();
    int getHeight();
    int getBitRate();
    int getFrameRate();

private:
    int codec;
    int videoW;
    int videoH;
    int bitrate;
    int framerate;
};

#endif
