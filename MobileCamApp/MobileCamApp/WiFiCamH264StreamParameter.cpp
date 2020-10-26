//
//  WiFiCamH264StreamParameter.cpp
//  WifiCamMobileApp
//
//  Created by Guo on 6/16/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#include "WiFiCamH264StreamParameter.h"
#include <stdio.h>

WiFiCamH264StreamParameter::WiFiCamH264StreamParameter(int codec, int width, int height, int bitrate, int framerate) {
    this->codec = codec;
    this->videoW = width;
    this->videoH = height;
    this->bitrate = bitrate;
    this->framerate = framerate;
}

WiFiCamH264StreamParameter::~WiFiCamH264StreamParameter() {}

string WiFiCamH264StreamParameter::getCmdLineParam() {
    char temp[32];
    sprintf(temp, "%d", videoW);
    string w(temp);
    
    sprintf(temp, "%d", videoH);
    string h(temp);
    
    sprintf(temp, "%d", bitrate);
    string br(temp);
    
    sprintf(temp, "%d", framerate);
    string fps1(temp);
    
    string url = ":554/H264?W="+w+"&H="+h+"&BR="+br+"&FPS="+fps1;
    printf("%s\n", url.c_str());
    return url;
}

int WiFiCamH264StreamParameter::getCodec() {
    return codec;
}
int WiFiCamH264StreamParameter::getWidth() {
    return videoW;
}
int WiFiCamH264StreamParameter::getHeight() {
    return videoH;
}
int WiFiCamH264StreamParameter::getBitRate() {
    return bitrate;
}
int WiFiCamH264StreamParameter::getFrameRate() {
    return framerate;
}

//int WiFiCamH264StreamParameter::getVideoWidth() {
//    return width;
//}
//
//int WiFiCamH264StreamParameter::getVideoHeight() {
//    return height;
//}

//void WiFiCamH264StreamParameter::setVideoWidth(int width) {
//    this->width = width;
//}
//void WiFiCamH264StreamParameter::setVideoHeight(int height) {
//    this->height = height;
//}
//void WiFiCamH264StreamParameter::setVideoBitrate(int bitrate) {
//    this->bitrate = bitrate;
//}
//void WiFiCamH264StreamParameter::setVideoFrameRate(int framerate) {
//    this->framerate = framerate;
//}
