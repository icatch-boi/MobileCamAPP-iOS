//
//  CustomerStreamParam.cpp
//  WifiCamMobileApp
//
//  Created by ZJ on 2016/10/23.
//  Copyright © 2016年 iCatchTech. All rights reserved.
//

#include "CustomerStreamParam.hpp"

CustomerStreamParam::CustomerStreamParam(int width, int height, int bitrate, int framerate) {
    this->width = width;
    this->height = height;
    this->bitrate = bitrate;
    this->framerate = framerate;
}

string CustomerStreamParam::getCmdLineParam() {
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

int CustomerStreamParam::getVideoWidth() {
    return width;
}

int CustomerStreamParam::getVideoHeight() {
    return height;
}
