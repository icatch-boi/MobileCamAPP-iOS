//
//  StreamSDKEventListener.cpp
//  WifiCamMobileApp
//
//  Created by ZJ on 2017/6/23.
//  Copyright © 2017年 iCatchTech. All rights reserved.
//

#include "StreamSDKEventListener.hpp"
#include "WifiCamEvent.h"

StreamSDKEventListener::StreamSDKEventListener(id object, SEL callback) {
    this->object = object;
    this->callback = callback;
}

void StreamSDKEventListener::eventNotify(shared_ptr<ICatchGLEvent> icatchEvt) {
    if ([NSStringFromSelector(callback) containsString:@":"]) {
        WifiCamEvent *obj = [WifiCamEvent wifiCamEvent:icatchEvt];
        [object performSelectorInBackground:callback withObject:obj];
    } else {
        [object performSelectorInBackground:callback withObject:nil];
    }
}
