//
//  ViewController_ViewControllerPrivate.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-2-28.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "HYOpenALHelper.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AppDelegate.h"
#import "SettingViewController.h"
#import "MBProgressHUD.h"
#import "CustomIOS7AlertView.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreMedia/CoreMedia.h>
#import <ImageIO/ImageIO.h>
#import "WifiCamManager.h"
#import "WifiCamControl.h"
#include "UtilsMacro.h"
#include "PreviewSDKEventListener.h"
#import "Camera.h"
#include "WifiCamSDKEventListener.h"
#import "GCDiscreetNotificationView.h"

#import "StreamSDKEventListener.hpp"
#import "StreamObserver.h"

#import "PanCamSDK.h"

enum SettingState{
  SETTING_DELAY_CAPTURE = 0,
  SETTING_STILL_CAPTURE,
  SETTING_VIDEO_CAPTURE,
  SETTING_SPHERE_TYPE,
};

@interface ViewController ()
<
UIAlertViewDelegate,
UITableViewDelegate,
UITableViewDataSource,
AppDelegateProtocol,
SettingDelegate
>
@property(weak, nonatomic) IBOutlet UIImageView *preview;
@property(nonatomic) IBOutlet UIView *h264View;
@property(weak, nonatomic) IBOutlet UIButton    *cameraToggle;
@property(weak, nonatomic) IBOutlet UIButton    *videoToggle;
@property(weak, nonatomic) IBOutlet UIButton    *timelapseToggle;
@property(weak, nonatomic) IBOutlet UIButton *zoomOutButton;
@property(weak, nonatomic) IBOutlet UIButton *zoomInButton;
@property(weak, nonatomic) IBOutlet UILabel *zoomValueLabel;
@property(weak, nonatomic) IBOutlet UISlider *zoomSlider;
@property(weak, nonatomic) IBOutlet UIButton    *mpbToggle;
@property(weak, nonatomic) IBOutlet UIImageView *batteryState;
@property(weak, nonatomic) IBOutlet UIImageView *awbLabel;
@property(weak, nonatomic) IBOutlet UIImageView *timelapseStateImageView;
@property(weak, nonatomic) IBOutlet UIImageView *slowMotionStateImageView;
@property(weak, nonatomic) IBOutlet UIImageView *invertModeStateImageView;
@property(weak, nonatomic) IBOutlet UIImageView *burstCaptureStateImageView;
@property(weak, nonatomic) IBOutlet UIButton    *selftimerButton;
@property(weak, nonatomic) IBOutlet UILabel     *selftimerLabel;
@property(weak, nonatomic) IBOutlet UIButton    *sizeButton;
@property(weak, nonatomic) IBOutlet UILabel     *sizeLabel;
@property(weak, nonatomic) IBOutlet UIBarButtonItem    *settingButton;
@property(weak, nonatomic) IBOutlet UIButton    *snapButton;
@property(weak, nonatomic) IBOutlet UILabel *movieRecordTimerLabel;
@property(weak, nonatomic) IBOutlet UILabel *noPreviewLabel;
@property(weak, nonatomic) IBOutlet UIImageView *autoDownloadThumbImage;
@property(weak, nonatomic) IBOutlet UIButton *enableAudioButton;
@property(nonatomic) MPMoviePlayerController *h264player;
@property(nonatomic, getter = isPVRun) BOOL PVRun;
@property(nonatomic, getter = isAudioRun) BOOL AudioRun;
//@property(nonatomic, getter = isPVRunning) BOOL PVRunning;
@property(nonatomic, getter = isVideoCaptureStopOn) BOOL videoCaptureStopOn;
@property(nonatomic, getter = isBatteryLowAlertShowed) BOOL batteryLowAlertShowed;
@property(nonatomic) enum SettingState curSettingState;
@property(nonatomic) NSMutableArray *alertTableArray;
@property(nonatomic) WifiCamAlertTable* tbDelayCaptureTimeArray;
@property(nonatomic) WifiCamAlertTable* tbPhotoSizeArray;
@property(nonatomic) WifiCamAlertTable* tbVideoSizeArray;
@property(nonatomic) dispatch_semaphore_t previewSemaphore;
@property(strong, nonatomic) CustomIOS7AlertView* customIOS7AlertView;
@property(nonatomic) UIAlertView *normalAlert;
@property(nonatomic) NSTimer *videoCaptureTimer;
@property(nonatomic) int elapsedVideoRecordSecs;
@property(nonatomic) NSTimer *burstCaptureTimer;
@property(nonatomic) NSUInteger burstCaptureCount;
@property(nonatomic) NSTimer *hideZoomControllerTimer;
@property(nonatomic) UIImage *stopOn;
@property(nonatomic) UIImage *stopOff;
@property(nonatomic) uint movieRecordElapsedTimeInSeconds;
@property(nonatomic) SystemSoundID stillCaptureSound;
@property(nonatomic) SystemSoundID delayCaptureSound;
@property(nonatomic) SystemSoundID changeModeSound;
@property(nonatomic) SystemSoundID videoCaptureSound;
@property(nonatomic) SystemSoundID burstCaptureSound;
@property(nonatomic) MBProgressHUD *progressHUD;
@property(nonatomic) AVAudioPlayer *player;
@property(nonatomic) AudioFileStreamID outAudioFileStream;
@property(nonatomic) HYOpenALHelper *al;
@property(nonatomic) WifiCam *wifiCam;
@property(nonatomic) WifiCamCamera *camera;
@property(nonatomic) WifiCamControlCenter *ctrl;
@property(nonatomic) WifiCamStaticData *staticData;
@property(nonatomic) dispatch_group_t previewGroup;
@property(nonatomic) dispatch_queue_t audioQueue;
@property(nonatomic) dispatch_queue_t videoQueue;
@property(nonatomic) ICatchCamPreviewMode previewMode;
//@property(nonatomic) NSMutableArray* pvCache;
@property(nonatomic) StreamObserver *streamObserver;
@property(nonatomic) BOOL readyGoToSetting;
@property(nonatomic) AVSampleBufferDisplayLayer *avslayer;
@property(nonatomic) double curVideoPTS;
@property(nonatomic) BOOL videoPlayFlag;
@property(nonatomic, retain) GCDiscreetNotificationView *notificationView;

@property (strong, nonatomic) EAGLContext *context;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSOperationQueue *queue;

@property(nonatomic) dispatch_queue_t liveQueue;
@property (weak, nonatomic) IBOutlet UISwitch *liveSwitch_YouTube;
@property (weak, nonatomic) IBOutlet UILabel *liveTitle_YouTube;
@property (weak, nonatomic) IBOutlet UILabel *liveResolution;

@property (weak, nonatomic) IBOutlet UIImageView *facebookLiveImg;
@property (weak, nonatomic) IBOutlet UILabel *liveTitle_Facebook;
@property (weak, nonatomic) IBOutlet UISwitch *liveSwitch_Facebook;
@property (nonatomic) dispatch_queue_t facebookLiveQueue;

@property (nonatomic) BOOL Living;
@property (nonatomic) BOOL Recording;

@property (nonatomic, strong) NSString *refreshToken;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic) StreamObserver *frameIntervalInfoObserver;

@property (nonatomic) NSMutableData *currentVideoData;

- (IBAction)liveSwitchClink:(id)sender;
- (IBAction)facebookLiveSwithClick:(id)sender;

@property (nonatomic) WifiCamAlertTable *tbPanoramaTypeArray;
@property (weak, nonatomic) IBOutlet UIButton *panoramaTypeButton;
- (IBAction)changePanoramaType:(id)sender;

@end
