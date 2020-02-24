//
//  WiFiCamH264StreamParameter.cpp
//  WifiCamMobileApp
//
//  Created by Guo on 6/16/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#include "WiFiCamH264StreamParameter.h"
#include <stdio.h>

WiFiCamH264StreamParameter::WiFiCamH264StreamParameter(int width, int height, int bitrate, int framerate) {
    this->width = width;
    this->height = height;
    this->bitrate = bitrate;
    this->framerate = framerate;
}

string WiFiCamH264StreamParameter::getCmdLineParam() {
    char temp[32];
    sprintf(temp, "%d", width);
    string w(temp);
    
    sprintf(temp, "%d", height);
    string h(temp);
    
    sprintf(temp, "%d", bitrate);
    string br(temp);
    
    sprintf(temp, "%d", framerate);
    string fps1(temp);
    
    string url = ":554/H264?W="+w+"&H="+h+"&BR="+br+"&FPS="+fps1;
    printf("%s\n", url.c_str());
    return url;
}

int WiFiCamH264StreamParameter::getVideoWidth() {
    return width;
}

int WiFiCamH264StreamParameter::getVideoHeight() {
    return height;
}

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
