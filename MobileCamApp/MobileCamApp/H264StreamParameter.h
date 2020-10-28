//
//  H264StreamParameter.h
//  WifiCamMobileApp
//
//  Created by Guo on 6/16/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#ifndef H264StreamParameter_H_
#define H264StreamParameter_H_

#include "ICatchStreamParam.h"
class H264StreamParameter : public ICatchStreamParam
{
public:
    H264StreamParameter(int codec, int width = 640, int height = 360, int bitrate = 5000000, int framerate = 30);
    ~H264StreamParameter();

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
