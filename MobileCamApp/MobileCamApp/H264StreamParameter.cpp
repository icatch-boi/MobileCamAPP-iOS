//
//  H264StreamParameter.cpp
//
//  Created by Guo on 6/16/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#include "H264StreamParameter.h"
#include <stdio.h>

H264StreamParameter::H264StreamParameter(int codec, int width, int height, int bitrate, int framerate) {
    this->codec = codec;
    this->videoW = width;
    this->videoH = height;
    this->bitrate = bitrate;
    this->framerate = framerate;
}

H264StreamParameter::~H264StreamParameter() {}

string H264StreamParameter::getCmdLineParam() {
    char temp[32];
    sprintf(temp, "%d", videoW);
    string w(temp);
    
    sprintf(temp, "%d", videoH);
    string h(temp);
    
    sprintf(temp, "%d", bitrate);
    string br(temp);
    
    sprintf(temp, "%d", framerate);
    string fps(temp);
    
    string url = ":554/H264?W="+w+"&H="+h+"&BR="+br+"&FPS="+fps;
    printf("%s\n", url.c_str());
    return url;
}

int H264StreamParameter::getCodec() {
    return codec;
}
int H264StreamParameter::getWidth() {
    return videoW;
}
int H264StreamParameter::getHeight() {
    return videoH;
}
int H264StreamParameter::getBitRate() {
    return bitrate;
}
int H264StreamParameter::getFrameRate() {
    return framerate;
}
