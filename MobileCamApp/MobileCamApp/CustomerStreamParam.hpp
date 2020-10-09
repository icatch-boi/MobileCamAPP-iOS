//
//  CustomerStreamParam.hpp
//  WifiCamMobileApp
//
//  Created by ZJ on 2016/10/23.
//  Copyright © 2016年 iCatchTech. All rights reserved.
//

#ifndef CustomerStreamParam_hpp
#define CustomerStreamParam_hpp

#include <stdio.h>
#import "ICatchStreamParam.h"

class CustomerStreamParam : public ICatchStreamParam
{
    /*
public:
    CustomerStreamParam(string streamParam) {
        this->streamParam = streamParam;
    }
    virtual ~CustomerStreamParam() { };
    
    string getCmdLineParam() { return this->streamParam; }
    
    int getVideoWidth() { return 0; }
    int getVideoHeight() { return 0; }
    
private:
    string streamParam;*/
    
public:
    CustomerStreamParam(int width, int height, int bitrate, int framerate);
    string getCmdLineParam();
    int getVideoWidth();
    int getVideoHeight();
    
    virtual ~CustomerStreamParam() { };
    
private:
    int width, height, bitrate, framerate;
};

#endif /* CustomerStreamParam_hpp */
