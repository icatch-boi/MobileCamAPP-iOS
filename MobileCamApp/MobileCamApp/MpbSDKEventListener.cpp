//
//  MpbSDKEventListener.cpp
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-13.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#include "MpbSDKEventListener.h"

void MpbSDKEventListener::eventNotify(shared_ptr<ICatchGLEvent> icatchEvt) {}

MpbSDKEventListener::MpbSDKEventListener(VideoPlaybackViewController *controller) {
  this->controller = controller;
}

void MpbSDKEventListener::updateVideoPbProgress(shared_ptr<ICatchGLEvent> icatchEvt) {
  //if (icatchEvt) {
//    AppLog(@"updateVideoPbProgress: %f", icatchEvt->getDoubleValue1());
    [controller updateVideoPbProgress:icatchEvt->getDoubleValue1() ];
  //}
}

void MpbSDKEventListener::updateVideoPbProgressState(shared_ptr<ICatchGLEvent> icatchEvt) {
  //if (icatchEvt) {
    if (icatchEvt->getLongValue1() == 1) {
      AppLog(@"I received an event: Pause");
      //sdk.videoPbNeedPause = YES;
      [controller updateVideoPbProgressState:YES];
    } else if (icatchEvt->getLongValue1() == 2) {
      AppLog(@"I received an event: Resume");
      //sdk.videoPbNeedPause = NO;
      [controller updateVideoPbProgressState:NO];
    }
  //}
}

void MpbSDKEventListener::stopVideoPb(shared_ptr<ICatchGLEvent> icatchEvt) {
  AppLog(@"I received an event: *Playback done");
  //[[SDK instance] setVideoPbDone:YES];
  [controller stopVideoPb];
}

void MpbSDKEventListener::showServerStreamError(shared_ptr<ICatchGLEvent> icatchEvt) {
  AppLog(@"I received an event: *Server Stream Error: %f,%f,%f", icatchEvt->getDoubleValue1(), icatchEvt->getDoubleValue2(), icatchEvt->getDoubleValue3());
  [controller showServerStreamError];
}


void MpbSDKEventListener::notifyInsufficientPerformanceInfo(shared_ptr<ICatchGLEvent> icatchEvt) {
    AppLog(@"I received an event: *Insufficient Performance at playback: %lld, %lld,%lld, %f, %f",
         icatchEvt->getLongValue1(), icatchEvt->getLongValue2(), icatchEvt->getLongValue3(),
         icatchEvt->getDoubleValue1(), icatchEvt->getDoubleValue2());
  [controller notifyInsufficientPerformanceInfo:icatchEvt->getLongValue1()
                                          width:icatchEvt->getLongValue2()
                                         height:icatchEvt->getLongValue3()
                                  frameInterval:icatchEvt->getDoubleValue1()
                                     decodeTime:icatchEvt->getDoubleValue2()];
}
