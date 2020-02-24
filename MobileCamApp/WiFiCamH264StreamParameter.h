//
//  WiFiCamH264StreamParameter.h
//  WifiCamMobileApp
//
//  Created by Guo on 6/16/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#ifndef __WifiCamMobileApp__WiFiCamH264StreamParameter__
#define __WifiCamMobileApp__WiFiCamH264StreamParameter__

class WiFiCamH264StreamParameter:public ICatchStreamParam {
public:
    WiFiCamH264StreamParameter(int width, int height, int bitrate, int framerate);
    string getCmdLineParam();

    int getVideoWidth();
    int getVideoHeight();
    
//    void setVideoWidth(int width);
//    void setVideoHeight(int height);
//    void setVideoBitrate(int bitrate);
//    void setVideoFrameRate(int framerate);
private:
    int width, height, bitrate, framerate;
};

#endif /* defined(__WifiCamMobileApp__WiFiCamH264StreamParameter__) */
