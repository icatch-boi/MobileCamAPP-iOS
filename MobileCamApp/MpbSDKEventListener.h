//
//  MpbSDKEventListener.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-13.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#ifndef WifiCamMobileApp_MpbSDKEventListener_h
#define WifiCamMobileApp_MpbSDKEventListener_h

#import "VideoPlaybackViewController.h"

class MpbSDKEventListener : public ICatchIPancamListener
{
private:
    VideoPlaybackViewController *controller;
protected:
    void eventNotify(shared_ptr<ICatchGLEvent> icatchEvt);
    MpbSDKEventListener(VideoPlaybackViewController *controller);
    void updateVideoPbProgress(shared_ptr<ICatchGLEvent> icatchEvt);
    void updateVideoPbProgressState(shared_ptr<ICatchGLEvent> icatchEvt);
    void stopVideoPb(shared_ptr<ICatchGLEvent> icatchEvt);
    void showServerStreamError(shared_ptr<ICatchGLEvent> icatchEvt);
    void notifyInsufficientPerformanceInfo(shared_ptr<ICatchGLEvent> icatchEvt);
};


class VideoPbProgressListener : public MpbSDKEventListener
{
private:
    void eventNotify(shared_ptr<ICatchGLEvent> icatchEvt) {
        updateVideoPbProgress(icatchEvt);
    }
public:
    VideoPbProgressListener(VideoPlaybackViewController *controller):MpbSDKEventListener(controller){}
};

class VideoPbProgressStateListener : public MpbSDKEventListener
{
private:
    void eventNotify(shared_ptr<ICatchGLEvent> icatchEvt) {
        updateVideoPbProgressState(icatchEvt);
    }
public:
    VideoPbProgressStateListener(VideoPlaybackViewController *controller):MpbSDKEventListener(controller){}
};

class VideoPbDoneListener : public MpbSDKEventListener
{
private:
    void eventNotify(shared_ptr<ICatchGLEvent> icatchEvt) {
        stopVideoPb(icatchEvt);
    }
public:
    VideoPbDoneListener(VideoPlaybackViewController *controller):MpbSDKEventListener(controller){}
};

class VideoPbServerStreamErrorListener : public MpbSDKEventListener {
private:
    void eventNotify(shared_ptr<ICatchGLEvent> icatchEvt) {
        showServerStreamError(icatchEvt);
    }
public:
    VideoPbServerStreamErrorListener(VideoPlaybackViewController *controller):MpbSDKEventListener(controller){}
};

class VideoPbInsufficientPerformanceListener : public MpbSDKEventListener {
private:
    void eventNotify(shared_ptr<ICatchGLEvent> icatchEvt) {
        notifyInsufficientPerformanceInfo(icatchEvt);
    }
public:
    VideoPbInsufficientPerformanceListener(VideoPlaybackViewController *controller):MpbSDKEventListener(controller){}
};

#endif
