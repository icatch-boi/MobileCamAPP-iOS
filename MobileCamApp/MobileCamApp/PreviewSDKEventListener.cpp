//
//  PreviewSDKEventListener.cpp
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-13.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#include "PreviewSDKEventListener.h"


void PreviewSDKEventListener::eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {}

PreviewSDKEventListener::PreviewSDKEventListener(ViewController *controller) {
  this->controller = controller;
}

PreviewSDKEventListener::PreviewSDKEventListener(HomeVC *homeVC) {
    this->homeVC = homeVC;
}

void PreviewSDKEventListener::showReconnectAlert(shared_ptr<ICatchCamEvent> icatchEvt) {
  //[startController showReconnectAlert];
    [homeVC showReconnectAlert];
}
void PreviewSDKEventListener::updateMovieRecState(shared_ptr<ICatchCamEvent> icatchEvt, MovieRecState state) {
  [controller updateMovieRecState:state];
}
void PreviewSDKEventListener::updateBatteryLevel(shared_ptr<ICatchCamEvent> icatchEvt) {
  [controller updateBatteryLevel];
}
void PreviewSDKEventListener::stopStillCapture(shared_ptr<ICatchCamEvent> icatchEvt) {
  [controller stopStillCapture];
}

void PreviewSDKEventListener::stopTimelapse(shared_ptr<ICatchCamEvent> icatchEvt) {
  [controller stopTimelapse];
}

void PreviewSDKEventListener::timelapseStartedNotice(shared_ptr<ICatchCamEvent> icatchEvt) {
  [controller timelapseStartedNotice];
}

void PreviewSDKEventListener::timelapseCompletedNotice(shared_ptr<ICatchCamEvent> icatchEvt) {
  [controller timelapseCompletedNotice];
}

void PreviewSDKEventListener::postMovieRecordTime(shared_ptr<ICatchCamEvent> icatchEvt) {
  [controller postMovieRecordTime];
}

void PreviewSDKEventListener::postMovieRecordFileAddedEvent(shared_ptr<ICatchCamEvent> icatchEvt) {
  [controller postMovieRecordFileAddedEvent];
}

void PreviewSDKEventListener::postFileDownloadEvent(shared_ptr<ICatchCamEvent> icatchEvt) {
#if 0
  [controller postFileDownloadEvent:icatchEvt.getFileValue()];
#endif
}

void PreviewSDKEventListener::sdFull(shared_ptr<ICatchCamEvent> icatchEvt) {
    [controller sdFull];
}
