//
//  WifiCamSDKEventListener.cpp
//  WifiCamMobileApp
//
//  Created by Guo on 6/26/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#include "WifiCamSDKEventListener.h"


WifiCamSDKEventListener::WifiCamSDKEventListener(id object, SEL callback) {
    this->object = object;
    this->callback = callback;
}

void WifiCamSDKEventListener::eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {
    [object performSelectorInBackground:callback withObject:nil];
}
