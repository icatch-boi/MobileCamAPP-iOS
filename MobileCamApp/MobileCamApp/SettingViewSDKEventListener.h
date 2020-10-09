//
//  SettingViewSDKEventListener.h
//  WifiCamMobileApp
//
//  Created by Guo on 4/9/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#ifndef __WifiCamMobileApp__SettingViewSDKEventListener__
#define __WifiCamMobileApp__SettingViewSDKEventListener__

#import "SettingViewController.h"


class SettingViewSDKEventListener : public ICatchICameraListener {
private:
  SettingViewController *controller;
protected:
  void eventNotify(shared_ptr<ICatchCamEvent> icatchEvt);
  SettingViewSDKEventListener(SettingViewController *controller);
  void udpateFWCompleted(shared_ptr<ICatchCamEvent> icatchEvt);
  void udpateFWPowerOff(shared_ptr<ICatchCamEvent> icatchEvt);
};

class UpdateFWCompleteListener : public SettingViewSDKEventListener {
private:
  void eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {
    AppLog(@"Update FW Completed Event Received.");
    udpateFWCompleted(icatchEvt);
  }
public:
  UpdateFWCompleteListener(SettingViewController *controller) : SettingViewSDKEventListener(controller) {}
};

class UpdateFWCompletePowerOffListener : public SettingViewSDKEventListener {
private:
  void eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {
    AppLog(@"Update FW Power Off Event Received.");
    udpateFWPowerOff(icatchEvt);
  }
public:
  UpdateFWCompletePowerOffListener(SettingViewController *controller) : SettingViewSDKEventListener(controller) {}
};

#endif /* defined(__WifiCamMobileApp__SettingViewSDKEventListener__) */
