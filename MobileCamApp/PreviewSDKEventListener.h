//
//  PreviewSDKEventListener.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-13.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#ifndef WifiCamMobileApp_PreviewSDKEventListener_h
#define WifiCamMobileApp_PreviewSDKEventListener_h

#import "ViewController.h"
#import "HomeVC.h"

class PreviewSDKEventListener: public ICatchICameraListener
{
private:
    ViewController *controller;
    HomeVC *homeVC;
protected:
    void eventNotify(shared_ptr<ICatchCamEvent> icatchEvt);
    PreviewSDKEventListener(ViewController *controller);
    PreviewSDKEventListener(HomeVC *homeVC);
    
    void showReconnectAlert(shared_ptr<ICatchCamEvent> icatchEvt);
    void updateMovieRecState(shared_ptr<ICatchCamEvent> icatchEvt, MovieRecState state);
    void updateBatteryLevel(shared_ptr<ICatchCamEvent> icatchEvt);
    void stopStillCapture(shared_ptr<ICatchCamEvent> icatchEvt);
    void stopTimelapse(shared_ptr<ICatchCamEvent> icatchEvt);
    void timelapseStartedNotice(shared_ptr<ICatchCamEvent> icatchEvt);
    void timelapseCompletedNotice(shared_ptr<ICatchCamEvent> icatchEvt);
    void sdCardFull(shared_ptr<ICatchCamEvent> icatchEvt);
    void postMovieRecordTime(shared_ptr<ICatchCamEvent> icatchEvt);
    void postMovieRecordFileAddedEvent(shared_ptr<ICatchCamEvent> icatchEvt);
    void postFileDownloadEvent(shared_ptr<ICatchCamEvent> icatchEvt);
    void sdFull(shared_ptr<ICatchCamEvent> icatchEvt);
};

// ICATCH_EVENT_CONNECTION_DISCONNECTED
class ConnectionListener : public PreviewSDKEventListener
{
private:
    void eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {
        AppLog(@"Disconnected event");
        showReconnectAlert(icatchEvt);
    }
public:
    ConnectionListener(HomeVC *homeVC) : PreviewSDKEventListener(homeVC) {}
};

// VideoRecOffListener
class VideoRecOffListener : public PreviewSDKEventListener
{
private:
    void eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {
        AppLog(@"video rec off");
        updateMovieRecState(icatchEvt, MovieRecStoped);
    }
public:
    VideoRecOffListener(ViewController *controller): PreviewSDKEventListener(controller) {}
};

// VideoRecOnListener
class VideoRecOnListener : public PreviewSDKEventListener
{
private:
    void eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {
        AppLog(@"video rec on");
        updateMovieRecState(icatchEvt, MovieRecStarted);
    }
public:
    VideoRecOnListener(ViewController *controller): PreviewSDKEventListener(controller) {}
};

class VideoRecPostTimeListener : public PreviewSDKEventListener
{
private:
    void eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {
        AppLog(@"video rec post time");
        postMovieRecordTime(icatchEvt);
    }
public:
    VideoRecPostTimeListener(ViewController *controller): PreviewSDKEventListener(controller) {}
};

class VideoRecFileAddedListener : public PreviewSDKEventListener
{
private:
    void eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {
        AppLog(@"video rec file Added.");
        postMovieRecordFileAddedEvent(icatchEvt);
    }
public:
    VideoRecFileAddedListener(ViewController *controller): PreviewSDKEventListener(controller) {}
};

// BatteryLevelListener
class BatteryLevelListener : public PreviewSDKEventListener
{
private:
    void eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {
        AppLog(@"battery level changed");
        updateBatteryLevel(icatchEvt);
    }
public:
    BatteryLevelListener(ViewController *controller): PreviewSDKEventListener(controller) {}
};

// StillCaptureDoneListener
class StillCaptureDoneListener : public PreviewSDKEventListener
{
private:
    void eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {
        AppLog(@"capture done event received !");
        stopStillCapture(icatchEvt);
    }
public:
    StillCaptureDoneListener (ViewController *controller): PreviewSDKEventListener(controller) {}
};

class SDCardFullListener : public PreviewSDKEventListener
{
private:
    void eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {
        AppLog(@"sd full event received !");
        sdFull(icatchEvt);
        /*
        NSDate *begin = [NSDate date];
        [NSThread sleepForTimeInterval:0.030];
        NSDate *end = [NSDate date];
        NSTimeInterval elapse = [end timeIntervalSinceDate:begin];
        AppLog(@"elapse: %f", elapse);
         */
    }
public:
    SDCardFullListener (ViewController *controller): PreviewSDKEventListener(controller) {}
};

class TimelapseStopListener : public PreviewSDKEventListener
{
private:
    void eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {
        AppLog(@"timelapse stop event received !");
        stopTimelapse(icatchEvt);
    }
public:
    TimelapseStopListener (ViewController *controller): PreviewSDKEventListener(controller) {}
};

class TimelapseCaptureStartedListener : public PreviewSDKEventListener
{
private:
    void eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {
        AppLog(@"timelapse start event received !");
        timelapseStartedNotice(icatchEvt);
    }
public:
    TimelapseCaptureStartedListener (ViewController *controller): PreviewSDKEventListener(controller) {}
};

class TimelapseCaptureCompleteListener : public PreviewSDKEventListener
{
private:
    void eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {
        AppLog(@"timelapse complete event received !");
        timelapseCompletedNotice(icatchEvt);
    }
public:
    TimelapseCaptureCompleteListener (ViewController *controller): PreviewSDKEventListener(controller) {}
};

class FileDownloadListener : public PreviewSDKEventListener
{
private:
    void eventNotify(shared_ptr<ICatchCamEvent> icatchEvt) {
        AppLog(@"file download event received !");
        postFileDownloadEvent(icatchEvt);
    }
public:
    FileDownloadListener (ViewController *controller): PreviewSDKEventListener(controller) {}
};

#endif
