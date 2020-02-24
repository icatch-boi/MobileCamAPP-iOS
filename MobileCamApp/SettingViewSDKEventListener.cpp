//
//  SettingViewSDKEventListener.cpp
//  WifiCamMobileApp
//
//  Created by Guo on 4/9/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#include "SettingViewSDKEventListener.h"

void SettingViewSDKEventListener::eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {}

SettingViewSDKEventListener::SettingViewSDKEventListener(SettingViewController *controller) {
  this->controller = controller;
}

void SettingViewSDKEventListener::udpateFWCompleted(shared_ptr<ICatchCamEvent> icatchEvt) {
  [controller updateFWCompleted];
}

void SettingViewSDKEventListener::udpateFWPowerOff(shared_ptr<ICatchCamEvent> icatchEvt) {
  [controller updateFWPowerOff];
}
