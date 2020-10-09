//
//  WiFiCamStreamPublish.hpp
//  WifiCamMobileApp
//
//  Created by ZJ on 2017/7/21.
//  Copyright © 2017年 iCatchTech. All rights reserved.
//

#ifndef WiFiCamStreamPublish_hpp
#define WiFiCamStreamPublish_hpp

#include <stdio.h>

class WiFiCamStreamPublish :public ICatchIStreamPublish {
    
public:
    int startPublishStreaming(string rtmpUrl);
};

#endif /* WiFiCamStreamPublish_hpp */
