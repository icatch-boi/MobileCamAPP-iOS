//
//  ViewController.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-5.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import "ViewController.h"
#import "ViewControllerPrivate.h"
#ifndef HW_DECODE_H264
#import "VideoFrameExtractor.h"
#endif

#import <VideoToolbox/VideoToolbox.h>
//#include "SignInViewController.h"
#import <GoogleSignIn/GoogleSignIn.h>
#import "WifiCamEvent.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

static NSString * const kClientID = @"759186550079-nj654ak1umgakji7qmhl290hfcp955ep.apps.googleusercontent.com";

@implementation ViewController {
    /**
     * 20150630  guo.jiang
     * Deprecated ! (USE WifiCamObserver & WifiCamSDKEventListener.)
     */
    
    shared_ptr<VideoRecOffListener> videoRecOffListener;
    shared_ptr<VideoRecOnListener> videoRecOnListener;
    /*shared_ptr<BatteryLevelListener> batteryLevelListener;
    shared_ptr<StillCaptureDoneListener> stillCaptureDoneListener;
    shared_ptr<SDCardFullListener> sdCardFullListener;
    shared_ptr<TimelapseStopListener> timelapseStopListener;
    shared_ptr<TimelapseCaptureStartedListener> timelapseCaptureStartedListener;
    shared_ptr<TimelapseCaptureCompleteListener> timelapseCaptureCompleteListener;
    shared_ptr<VideoRecPostTimeListener> videoRecPostTimeListener;*/
    shared_ptr<FileDownloadListener> fileDownloadListener; //ICATCH_EVENT_FILE_DOWNLOAD
    
    shared_ptr<WifiCamSDKEventListener> batteryLevelListener, stillCaptureDoneListener, sdCardFullListener, timelapseStopListener,
                            timelapseCaptureStartedListener, timelapseCaptureCompleteListener, videoRecPostTimeListener;
    
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
    VTDecompressionSessionRef _deocderSession;
    
    BOOL _isSDcardRemoved;
}

#pragma mark - Lifecycle
- (void)viewDidLoad
{
    TRACE();
    [super viewDidLoad];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    //_Living = NO;
    
    //GLKView
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    [EAGLContext setCurrentContext:self.context];
    
    //[[PanCamSDK instance] initStream];

    GLKView* view = (GLKView*)self.glkView;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    NSLog(@"GLKView, view: %@", self.glkView);
    [self.view sendSubviewToBack:self.glkView];
    
    WifiCamManager *app = [WifiCamManager instance];
    self.wifiCam = [app.wifiCams objectAtIndex:0];
    self.camera = _wifiCam.camera;
    self.ctrl = _wifiCam.controler;
    self.staticData = [WifiCamStaticData instance];
    
    [self p_constructPreviewData];
    [self p_initPreviewGUI];
    
    self.enableAudioButton.hidden = YES;
    self.sizeButton.userInteractionEnabled = YES;
    self.selftimerButton.userInteractionEnabled = YES;
    if (self.enableAudioButton.isHidden) {
        [self.enableAudioButton removeFromSuperview];
    }
    // Test
    //    self.pvCache = [NSMutableArray arrayWithCapacity:30];
    
    UITapGestureRecognizer *tap0 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showZoomController:)];
    [_preview addGestureRecognizer:tap0];
    
#ifdef HW_DECODE_H264
    // H.264
    self.avslayer = [[AVSampleBufferDisplayLayer alloc] init];
    self.avslayer.bounds = _preview.bounds;
    self.avslayer.position = CGPointMake(CGRectGetMidX(_preview.bounds), CGRectGetMidY(_preview.bounds));
    self.avslayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.avslayer.backgroundColor = [[UIColor blackColor] CGColor];
    
    CMTimebaseRef controlTimebase;
    CMTimebaseCreateWithMasterClock(CFAllocatorGetDefault(), CMClockGetHostTimeClock(), &controlTimebase);
    self.avslayer.controlTimebase = controlTimebase;
    //    CMTimebaseSetTime(self.avslayer.controlTimebase, CMTimeMake(5, 1));
    CMTimebaseSetRate(self.avslayer.controlTimebase, 1.0);
    
    //    [self.view.layer insertSublayer:_avslayer below:_preview.layer];
    
    self.h264View = [[UIView alloc] initWithFrame:self.view.bounds];
    [_h264View.layer addSublayer:_avslayer];
    [self.view insertSubview:_h264View belowSubview:_preview];
    
    UITapGestureRecognizer *tap1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showZoomController:)];
    [_h264View addGestureRecognizer:tap1];
#endif
    
    _motionManager = [[CMMotionManager alloc] init];
    _queue = [[NSOperationQueue alloc]init];
    cDistance = maxDistance;
    
    if ([[PanCamSDK instance] isPanoramaWithFile:nil]) {
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        [self.view addGestureRecognizer:pinchGesture];
    }
    
    _panoramaTypeButton.hidden = ![[PanCamSDK instance] isPanoramaWithFile:nil];
}

- (void)showLiveGUIIfNeeded:(WifiCamPreviewMode)curMode
{
    dispatch_async(dispatch_get_main_queue(), ^{
//        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:Live"] && (curMode == WifiCamPreviewModeVideoOff || curMode == WifiCamPreviewModeVideoOn) && ![[PanCamSDK instance] isStreamSupportPublish]) {
//            _liveSwitch_YouTube.hidden = NO;
//            _liveTitle_YouTube.hidden = NO;
//            _liveResolution.hidden = NO;
//        } else {
//            _liveSwitch_YouTube.hidden = YES;
//            _liveTitle_YouTube.hidden = YES;
//            _liveResolution.hidden = YES;
//        }
#if 0
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        BOOL isLive = [defaults boolForKey:@"PreferenceSpecifier:YouTube_Live"]/* || [defaults boolForKey:@"PreferenceSpecifier:Facebook_Live"]*/;
        BOOL curModeStatus = (curMode == WifiCamPreviewModeVideoOff || curMode == WifiCamPreviewModeVideoOn);
        
        self.liveResolution.hidden = !(isLive && curModeStatus);
        
        BOOL isHideFacebookIcon = [defaults boolForKey:@"PreferenceSpecifier:Facebook_Live"] && curModeStatus;
        self.liveSwitch_Facebook.hidden = !isHideFacebookIcon;
        self.liveTitle_Facebook.hidden = !isHideFacebookIcon;

        BOOL isHideYouTubeIcon = [defaults boolForKey:@"PreferenceSpecifier:YouTube_Live"] && curModeStatus;
        self.liveSwitch_YouTube.hidden = !isHideYouTubeIcon;
        self.liveTitle_YouTube.hidden = !isHideYouTubeIcon;
#endif
    });
}

-(void)viewWillAppear:(BOOL)animated
{
    TRACE();
    NSInteger currentState = [UIApplication sharedApplication].applicationState;
    if (currentState != UIApplicationStateActive) {
        AppLog("Application is not active, current statue: %ld", (long)currentState);
        return;
    }
    [EAGLContext setCurrentContext:self.context];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:UseSDKDecode"]) {
        [[PanCamSDK instance] initStreamWithRenderType:RenderType_AutoSelect isPreview:YES file:nil];
    } else {
        [[PanCamSDK instance] initStreamWithRenderType:RenderType_Disable isPreview:YES file:nil];
    }

    [super viewWillAppear:animated];
    self.AudioRun = _wifiCam.camera.enableAudio;
    if (!_AudioRun) {
        self.enableAudioButton.tag = 1;
        [self.enableAudioButton setBackgroundImage:[UIImage imageNamed:@"audio_off"]
                                          forState:UIControlStateNormal];
    }
    self.enableAudioButton.enabled = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recoverFromDisconnection)
                                             name    :@"kCameraNetworkConnectedNotification"
                                             object  :nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reconnectNotification:)
                                             name    :@"kCameraReconnectNotification"
                                             object  :nil];
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.delegate = self;
    
    if (_tbPanoramaTypeArray.lastIndex) {
        if (![self changePanoramaTypeWithIndex:_tbPanoramaTypeArray.lastIndex]) {
            _tbPanoramaTypeArray.lastIndex = 0;
        }
    }
    [self updatePanoramaTyprOnScreen];
    
#if 0
    GIDGoogleUser *user = [GIDSignIn sharedInstance].currentUser;
    if (user == nil) {
        [self liveFailedUpdateGUI];
        return;
    }
    
    NSString *accessToken = [[user valueForKeyPath:@"authentication.accessToken"] description];
    NSString *refreshToken = [[user valueForKeyPath:@"authentication.refreshToken"] description];
    AppLog(@"authorization: %@\nrefreshToken: %@", accessToken, refreshToken);
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults stringForKey:@"refreshToken"] && refreshToken) {
        [defaults setObject:refreshToken forKey:@"refreshToken"];
    }
    
    _accessToken = accessToken;
    _refreshToken = refreshToken ? refreshToken : [defaults stringForKey:@"refreshToken"];
    
    if (_Living) {
        if (_accessToken) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self createLiveChannel];
            });
        } else {
            [self liveErrorHandle:100 andMessage:@"未通过授权"];
        }
    }
#endif
}

-(void)reconnectNotification:(NSNotification*)notification
{
    _notificationView = (GCDiscreetNotificationView*)notification.object;
}
    
-(void)viewWillLayoutSubviews {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")
        && !_customIOS7AlertView.hidden) {
        [_customIOS7AlertView updatePositionForDialogView];
    }
    [super viewWillLayoutSubviews];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSInteger currentState = [UIApplication sharedApplication].applicationState;
    if (currentState != UIApplicationStateActive) {
        AppLog("Application is not active, current statue: %ld", (long)currentState);
        return;
    }
//    [self showLiveGUIIfNeeded:_camera.previewMode];
    
/*
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil)
                                         message           :NSLocalizedString(@"Support iCatch 360Cam & SBC", nil)//NSLocalizedString(@"Only for iCatch 360Cam.", nil)
                                         delegate          :self
                                         cancelButtonTitle :NSLocalizedString(@"OK", nil)
                                         otherButtonTitles :nil, nil];
    [alert show];
*/
    
    if ([self capableOf:WifiCamAbilityBatteryLevel]) {
        [self updateBatteryLevelIcon];
    }
    AppLog(@"curDateStamp: %d", _camera.curDateStamp);
//    if ([self capableOf:WifiCamAbilityDateStamp] && _camera.curDateStamp != DATE_STAMP_OFF) {
//        _preview.userInteractionEnabled = NO;
//#ifdef HW_DECODE_H264
//        _h264View.userInteractionEnabled = NO;
//#endif
//    } else {
//        _preview.userInteractionEnabled = YES;
//#ifdef HW_DECODE_H264
//        _h264View.userInteractionEnabled = YES;
//#endif
//    }
    
    // Update the AWB icon after setting new awb value
    if ([self capableOf:WifiCamAbilityWhiteBalance]) {
        [self updateWhiteBalanceIcon:_camera.curWhiteBalance];
    }
    
    // Update the Timelapse icon
    if ([self capableOf:WifiCamAbilityTimeLapse]
        && _camera.previewMode == WifiCamPreviewModeTimelapseOff
        && _camera.curTimelapseInterval != 0) {
        self.timelapseStateImageView.hidden = NO;
        if (_camera.timelapseType == WifiCamTimelapseTypeVideo) {
            self.timelapseStateImageView.image = [UIImage imageNamed:@"timelapse_video"];
        } else {
            self.timelapseStateImageView.image = [UIImage imageNamed:@"timelapse_capture"];
        }
    } else {
        self.timelapseStateImageView.hidden = YES;
    }
    
    // Update the Slow-Motion icon
    if ([self capableOf:WifiCamAbilitySlowMotion]
        && _camera.previewMode == WifiCamPreviewModeVideoOff
        && _camera.curSlowMotion == 1) {
        self.slowMotionStateImageView.hidden = NO;
    } else {
        self.slowMotionStateImageView.hidden = YES;
    }
    
    // Update the Invert-Mode icon
    if ([self capableOf:WifiCamAbilityUpsideDown]
        && _camera.curInvertMode == 1) {
        self.invertModeStateImageView.hidden = NO;
    } else {
        self.invertModeStateImageView.hidden = YES;
    }
    
    // Update delay capture icon after enable burst capture
    if ([self capableOf:WifiCamAbilityDelayCapture]
        && _camera.previewMode == WifiCamPreviewModeCameraOff) {
        [self updateCaptureDelayItem:_camera.curCaptureDelay];
    }
    
    // Burst-capture icon
    if ([self capableOf:WifiCamAbilityBurstNumber]
        && _camera.previewMode == WifiCamPreviewModeCameraOff) {
        [self updateBurstCaptureIcon:_camera.curBurstNumber];
    }
    
    // Movie Rec timer
    if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]
        && (_camera.previewMode == WifiCamPreviewModeVideoOn
            || (_camera.previewMode == WifiCamPreviewModeTimelapseOn
                /*&& _camera.timelapseType == WifiCamTimelapseTypeVideo*/))) {
                self.movieRecordTimerLabel.hidden = NO;
            } else {
                self.movieRecordTimerLabel.hidden = YES;
            }
    
    // Update the size icon after delete or capture
    if ([self capableOf:WifiCamAbilityImageSize]
        && _camera.previewMode == WifiCamPreviewModeCameraOff) {
        [self updateImageSizeOnScreen:_camera.curImageSize];
    } else if ([self capableOf:WifiCamAbilityVideoSize]
               && _camera.previewMode == WifiCamPreviewModeVideoOff) {
        [self updateVideoSizeOnScreen:_camera.curVideoSize];
    } else if (_camera.previewMode == WifiCamPreviewModeTimelapseOff) {
        if (_camera.timelapseType == WifiCamTimelapseTypeStill) {
            [self updateImageSizeOnScreen:_camera.curImageSize];
        } else {
            [self updateVideoSizeOnScreen:_camera.curVideoSize];
        }
    }
    
    // Movie rec
    if ([self capableOf:WifiCamAbilityMovieRecord]) {
        videoRecOnListener = make_shared<VideoRecOnListener>(self);
        [_ctrl.comCtrl addObserver:ICH_CAM_EVENT_VIDEO_ON
                          listener:videoRecOnListener
                       isCustomize:NO];
    }
    
    if (_camera.enableAutoDownload) {
        fileDownloadListener = make_shared<FileDownloadListener>(self);
        [_ctrl.comCtrl addObserver:ICH_CAM_EVENT_FILE_DOWNLOAD
                          listener:fileDownloadListener
                       isCustomize:NO];
    }
    
    // Zoom In/Out
    uint maxZoomRatio = [_ctrl.propCtrl retrieveMaxZoomRatio];
    uint curZoomRatio = [_ctrl.propCtrl retrieveCurrentZoomRatio];
    AppLog(@"maxZoomRatio: %d", maxZoomRatio);
    AppLog(@"curZoomRatio: %d", curZoomRatio);
    self.zoomSlider.minimumValue = 1.0;
    self.zoomSlider.maximumValue = maxZoomRatio/10.0;
    self.zoomSlider.value = curZoomRatio/10.0;
    _zoomValueLabel.text = [NSString stringWithFormat:@"x%0.1f",curZoomRatio/10.0];
    
    
    if (_PVRun) {
        return;
    }
    self.PVRun = YES;
    _noPreviewLabel.hidden = YES;
    
    switch (_camera.previewMode) {
        case WifiCamPreviewModeCameraOff:
        case WifiCamPreviewModeCameraOn:
            [self runPreview:ICH_CAM_STILL_PREVIEW_MODE];
            break;
            
        case WifiCamPreviewModeTimelapseOff:
        case WifiCamPreviewModeTimelapseOn:
            if (_camera.timelapseType == WifiCamTimelapseTypeVideo) {
                // mark by allen.chuang 2015.1.15 ICOM-2692
                //if( [_ctrl.propCtrl changeTimelapseType:ICATCH_TIMELAPSE_VIDEO_PREVIEW_MODE] == WCRetSuccess)
                //    AppLog(@"change to ICATCH_TIMELAPSE_VIDEO_PREVIEW_MODE success");
                [self runPreview:ICH_CAM_TIMELAPSE_VIDEO_PREVIEW_MODE];
            } else {
                // mark by allen.chuang 2015.1.15 ICOM-2692
                //if( [_ctrl.propCtrl changeTimelapseType:ICATCH_TIMELAPSE_STILL_PREVIEW_MODE] == WCRetSuccess)
                //    AppLog(@"change to ICATCH_TIMELAPSE_STILL_PREVIEW_MODE success");
                [self runPreview:ICH_CAM_TIMELAPSE_STILL_PREVIEW_MODE];
            }
            
            break;
            
        case WifiCamPreviewModeVideoOff:
        case WifiCamPreviewModeVideoOn:
            [self runPreview:ICH_CAM_VIDEO_PREVIEW_MODE];
            
            break;
            
        default:
            break;
    }
    
}

- (void)viewWillDisappear:(BOOL)animated {
    TRACE();
//    if (self.currentVideoData.length == 0) {
//        self.savedCamera.thumbnail = (id)_preview.image;
//    }
    
    [super viewWillDisappear:animated];
    [self hideZoomController:YES];
    
    //    AppLog(@"self.PVRun = NO");
    // Stop preview
    //    self.PVRun = NO;
    
    [self removeObservers];
    
    if (!_customIOS7AlertView.hidden) {
        _customIOS7AlertView.hidden = YES;
    }
    if (!_normalAlert.hidden) {
        [_normalAlert dismissWithClickedButtonIndex:0 animated:NO];
    }
    
    // Save data to sqlite
    NSError *error = nil;
    if (![self.savedCamera.managedObjectContext save:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        AppLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
        abort();
#endif
    } else {
        AppLog(@"Saved to sqlite.");
    }
    
    [self hideProgressHUD:YES];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kCameraNetworkConnectedNotification" object:nil];
}

- (void)destroyGLData {
    [self stopGLKAnimation];
    [self.motionManager stopGyroUpdates];
    [EAGLContext setCurrentContext:self.context];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)dealloc {
    AppLog(@"%s", __func__);
    [self p_deconstructPreviewData];
    [self destroyGLData];
    
    [[SDK instance] destroySDK];
    [[PanCamSDK instance] destroypanCamSDK];
}

- (BOOL)capableOf:(WifiCamAbility)ability {
//    return (_camera.ability & ability) == ability ? YES : NO;
    return [_camera.ability containsObject:@(ability)];
}


-(void)recoverFromDisconnection {
    WifiCamManager *app = [WifiCamManager instance];
    self.wifiCam = [app.wifiCams objectAtIndex:0];
    self.camera = _wifiCam.camera;
    self.ctrl = _wifiCam.controler;
    self.staticData = [WifiCamStaticData instance];
    
    [self p_constructPreviewData];
    [self p_initPreviewGUI];
    
    [self viewDidAppear:YES];
}


#pragma mark - Initialization
- (void)p_constructPreviewData {
    BOOL onlyStillFunction = YES;
    
    self.previewGroup = dispatch_group_create();
    self.audioQueue = dispatch_queue_create("WifiCam.GCD.Queue.Preview.Audio", 0);
    self.videoQueue = dispatch_queue_create("WifiCam.GCD.Queue.Preview.Video", 0);
    
//    self.AudioRun = YES;
    
    if (!_previewSemaphore) {
        self.previewSemaphore = dispatch_semaphore_create(1);
    }
    NSString *stillCaptureSoundUri = [[NSBundle mainBundle] pathForResource:@"Capture_Shutter" ofType:@"WAV"];
    id url = [NSURL fileURLWithPath:stillCaptureSoundUri];
//    OSStatus errcode =
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_stillCaptureSound);
//    NSAssert1(errcode == 0, @"Failed to load sound ", @"Capture_Shutter.WAV");
    
    NSString *delayCaptureBeepUri = [[NSBundle mainBundle] pathForResource:@"DelayCapture_BEEP" ofType:@"WAV"];
    url = [NSURL fileURLWithPath:delayCaptureBeepUri];
//    errcode =
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_delayCaptureSound);
//    NSAssert1(errcode == 0, @"Failed to load sound ", @"DelayCapture_BEEP.WAV");
    
    NSString *changeModeSoundUri = [[NSBundle mainBundle] pathForResource:@"ChangeMode" ofType:@"WAV"];
    url = [NSURL fileURLWithPath:changeModeSoundUri];
//    errcode =
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_changeModeSound);
//    NSAssert1(errcode == 0, @"Failed to load sound ", @"ChangeMode.WAV");
    
    NSString *videoCaptureSoundUri = [[NSBundle mainBundle] pathForResource:@"StartStopVideoRec" ofType:@"WAV"];
    url = [NSURL fileURLWithPath:videoCaptureSoundUri];
//    errcode =
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_videoCaptureSound);
//    NSAssert1(errcode == 0, @"Failed to load sound ", @"StartStopVideoRec.WAV");
    
    NSString *burstCaptureSoundUri = [[NSBundle mainBundle] pathForResource:@"BurstCapture&TimelapseCapture" ofType:@"WAV"];
    url = [NSURL fileURLWithPath:burstCaptureSoundUri];
//    errcode =
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_burstCaptureSound);
//    NSAssert1(errcode == 0, @"Failed to load sound ", @"BurstCapture&TimelapseCapture.WAV");
    
    self.alertTableArray = [[NSMutableArray alloc] init];
    
    if ([self capableOf:WifiCamAbilityTimeLapse]) {
        [self p_initTimelapseRec];
        onlyStillFunction = NO;
    } else {
        [self.timelapseToggle removeFromSuperview];
        [self.timelapseStateImageView removeFromSuperview];
    }
    
    if ([self capableOf:WifiCamAbilityMovieRecord]) {
        if ([self capableOf:WifiCamAbilityVideoSize]) {
            if( _camera.cameraMode == ICH_CAM_MODE_TIMELAPSE_VIDEO
               || _camera.cameraMode == ICH_CAM_MODE_TIMELAPSE_VIDEO_OFF){
                self.tbVideoSizeArray = [_ctrl.propCtrl prepareDataForTimeLapseVideoSize:_camera.curVideoSize];
            }else
                self.tbVideoSizeArray = [_ctrl.propCtrl prepareDataForVideoSize:_camera.curVideoSize];
        }
        [self p_initMovieRec];
        onlyStillFunction = NO;
    }
    
    if ([self capableOf:WifiCamAbilityStillCapture]){
        if ([self capableOf:WifiCamAbilityImageSize]) {
            self.tbPhotoSizeArray = [_ctrl.propCtrl prepareDataForImageSize:_camera.curImageSize];
        }
        if ([self capableOf:WifiCamAbilityDelayCapture]) {
            self.tbDelayCaptureTimeArray = [_ctrl.propCtrl prepareDataForDelayCapture:_camera.curCaptureDelay];
        }
        if (onlyStillFunction) {
            _camera.previewMode = WifiCamPreviewModeCameraOff;
        }
    }
    
    [self preparePanoramaTypeData];
    
    AppLog(@"_camera.cameraMode: %d", _camera.cameraMode);
    switch (_camera.cameraMode) {
        case ICH_CAM_MODE_VIDEO_OFF:
            _camera.previewMode = WifiCamPreviewModeVideoOff;
            break;
            
        case ICH_CAM_MODE_CAMERA:
            _camera.previewMode = WifiCamPreviewModeCameraOff;
            break;
            
        case ICH_CAM_MODE_IDLE:
            break;
            
        case ICH_CAM_MODE_SHARED:
            break;
            
        case ICH_CAM_MODE_TIMELAPSE_STILL_OFF:
            _camera.previewMode = WifiCamPreviewModeTimelapseOff;
            _camera.timelapseType = WifiCamTimelapseTypeStill;
            break;
            
        case ICH_CAM_MODE_TIMELAPSE_STILL:
            _camera.previewMode = WifiCamPreviewModeTimelapseOn;
            _camera.timelapseType = WifiCamTimelapseTypeStill;
            break;
            
        case ICH_CAM_MODE_TIMELAPSE_VIDEO_OFF:
            _camera.previewMode =WifiCamPreviewModeTimelapseOff;
            _camera.timelapseType =WifiCamTimelapseTypeVideo;
            break;
            
        case ICH_CAM_MODE_TIMELAPSE_VIDEO:
            _camera.previewMode = WifiCamPreviewModeTimelapseOn;
            _camera.timelapseType = WifiCamTimelapseTypeVideo;
            break;
            
        case ICH_CAM_MODE_VIDEO_ON:
            _camera.previewMode = WifiCamPreviewModeVideoOn;
            break;
            
        case ICH_CAM_MODE_UNDEFINED:
        default:
            break;
    }
    
    [self updatePreviewSceneByMode:_camera.previewMode];
}

- (void)preparePanoramaTypeData {
    NSArray *temp = @[@"Sphere", @"Asteroid", @"VR"];
    _tbPanoramaTypeArray = [[WifiCamAlertTable alloc] initWithParameters:[NSMutableArray arrayWithArray:temp] andLastIndex:0];
}

- (void)p_initMovieRec {
    AppLog(@"%s", __func__);
    self.stopOn = [UIImage imageNamed:@"stop_on"];
    self.stopOff = [UIImage imageNamed:@"stop_off"];
    
    if (_camera.movieRecording) {
        [self addMovieRecListener];
        if (![_videoCaptureTimer isValid]) {
            self.videoCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                    target  :self
                                                                    selector:@selector(movieRecordingTimerCallback:)
                                                                    userInfo:nil
                                                                    repeats :YES];
            
            if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
                self.movieRecordElapsedTimeInSeconds = [_ctrl.propCtrl retrieveCurrentMovieRecordElapsedTime];
                AppLog(@"elapsedTimeInSeconds: %d", _movieRecordElapsedTimeInSeconds);
                self.movieRecordTimerLabel.text = [Tool translateSecsToString:_movieRecordElapsedTimeInSeconds];
            }
            
        }
        _camera.previewMode = WifiCamPreviewModeVideoOn;
    }
}

- (void)p_initTimelapseRec {
    BOOL isTimelapseAlreadyStarted = NO;
    
    if (_camera.stillTimelapseOn) {
        AppLog(@"stillTimelapse On");
        _camera.timelapseType = WifiCamTimelapseTypeStill;
        isTimelapseAlreadyStarted = YES;
    } else if (_camera.videoTimelapseOn) {
        AppLog(@"videoTimelapseOn On");
        _camera.timelapseType = WifiCamTimelapseTypeVideo;
        isTimelapseAlreadyStarted = YES;
    }
    
    if (isTimelapseAlreadyStarted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (![_videoCaptureTimer isValid]) {
                self.videoCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                        target  :self
                                                                        selector:@selector(movieRecordingTimerCallback:)
                                                                        userInfo:nil
                                                                        repeats :YES];
                if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
                    self.movieRecordElapsedTimeInSeconds = [_ctrl.propCtrl retrieveCurrentMovieRecordElapsedTime];
                    AppLog(@"elapsedTimeInSeconds: %d", _movieRecordElapsedTimeInSeconds);
                    self.movieRecordTimerLabel.text = [Tool translateSecsToString:_movieRecordElapsedTimeInSeconds];
                }
            }
        });
        [self addTimelapseRecListener];
        _camera.previewMode = WifiCamPreviewModeTimelapseOn;
    }
}

- (void)p_initPreviewGUI {
    if ([self capableOf:WifiCamAbilityStillCapture
         && self.snapButton.hidden]) {
        self.snapButton.hidden = NO;
    }
    if (self.mpbToggle.hidden) {
        self.mpbToggle.hidden = NO;
    }
    self.snapButton.exclusiveTouch = YES;
    self.mpbToggle.exclusiveTouch = YES;
    self.cameraToggle.exclusiveTouch = YES;
    self.videoToggle.exclusiveTouch = YES;
    self.selftimerButton.exclusiveTouch = YES;
    self.sizeButton.exclusiveTouch = YES;
    self.view.exclusiveTouch = YES;
}

- (void)p_deconstructPreviewData {
    AudioServicesDisposeSystemSoundID(_stillCaptureSound);
    AudioServicesDisposeSystemSoundID(_delayCaptureSound);
    AudioServicesDisposeSystemSoundID(_changeModeSound);
    AudioServicesDisposeSystemSoundID(_videoCaptureSound);
    AudioServicesDisposeSystemSoundID(_burstCaptureSound);
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view.window];
        _progressHUD.minSize = CGSizeMake(60, 60);
        _progressHUD.minShowTime = 1;
        _progressHUD.dimBackground = YES;
        // The sample image is based on the
        // work by: http://www.pixelpressicons.com
        // licence: http://creativecommons.org/licenses/by/2.5/ca/
        self.progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]];
        [self.view.window addSubview:_progressHUD];
    }
    return _progressHUD;
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
}

- (void)showProgressHUDNotice:(NSString *)message
                     showTime:(NSTimeInterval)time {
//    if (message) {
//        [self.progressHUD show:YES];
//        self.progressHUD.labelText = message;
//        self.progressHUD.mode = MBProgressHUDModeText;
//        [self.progressHUD hide:YES afterDelay:time];
//    } else {
//        [self.progressHUD hide:YES];
//    }
    
    [self hideProgressHUD:NO];
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view.window];
    hud.minSize = CGSizeMake(60, 60);
    hud.minShowTime = 1;
    hud.dimBackground = YES;
    [self.view.window addSubview:hud];
    [hud show:YES];
    hud.labelText = message;
    hud.mode = MBProgressHUDModeText;
    [hud hide:YES afterDelay:time];
}

- (void)showProgressHUDNotice:(NSString *)message
                       detail:(NSString *)detailmsg
                     showTime:(NSTimeInterval)time {
//    if (title) {
//        [self.progressHUD show:YES];
//        self.progressHUD.labelText = title;
//        self.progressHUD.detailsLabelText = detailmsg;
//        self.progressHUD.mode = MBProgressHUDModeText;
//        [self.progressHUD hide:YES afterDelay:time];
//    } else {
//        [self.progressHUD hide:YES];
//    }
    
    [self hideProgressHUD:NO];
    
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.view.window];
    hud.minSize = CGSizeMake(60, 60);
    hud.minShowTime = 1;
    hud.dimBackground = YES;
    [self.view.window addSubview:hud];
    [hud show:YES];
    hud.labelText = message;
    hud.detailsLabelText = detailmsg;
    hud.mode = MBProgressHUDModeText;
    [hud hide:YES afterDelay:time];
}
- (void)showProgressHUDCompleteMessage:(NSString *)message {
    if (message) {
        [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.detailsLabelText = nil;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hide:YES afterDelay:1.0];
    } else {
        [self.progressHUD hide:YES];
    }
}

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hide:animated];
}

#pragma mark - Preview GUI
- (void)updateBatteryLevelIcon {
    [self.batteryState setHidden:NO];
    
    NSString *imagePath = [_ctrl.propCtrl prepareDataForBatteryLevel];
    UIImage *batteryStatusImage = [UIImage imageNamed:imagePath];
    [self.batteryState setImage:batteryStatusImage];
    self.batteryLowAlertShowed = NO;
    
    /*batteryLevelListener = new BatteryLevelListener(self);
    [_ctrl.comCtrl addObserver:ICATCH_EVENT_BATTERY_LEVEL_CHANGED
                      listener:batteryLevelListener
                   isCustomize:NO];*/
    batteryLevelListener = make_shared<WifiCamSDKEventListener>(self, @selector(updateBatteryLevel));
    [[SDK instance] addObserver:ICH_CAM_EVENT_BATTERY_LEVEL_CHANGED listener:batteryLevelListener isCustomize:NO];
}

- (void)updateWhiteBalanceIcon:(unsigned int)curWhiteBalance
{
    NSString  *imageName = [_staticData.awbDict objectForKey:@(curWhiteBalance)];
    [self.awbLabel setImage:[UIImage imageNamed:imageName]];
}

- (void)updateCaptureDelayItem:(unsigned int)curCaptureDelay {
    if (curCaptureDelay == ICH_CAM_CAP_DELAY_NO) {
        _tbDelayCaptureTimeArray.lastIndex = 0;
    }
    NSString *title = [_staticData.captureDelayDict objectForKey:@(curCaptureDelay)];
    [self.selftimerLabel setText:title];
    [self.selftimerButton setImage:[UIImage imageNamed:@"btn_selftimer_n"]
                          forState:UIControlStateNormal];
    self.selftimerLabel.hidden = NO;
    self.selftimerButton.hidden = NO;
    self.selftimerButton.enabled = YES;
}

- (void)updateBurstCaptureIcon:(unsigned int)curBurstNumber {
    if (curBurstNumber != ICH_CAM_BURST_NUMBER_OFF) {
        NSDictionary *burstNumberStringTable = [[WifiCamStaticData instance] burstNumberStringDict];
        id imageName = [[burstNumberStringTable objectForKey:@(curBurstNumber)] lastObject];
        UIImage *continuousCaptureImage = [UIImage imageNamed:imageName];
        _burstCaptureStateImageView.image = continuousCaptureImage;
        
        self.burstCaptureStateImageView.hidden = NO;
    } else {
        self.burstCaptureStateImageView.hidden = YES;
    }
}

- (void)updateSizeItemWithTitle:(NSString *)title
                     andStorage:(NSString *)storage {
    if (title) {
        [self.sizeButton setTitle:title forState:UIControlStateNormal];
    }
    [self.sizeLabel setText:storage];
}

- (void)updateImageSizeOnScreen:(string)imageSize {
    NSArray *imageArray = [_ctrl.propCtrl prepareDataForStorageSpaceOfImage: imageSize];
    _camera.storageSpaceForImage = [[imageArray lastObject] unsignedIntValue];
    NSString *storage = @"0";
    if(!_isSDcardRemoved) {
        storage = [NSString stringWithFormat:@"%d", _camera.storageSpaceForImage];
    }
    [self updateSizeItemWithTitle:[imageArray firstObject]
                       andStorage:storage];
}

- (void)updateVideoSizeOnScreen:(string)videoSize {
    NSArray *videoArray = [_ctrl.propCtrl prepareDataForStorageSpaceOfVideo: videoSize];
    _camera.storageSpaceForVideo = [[videoArray lastObject] unsignedIntValue];
    NSString *storage = @"00:00:00";
    if(!_isSDcardRemoved) {
        storage = [Tool translateSecsToString: _camera.storageSpaceForVideo];
    }
    [self updateSizeItemWithTitle:[videoArray firstObject] andStorage:storage];
}

- (void)updatePanoramaTyprOnScreen {
    NSArray *panoramaTypeArray = _tbPanoramaTypeArray.array;
   
    NSString *title = panoramaTypeArray[_tbPanoramaTypeArray.lastIndex];
    [_panoramaTypeButton setTitle:title forState:UIControlStateNormal];
    [_panoramaTypeButton setTitle:title forState:UIControlStateHighlighted];
}

- (void)setToCameraOffScene
{
    self.snapButton.enabled = YES;
    self.mpbToggle.enabled = YES;
    self.settingButton.enabled = YES;
    // AIBSP-603
    [_ctrl.fileCtrl resetBusyToggle:NO];
    
    // DelayCapture Item
    if ([self capableOf:WifiCamAbilityDelayCapture]) {
        [self updateCaptureDelayItem:_camera.curCaptureDelay];
    }
    // CaptureSize Item
    if ([self capableOf:WifiCamAbilityImageSize]) {
        if (self.sizeButton.hidden) {
            self.sizeButton.hidden = NO;
            self.sizeLabel.hidden = NO;
        }
        self.sizeButton.enabled = YES;
        self.tbPhotoSizeArray = [_ctrl.propCtrl prepareDataForImageSize:_camera.curImageSize];
        [self updateImageSizeOnScreen:_camera.curImageSize];
        
    } else {
        self.sizeButton.hidden = YES;
        self.sizeLabel.hidden = YES;
    }
    // WhiteBalance
    if ([self capableOf:WifiCamAbilityWhiteBalance]
        && self.awbLabel.hidden) {
        self.awbLabel.hidden = NO;
    }
    // timelapse icon
    if (self.timelapseStateImageView.hidden == NO) {
        self.timelapseStateImageView.hidden = YES;
    }
    // slow-motion
    if (self.slowMotionStateImageView.hidden == NO) {
        self.slowMotionStateImageView.hidden = YES;
    }
    // invert-mode
    if (_camera.curInvertMode == 1) {
        self.invertModeStateImageView.hidden = NO;
    } else {
        self.invertModeStateImageView.hidden = YES;
    }
    // Burst-Capture icon
    if ([self capableOf:WifiCamAbilityBurstNumber]) {
        //self.burstCaptureStateImageView.hidden = NO;
        [self updateBurstCaptureIcon:_camera.curBurstNumber];
    }
    // movie record timer label
    /*
     if (!self.movieRecordTimerLabel.hidden) {
     self.movieRecordTimerLabel.hidden = YES;
     }
     */
    
    
    // Video Toggle & Timelapse Toggle & Camera Toggle
    if ([self capableOf:WifiCamAbilityMovieRecord]) {
        if (self.videoToggle.hidden) {
            self.videoToggle.hidden = NO;
        }
        [self.videoToggle setImage:[UIImage imageNamed:@"video_off"]
                          forState:UIControlStateNormal];
        self.videoToggle.enabled = YES;
    }
    
    if ([self capableOf:WifiCamAbilityTimeLapse]) {
        if (self.timelapseToggle.hidden) {
            self.timelapseToggle.hidden = NO;
        }
        
        [self.timelapseToggle setImage:[UIImage imageNamed:@"timelapse_off"]
                              forState:UIControlStateNormal];
        self.timelapseToggle.enabled = YES;
    }
    
    if ([self capableOf:WifiCamAbilityStillCapture]) {
        if (self.cameraToggle.hidden) {
            self.cameraToggle.hidden = NO;
        }
        
        [self.cameraToggle setImage:[UIImage imageNamed:@"camera_on"]
                           forState:UIControlStateNormal];
        self.cameraToggle.enabled = YES;
        [self.snapButton setImage:[UIImage imageNamed:@"ic_camera1"]
                         forState:UIControlStateNormal];
    }
    
    
    //self.autoDownloadThumbImage.hidden = YES;
}

- (void)setToCameraOnScene {
    self.snapButton.enabled = NO;
    self.mpbToggle.enabled = NO;
    self.settingButton.enabled = NO;
    self.videoToggle.enabled = NO;
    if ([self capableOf:WifiCamAbilityTimeLapse]) {
        self.timelapseToggle.enabled = NO;
    }
    if ([self capableOf:WifiCamAbilityDelayCapture]) {
        self.selftimerButton.enabled = NO;
    }
    if ([self capableOf:WifiCamAbilityImageSize]) {
        self.sizeButton.enabled = NO;
    }
    
    // AIBSP-603
    if ([self capableOf:WifiCamAbilityZoom]) {
        [_ctrl.fileCtrl resetBusyToggle:YES];
        [self hideZoomController:YES];
    }
}

- (void)setToVideoOffScene {
    [self.mpbToggle setEnabled:YES];
    [self.settingButton setEnabled:YES];
    [self.enableAudioButton setEnabled:YES];
    
    // DelayCapture Item
    if ([self capableOf:WifiCamAbilityDelayCapture] && ![self.selftimerButton isHidden]) {
        [self.selftimerButton setHidden:YES];
        [self.selftimerLabel setHidden:YES];
        
    }
    
    // CaptureSize Item
    if ([self capableOf:WifiCamAbilityVideoSize]) {
        if ([self.sizeButton isHidden]) {
            [self.sizeButton setHidden:NO];
            [self.sizeLabel setHidden:NO];
        }
        [self.sizeButton setEnabled:YES];
        self.tbVideoSizeArray = [_ctrl.propCtrl prepareDataForVideoSize:_camera.curVideoSize];
        [self updateVideoSizeOnScreen:_camera.curVideoSize];
    } else {
        [self.sizeButton setHidden:YES];
        [self.sizeLabel setHidden:YES];
    }
    
    // WhiteBalance
    if ([self capableOf:WifiCamAbilityWhiteBalance] && [self.awbLabel isHidden]) {
        [self.awbLabel setHidden:NO];
    }
    
    // timelapse icon
    if (self.timelapseStateImageView.hidden == NO) {
        self.timelapseStateImageView.hidden = YES;
    }
    
    // slow-motion
    if (_camera.curSlowMotion == 1) {
        self.slowMotionStateImageView.hidden = NO;
    } else {
        self.slowMotionStateImageView.hidden = YES;
    }
    
    // invert-mode
    if (_camera.curInvertMode == 1) {
        self.invertModeStateImageView.hidden = NO;
    } else {
        self.invertModeStateImageView.hidden = YES;
    }
    
    // Burst-Capture icon
    if (!self.burstCaptureStateImageView.hidden) {
        self.burstCaptureStateImageView.hidden = YES;
    }
    
    // Camera Toggle &Timelapse Toggle & Video Toggle
    if ([self capableOf:WifiCamAbilityStillCapture]) {
        if (self.cameraToggle.isHidden) {
            self.cameraToggle.hidden = NO;
        }
        [self.cameraToggle setImage:[UIImage imageNamed:@"camera_off"]
                           forState:UIControlStateNormal];
        [self.cameraToggle setEnabled:YES];
    }
    
    if ([self capableOf:WifiCamAbilityTimeLapse]) {
        if (self.timelapseToggle.isHidden) {
            self.timelapseToggle.hidden = NO;
        }
        [self.timelapseToggle setImage:[UIImage imageNamed:@"timelapse_off"]
                              forState:UIControlStateNormal];
        [self.timelapseToggle setEnabled:YES];
    }
    
    if ([self capableOf:WifiCamAbilityMovieRecord]) {
        if (self.videoToggle.isHidden) {
            self.videoToggle.hidden = NO;
        }
        [self.videoToggle setImage:[UIImage imageNamed:@"video_on"]
                          forState:UIControlStateNormal];
        [self.videoToggle setEnabled:YES];
        [self.snapButton setImage:[UIImage imageNamed:@"stop_on"]
                         forState:UIControlStateNormal];
        
        // movie record timer label
        if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
            self.movieRecordTimerLabel.hidden = YES;
        }
    }
    
    if (self.autoDownloadThumbImage.image) {
        self.autoDownloadThumbImage.hidden = NO;
    }
    
#if 0
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSString *curLiveSize = [defaults stringForKey:@"LiveSize"];
//    if ([defaults boolForKey:@"PreferenceSpecifier:Live"] && curLiveSize) {
//        self.liveResolution.text = curLiveSize;
//    } else {
//        self.liveResolution.text = nil;
//    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *curLiveSize = [defaults stringForKey:@"LiveSize"];
    BOOL isLive = [defaults boolForKey:@"PreferenceSpecifier:YouTube_Live"] || [defaults boolForKey:@"PreferenceSpecifier:Facebook_Live"];
    
    if (isLive && curLiveSize) {
        self.liveResolution.text = curLiveSize;
    } else {
        self.liveResolution.text = nil;
    }
#endif
}

- (void)setToVideoOnScene
{
    [self setToVideoOffScene];
    
    if ([self capableOf:WifiCamAbilityStillCapture]) {
        self.cameraToggle.enabled = NO;
    }
    self.videoToggle.enabled = NO;
    self.mpbToggle.enabled = NO;
    self.settingButton.enabled = NO;
    self.enableAudioButton.enabled = NO;
    if ([self capableOf:WifiCamAbilityTimeLapse]) {
        self.timelapseToggle.enabled = NO;
    }
    if ([self capableOf:WifiCamAbilityVideoSize]) {
        self.sizeButton.enabled = NO;
    }
    
    if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
        self.movieRecordTimerLabel.text = @"00:00:00";
        self.movieRecordTimerLabel.hidden = NO;
    }
}

- (void)setToTimelapseOffScene
{
    [self.mpbToggle setEnabled:YES];
    [self.settingButton setEnabled:YES];
    
    //[_ctrl.propCtrl updateAllProperty:_camera];
    
    // DelayCapture Item
    if ([self capableOf:WifiCamAbilityDelayCapture] && ![self.selftimerButton isHidden]) {
        [self.selftimerButton setHidden:YES];
        [self.selftimerLabel setHidden:YES];
    }
    
    // CaptureSize Item
    //  if (![self.sizeButton isHidden]) {
    //    [self.sizeButton setHidden:YES];
    //    [self.sizeLabel setHidden:YES];
    //  }
    if ([self capableOf:WifiCamAbilityVideoSize] || [self capableOf:WifiCamAbilityImageSize]) {
        if ([self.sizeButton isHidden]) {
            [self.sizeButton setHidden:NO];
            [self.sizeLabel setHidden:NO];
        }
        [self.sizeButton setEnabled:YES];
        
        // update current video size. V35 cannot support 4K,2K in timelapse mode, so camera will auto-change video size
        // add by Allen
        _camera.curVideoSize = [_ctrl.propCtrl retrieveCurrentVideoSize2];
        
        //self.tbVideoSizeArray = [_ctrl.propCtrl prepareDataForVideoSize:_camera.curVideoSize];
//        self.tbVideoSizeArray = [_ctrl.propCtrl prepareDataForTimeLapseVideoSize:_camera.curVideoSize];
        
        
        if (_camera.timelapseType == WifiCamTimelapseTypeVideo) {
            self.tbVideoSizeArray = [_ctrl.propCtrl prepareDataForTimeLapseVideoSize:_camera.curVideoSize];
            [self updateVideoSizeOnScreen:_camera.curVideoSize];
        } else {
            self.tbPhotoSizeArray = [_ctrl.propCtrl prepareDataForImageSize:_camera.curImageSize];
            [self updateImageSizeOnScreen:_camera.curImageSize];
        }
        
        
        
    } else {
        self.sizeButton.hidden = NO;
        self.sizeLabel.hidden = NO;
    }
    
    
    // AWB
    if ([self capableOf:WifiCamAbilityWhiteBalance]
        && self.awbLabel.hidden) {
        self.awbLabel.hidden = NO;
    }
    
    // timelapse icon
    if (_camera.curTimelapseInterval != 0) {
        self.timelapseStateImageView.hidden = NO;
    }
    
    
    // slow-motion
    if (self.slowMotionStateImageView.hidden == NO) {
        self.slowMotionStateImageView.hidden = YES;
    }
    
    //
    if (_camera.curInvertMode == 1) {
        self.invertModeStateImageView.hidden = NO;
    } else {
        self.invertModeStateImageView.hidden = YES;
    }
    
    // Burst-Capture icon
    if (!self.burstCaptureStateImageView.hidden) {
        self.burstCaptureStateImageView.hidden = YES;
    }
    
    // Camera Toggle & Video Toggle &Timelapse Toggle
    if ([self capableOf:WifiCamAbilityStillCapture]) {
        if (self.cameraToggle.isHidden) {
            self.cameraToggle.hidden = NO;
        }
        [self.cameraToggle setImage:[UIImage imageNamed:@"camera_off"]
                           forState:UIControlStateNormal];
        [self.cameraToggle setEnabled:YES];
    }
    
    if ([self capableOf:WifiCamAbilityMovieRecord]) {
        if (self.videoToggle.isHidden) {
            self.videoToggle.hidden = NO;
        }
        [self.videoToggle setImage:[UIImage imageNamed:@"video_off"]
                          forState:UIControlStateNormal];
        [self.videoToggle setEnabled:YES];
        
        // movie record timer label
        if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
            self.movieRecordTimerLabel.hidden = YES;
        }
        
    }
    
    if ([self capableOf:WifiCamAbilityTimeLapse]) {
        if (self.timelapseToggle.isHidden) {
            self.timelapseToggle.hidden = NO;
        }
        [self.timelapseToggle setImage:[UIImage imageNamed:@"timelapse_on"]
                              forState:UIControlStateNormal];
        [self.timelapseToggle setEnabled:YES];
        [self.snapButton setImage:[UIImage imageNamed:@"stop_on"]
                         forState:UIControlStateNormal];
    }
    
    self.autoDownloadThumbImage.hidden = YES;
}

- (void)setToTimelapseOnScene
{
    [self setToTimelapseOffScene];
    
    if ([self capableOf:WifiCamAbilityStillCapture]) {
        self.cameraToggle.enabled = NO;
    }
    if ([self capableOf:WifiCamAbilityMovieRecord]) {
        self.videoToggle.enabled = NO;
    }
    self.mpbToggle.enabled = NO;
    self.settingButton.enabled = NO;
    self.timelapseToggle.enabled = NO;
    if ([self capableOf:WifiCamAbilityVideoSize]) {
        self.sizeButton.enabled = NO;
    }
    
    if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
        self.movieRecordTimerLabel.text = @"00:00:00";
        self.movieRecordTimerLabel.hidden = NO;
    }
    
}

- (void)updatePreviewSceneByMode:(WifiCamPreviewMode)mode
{
    _camera.previewMode = mode;
    AppLog(@"camera.previewMode: %lu", (unsigned long)_camera.previewMode);
    switch (mode) {
        case WifiCamPreviewModeCameraOff:
            [self setToCameraOffScene];
            break;
        case WifiCamPreviewModeCameraOn:
            [self setToCameraOnScene];
            break;
        case WifiCamPreviewModeVideoOff:
            [self setToVideoOffScene];
            break;
        case WifiCamPreviewModeVideoOn:
            [self setToVideoOnScene];
            break;
        case WifiCamPreviewModeTimelapseOff:
            [self setToTimelapseOffScene];
            break;
        case WifiCamPreviewModeTimelapseOn:
            [self setToTimelapseOnScene];
            break;
        default:
            break;
    }
}

#pragma mark - Preview
- (void)runPreview:(ICatchCamPreviewMode)mode
{
    AppLog(@"%s start(%d)", __func__, mode);
    self.videoPlayFlag = NO;
    self.paused = NO;
    
    self.previewMode = mode;
    dispatch_queue_t previewQ = dispatch_queue_create("WifiCam.GCD.Queue.Preview", DISPATCH_QUEUE_SERIAL);
    dispatch_time_t timeOutCount = dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC);
    
    [self showProgressHUDWithMessage:nil];
    dispatch_async(previewQ, ^{
        if (dispatch_semaphore_wait(_previewSemaphore, timeOutCount) != 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [self showErrorAlertView];
            });
            return;
        }
        
//        int ret = [_ctrl.actCtrl startPreview:mode withAudioEnabled:self.AudioRun];
        //int ret = [[SDK instance] startMediaStream:mode];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
#if 0
        BOOL isLive = [defaults boolForKey:@"PreferenceSpecifier:YouTube_Live"] /*|| [defaults boolForKey:@"PreferenceSpecifier:Facebook_Live"]*/;
#endif
        BOOL isUseSDKDecode = [defaults boolForKey:@"PreferenceSpecifier:UseSDKDecode"];
        
        BOOL isEnableLive = false; //isLive && (_camera.previewMode == WifiCamPreviewModeVideoOff || _camera.previewMode == WifiCamPreviewModeVideoOn);
//        int ret = [[SDK instance] startMediaStream:mode enableAudio:self.AudioRun enableLive:isEnableLive];
//        int ret = [_ctrl.actCtrl startPreview:mode withAudioEnabled:self.AudioRun enableLive:isEnableLive];
        int ret = [_ctrl.actCtrl startPreview:mode withAudioEnabled:YES enableLive:isEnableLive];
        
        if (ret != ICH_SUCCEED) {
            dispatch_semaphore_signal(_previewSemaphore);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updatePreviewSceneByMode:_camera.previewMode];
                [self hideProgressHUD:YES];
                _preview.image = nil;
                _noPreviewLabel.hidden = NO;
                if (ret == ICH_STREAM_NOT_SUPPORT) {
                    _noPreviewLabel.text = NSLocalizedString(@"PreviewNotSupported", nil);
                    _noPreviewLabel.font = [UIFont systemFontOfSize:28];
                    _noPreviewLabel.textColor = [UIColor redColor];
                } else {
                    _noPreviewLabel.text = NSLocalizedString(@"StartPVFailed", nil);
                }
                _preview.userInteractionEnabled = NO;
#ifdef HW_DECODE_H264
                _h264View.userInteractionEnabled = NO;
#endif
            });
            return;
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updatePreviewSceneByMode:_camera.previewMode];
                [self hideProgressHUD:YES];
                _noPreviewLabel.hidden = YES;
                _preview.userInteractionEnabled = YES;
#ifdef HW_DECODE_H264
                _h264View.userInteractionEnabled = YES;
#endif
                
                [self showLiveGUIIfNeeded:_camera.previewMode];
//                if (![[SDK instance] isStreamSupportPublish]) {
//                    _liveSwitch.hidden = NO;
//                    _liveTitle.hidden = NO;
//                    _liveResolution.hidden = NO;
//                } else {
//                    _liveSwitch.hidden = YES;
//                    _liveTitle.hidden = YES;
//                    _liveResolution.hidden = YES;
//                }
                
                if (isUseSDKDecode) {
                    self.glkView.hidden = NO;
                    _preview.hidden = YES;
                    _avslayer.hidden = YES;
                    [self startGLKAnimation];
                    if ([[PanCamSDK instance] isPanoramaWithFile:nil]) {
                        [self configureGyro];
                    }
                }
            });
            
//            WifiCamSDKEventListener *listener = new WifiCamSDKEventListener(self, @selector(streamCloseCallback));
            auto listener = make_shared<StreamSDKEventListener>(self, @selector(streamCloseCallback));
            self.streamObserver = [[StreamObserver alloc] initWithListener:listener
                                                                  eventType:ICH_GL_EVENT_STREAM_CLOSED//ICATCH_EVENT_MEDIA_STREAM_CLOSED
                                                               isCustomized:NO isGlobal:NO];
            [[PanCamSDK instance] addObserver:_streamObserver];
            
            [self addStreamStatusObserver];
        }
        
        if (!isUseSDKDecode) {
            if ([_ctrl.propCtrl audioStreamEnabled] && self.AudioRun) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.enableAudioButton.tag = 0;
                    [self.enableAudioButton setBackgroundImage:[UIImage imageNamed:@"audio_on"]
                                                      forState:UIControlStateNormal];
                    self.enableAudioButton.enabled = YES;
                });
                dispatch_group_async(self.previewGroup, self.audioQueue, ^{[self playbackAudio];});
            } else {
                self.AudioRun = NO;
                AppLog(@"Streaming doesn't contains audio.");
            }
            
            
            if ([_ctrl.propCtrl videoStreamEnabled]) {
                dispatch_group_async(self.previewGroup, self.videoQueue, ^{[self playbackVideo];});
            } else {
                AppLog(@"Streaming doesn't contains video.");
            }
            
            dispatch_group_notify(_previewGroup, previewQ, ^{
                [[PanCamSDK instance] removeObserver:_streamObserver];
                _streamObserver.listener.reset();
                self.streamObserver = nil;
                
                self.paused = YES;
                [_ctrl.actCtrl stopPreview];
//                [[PanCamSDK instance] panCamStopPreview];
                [self.motionManager stopGyroUpdates];
                
                dispatch_semaphore_signal(_previewSemaphore);
            });
        }
    });
    
    dispatch_async(previewQ, ^{
        // Check SD card
        if (![_ctrl.propCtrl checkSDExist]) {
            AppLog("SD card not inserted");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgressHUDNotice:NSLocalizedString(@"NoCard", nil) showTime:2.0];
            });
        } else {
            if ((_camera.previewMode == WifiCamPreviewModeCameraOff && _camera.storageSpaceForImage <= 0)
                || (_camera.previewMode == WifiCamPreviewModeCameraOff && _camera.storageSpaceForVideo==0)) {
                
                AppLog("SD card is full");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showProgressHUDNotice:NSLocalizedString(@"CARD_FULL", nil) showTime:2.0];
                });
                
            }
        }
    });
}

- (void)addStreamStatusObserver {
    auto frameIntervalInfo = make_shared<StreamSDKEventListener>(self, @selector(frameIntervalInfoCallback:));
    self.frameIntervalInfoObserver = [[StreamObserver alloc] initWithListener:frameIntervalInfo eventType:ICH_GL_EVENT_FRAME_INTERVAL_INFO isCustomized:NO isGlobal:NO];
    [[PanCamSDK instance] addObserver:self.frameIntervalInfoObserver];
}

- (void)removeStreamStatusObserver {
    if (self.frameIntervalInfoObserver) {
        [[PanCamSDK instance] removeObserver:self.frameIntervalInfoObserver];
        self.frameIntervalInfoObserver.listener.reset();
        self.frameIntervalInfoObserver = nil;
    }
}

- (void)frameIntervalInfoCallback:(WifiCamEvent *)event {
    double interval = event.doubleValue1;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (interval >= 1 && self.progressHUD.hidden) {
            [self showProgressHUDWithMessage:nil];
        } else {
            [self hideProgressHUD:YES];
        }
    });
}

- (void)setPVRun:(BOOL)PVRun {
    _PVRun = PVRun;
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:UseSDKDecode"]) {
        if (!PVRun) {
            [self stopPreview];
        }
    }
}

- (void)stopPreview {
    if (self.streamObserver) {
        [[PanCamSDK instance] removeObserver:_streamObserver];
        _streamObserver.listener.reset();
        self.streamObserver = nil;
    }
    
    [self removeStreamStatusObserver];

    self.paused = YES;
//    [_ctrl.actCtrl stopPreview];
    [[PanCamSDK instance] panCamStopPreview];
    [self.motionManager stopGyroUpdates];
    
    dispatch_semaphore_signal(_previewSemaphore);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    if (!self.paused) {
        /*if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            [[PanCamSDK instance] panCamSetViewPort:0 andY:CGRectGetMaxY(self.movieRecordTimerLabel.frame) andWidth:(int)view.drawableWidth andHeight:abs(self.mpbToggle.frame.origin.y + CGRectGetMaxY(self.movieRecordTimerLabel.frame) + 84)];
        } else {
            [[PanCamSDK instance] panCamSetViewPort:0 andY:CGRectGetMaxY(self.movieRecordTimerLabel.frame) - 40  andWidth:(int)view.drawableWidth andHeight:abs(self.mpbToggle.frame.origin.y - CGRectGetMaxY(self.movieRecordTimerLabel.frame))];
        }*/
       // [[PanCamSDK instance] panCamSetViewPort:0 andY:CGRectGetMaxY(self.movieRecordTimerLabel.frame) * [UIScreen mainScreen].scale andWidth:(int)view.drawableWidth * [UIScreen mainScreen].scale andHeight:(CGRectGetMinY(self.mpbToggle.frame) - CGRectGetMaxY(self.movieRecordTimerLabel.frame)) * [UIScreen mainScreen].scale];
        
//        [[PanCamSDK instance] panCamSetViewPort:0 andY:0 andWidth:(int)view.drawableWidth andHeight:(int)view.drawableHeight];
//        [[PanCamSDK instance] panCamRender];
        
        int windowW = (int)view.drawableWidth;
        int windowH = (int)view.drawableHeight;
        BOOL isNeed = YES;
        
        if (!self.paused) {
            //        FIXME: modify viewPort
            if (drawableWidth == 0 || drawableHeight == 0) {
                drawableWidth = windowW;
                drawableHeight = windowH;
            }
            
            if (windowH != drawableHeight || windowW != drawableWidth) {
                drawableWidth = windowW;
                drawableHeight = windowH;
                isNeed = NO;
            }
            
            [[PanCamSDK instance] panCamSetViewPort:0 andY:0 andWidth:windowW andHeight:windowH needJudge:isNeed];
            [[PanCamSDK instance] panCamRenderWithNeedJudge:isNeed];
        }
    }
}

#pragma mark ------------ Gyro Events ------------
static double __timestampA = 0;

- (void)configureGyro
{
    if (([_motionManager isGyroAvailable])) {
        [self.motionManager startGyroUpdatesToQueue:_queue withHandler:^(CMGyroData* gyroData, NSError* error){
            
            if (__timestampA == 0) {
                __timestampA = gyroData.timestamp;
            }
            
            long timestamp = (gyroData.timestamp - __timestampA) * 1000 * 1000 * 1000;
            if (!self.paused) {
                //NSLog(@"--x: %f, y: %f, z: %f, timestamp: %ld", gyroData.rotationRate.x, gyroData.rotationRate.y, gyroData.rotationRate.z, timestamp);
                float speedX = roundf(gyroData.rotationRate.x * 10) / 10;
                float speedY = roundf(gyroData.rotationRate.y * 10) / 10;
                float speedZ = roundf(gyroData.rotationRate.z * 10) / 10;
                //NSLog(@"++x: %f, y: %f, z: %f, timestamp: %ld", speedX, speedY, speedZ, timestamp);
                
                __block UIInterfaceOrientation orientation;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    orientation = [[UIApplication sharedApplication] statusBarOrientation];
                });
                switch (orientation) {
                    case UIInterfaceOrientationPortrait:
                        [[PanCamSDK instance] panCamRotate:0 andSpeedX:speedX andSpeedY:speedY andSpeedZ:speedZ andTamp:timestamp andType:PCFileTypeStream];
                        break;
                    case UIInterfaceOrientationLandscapeLeft:
                        [[PanCamSDK instance] panCamRotate:3 andSpeedX:speedX andSpeedY:speedY andSpeedZ:speedZ andTamp:timestamp andType:PCFileTypeStream];
                        break;
                    case UIInterfaceOrientationPortraitUpsideDown:
                        [[PanCamSDK instance] panCamRotate:2 andSpeedX:speedX andSpeedY:speedY andSpeedZ:speedZ andTamp:timestamp andType:PCFileTypeStream];
                        break;
                    case UIInterfaceOrientationLandscapeRight:
                        [[PanCamSDK instance] panCamRotate:1 andSpeedX:speedX andSpeedY:speedY andSpeedZ:speedZ andTamp:timestamp andType:PCFileTypeStream];
                        break;
                    case UIInterfaceOrientationUnknown:
                        break;
                }
            }
        }];
    }
    else {
        NSLog(@"Gyro not abaliable");
    }
}

#pragma mark ------------- UI Events --------------

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *touch in event.allTouches) {
        CGPoint pointC = [touch locationInView:nil];
        pointP.x = pointC.x;
        pointP.y = pointC.y;
    }
    
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    for(UITouch *touch in event.allTouches) {
        
        // Create ICatch GL point
        CGPoint pointC = [touch locationInView:nil];
        
        if ([[PanCamSDK instance] isPanoramaWithFile:nil]) {
            [[PanCamSDK instance] panCamRotate:pointC andPointPre:pointP andType:PCFileTypeStream];
        }
        
        // Update Prev point
        pointP.x = pointC.x;
        pointP.y = pointC.y;
    }
    
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Nothing to do
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Nothing to do
    [super touchesCancelled:touches withEvent:event];
}

- (float) calculateDistance:(float) distanceP andScale:(CGFloat) scale {
    float distanceC = distanceP * scale;
    
    if (distanceC > maxDistance) {
        distanceC = maxDistance;
    } else if (distanceC < minDistance) {
        distanceC = minDistance;
    }
    
    return distanceC;
}

- (void)handleGesture:(UIPinchGestureRecognizer *)gestureRecognizer
{
    CGFloat scale = gestureRecognizer.scale;
    NSLog(@"======scale: %f", scale);
    
    CGFloat velocity = gestureRecognizer.velocity;
    NSLog(@"======scvelocityale: %f", velocity);
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateEnded:{ // UIGestureRecognizerStateRecognized = UIGestureRecognizerStateEnded
            NSLog(@"======UIGestureRecognizerStateEnded || UIGestureRecognizerStateRecognized");
            //gestureRecognizer.scale = 1;
            cDistance = [self calculateDistance:cDistance andScale:scale];
            
            break;
        }
        case UIGestureRecognizerStateBegan:{ //
            NSLog(@"======UIGestureRecognizerStateBegan");
            break;
        }
        case UIGestureRecognizerStateChanged:{ //
            NSLog(@"======UIGestureRecognizerStateChanged");
            
            //gestureRecognizer.view.transform = CGAffineTransformScale(gestureRecognizer.view.transform, gestureRecognizer.scale, gestureRecognizer.scale);
            [[PanCamSDK instance] panCamLocate: [self calculateDistance:cDistance andScale:scale] andType:PCFileTypeStream];
            //gestureRecognizer.scale = 1; // 重置，很重要！！！
            
            break;
        }
        case UIGestureRecognizerStateCancelled:{ //
            NSLog(@"======UIGestureRecognizerStateCancelled");
            break;
        }
        case UIGestureRecognizerStateFailed:{ //
            NSLog(@"======UIGestureRecognizerStateFailed");
            break;
        }
        case UIGestureRecognizerStatePossible:{ //
            NSLog(@"======UIGestureRecognizerStatePossible");
            break;
        }
        default:{
            NSLog(@"======Unknow gestureRecognizer");
            break;
        }
    }
}

-(BOOL)dataIsValidJPEG:(NSData *)data
{
    if (!data || data.length < 2) return NO;
    
    NSInteger totalBytes = data.length;
    const char *bytes = (const char*)[data bytes];
    
    return (bytes[0] == (char)0xff &&
            bytes[1] == (char)0xd8 &&
            bytes[totalBytes-2] == (char)0xff &&
            bytes[totalBytes-1] == (char)0xd9);
}

- (BOOL)dataIsIFrame:(NSData *)data {
    if (!data || data.length < 5) return NO;
    
    //    char array[] = {0x00, 0x00, 0x00, 0x01, 0x65};
    const char *bytes = (const char*)[data bytes];
    //    printf("%02x, %02x, %02x, %02x, %02x \n", bytes[0], bytes[1], bytes[2], bytes[3], bytes[4]);
    return bytes[4] == 0x65 ? YES : NO;
}

static void didDecompress(void* decompressionOutputRefCon, void* sourceFrameRefCon,
                          OSStatus status, VTDecodeInfoFlags infoFlags,
                          CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration )
{
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

-(BOOL)initH264Env:(shared_ptr<ICatchVideoFormat>)format {
    
    AppLog(@"w:%d, h: %d", format->getVideoW(), format->getVideoH());
    
    _spsSize = format->getCsd_0_size()-4;
    _sps = (uint8_t *)malloc(_spsSize);
    memcpy(_sps, format->getCsd_0()+4, _spsSize);
    /*
     printf("sps:");
     for(int i=0;i<_spsSize;++i) {
     printf("0x%x ", _sps[i]);
     }
     printf("\n");
     */
    
    _ppsSize = format->getCsd_1_size()-4;
    _pps = (uint8_t *)malloc(_ppsSize);
    memcpy(_pps, format->getCsd_1()+4, _ppsSize);
    /*
     printf("pps:");
     for(int i=0;i<_ppsSize;++i) {
     printf("0x%x ", _pps[i]);
     }
     printf("\n");
     */
    
    AppLog(@"sps:%ld, pps: %ld", (long)_spsSize, (long)_ppsSize);
    
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { static_cast<size_t>(_spsSize), static_cast<size_t>(_ppsSize) };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          &_decoderFormatDescription);
    if(status != noErr) {
        NSLog(@"IOS8VT: reset decoder session failed status=%d", (int)status);
    } else {
        uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void* keys[] = { kCVPixelBufferPixelFormatTypeKey };
        const void* values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
        CFDictionaryRef attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = NULL;
        
        VTDecompressionSessionCreate(kCFAllocatorDefault,
                                     _decoderFormatDescription,
                                     NULL, attrs,
                                     &callBackRecord,
                                     &_deocderSession);
        
        NSLog(@"__init_decoder__ deocderSession: %p", _deocderSession);
        NSLog(@"__init_decoder__ decoderFormatDescription: %p", _decoderFormatDescription);
        CFRelease(attrs);
    }
    
    return YES;
}

-(void)clearH264Env {
    if(_deocderSession) {
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
    
    if(_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
    
    free(_sps);
    free(_pps);
    _spsSize = _ppsSize = 0;
}

-(void)decodeAndDisplayH264Frame:(NSData *)frame {
    CMBlockBufferRef blockBuffer = NULL;
    CMSampleBufferRef sampleBuffer = NULL;
    
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                         (void*)frame.bytes, frame.length,
                                                         kCFAllocatorNull,
                                                         NULL, 0, frame.length,
                                                         0, &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        const size_t sampleSizeArray[] = {frame.length};
        
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        CFRelease(blockBuffer);
        CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
        CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
        CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
        if (status == kCMBlockBufferNoErr) {
            if ([_avslayer isReadyForMoreMediaData]) {
                dispatch_sync(dispatch_get_main_queue(),^{
                    [_avslayer enqueueSampleBuffer:sampleBuffer];
                });
            }
            CFRelease(sampleBuffer);
        }
    }
}

- (void)decode:(NSData*)data
{
    /* create block buffer */
    CMBlockBufferRef blockBuffer = NULL;
    CVPixelBufferRef pixelBuffer = NULL;

    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          (void*)data.bytes, data.length,
                                                          kCFAllocatorNull,
                                                          NULL, 0, data.length,
                                                          0, &blockBuffer);
    if (status == kCMBlockBufferNoErr) {
        /* create sample buffer */
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {static_cast<size_t>(data.length)};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        if (status == kCMBlockBufferNoErr || sampleBuffer) {
            /* decode frame */
            VTDecodeFrameFlags  flags = 0;
            VTDecodeInfoFlags   flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &pixelBuffer,
                                                                      &flagOut);
            
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", (int)decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT: decode failed status=%d", (int)decodeStatus);
            }
            
            CFRelease(sampleBuffer);
            
        } else  NSLog(@"IOS8VT: create sample buffer failed.");
        
        CFRelease(blockBuffer);

    } else  NSLog(@"IOS8VT: create block failed.");
    
    if (pixelBuffer != NULL) {
#if APP_TEST
        if (_i++ < 3) {
            /************ CVPixelBufferRef to UIImage ************/
            CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
            
            CIContext *temporaryContext = [CIContext contextWithOptions:nil];//required
            CGImageRef videoImage = [temporaryContext
                                     createCGImage:ciImage
                                     fromRect:CGRectMake(0, 0,
                                                         CVPixelBufferGetWidth(pixelBuffer),
                                                         CVPixelBufferGetHeight(pixelBuffer))];//required
            
            UIImage *uiImage = [UIImage imageWithCGImage:videoImage];
            CGImageRelease(videoImage);
            
            AppLog(@"-----> %d: %@", _i, uiImage);
            [[SDK instance] writeImageDataToFile:uiImage andName:[NSString stringWithFormat:@"%d", _i]];
        }
#endif
        if (!CVPixelBufferIsPlanar(pixelBuffer)) {
            NSLog(@"...., not a planar buffer.");
        }
        
        size_t planCount = CVPixelBufferGetPlaneCount(pixelBuffer);
        if (planCount != 2) {
            NSLog(@"...., not a NV12 color.");
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        uint8_t* dataNV12_YY = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        uint8_t* dataNV12_UV = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        int32_t  dataNV12_YY_size = (int32_t)(CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0) * CVPixelBufferGetHeightOfPlane(pixelBuffer, 0));
        int32_t  dataNV12_UV_size = (int32_t)(CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1) * CVPixelBufferGetHeightOfPlane(pixelBuffer, 1));
        
        [[PanCamSDK instance] panCamUpdateFrame:dataNV12_YY andImageYsize:dataNV12_YY_size andImageU:dataNV12_UV andImageUsize:dataNV12_UV_size andImageV:dataNV12_UV andImageVsize:dataNV12_UV_size];
        
        //NSLog(@"dataNV12, dataNV12_YY, %p %d", dataNV12_YY, dataNV12_YY_size);
        //NSLog(@"dataNV12, dataNV12_UV, %p %d", dataNV12_YY, dataNV12_UV_size);
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CVPixelBufferRelease(pixelBuffer);
    }
}

// MARK: - save last video frame
- (CVPixelBufferRef)decodeToPixelBufferRef:(NSData*)vp {
    CVPixelBufferRef outputPixelBuffer = NULL;
    
    CMBlockBufferRef blockBuffer = NULL;
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          (void*)vp.bytes, vp.length,
                                                          kCFAllocatorNull,
                                                          NULL, 0, vp.length,
                                                          0, &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {vp.length};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        if (status == kCMBlockBufferNoErr && sampleBuffer) {
            VTDecodeFrameFlags flags = 0;
            VTDecodeInfoFlags flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &outputPixelBuffer,
                                                                      &flagOut);
            
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", (int)decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT: decode failed status=%d", (int)decodeStatus);
            }
            
            CFRelease(sampleBuffer);
        }
        CFRelease(blockBuffer);
    }
    
    return outputPixelBuffer;
}

- (UIImage *)imageFromPixelBufferRef:(NSData *)data {
    CVPixelBufferRef pixelBuffer = [self decodeToPixelBufferRef:data];
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    UIImage *image = [UIImage imageWithCIImage:ciImage];
//    AppLog("last image: %@", image);
    return image;
}

- (NSMutableData *)currentVideoData {
    if (_currentVideoData == nil) {
        _currentVideoData = [NSMutableData data];
    }
    
    return _currentVideoData;
}

- (void)recordCurrentVideoFrame:(NSData *)data {
    if ([self dataIsIFrame:data]) {
        self.currentVideoData.length = 0;
        [self.currentVideoData appendData:data];
    }
}

- (void)saveLastVideoFrame:(UIImage *)image {
#if 0
    CGSize size = CGSizeMake(120, 120);
#else
    CGSize size = image.size;
#endif
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    self.savedCamera.thumbnail = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

-(void)playbackVideoH264 {
    auto format = [_ctrl.propCtrl retrieveVideoFormat];
    [[PanCamSDK instance] panCamUpdateFormat:format];
    
    NSRange headerRange = NSMakeRange(0, 4);
    NSMutableData *headFrame = nil;
    uint32_t nalSize = 0;

    while (_PVRun) {
        if (_readyGoToSetting) {
            AppLog(@"Sleep 1 second.");
            [NSThread sleepForTimeInterval:1.0];
            continue;
        }
        
        //flush avslayer when active from background
        if (self.avslayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
            [self.avslayer flush];
        }
        
        // HW decode
        [self initH264Env:format];
        for(;;) {
            @autoreleasepool {
                // 1st frame contains sps & pps data.
#if RUN_DEBUG
                NSDate *begin = [NSDate date];
                WifiCamAVData *avData = [[SDK instance] getVideoData2];
                NSDate *end = [NSDate date];
                NSTimeInterval elapse = [end timeIntervalSinceDate:begin];
                AppLog(@"[V]Get %lu, elapse: %f", (unsigned long)avData.data.length, elapse);
#else
                WifiCamAVData *avData = [[PanCamSDK instance] getVideoData];
#endif
                if (avData.data.length > 0) {
                    self.curVideoPTS = avData.time;
                    
                    NSUInteger loc = (4+_spsSize)+(4+_ppsSize);
                    nalSize = (uint32_t)(avData.data.length - loc - 4);
                    NSRange iRange = NSMakeRange(loc, avData.data.length - loc);
                    const uint8_t lengthBytes[] = {(uint8_t)(nalSize>>24),
                        (uint8_t)(nalSize>>16), (uint8_t)(nalSize>>8), (uint8_t)nalSize};
                    headFrame = [NSMutableData dataWithData:[avData.data subdataWithRange:iRange]];
                    [headFrame replaceBytesInRange:headerRange withBytes:lengthBytes];
                    [self decode:headFrame];
                    
                    break;
                }
            }
        }
        while (_PVRun) {
            @autoreleasepool {
#if RUN_DEBUG
                NSDate *begin = [NSDate date];
                WifiCamAVData *avData = [[SDK instance] getVideoData2];
                NSDate *end = [NSDate date];
                NSTimeInterval elapse = [end timeIntervalSinceDate:begin];
                AppLog(@"[V]Get %lu, elapse: %f", (unsigned long)avData.data.length, elapse);
#else
                WifiCamAVData *avData = [[PanCamSDK instance] getVideoData];
#endif
                if (avData.data.length > 0) {
                    self.curVideoPTS = avData.time;
                    nalSize = (uint32_t)(avData.data.length - 4);
                    const uint8_t lengthBytes[] = {(uint8_t)(nalSize>>24),
                        (uint8_t)(nalSize>>16), (uint8_t)(nalSize>>8), (uint8_t)nalSize};
                    [avData.data replaceBytesInRange:headerRange withBytes:lengthBytes];
                    self.videoPlayFlag = YES;
                    [self decode:avData.data];
                }
            }
        }
        [self clearH264Env];
    }
}

-(void)playbackVideoH264:(shared_ptr<ICatchVideoFormat>) format {
//    NSMutableData *videoFrameData = nil;
#ifdef HW_DECODE_H264
    NSRange headerRange = NSMakeRange(0, 4);
    NSMutableData *headFrame = nil;
    uint32_t nalSize = 0;
#else
    // Decode using FFmpeg
    VideoFrameExtractor *ff_h264_decoder = [[VideoFrameExtractor alloc] initWithSize:format.getVideoW()
                                                                           andHeight:format.getVideoH()];
#endif
    
    while (_PVRun) {
#ifdef HW_DECODE_H264
        if (_readyGoToSetting) {
            AppLog(@"Sleep 1 second.");
            [NSThread sleepForTimeInterval:1.0];
            continue;
        }
        
        //flush avslayer when active from background
        if (self.avslayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
            [self.avslayer flush];
        }
        
        // HW decode
        [self initH264Env:format];
        for(;;) {
            @autoreleasepool {
                // 1st frame contains sps & pps data.
#if RUN_DEBUG
                NSDate *begin = [NSDate date];
                WifiCamAVData *avData = [[SDK instance] getVideoData2];
                NSDate *end = [NSDate date];
                NSTimeInterval elapse = [end timeIntervalSinceDate:begin];
                AppLog(@"[V]Get %lu, elapse: %f", (unsigned long)avData.data.length, elapse);
#else
                WifiCamAVData *avData = [[PanCamSDK instance] getVideoData];
#endif
                if (avData.data.length > 0) {
                    self.curVideoPTS = avData.time;
                    
                    NSUInteger loc = (4+_spsSize)+(4+_ppsSize);
                    nalSize = (uint32_t)(avData.data.length - loc - 4);
                    NSRange iRange = NSMakeRange(loc, avData.data.length - loc);
                    const uint8_t lengthBytes[] = {(uint8_t)(nalSize>>24),
                        (uint8_t)(nalSize>>16), (uint8_t)(nalSize>>8), (uint8_t)nalSize};
                    headFrame = [NSMutableData dataWithData:[avData.data subdataWithRange:iRange]];
                    [headFrame replaceBytesInRange:headerRange withBytes:lengthBytes];
                    [self decodeAndDisplayH264Frame:headFrame];
                    
                    [self recordCurrentVideoFrame:headFrame];
                    break;
                }
            }
        }
        while (_PVRun) {
            @autoreleasepool {
#if RUN_DEBUG
                NSDate *begin = [NSDate date];
                WifiCamAVData *avData = [[SDK instance] getVideoData2];
                NSDate *end = [NSDate date];
                NSTimeInterval elapse = [end timeIntervalSinceDate:begin];
                AppLog(@"[V]Get %lu, elapse: %f", (unsigned long)avData.data.length, elapse);
#else
                WifiCamAVData *avData = [[PanCamSDK instance] getVideoData];
#endif
                if (avData.data.length > 0) {
                    self.curVideoPTS = avData.time;
                    nalSize = (uint32_t)(avData.data.length - 4);
                    const uint8_t lengthBytes[] = {(uint8_t)(nalSize>>24),
                        (uint8_t)(nalSize>>16), (uint8_t)(nalSize>>8), (uint8_t)nalSize};
                    [avData.data replaceBytesInRange:headerRange withBytes:lengthBytes];
                    self.videoPlayFlag = YES;
                    [self decodeAndDisplayH264Frame:avData.data];
                    
                    [self recordCurrentVideoFrame:avData.data];
                }
            }
        }
        
        if (self.currentVideoData.length > 0) {
            [self saveLastVideoFrame:[self imageFromPixelBufferRef:self.currentVideoData]];
        }
        
        [self clearH264Env];
#else
        // Decode using FFmpeg
        videoFrameData = [[SDK instance] getVideoData];
        if (videoFrameData) {
            [ff_h264_decoder fillData:(uint8_t *)videoFrameData.bytes
                                 size:videoFrameData.length];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImage *receivedImage = ff_h264_decoder.currentImage;
                if (_PVRun && receivedImage) {
                    _preview.image = receivedImage;
                }
                
            });
            
        }
#endif
    }
}

-(void)playbackVideoMJPEG {
//    NSMutableData *videoFrameData = nil;
//    UIImage *receivedImage = nil;
    
    while (_PVRun) {
        @autoreleasepool {
            if (_readyGoToSetting) {
                AppLog(@"Sleep 1 second.");
                [NSThread sleepForTimeInterval:1.0];
                continue;
            }
#if RUN_DEBUG
            NSDate *begin = [NSDate date];
            WifiCamAVData *avData = [[SDK instance] getVideoData2];
            NSDate *end = [NSDate date];
            NSTimeInterval elapse = [end timeIntervalSinceDate:begin];
            AppLog(@"[V]Get %lu, elapse: %f", (unsigned long)avData.data.length, elapse);
#else
            WifiCamAVData *avData = [[PanCamSDK instance] getVideoData];
#endif
            if (avData.data.length > 0) {
                self.curVideoPTS = avData.time;
                if (![self dataIsValidJPEG:avData.data]) {
                    AppLog(@"Invalid JPEG.");
                    continue;
                }
                
                UIImage *receivedImage = [[UIImage alloc] initWithData:avData.data];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if (_PVRun && receivedImage) {
                        self.videoPlayFlag = YES;
//                        TRACE();
                        _preview.image = receivedImage;
                    }
                });
                
                //            videoFrameData = nil;
                receivedImage = nil;
            }
        }
    }
}

- (void)playbackVideo {
    
    /*
     dispatch_queue_t mainQueue = dispatch_get_main_queue();
     NSMutableData *videoFrameData = nil;
     UIImage *receivedImage = nil;
     */
    
    auto format = [_ctrl.propCtrl retrieveVideoFormat];
    if (format->getCodec() == ICH_CODEC_JPEG) {
        AppLog(@"playbackVideoMJPEG");
#ifdef HW_DECODE_H264
        dispatch_async(dispatch_get_main_queue(), ^{
            _preview.hidden = NO;
            _avslayer.hidden = YES;
            
            self.glkView.hidden = YES;
            self.paused = YES;
        });
#endif
        [self playbackVideoMJPEG];
        
    } else if (format->getCodec() == ICH_CODEC_H264) {
/*
        int w = format->getVideoW();
        int h = format->getVideoH();
        if (w == 1920 && h == 1080) {
            h = 960;
        }
        float scale = w / h;
        
        //        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        //        BOOL isLive = [defaults boolForKey:@"PreferenceSpecifier:YouTube_Live"] || [defaults boolForKey:@"PreferenceSpecifier:Facebook_Live"];
        
        if (scale == 2 || scale == 0.5) {
            AppLog(@"playbackVideoH264 ---- MobileCamApp");
            dispatch_async(dispatch_get_main_queue(), ^{
                //MobileCamApp
                self.glkView.hidden = NO;
                _preview.hidden = YES;
                _avslayer.hidden = YES;
                [self startGLKAnimation];
                [self configureGyro];
            });
            [self playbackVideoH264];
        } else {
*/
            AppLog(@"playbackVideoH264 ---- SBC");
#ifdef HW_DECODE_H264
            // HW decode
            dispatch_async(dispatch_get_main_queue(), ^{
                _avslayer.hidden = NO;
                _avslayer.bounds = _preview.bounds;
                _avslayer.position = CGPointMake(CGRectGetMidX(_preview.bounds), CGRectGetMidY(_preview.bounds));
                _preview.hidden = YES;
                
                //MobileCamApp
                self.glkView.hidden = YES;
                self.paused = YES;
            });
#endif
            [self playbackVideoH264:format];
            //        }
        } else {
            AppLog(@"Unknown codec.");
        }
        
        AppLog(@"Break video");
    }

- (void)playbackAudio {
    /*
     NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
     NSString *cacheDirectory = [paths objectAtIndex:0];
     NSString *toFilePath = [cacheDirectory stringByAppendingPathComponent:@"test.raw"];
     AppLog(@"TO : %@", toFilePath);
     FILE *toFileHandle = fopen(toFilePath.UTF8String, "wb");
     */
//    NSData *audioBufferData = nil;
//    NSMutableData *audioBuffer3Data = [[NSMutableData alloc] init];
    self.al = [[HYOpenALHelper alloc] init];
    auto format = [_ctrl.propCtrl retrieveAudioFormat];
    
    AppLog(@"freq: %d, chl: %d, bit:%d", format->getFrequency(), format->getNChannels(), format->getSampleBits());
    
    if (![_al initOpenAL:format->getFrequency() channel:format->getNChannels() sampleBit:format->getSampleBits()]) {
        AppLog(@"Init OpenAL failed.");
        return;
    }
    
    while (_PVRun) {
        @autoreleasepool {
            if (_readyGoToSetting || !_AudioRun) {
                [NSThread sleepForTimeInterval:1.0];
                continue;
            }
            
#if RUN_DEBUG
            NSDate *begin = [NSDate date];
            WifiCamAVData *wifiCamData = [[PanCamSDK instance] getAudioData];
            NSDate *end = [NSDate date];
            NSTimeInterval elapse = [end timeIntervalSinceDate:begin];
            AppLog(@"[A]Get %lu, elapse: %f", (unsigned long)wifiCamData.data.length, elapse);
#else
            WifiCamAVData *wifiCamData = [[PanCamSDK instance] getAudioData];
#endif
            
            if (wifiCamData.data.length > 0 && self.videoPlayFlag) {
                [_al insertPCMDataToQueue:wifiCamData.data.bytes
                                     size:wifiCamData.data.length];
                [_al play];
            }
            
            //            if (wifiCamData.time >= _curVideoPTS + 0.1 && _curVideoPTS != 0) {
            //                [NSThread sleepForTimeInterval:0.003];
            //            }
            //            if((wifiCamData.time >= _curVideoPTS - 0.25 && _curVideoPTS != 0) ||
            //               (wifiCamData.time <= _curVideoPTS + 0.25 && _curVideoPTS != 0)) {
            //                [_al play];
            //            } else {
            //                [_al pause];
            //            }
            //        }
            
//                    int count = [_al getInfo];
//                    if(count < 4) {
//                        if (count == 1) {
//                            [_al play];
//                        }
//            
//                        [audioBuffer3Data setLength:0];
//            
//                        for (int i=0; i<3; ++i) {
//            
//                            NSDate *begin = [NSDate date];
//                            WifiCamAVData *wifiCamData = [[SDK instance] getAudioData2];
//                            NSDate *end = [NSDate date];
//                            NSTimeInterval elapse = [end timeIntervalSinceDate:begin];
//                            AppLog(@"[A]Get %lu, elapse: %f", (unsigned long)wifiCamData.data.length, elapse);
//            
//                            if (wifiCamData) {
//                                [audioBuffer3Data appendData:wifiCamData.data];
//                            }
//                        }
//                        
//                        if(audioBuffer3Data.length>0) {
//                            [_al insertPCMDataToQueue:audioBuffer3Data.bytes
//                                                 size:audioBuffer3Data.length];
//                        }
//                    }
        }
    }
    [_al clean];
    self.al = nil;
    /*
     fwrite(audioBufferData.bytes, sizeof(char), audioBufferData.length, toFileHandle);
     fclose(toFileHandle);
     */
    AppLog(@"Break audio");
}

- (IBAction)toggleAudio:(UIButton *)sender {
    [self showProgressHUDWithMessage:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if(![[PanCamSDK instance] openAudio: sender.tag == 0 ? NO : YES]) {
            [self hideProgressHUD:YES];
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (sender.tag == 0) {
                sender.tag = 1;
                [sender setBackgroundImage:[UIImage imageNamed:@"audio_off"]
                                  forState:UIControlStateNormal];
                self.AudioRun = NO;
            } else {
                sender.tag = 0;
                [sender setBackgroundImage:[UIImage imageNamed:@"audio_on"]
                                  forState:UIControlStateNormal];
                self.AudioRun = YES;
            }
            [self hideProgressHUD:YES];
            _camera.enableAudio = self.AudioRun;
        });
    });
}

- (IBAction)captureAction:(id)sender
{
    // Capture
    switch(_camera.previewMode) {
        case WifiCamPreviewModeCameraOff:
            [self stillCapture];
            break;
        case WifiCamPreviewModeVideoOff:
            [self startMovieRec];
            break;
        case WifiCamPreviewModeVideoOn:
            [self stopMovieRec];
            break;
//        case WifiCamPreviewModeCameraOn:
//            break;
        case WifiCamPreviewModeTimelapseOff:
            if (_camera.curTimelapseInterval != 0 && _camera.curTimelapseDuration>0) {
                [self startTimelapseRec];
            } else {
                [self showTimelapseOffAlert];
            }
            break;
        case WifiCamPreviewModeTimelapseOn:
            [self stopTimelapseRec];
            break;
        default:
            break;
    }
}

- (void)showTimelapseOffAlert {
    [self showProgressHUDNotice:NSLocalizedString(@"TimelapseOff", nil) showTime:2.0];
}

- (void)stillCapture {
//    [self showProgressHUDWithMessage:nil];
    if (![self capableOf:WifiCamAbilityNewCaptureWay]) {
        [self showProgressHUDWithMessage:nil];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updatePreviewSceneByMode:WifiCamPreviewModeCameraOn];
        });
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (![_ctrl.propCtrl checkSDExist]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgressHUDNotice:NSLocalizedString(@"NoCard", nil)
                                   showTime:1.0];
                [self updatePreviewSceneByMode:WifiCamPreviewModeCameraOff];
            });
            return;
        }
        if (/*_camera.storageSpaceForImage==0*/![[SDK instance] checkstillCapture] && [_ctrl.propCtrl connected]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgressHUDNotice:NSLocalizedString(@"CARD_FULL", nil)
                                   showTime:1.0];
                [self updatePreviewSceneByMode:WifiCamPreviewModeCameraOff];
            });
            return;
        }
        
        self.burstCaptureCount = [[_staticData.burstNumberDict objectForKey:@(_camera.curBurstNumber)] integerValue];
        NSInteger delayCaptureCount = [[_staticData.delayCaptureDict objectForKey:@(_camera.curCaptureDelay)] integerValue]*2 - 1;
        
        // Stop streaming right now?
        if (// Doesn't support delay-capture, stop right now.
            ![self capableOf:WifiCamAbilityDelayCapture]
            // Support delay-capture, but it's OFF, stop right now.
            || _camera.curCaptureDelay == ICH_CAM_CAP_DELAY_NO
            // Doesn't support ***(stop after delay), stop right now.
            || ![self capableOf:WifiCamAbilityLatestDelayCapture]) {
            
            if (![self capableOf:WifiCamAbilityBurstNumber] || _burstCaptureCount == 0 || _burstCaptureCount > 0) {
                AudioServicesPlaySystemSound(_stillCaptureSound);
            }
            
            if (![self capableOf:WifiCamAbilityNewCaptureWay]) {
                AppLog(@"Stop PV");
                self.PVRun = NO;
                dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
                if (dispatch_semaphore_wait(_previewSemaphore, time) != 0) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self hideProgressHUD:YES];
                        [self showErrorAlertView];
                        [self updatePreviewSceneByMode:WifiCamPreviewModeCameraOff];
                    });
                    return;
                }
            }
        } else {
            AppLog(@"Don't stop right now.");
        }
        
        
        // Capture
        /*stillCaptureDoneListener = new StillCaptureDoneListener(self);
        [_ctrl.comCtrl addObserver:ICATCH_EVENT_CAPTURE_COMPLETE
                          listener:stillCaptureDoneListener
                       isCustomize:NO];*/
        stillCaptureDoneListener = make_shared<WifiCamSDKEventListener>(self, @selector(stopStillCapture));
        [[SDK instance] addObserver:ICH_CAM_EVENT_CAPTURE_COMPLETE listener:stillCaptureDoneListener isCustomize:NO];
        
        if( [self capableOf:WifiCamAbilityLatestDelayCapture] ){
            [_ctrl.actCtrl triggerCapturePhoto];
            
            // Delay-capture sound effect
            if ([self capableOf:WifiCamAbilityDelayCapture] && delayCaptureCount > 0) {
                NSUInteger edgedCount = delayCaptureCount/2;
                
                BOOL isRush = NO;
                while (delayCaptureCount > 0) {
                    AudioServicesPlaySystemSound(_delayCaptureSound);
                    
                    if (delayCaptureCount > edgedCount && !isRush) {
                        [NSThread sleepForTimeInterval:0.5];AppLog(@"sleep 0.5s");
                    } else {
                        if (!isRush) {
                            delayCaptureCount *= 2;
                        }
                        [NSThread sleepForTimeInterval:0.25];AppLog(@"sleep 0.25s");
                        isRush = YES;
                    }
                    --delayCaptureCount;
                }
                
                AppLog(@"Stop streaming ASAP before camera take a picture.");
                AudioServicesPlaySystemSound(_stillCaptureSound);
                
                if ([self capableOf:WifiCamAbilityLatestDelayCapture] && ![self capableOf:WifiCamAbilityNewCaptureWay]) {
                    AppLog(@"Stop PV");
                    self.PVRun = NO;
                    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC);
                    if (dispatch_semaphore_wait(_previewSemaphore, time) != 0) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self hideProgressHUD:YES];
                            [self showErrorAlertView];
                            [self updatePreviewSceneByMode:WifiCamPreviewModeCameraOff];
                        });
                    }
                }
            } else if ([self capableOf:WifiCamAbilityBurstNumber] && _burstCaptureCount > 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.burstCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:/*0.15*/0.75
                                                                            target  :self
                                                                            selector:@selector(burstCaptureTimerCallback:)
                                                                            userInfo:nil
                                                                            repeats :YES];
                });
            }
        } else {
            // use old capture procedure
            [_ctrl.actCtrl capturePhoto];
        }

    });
}

- (void)startMovieRec {
    [self showProgressHUDWithMessage:nil];
    AudioServicesPlaySystemSound(_videoCaptureSound);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (![_ctrl.propCtrl checkSDExist]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgressHUDNotice:NSLocalizedString(@"NoCard", nil)
                                   showTime:1.0];
            });
            return;
        }
        if( [self capableOf:WifiCamAbilityGetVideoFileLength] )
        {
            if( [[SDK instance] retrieveCurrentVideoFileLength] == 0){
                if (_camera.storageSpaceForVideo==0 && [_ctrl.propCtrl connected]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self showProgressHUDNotice:NSLocalizedString(@"CARD_FULL", nil)
                                           showTime:1.0];
                    });
                    return;
                }
            }
        }else{
            if (_camera.storageSpaceForVideo==0 && [_ctrl.propCtrl connected]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showProgressHUDNotice:NSLocalizedString(@"CARD_FULL", nil)
                                       showTime:1.0];
                });
                return;
            }
        }
        
        if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
            AppLog(@"Support to get recorded time!");
            /*videoRecPostTimeListener = new VideoRecPostTimeListener(self);
            [_ctrl.comCtrl addObserver:(ICatchEventID)0x5001
                              listener:videoRecPostTimeListener
                           isCustomize:YES];*/
            videoRecPostTimeListener = make_shared<WifiCamSDKEventListener>(self, @selector(postMovieRecordTime));
            [[SDK instance] addObserver:(ICatchCamEventID)0x5001 listener:videoRecPostTimeListener isCustomize:YES];
        } else {
            AppLog(@"Don't support to get recorded time.");
        }
        
        [NSThread sleepForTimeInterval:0.7]; /// wait for the sound effect to finish playing
        TRACE();
        BOOL ret = [_ctrl.actCtrl startMovieRecord];
        TRACE();
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ret) {
                [self updatePreviewSceneByMode:WifiCamPreviewModeVideoOn];
                [self addMovieRecListener];
                
                //if (![self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
                    if (![_videoCaptureTimer isValid]) {
                        self.videoCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                                target  :self
                                                                                selector:@selector(movieRecordingTimerCallback:)
                                                                                userInfo:nil
                                                                                repeats :YES];
                    }
                //}
                [self hideProgressHUD:YES];
                _Recording = YES;
            } else {
                [self showProgressHUDNotice:@"Failed to begin movie recording." showTime:2.0];
                if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
                    [_ctrl.comCtrl removeObserver:(ICatchCamEventID)0x5001
                                         listener:videoRecPostTimeListener
                                      isCustomize:YES];
                    if (videoRecPostTimeListener) {
                        videoRecPostTimeListener = NULL;
                    }
                }
            }
        });
    });
}

- (void)stopMovieRec
{
    [self showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
            [_ctrl.comCtrl removeObserver:(ICatchCamEventID)0x5001
                                 listener:videoRecPostTimeListener
                              isCustomize:YES];
            if (videoRecPostTimeListener) {
                videoRecPostTimeListener = NULL;
            }
        }
        TRACE();
        BOOL ret = [_ctrl.actCtrl stopMovieRecord];
        TRACE();
        dispatch_async(dispatch_get_main_queue(), ^{
            AudioServicesPlaySystemSound(_videoCaptureSound);
            if (ret) {
//                if (!_Living) {
//                    [self updatePreviewSceneByMode:WifiCamPreviewModeVideoOff];
//                } else {
//                    _camera.previewMode = WifiCamPreviewModeVideoOff;
//                }
                [self updatePreviewSceneByMode:WifiCamPreviewModeVideoOff];
                [self remMovieRecListener];
                if ([_videoCaptureTimer isValid]) {
                    [_videoCaptureTimer invalidate];
                    self.movieRecordElapsedTimeInSeconds = 0;
                }
                [self hideProgressHUD:YES];
                _Recording = NO;
            } else {
                [self showProgressHUDNotice:@"Failed to stop movie recording."
                                   showTime:2.0];
#if 0
                BOOL ret = [_ctrl.actCtrl stopMovieRecord];
                if (ret) {
                    [self updatePreviewSceneByMode:WifiCamPreviewModeVideoOff];
                    [self remMovieRecListener];
                    if ([_videoCaptureTimer isValid]) {
                        [_videoCaptureTimer invalidate];
                        self.movieRecordElapsedTimeInSeconds = 0;
                    }
                    [self hideProgressHUD:YES];
                }
#endif
            }
        });
    });
}

- (void)startTimelapseRec {
    [self showProgressHUDWithMessage:nil];
    AudioServicesPlaySystemSound(_videoCaptureSound);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (![_ctrl.propCtrl checkSDExist]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgressHUDNotice:NSLocalizedString(@"NoCard", nil)
                                   showTime:1.5];
            });
            
            return;
        }
        if ([_ctrl.propCtrl connected]) {
            if (_camera.timelapseType == WifiCamTimelapseTypeStill && _camera.storageSpaceForImage==0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showProgressHUDNotice:NSLocalizedString(@"CARD_FULL", nil)
                                       showTime:1.0];
                });
                return;
            } else if (_camera.timelapseType == WifiCamTimelapseTypeVideo && _camera.storageSpaceForVideo==0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showProgressHUDNotice:NSLocalizedString(@"CARD_FULL", nil)
                                       showTime:1.0];
                });
                return;
            } else {
                
            }
        }
        
        [NSThread sleepForTimeInterval:0.7]; /// wait for the sound effect to finish playing
        BOOL ret = [_ctrl.actCtrl startTimelapseRecord];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (ret) {
                [self updatePreviewSceneByMode:WifiCamPreviewModeTimelapseOn];
                [self addTimelapseRecListener];
                if (![_videoCaptureTimer isValid]) {
                    self.videoCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                            target  :self
                                                                            selector:@selector(movieRecordingTimerCallback:)
                                                                            userInfo:nil
                                                                            repeats :YES];
                }
                [self hideProgressHUD:YES];
            } else {
                [self showProgressHUDNotice:@"Failed to begin time-lapse recording" showTime:2.0];
            }
            
        });
    });
}

- (void)stopTimelapseRec {
    [self showProgressHUDWithMessage:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL ret = [_ctrl.actCtrl stopTimelapseRecord];
        dispatch_async(dispatch_get_main_queue(), ^{
            AudioServicesPlaySystemSound(_videoCaptureSound);
            if (ret) {
                [self remTimelapseRecListener];
                [self hideProgressHUD:YES];
            } else {
                [self showProgressHUDNotice:@"Failed to stop time-lapse recording" showTime:2.0];
            }
            
            if ([_videoCaptureTimer isValid]) {
                [_videoCaptureTimer invalidate];
                self.movieRecordElapsedTimeInSeconds = 0;
            }
            [self updatePreviewSceneByMode:WifiCamPreviewModeTimelapseOff];
        });
    });
}

- (void)movieRecordingTimerCallback:(NSTimer *)sender {
    UIImage *image = nil;
    
    if (_videoCaptureStopOn) {
        self.videoCaptureStopOn = NO;
        image = _stopOn;
    } else {
        self.videoCaptureStopOn = YES;
        image = _stopOff;
    }
    //if (_movieRecordElapsedTimeInSeconds < _camera.storageSpaceForVideo
    //    || _camera.previewMode == WifiCamPreviewModeTimelapseOn) {
        ++self.movieRecordElapsedTimeInSeconds;
    //}
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.snapButton setImage:image forState:UIControlStateNormal];
    });
    
}


- (void)burstCaptureTimerCallback:(NSTimer *)sender {
    AppLog(@"_burstCaptureCount: %lu", (unsigned long)_burstCaptureCount);
    if (self.burstCaptureCount-- <= 0) {
        [sender invalidate];
    } else {
        AppLog(@"burst capture... %lu", (unsigned long)_burstCaptureCount);
        AudioServicesPlaySystemSound(_burstCaptureSound);
    }
}

- (IBAction)showZoomController:(UITapGestureRecognizer *)sender {
    if ([self capableOf:WifiCamAbilityDateStamp] && _camera.curDateStamp != ICH_CAM_DATE_STAMP_OFF) {
        return;
    }
    
    // AIBSP-603
    if ([_ctrl.fileCtrl isBusy]) {
        return;
    }
    if ([self capableOf:WifiCamAbilityZoom] && _zoomSlider.hidden) {
        [self hideZoomController:NO];
        if (![_hideZoomControllerTimer isValid]) {
            _hideZoomControllerTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                        target:self
                                                                      selector:@selector(autoHideZoomController)
                                                                      userInfo:nil
                                                                       repeats:NO];
        }
    } else {
        [self hideZoomController:YES];
    }
}

- (void)hideZoomController: (BOOL)value {
    _zoomSlider.hidden = value;
    _zoomInButton.hidden = value;
    _zoomOutButton.hidden = value;
    _zoomValueLabel.hidden = value;
}

- (void)autoHideZoomController
{
    [self hideZoomController:YES];
}

- (IBAction)zoomCtrlBeenTouched:(id)sender {
    [_hideZoomControllerTimer invalidate];
}

- (IBAction)zoomValueChanged:(id)sender {
    __block BOOL err = NO;
    //[_hideZoomControllerTimer invalidate];
    
    [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        uint curZoomRatio = [_ctrl.propCtrl retrieveCurrentZoomRatio];
        AppLog(@"curZoomRatio: %d", curZoomRatio);
        uint tryCount = 0;
        __block float sliderValue = 0;
        dispatch_sync(dispatch_get_main_queue(), ^{
            sliderValue = self.zoomSlider.value;
        });
        AppLog(@"self.zoomSlider.value: %f", sliderValue);
        if (sliderValue*10.0 > curZoomRatio) {
            while (sliderValue*10.0 > curZoomRatio) {
                AppLog(@"zoomIn:%d", curZoomRatio);
                [_ctrl.actCtrl zoomIn];
                uint r = [_ctrl.propCtrl retrieveCurrentZoomRatio];
                if (r < curZoomRatio) {
                    AppLog(@"r, curZoomRatio: %d, %d", r, curZoomRatio);
                    if (tryCount++ > 20) {
                        err = YES;
                        break;
                    } else {
                        [NSThread sleepForTimeInterval:0.1];
                    }
                } else {
                    curZoomRatio = r;
                }
                dispatch_sync(dispatch_get_main_queue(), ^{
                    sliderValue = self.zoomSlider.value;
                });
            }
        } else if (sliderValue*10.0  < curZoomRatio){
            while (sliderValue*10.0 < curZoomRatio) {
                AppLog(@"zoomOut:%d", curZoomRatio);
                [_ctrl.actCtrl zoomOut];
                uint r = [_ctrl.propCtrl retrieveCurrentZoomRatio];
                if (r > curZoomRatio) {
                    AppLog(@"r, curZoomRatio: %d, %d", r, curZoomRatio);
                    if (tryCount++ > 20) {
                        err = YES;
                        break;
                    } else {
                        [NSThread sleepForTimeInterval:0.1];
                    }
                } else {
                    curZoomRatio = r;
                }
                dispatch_sync(dispatch_get_main_queue(), ^{
                    sliderValue = self.zoomSlider.value;
                });
            }
            
        } else {
            
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (err) {
                UISlider *slider = sender;
                slider.value = curZoomRatio / 10.0;
                [self showProgressHUDNotice:NSLocalizedString(@"Zoom In/Out failed.", nil) showTime:1.0];
            } else {
                _zoomValueLabel.text = [NSString stringWithFormat:@"x%0.1f", curZoomRatio/10.0];
                [self hideProgressHUD:YES];
            }
            
            if (![_hideZoomControllerTimer isValid]) {
                _hideZoomControllerTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                            target:self
                                                                          selector:@selector(autoHideZoomController)
                                                                          userInfo:nil
                                                                           repeats:NO];
            }
        });
    });
    
}

- (IBAction)zoomIn:(id)sender {
    [_hideZoomControllerTimer invalidate];
    
    [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_ctrl.actCtrl zoomIn];
        uint curZoomRatio = [_ctrl.propCtrl retrieveCurrentZoomRatio];
        AppLog(@"curZoomRatio: %d", curZoomRatio);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideProgressHUD:YES];
            [self updateZoomCtrl:curZoomRatio];
        });
    });
    
}

- (IBAction)zoomOut:(id)sender {
    [_hideZoomControllerTimer invalidate];
    
    [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_ctrl.actCtrl zoomOut];
        uint curZoomRatio = [_ctrl.propCtrl retrieveCurrentZoomRatio];
        AppLog(@"curZoomRatio: %d", curZoomRatio);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideProgressHUD:YES];
            [self updateZoomCtrl:curZoomRatio];
        });
    });
}

- (void)updateZoomCtrl: (uint)curZoomRatio {
    self.zoomSlider.value = curZoomRatio/10.0;
    _zoomValueLabel.text = [NSString stringWithFormat:@"x%0.1f", curZoomRatio/10.0];
    
    if (![_hideZoomControllerTimer isValid]) {
        _hideZoomControllerTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                                    target:self
                                                                  selector:@selector(autoHideZoomController)
                                                                  userInfo:nil
                                                                   repeats:NO];
    }
}

- (void)showBusyNotice
{
    NSString *busyInfo = nil;
    
    if (_camera.previewMode == WifiCamPreviewModeCameraOn) {
        busyInfo = @"STREAM_ERROR_CAPTURING";
    } else if (_camera.previewMode == WifiCamPreviewModeVideoOn) {
        busyInfo = @"STREAM_ERROR_RECORDING";
    } else if (_camera.previewMode == WifiCamPreviewModeTimelapseOn) {
        busyInfo = @"STREAM_ERROR_CAPTURING";
    }
    [self showProgressHUDNotice:NSLocalizedString(busyInfo, nil) showTime:2.0];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"goSettingSegue"]) {
        UINavigationController *navVC = [segue destinationViewController];
        SettingViewController *settingVC = (SettingViewController *)navVC.topViewController;
        settingVC.delegate = self;
    }
}

- (IBAction)settingAction:(id)sender {
    TRACE();
    //    dispatch_suspend(_audioQueue);
    //    dispatch_suspend(_videoQueue);
//    if( _camera.previewMode != WifiCamPreviewModeCameraOff &&  _camera.previewMode != WifiCamPreviewModeCameraOn)
    
    BOOL isUseSDKDecode = [[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:UseSDKDecode"];
    if (isUseSDKDecode) {
        self.savedCamera.thumbnail = [[PanCamSDK instance] getPreviewThumbnail];
    }
    
        self.PVRun = NO;

    //[[PanCamSDK instance] destroyStream];

    self.readyGoToSetting = YES;
    [self performSegueWithIdentifier:@"goSettingSegue" sender:sender];
}

-(void)goHome {
    TRACE();
    self.readyGoToSetting = NO;
    //    dispatch_resume(_audioQueue);
    //    dispatch_resume(_videoQueue);
}

- (IBAction)mpbAction:(id)sender
{
    BOOL isUseSDKDecode = [[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:UseSDKDecode"];
    if (isUseSDKDecode) {
        self.savedCamera.thumbnail = [[PanCamSDK instance] getPreviewThumbnail];
    }
    
    [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (![_ctrl.propCtrl checkSDExist]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgressHUDNotice:NSLocalizedString(@"NoCard", nil) showTime:2.0];
            });
            return;
        }
        
        self.PVRun = NO;
        //[[PanCamSDK instance] destroyStream];

        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        if ((dispatch_semaphore_wait(_previewSemaphore, time) != 0)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [self showErrorAlertView];
            });
        } else {
            [[PanCamSDK instance] destroypanCamSDK];

            dispatch_async(dispatch_get_main_queue(), ^{
                dispatch_semaphore_signal(_previewSemaphore);
                [self hideProgressHUD:YES];
#if !USE_NEW_MPB
                [self performSegueWithIdentifier:@"goMpbSegue" sender:sender];
#else
                UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MPBHome" bundle:nil];
                UINavigationController *nav = sb.instantiateInitialViewController;
                [self presentViewController:nav animated:YES completion:nil];
#endif
            });
        }
    });
}

- (IBAction)changeToCameraState:(id)sender {
    
    if (_camera.previewMode == WifiCamPreviewModeCameraOff) {
        return;
    }
    [self showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AudioServicesPlaySystemSound(_changeModeSound);
        self.PVRun = NO;
        _camera.previewMode = WifiCamPreviewModeCameraOff;
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        if (dispatch_semaphore_wait(_previewSemaphore, time) != 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [self showErrorAlertView];
            });
        } else {
            dispatch_semaphore_signal(_previewSemaphore);
            self.PVRun = YES;
            [self runPreview:ICH_CAM_STILL_PREVIEW_MODE];
        }
    });
}

- (IBAction)changeToVideoState:(id)sender {
    if (_camera.previewMode == WifiCamPreviewModeVideoOff) {
        return;
    }
    
    [self showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AudioServicesPlaySystemSound(_changeModeSound);
        self.PVRun = NO;
        _camera.previewMode = WifiCamPreviewModeVideoOff;
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        if (dispatch_semaphore_wait(_previewSemaphore, time) != 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [self showErrorAlertView];
            });
        } else {
            dispatch_semaphore_signal(_previewSemaphore);
            self.PVRun = YES;
            [self runPreview:ICH_CAM_VIDEO_PREVIEW_MODE];
        }
    });
}

- (IBAction)changeToTimelapseState:(UIButton *)sender {
    if (_camera.previewMode == WifiCamPreviewModeTimelapseOff) {
        return;
    }
    
    [self showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AudioServicesPlaySystemSound(_changeModeSound);
        self.PVRun = NO;
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        if (dispatch_semaphore_wait(_previewSemaphore, time) != 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [self showErrorAlertView];
            });
        } else {
            dispatch_semaphore_signal(_previewSemaphore);
            self.PVRun = YES;
            _camera.previewMode = WifiCamPreviewModeTimelapseOff;
//            [self showLiveGUIIfNeeded:_camera.previewMode];
            if (_camera.timelapseType == WifiCamTimelapseTypeVideo) {
                [self runPreview:ICH_CAM_TIMELAPSE_VIDEO_PREVIEW_MODE];
            } else {
                [self runPreview:ICH_CAM_TIMELAPSE_STILL_PREVIEW_MODE];
            }
        }
    });
    
}

- (void)setButtonEnable:(BOOL)value
{
    self.snapButton.enabled = value;
    self.mpbToggle.enabled = value;
    self.settingButton.enabled = value;
    self.cameraToggle.enabled = value;
    self.videoToggle.enabled = value;
    self.timelapseToggle.enabled = value;
    self.sizeButton.enabled = value;
    self.selftimerButton.enabled = value;
}

- (IBAction)changeDelayCaptureTime:(id)sender
{
    [_alertTableArray setArray:_tbDelayCaptureTimeArray.array];
    self.curSettingState = SETTING_DELAY_CAPTURE;
    
    self.customIOS7AlertView = [[CustomIOS7AlertView alloc] initWithTitle:NSLocalizedString(@"ALERT_TITLE_SET_SELF_TIMER", nil)];
    UIView      *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 150)];
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 10, 275, 130)
                                                          style:UITableViewStylePlain];
    [containerView addSubview:tableView];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _customIOS7AlertView.containerView = containerView;
    [_customIOS7AlertView setUseMotionEffects:TRUE];
    [_customIOS7AlertView setButtonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"ALERT_CLOSE", @""), nil]];
    [_customIOS7AlertView show];
}

- (IBAction)changeCaptureSize:(id)sender
{
    NSString *alertTitle = nil;
    
    if (_camera.previewMode == WifiCamPreviewModeCameraOff) {
        alertTitle = NSLocalizedString(@"SetPhotoResolution", @"");
        [_alertTableArray setArray:_tbPhotoSizeArray.array];
        self.curSettingState = SETTING_STILL_CAPTURE;
        
    } else if (_camera.previewMode == WifiCamPreviewModeVideoOff){
        alertTitle = NSLocalizedString(@"ALERT_TITLE_SET_VIDEO_RESOLUTION", @"");
        [_alertTableArray setArray:_tbVideoSizeArray.array];
        self.curSettingState = SETTING_VIDEO_CAPTURE;
        
    } else if (_camera.previewMode == WifiCamPreviewModeTimelapseOff) {
        if (_camera.timelapseType == WifiCamTimelapseTypeStill) {
            alertTitle = NSLocalizedString(@"SetPhotoResolution", @"");
            [_alertTableArray setArray:_tbPhotoSizeArray.array];
            self.curSettingState = SETTING_STILL_CAPTURE;
        } else {
            alertTitle = NSLocalizedString(@"ALERT_TITLE_SET_VIDEO_RESOLUTION", @"");
            [_alertTableArray setArray:_tbVideoSizeArray.array];
            self.curSettingState = SETTING_VIDEO_CAPTURE;
        }
        
    }
    
    self.customIOS7AlertView = [[CustomIOS7AlertView alloc] initWithTitle:alertTitle];
    UIView      *demoView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 150)];
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 10, 275, 130)
                                                          style:UITableViewStylePlain];
    [demoView addSubview:tableView];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [_customIOS7AlertView setContainerView:demoView];
    [_customIOS7AlertView setUseMotionEffects:TRUE];
    [_customIOS7AlertView setButtonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"ALERT_CLOSE", @""), nil]];
    [_customIOS7AlertView show];
}

- (IBAction)changePanoramaType:(id)sender {
    [_alertTableArray setArray:_tbPanoramaTypeArray.array];
    self.curSettingState = SETTING_SPHERE_TYPE;
    
    self.customIOS7AlertView = [[CustomIOS7AlertView alloc] initWithTitle:@"Set Panorama Type"];
    UIView      *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 150)];
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 10, 275, 130)
                                                          style:UITableViewStylePlain];
    [containerView addSubview:tableView];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _customIOS7AlertView.containerView = containerView;
    [_customIOS7AlertView setUseMotionEffects:TRUE];
    [_customIOS7AlertView setButtonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"ALERT_CLOSE", @""), nil]];
    [_customIOS7AlertView show];
}
    
- (void)didReceiveMemoryWarning
{
    AppLog(@"ReceiveMemoryWarning");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations.
    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)showErrorAlertView
{
    AppLog(@"Timeout");
    self.normalAlert = [[UIAlertView alloc] initWithTitle:nil
                                       message           :NSLocalizedString(@"ActionTimeOut.", nil)
                                       delegate          :self
                                       cancelButtonTitle :NSLocalizedString(@"Exit", nil)
                                       otherButtonTitles :nil, nil];
    _normalAlert.tag = APP_RECONNECT_ALERT_TAG;
    [_normalAlert show];
}


- (void)addMovieRecListener
{
    videoRecOffListener = make_shared<VideoRecOffListener>(self);
    [_ctrl.comCtrl addObserver:ICH_CAM_EVENT_VIDEO_OFF
                      listener:videoRecOffListener isCustomize:NO];
    /*sdCardFullListener = make_shared<SDCardFullListener>(self);
    [_ctrl.comCtrl addObserver:ICATCH_EVENT_SDCARD_FULL
                      listener:sdCardFullListener isCustomize:NO];*/
    sdCardFullListener = make_shared<WifiCamSDKEventListener>(self, @selector(sdFull));
    [[SDK instance] addObserver:ICH_CAM_EVENT_SDCARD_FULL listener:sdCardFullListener isCustomize:NO];
    
    
    if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
        [self addObserver:self forKeyPath:@"movieRecordElapsedTimeInSeconds"
                  options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)remMovieRecListener
{
    [_ctrl.comCtrl removeObserver:ICH_CAM_EVENT_VIDEO_OFF
                         listener:videoRecOffListener
                      isCustomize:NO];
    if (videoRecOffListener) {
        videoRecOffListener = NULL;
    }
    [_ctrl.comCtrl removeObserver:ICH_CAM_EVENT_SDCARD_FULL
                         listener:sdCardFullListener isCustomize:NO];
    if (sdCardFullListener) {
        sdCardFullListener = NULL;
    }
    
    if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
//        [self removeObserver:self forKeyPath:@"movieRecordElapsedTimeInSeconds"];
        if (self.observationInfo) {
            @try{
                [self removeObserver:self forKeyPath:@"movieRecordElapsedTimeInSeconds"];
            }@catch (NSException *exception) {}
        }
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"movieRecordElapsedTimeInSeconds"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUInteger sec = [[change objectForKey:NSKeyValueChangeNewKey] unsignedIntegerValue];
            self.movieRecordTimerLabel.text = [Tool translateSecsToString:sec];
        });
    }
}

- (void)addTimelapseRecListener
{
    /*timelapseStopListener = new TimelapseStopListener(self);
    timelapseCaptureStartedListener = new TimelapseCaptureStartedListener(self);
    timelapseCaptureCompleteListener = new TimelapseCaptureCompleteListener(self);
    sdCardFullListener = new SDCardFullListener(self);
    
    [_ctrl.comCtrl addObserver:ICATCH_EVENT_TIMELAPSE_STOP
                      listener:timelapseStopListener isCustomize:NO];
    [_ctrl.comCtrl addObserver:ICATCH_EVENT_CAPTURE_START
                      listener:timelapseCaptureStartedListener isCustomize:NO];
    [_ctrl.comCtrl addObserver:ICATCH_EVENT_CAPTURE_COMPLETE
                      listener:timelapseCaptureCompleteListener isCustomize:NO];
    [_ctrl.comCtrl addObserver:ICATCH_EVENT_SDCARD_FULL
                      listener:sdCardFullListener isCustomize:NO];*/
    
    timelapseStopListener = make_shared<WifiCamSDKEventListener>(self, @selector(stopTimelapse));
    [[SDK instance] addObserver:ICH_CAM_EVENT_TIMELAPSE_STOP listener:timelapseStopListener isCustomize:NO];
    timelapseCaptureStartedListener = make_shared<WifiCamSDKEventListener>(self, @selector(timelapseStartedNotice));
    [[SDK instance] addObserver:ICH_CAM_EVENT_CAPTURE_START listener:timelapseCaptureStartedListener isCustomize:NO];
    timelapseCaptureCompleteListener = make_shared<WifiCamSDKEventListener>(self, @selector(timelapseCompletedNotice));
    [[SDK instance] addObserver:ICH_CAM_EVENT_CAPTURE_COMPLETE listener:timelapseCaptureCompleteListener isCustomize:NO];
    sdCardFullListener = make_shared<WifiCamSDKEventListener>(self, @selector(sdFull));
    [[SDK instance] addObserver:ICH_CAM_EVENT_SDCARD_FULL listener:sdCardFullListener isCustomize:NO];
    
    if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
        [self addObserver:self forKeyPath:@"movieRecordElapsedTimeInSeconds"
                  options:NSKeyValueObservingOptionNew context:nil];
        
    }
}

- (void)remTimelapseRecListener
{
    [_ctrl.comCtrl removeObserver:ICH_CAM_EVENT_TIMELAPSE_STOP
                         listener:timelapseStopListener isCustomize:NO];
    [_ctrl.comCtrl removeObserver:ICH_CAM_EVENT_CAPTURE_START
                         listener:timelapseCaptureStartedListener isCustomize:NO];
    [_ctrl.comCtrl removeObserver:ICH_CAM_EVENT_CAPTURE_COMPLETE
                         listener:timelapseCaptureCompleteListener isCustomize:NO];
    [_ctrl.comCtrl removeObserver:ICH_CAM_EVENT_SDCARD_FULL
                         listener:sdCardFullListener isCustomize:NO];
    
    if (timelapseStopListener) {
        timelapseStopListener = NULL;
    }
    if (timelapseCaptureStartedListener) {
        timelapseCaptureStartedListener = NULL;
    }
    if (timelapseCaptureCompleteListener) {
        timelapseCaptureCompleteListener = NULL;
    }
    if (sdCardFullListener) {
        sdCardFullListener = NULL;
    }
    if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
//        [self removeObserver:self forKeyPath:@"movieRecordElapsedTimeInSeconds"];
        if (self.observationInfo) {
            @try{
                [self removeObserver:self forKeyPath:@"movieRecordElapsedTimeInSeconds"];
            }@catch (NSException *exception) {}
        }
    }
}

- (IBAction)returnBackToHome:(id)sender {
    BOOL isUseSDKDecode = [[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:UseSDKDecode"];
    if (isUseSDKDecode) {
        self.savedCamera.thumbnail = [[PanCamSDK instance] getPreviewThumbnail];
    }
    
    [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
    self.PVRun = NO;
    [self stopGLKAnimation];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        if ((dispatch_semaphore_wait(_previewSemaphore, time) != 0)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [self showErrorAlertView];
            });
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                dispatch_semaphore_signal(_previewSemaphore);
                [self hideProgressHUD:YES];
                //[self.navigationController popToRootViewControllerAnimated:YES];
                [self.view.window.rootViewController dismissViewControllerAnimated:YES completion: ^{
                    [[SDK instance] destroySDK];
                    
                    [EAGLContext setCurrentContext:self.context];
                    
                    [[PanCamSDK instance] destroypanCamSDK];
                    
                    if ([EAGLContext currentContext] == self.context) {
                        [EAGLContext setCurrentContext:nil];
                    }
                }];
//                [self dismissViewControllerAnimated:YES completion:^{
//                    [[SDK instance] destroySDK];
//                }];
            });
        }
    });
}

- (void)selectDelayCaptureTimeAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row != _tbDelayCaptureTimeArray.lastIndex) {
        
        [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            _tbDelayCaptureTimeArray.lastIndex = indexPath.row;
            
            unsigned int curCaptureDelay = [_ctrl.propCtrl parseDelayCaptureInArray:indexPath.row];
            /*
             if (curCaptureDelay != CAP_DELAY_NO) {
             // Disable burst capture
             _camera.curBurstNumber = BURST_NUMBER_OFF;
             [_ctrl.propCtrl changeBurstNumber:BURST_NUMBER_OFF];
             }
             */
            
            [_ctrl.propCtrl changeDelayedCaptureTime:curCaptureDelay];
            //_camera.curCaptureDelay = curCaptureDelay;
            
            // Re-Get
            //_camera.curBurstNumber = [_ctrl.propCtrl retrieveBurstNumber];
            //_camera.curTimelapseInterval = [_ctrl.propCtrl retrieveCurrentTimelapseInterval];
            [_ctrl.propCtrl updateAllProperty:_camera];
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [self.selftimerLabel setText:[_staticData.captureDelayDict objectForKey:@(curCaptureDelay)]];
                [self updateBurstCaptureIcon:_camera.curBurstNumber];
                
            });
            
        });
    }
}

- (void)selectImageSizeAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row != _tbPhotoSizeArray.lastIndex) {
        
        //self.PVRun = NO;
        [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            /*
             dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
             if ((dispatch_semaphore_wait(_previewSemaphore, time) != 0)) {
             dispatch_async(dispatch_get_main_queue(), ^{
             [self hideProgressHUD:YES];
             [self showErrorAlertView];
             });
             
             } else {
             */
            
            _tbPhotoSizeArray.lastIndex = indexPath.row;
            string curImageSize = [_ctrl.propCtrl parseImageSizeInArray:indexPath.row];
            
            [_ctrl.propCtrl changeImageSize:curImageSize];
            //_camera.curImageSize = curImageSize;
            
            [_ctrl.propCtrl updateAllProperty:_camera];
            
            //dispatch_semaphore_signal(_previewSemaphore);
            //self.PVRun = YES;
            //[self runPreview:ICATCH_STILL_PREVIEW_MODE];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [self updateImageSizeOnScreen:curImageSize];
                
            });
            //}
        });
        
        
        /*
         _tbPhotoSizeArray.lastIndex = indexPath.row;
         
         string curImageSize = [_ctrl.propCtrl parseImageSizeInArray:indexPath.row];
         _camera.curImageSize = curImageSize;
         [_ctrl.propCtrl changeImageSize:curImageSize];
         [self updateImageSizeOnScreen:curImageSize];
         */
    }
}

- (void)selectVideoSizeAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row != _tbVideoSizeArray.lastIndex) {
        [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if ([_ctrl.propCtrl isSupportMethod2ChangeVideoSize]) {
                AppLog(@"New Method");
                self.PVRun = NO;
                
                dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
                if ((dispatch_semaphore_wait(_previewSemaphore, time) != 0)) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self hideProgressHUD:YES];
                        [self showErrorAlertView];
                    });
                    
                } else {
                    _tbVideoSizeArray.lastIndex = indexPath.row;
                    string curVideoSize = "";
                    if( _camera.previewMode == WifiCamPreviewModeTimelapseOff || _camera.previewMode == WifiCamPreviewModeTimelapseOn)
                        curVideoSize = [_ctrl.propCtrl parseTimeLapseVideoSizeInArray:indexPath.row];
                    else
                        curVideoSize = [_ctrl.propCtrl parseVideoSizeInArray:indexPath.row];
                    //string curVideoSize = [_ctrl.propCtrl parseVideoSizeInArray:indexPath.row];
                    
                    
                    [_ctrl.propCtrl changeVideoSize:curVideoSize];
                    [_ctrl.propCtrl updateAllProperty:_camera];
                    
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _noPreviewLabel.hidden = YES;
                        [self updateVideoSizeOnScreen:curVideoSize];
                        //                        [self hideProgressHUD:YES];
                        _preview.userInteractionEnabled = YES;
#ifdef HW_DECODE_H264
                        _h264View.userInteractionEnabled = YES;
#endif
                    });
                    
                    
                    // Is support Slow-Motion under this video size?
                    // Update the Slow-Motion icon
                    if ([self capableOf:WifiCamAbilitySlowMotion]
                        && _camera.previewMode == WifiCamPreviewModeVideoOff) {
                        
                        _camera.curSlowMotion = [_ctrl.propCtrl retrieveCurrentSlowMotion];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (_camera.curSlowMotion == 1) {
                                self.slowMotionStateImageView.hidden = NO;
                            } else {
                                self.slowMotionStateImageView.hidden = YES;
                            }
                        });
                    }
                    
                    self.PVRun = YES;
                    dispatch_semaphore_signal(_previewSemaphore);
                    
                    if( _camera.previewMode == WifiCamPreviewModeTimelapseOff || _camera.previewMode == WifiCamPreviewModeTimelapseOn){
                        if (_camera.timelapseType == WifiCamTimelapseTypeVideo) {
                            if( [_ctrl.propCtrl changeTimelapseType:ICH_CAM_TIMELAPSE_VIDEO_PREVIEW_MODE] == WCRetSuccess)
                                AppLog(@"change to ICATCH_TIMELAPSE_VIDEO_PREVIEW_MODE success");
                            [self runPreview:ICH_CAM_TIMELAPSE_VIDEO_PREVIEW_MODE];
                        } else {
                            if( [_ctrl.propCtrl changeTimelapseType:ICH_CAM_TIMELAPSE_STILL_PREVIEW_MODE]== WCRetSuccess)
                                AppLog(@"change to ICATCH_TIMELAPSE_STILL_PREVIEW_MODE success");
                            [self runPreview:ICH_CAM_TIMELAPSE_STILL_PREVIEW_MODE];
                        }
                    }
                    else
                        [self runPreview:ICH_CAM_VIDEO_PREVIEW_MODE];
                    
                }
            } else {
                AppLog(@"Old Method");
                
                _tbVideoSizeArray.lastIndex = indexPath.row;
                string curVideoSize;
                if( _camera.previewMode == WifiCamPreviewModeTimelapseOff || _camera.previewMode == WifiCamPreviewModeTimelapseOn)
                    curVideoSize = [_ctrl.propCtrl parseTimeLapseVideoSizeInArray:indexPath.row];
                else
                    curVideoSize = [_ctrl.propCtrl parseVideoSizeInArray:indexPath.row];
                
                [_ctrl.propCtrl changeVideoSize:curVideoSize];
                [_ctrl.propCtrl updateAllProperty:_camera];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideProgressHUD:YES];
                    [self updateVideoSizeOnScreen:curVideoSize];
                });
            }
            
        });
        
    }
}

- (void)selectPanoramaTypeAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row != _tbPanoramaTypeArray.lastIndex) {
        [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#if 0
            AppLog(@"New Method");
            self.PVRun = NO;
            
            dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
            if ((dispatch_semaphore_wait(_previewSemaphore, time) != 0)) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideProgressHUD:YES];
                    [self showErrorAlertView];
                });
                
            } else {
                [[PanCamSDK instance] destroyStream];
                _tbPanoramaTypeArray.lastIndex = indexPath.row;
                
                RenderType renderType = RenderType_Disable;
                if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:UseSDKDecode"]) {
                    renderType = RenderType_AutoSelect;
                }
                
                int panoramaType = 0;
                switch (_tbPanoramaTypeArray.lastIndex) {
                    case 0:
                        panoramaType = ICH_GL_PANORAMA_TYPE_SPHERE;
                        break;
                        
                    case 1:
                        panoramaType = ICH_GL_PANORAMA_TYPE_ASTEROID;
                        break;
                        
                    case 2:
                        panoramaType = ICH_GL_PANORAMA_TYPE_VIRTUAL_R;
                        break;
                        
                    default:
                        break;
                }
                
                [[PanCamSDK instance] initStreamWithRenderType:renderType isPreview:YES file:nil panoramaType:panoramaType];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    _noPreviewLabel.hidden = YES;
                    [self updatePanoramaTyprOnScreen];
                    //                        [self hideProgressHUD:YES];
                    _preview.userInteractionEnabled = YES;
#ifdef HW_DECODE_H264
                    _h264View.userInteractionEnabled = YES;
#endif
                });
                
                self.PVRun = YES;
                dispatch_semaphore_signal(_previewSemaphore);
                
                switch (_camera.previewMode) {
                    case WifiCamPreviewModeCameraOff:
                    case WifiCamPreviewModeCameraOn:
                        [self runPreview:ICH_CAM_STILL_PREVIEW_MODE];
                        break;
                        
                    case WifiCamPreviewModeTimelapseOff:
                    case WifiCamPreviewModeTimelapseOn:
                        if (_camera.timelapseType == WifiCamTimelapseTypeVideo) {
                            // mark by allen.chuang 2015.1.15 ICOM-2692
                            //if( [_ctrl.propCtrl changeTimelapseType:ICATCH_TIMELAPSE_VIDEO_PREVIEW_MODE] == WCRetSuccess)
                            //    AppLog(@"change to ICATCH_TIMELAPSE_VIDEO_PREVIEW_MODE success");
                            [self runPreview:ICH_CAM_TIMELAPSE_VIDEO_PREVIEW_MODE];
                        } else {
                            // mark by allen.chuang 2015.1.15 ICOM-2692
                            //if( [_ctrl.propCtrl changeTimelapseType:ICATCH_TIMELAPSE_STILL_PREVIEW_MODE] == WCRetSuccess)
                            //    AppLog(@"change to ICATCH_TIMELAPSE_STILL_PREVIEW_MODE success");
                            [self runPreview:ICH_CAM_TIMELAPSE_STILL_PREVIEW_MODE];
                        }
                        
                        break;
                        
                    case WifiCamPreviewModeVideoOff:
                    case WifiCamPreviewModeVideoOn:
                        [self runPreview:ICH_CAM_VIDEO_PREVIEW_MODE];
                        
                        break;
                        
                    default:
                        break;
                }
            }
#else
            BOOL isSuccess = [self changePanoramaTypeWithIndex:indexPath.row];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (isSuccess) {
                    _tbPanoramaTypeArray.lastIndex = indexPath.row;
                    
                    [self hideProgressHUD:YES];
                    [self updatePanoramaTyprOnScreen];
                } else {
                    [self showProgressHUDNotice:@"changePanoramaType failed." showTime:2.0];
                }
            });
#endif
        });
    }
}
    
- (BOOL)changePanoramaTypeWithIndex:(NSInteger)index {
    int panoramaType = 0;
    
    switch (index) {
        case 0:
            panoramaType = ICH_GL_PANORAMA_TYPE_SPHERE;
            break;
            
        case 1:
            panoramaType = ICH_GL_PANORAMA_TYPE_ASTEROID;
            break;
            
        case 2:
            panoramaType = ICH_GL_PANORAMA_TYPE_VIRTUAL_R;
            break;
            
        default:
            break;
    }
    
    return  [[PanCamSDK instance] changePanoramaType:panoramaType isStream:YES];
}
    
-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                        duration:(NSTimeInterval)duration {
    
    if (!_avslayer.hidden) {
        self.avslayer.bounds = _preview.bounds;
        self.avslayer.position = CGPointMake(CGRectGetMidX(_preview.bounds), CGRectGetMidY(_preview.bounds));
        
        [self showLiveGUIIfNeeded:_camera.previewMode];
    }
    
    _notificationView.center = CGPointMake(self.view.bounds.size.width / 2, 15);

    /*
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            AppLog(@"rotate to left/right");
            //            self.navigationController.navigationBarHidden = YES;
            //            self.preview.contentMode = UIViewContentModeScaleAspectFill;
            
            break;
            
        default:
            AppLog(@"rotate to portrait");
            //            self.navigationController.navigationBarHidden = NO;
            //            self.preview.contentMode = UIViewContentModeScaleAspectFit;
            break;
    }
    */
}

//-(BOOL)prefersStatusBarHidden {
//    if (self.view.frame.size.width < self.view.frame.size.height) {
//        return NO;
//    } else {
//        return YES;
//    }
//}

-(void)removeObservers {
    if ([self capableOf:WifiCamAbilityBatteryLevel] && batteryLevelListener) {
        [_ctrl.comCtrl removeObserver:ICH_CAM_EVENT_BATTERY_LEVEL_CHANGED
                             listener:batteryLevelListener
                          isCustomize:NO];
        batteryLevelListener = NULL;
    }
    if ([self capableOf:WifiCamAbilityMovieRecord] && videoRecOnListener) {
        [_ctrl.comCtrl removeObserver:ICH_CAM_EVENT_VIDEO_ON
                             listener:videoRecOnListener
                          isCustomize:NO];
        videoRecOnListener = NULL;
    }
    
    if (_camera.enableAutoDownload && fileDownloadListener) {
        [_ctrl.comCtrl removeObserver:ICH_CAM_EVENT_FILE_DOWNLOAD
                             listener:fileDownloadListener
                          isCustomize:NO];
        fileDownloadListener = NULL;
    }
}

// MARK: - ICatchWificamListener

- (void)updateMovieRecState:(MovieRecState)state
{
    if (state == MovieRecStoped) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //            [self remMovieRecListener];
            [_ctrl.comCtrl removeObserver:ICH_CAM_EVENT_VIDEO_OFF
                                 listener:videoRecOffListener
                              isCustomize:NO];
            if (videoRecOffListener) {
                videoRecOffListener = NULL;
            }
            
            if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
//                [self removeObserver:self forKeyPath:@"movieRecordElapsedTimeInSeconds"];
                if (self.observationInfo) {
                    @try{
                        [self removeObserver:self forKeyPath:@"movieRecordElapsedTimeInSeconds"];
                    }@catch (NSException *exception) {}
                }
            }
            // Mark by Allen.Chuang 2015.1.28 ICOM-2754 , camera will stop record by itself.
            //[_ctrl.actCtrl stopMovieRecord];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updatePreviewSceneByMode:WifiCamPreviewModeVideoOff];
                
                if ([_videoCaptureTimer isValid]) {
                    [_videoCaptureTimer invalidate];
                    self.movieRecordElapsedTimeInSeconds = 0;
                }
            });
        });
    } else if (state == MovieRecStarted) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_ctrl.actCtrl startMovieRecord];
            [self addMovieRecListener];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updatePreviewSceneByMode:WifiCamPreviewModeVideoOn];
                
                if (![_videoCaptureTimer isValid]) {
                    self.videoCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                            target  :self
                                                                            selector:@selector(movieRecordingTimerCallback:)
                                                                            userInfo:nil
                                                                            repeats :YES];
                }
            });
            
        });
    }
}

- (void)updateBatteryLevel
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![_ctrl.propCtrl connected]) {
            return;
        }
        
        NSString *imagePath = [_ctrl.propCtrl prepareDataForBatteryLevel];
        UIImage *batteryStatusImage = [UIImage imageNamed:imagePath];
        [self.batteryState setImage:batteryStatusImage];
        
        if ([imagePath isEqualToString:@"battery_0"] && !_batteryLowAlertShowed) {
            self.batteryLowAlertShowed = YES;
            [self showProgressHUDNotice:NSLocalizedString(@"ALERT_LOW_BATTERY", nil) showTime:2.0];
            
        } else if ([imagePath isEqualToString:@"battery_4"]) {
            self.batteryLowAlertShowed = NO;
        }
    });
}

- (void)stopStillCapture
{
    TRACE();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_ctrl.comCtrl removeObserver:ICH_CAM_EVENT_CAPTURE_COMPLETE
                             listener:stillCaptureDoneListener
                          isCustomize:NO];
        if (stillCaptureDoneListener) {
            stillCaptureDoneListener = NULL;
        }
        if( ! [self capableOf:WifiCamAbilityLatestDelayCapture] ){
            AppLog(@"wait 1 second");
            [NSThread sleepForTimeInterval:1]; // old method must slow start media stream
        }
        _camera.previewMode = WifiCamPreviewModeCameraOff;
        
//        self.PVRun = YES;
//        dispatch_semaphore_signal(_previewSemaphore);
//        [self runPreview:ICH_CAM_STILL_PREVIEW_MODE];

        if (![self capableOf:WifiCamAbilityNewCaptureWay]) {
            dispatch_semaphore_signal(_previewSemaphore);
            self.PVRun = YES;
            [self runPreview:ICH_CAM_STILL_PREVIEW_MODE];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updatePreviewSceneByMode:_camera.previewMode];
            });
        }
    });
}

- (void)stopTimelapse
{
    BOOL ret = [_ctrl.actCtrl stopTimelapseRecord];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (ret) {
            [self remTimelapseRecListener];
        }
        
        if ([_videoCaptureTimer isValid]) {
            [_videoCaptureTimer invalidate];
            self.movieRecordElapsedTimeInSeconds = 0;
        }
        [self updatePreviewSceneByMode:WifiCamPreviewModeTimelapseOff];
    });
}

- (void)timelapseStartedNotice {
    AudioServicesPlaySystemSound(_burstCaptureSound);
}

- (void)timelapseCompletedNotice
{
    
    /*
     dispatch_async(dispatch_get_main_queue(), ^{
     [self showProgressHUDCompleteMessage:NSLocalizedString(@"Done", nil)];
     });
     */
}

- (void)postMovieRecordTime
{
    TRACE();
    self.movieRecordElapsedTimeInSeconds = 0;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![_videoCaptureTimer isValid]) {
            self.videoCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                    target  :self
                                                                    selector:@selector(movieRecordingTimerCallback:)
                                                                    userInfo:nil
                                                                    repeats :YES];
        }
        
        [self hideProgressHUD:YES];
    });
    
    
}

- (void)postMovieRecordFileAddedEvent
{
    self.movieRecordElapsedTimeInSeconds = 0;
}

- (void)postFileDownloadEvent:(shared_ptr<ICatchFile>)file {
    TRACE();
    printf("filePath: %s\n", file->getFilePath().c_str());
    printf("fileName: %s\n", file->getFileName().c_str());
    printf("fileDate: %s\n", file->getFileDate().c_str());
    printf("fileType: %d\n", file->getFileType());
    printf("fileSize: %llu\n", file->getFileSize());
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showProgressHUDWithMessage:nil];
    });
    
    shared_ptr<ICatchFile> f = make_shared<ICatchFile>(file->getFileHandle(), file->getFileType(), file->getFilePath(), file->getFileSize());
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_ctrl.fileCtrl downloadFile:f];
        UIImage *image = [_ctrl.actCtrl getAutoDownloadImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.autoDownloadThumbImage.image = image;
            self.autoDownloadThumbImage.hidden = NO;
            [self hideProgressHUD:YES];
        });
    });
}

-(void)sdFull {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [_ctrl.comCtrl removeObserver:ICH_CAM_EVENT_SDCARD_FULL
                             listener:sdCardFullListener isCustomize:NO];
        if (sdCardFullListener) {
            sdCardFullListener = NULL;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showProgressHUDNotice:NSLocalizedString(@"CARD_FULL", nil)
                               showTime:1.5];
            
        });
    });
}

#pragma mark - WifiCamSDKEventListener
-(void)streamCloseCallback {
    self.PVRun = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showProgressHUDNotice:@"Streaming is stopped unexpected." showTime:2.0];
    });
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return _alertTableArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:nil];
    [cell.textLabel setText:[_alertTableArray objectAtIndex:indexPath.row]];
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (_curSettingState) {
        case SETTING_DELAY_CAPTURE:
            [self selectDelayCaptureTimeAtIndexPath:indexPath];
            break;
            
        case SETTING_STILL_CAPTURE:
            [self selectImageSizeAtIndexPath:indexPath];
            break;
            
        case SETTING_VIDEO_CAPTURE:
            [self selectVideoSizeAtIndexPath:indexPath];
            break;
            
        case SETTING_SPHERE_TYPE:
            [self selectPanoramaTypeAtIndexPath:indexPath];
            break;
            
        default:
            break;
    }
    
    [_customIOS7AlertView close];
}

- (void)tableView         :(UITableView *)tableView
        willDisplayCell   :(UITableViewCell *)cell
        forRowAtIndexPath :(NSIndexPath *)indexPath
{
    NSInteger lastIndex = 0;
    
    switch (_curSettingState) {
        case SETTING_DELAY_CAPTURE:
            lastIndex = _tbDelayCaptureTimeArray.lastIndex;
            break;
            
        case SETTING_STILL_CAPTURE:
            lastIndex = _tbPhotoSizeArray.lastIndex;
            break;
            
        case SETTING_VIDEO_CAPTURE:
            lastIndex = _tbVideoSizeArray.lastIndex;
            break;
            
        case SETTING_SPHERE_TYPE:
            lastIndex = _tbPanoramaTypeArray.lastIndex;
            break;
            
        default:
            break;
    }
    
    if (indexPath.row == lastIndex) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case APP_RECONNECT_ALERT_TAG:
            [self dismissViewControllerAnimated:YES completion:^{}];
            //exit(0);
            break;
        default:
            break;
    }
}


#pragma mark - AppDelegateProtocol
-(void)cleanContext {
    [self removeObservers];
    self.PVRun = NO;
    [self stopGLKAnimation];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        if ((dispatch_semaphore_wait(_previewSemaphore, time) != 0)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [self showErrorAlertView];
            });
            
        } else {
            dispatch_async([[SDK instance] sdkQueue], ^{
                dispatch_semaphore_signal(_previewSemaphore);
                [[SDK instance] destroySDK];
                
                [EAGLContext setCurrentContext:self.context];
                
                [[PanCamSDK instance] destroypanCamSDK];
                
                if ([EAGLContext currentContext] == self.context) {
                    [EAGLContext setCurrentContext:nil];
                }
                
                self.navigationController.interactivePopGestureRecognizer.enabled = NO ;
            });
        }
    });
}

-(void)applicationDidEnterBackground:(UIApplication *)application {
    [self removeObservers];
    self.PVRun = NO;
    [self stopGLKAnimation];
    
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        if ((dispatch_semaphore_wait(_previewSemaphore, time) != 0)) {
            AppLog(@"Timeout!");
        } else {
            dispatch_async([[SDK instance] sdkQueue], ^{
                dispatch_semaphore_signal(_previewSemaphore);
                [[SDK instance] destroySDK];
                
                [EAGLContext setCurrentContext:self.context];
                
                [[PanCamSDK instance] destroypanCamSDK];
                
                if ([EAGLContext currentContext] == self.context) {
                    [EAGLContext setCurrentContext:nil];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.navigationController.interactivePopGestureRecognizer.enabled = NO ;
                });
            });
        }
    });
}
//-(void)applicationDidEnterBackground:(UIApplication *)application {
//    [self removeObservers];
//    self.PVRun = NO;
//    [self stopGLKAnimation];
//    
//    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
//    dispatch_async(dispatch_get_main_queue(), ^{
//        if ((dispatch_semaphore_wait(_previewSemaphore, time) != 0)) {
//            AppLog(@"Timeout!");
//            
//        } else {
//            dispatch_semaphore_signal(_previewSemaphore);
//            [[SDK instance] destroySDK];
//            
//            [EAGLContext setCurrentContext:self.context];
//            
//            [[PanCamSDK instance] destroypanCamSDK];
//            
//            if ([EAGLContext currentContext] == self.context) {
//                [EAGLContext setCurrentContext:nil];
//            }
//        }
//    });
//}

-(NSString *)notifyConnectionBroken {
    switch(_camera.previewMode) {
        case WifiCamPreviewModeVideoOn: {
            if ([self capableOf:WifiCamAbilityGetMovieRecordedTime]) {
                [_ctrl.comCtrl removeObserver:(ICatchCamEventID)0x5001
                                     listener:videoRecPostTimeListener
                                  isCustomize:YES];
                if (videoRecPostTimeListener) {
                    videoRecPostTimeListener = NULL;
                }
            }
            [self remMovieRecListener];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([_videoCaptureTimer isValid]) {
                    [_videoCaptureTimer invalidate];
                    self.movieRecordElapsedTimeInSeconds = 0;
                }
                [self updatePreviewSceneByMode:WifiCamPreviewModeVideoOff];
            });
        }
            break;
        case WifiCamPreviewModeTimelapseOn: {
            [self remTimelapseRecListener];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([_videoCaptureTimer isValid]) {
                    [_videoCaptureTimer invalidate];
                    self.movieRecordElapsedTimeInSeconds = 0;
                }
                [self updatePreviewSceneByMode:WifiCamPreviewModeTimelapseOff];
            });
        }
            
            break;
        default:
            break;
    }
    
    [self cleanContext];
    return self.savedCamera.wifi_ssid;
}

- (void)sdcardRemoveCallback{
    _isSDcardRemoved = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showProgressHUDNotice:NSLocalizedString(@"CARD_REMOVED", nil) showTime:2.0];
        [self updatePreviewSceneByMode:_camera.previewMode];
    });
}

- (void)sdcardInCallback {
    _isSDcardRemoved = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showProgressHUDNotice:NSLocalizedString(@"CARD_INSERTED", nil) showTime:2.0];
        [self updatePreviewSceneByMode:_camera.previewMode];
    });
}
    
#if 0
#pragma mark - YouTube live
- (IBAction)liveSwitchClink:(id)sender {
    if (!_liveQueue) {
        _liveQueue = dispatch_queue_create("WifiCam.GCD.Queue.YoutubeLive", DISPATCH_QUEUE_SERIAL);
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UISwitch *live = (UISwitch *)sender;
        
        if ([live isOn]) {
            if (_Living) {
                return;
            }
            AppLog(@"start YouTube Live ...");
            
            if ([[PanCamSDK instance] isStreamSupportPublish] == ICH_SUCCEED) {
                NSString *liveBroadcast = [[NSUserDefaults standardUserDefaults] stringForKey:@"PreferenceSpecifier:LiveBroadcast"];
                AppLog(@"LiveBroadcast: %@", liveBroadcast);
                
                if ([liveBroadcast isEqualToString:@"立即直播"]) {
                    [self startYoutubeLive];
                } else {
                    if (_accessToken) {
                        [self createLiveChannel];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            _Living = YES;
                            [self setToVideoOnScene];
                        });
                    } else {
                        SignInViewController *masterViewController = [[SignInViewController alloc] initWithNibName:@"SignInViewController" bundle:nil];
                        
//                        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:masterViewController];
//                        nc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            _Living = YES;
                            [self setToVideoOnScene];
//                            [self presentViewController:nc animated:YES completion:nil];
                            [self.navigationController pushViewController:masterViewController animated:YES];
                        });
                    }
                }
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:@"The current video format not supported live function." delegate:self cancelButtonTitle:NSLocalizedString(@"Sure", nil) otherButtonTitles:nil, nil];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [alert show];
                    _liveSwitch_YouTube.on = NO;
                });
            }
        } else {
            if (!_Living) {
                return;
            }
            AppLog(@"stop  YouTube Live ...");
            [self stopYoutubeLive];
        }
    });
}

- (void)startYoutubeLive:(NSString *)postUrl
{
    //1.获取授权，成功后得到credential
    //2.利用credential创建Live频道，成功后得到推流addr
    
    dispatch_async(_liveQueue/*dispatch_queue_create("WifiCam.GCD.Queue.YoutubeLive", DISPATCH_QUEUE_SERIAL)*/, ^{
        //3.开始推流
        int ret = [[PanCamSDK instance] startPublishStreaming:[postUrl UTF8String]];
        
        if (ret != ICH_SUCCEED) {
            dispatch_async(dispatch_get_main_queue(), ^{
                _Living = NO;
                [self hideProgressHUD:YES];
                
                [[PanCamSDK instance] deleteLiveChannel];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"LIVE_FAILED", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Sure", nil) otherButtonTitles:nil, nil];
                [alert show];
            });
        } else {
            //4.开始直播，成功后得到Share addr
            NSString *shareUrl = [[PanCamSDK instance] startLive];
            AppLog(@"shareUrl: %@", shareUrl);
            if (shareUrl) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    //5.将Share addr生成二维码
                    [self showShareUrlQRCode:shareUrl];
                });
            } else {
                [[PanCamSDK instance] deleteLiveChannel];
                [self liveErrorHandle:LiveErrorBind andMessage:nil];
            }
        }
    });
}

- (void)startYoutubeLive
{
    //1.获取授权，成功后得到credential
    //2.利用credential创建Live频道，成功后得到推流addr
    //  share...
    //3.开始推流
    [self showProgressHUDWithMessage:NSLocalizedString(@"Start Live", nil)];
    
    dispatch_async(_liveQueue/*dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)*/, ^{
        int ret = [[PanCamSDK instance] startPublishStreaming:[[[NSUserDefaults standardUserDefaults] stringForKey:@"RTMPURL"] UTF8String]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideProgressHUD:YES];
            
            if (ret != ICH_SUCCEED) {
                [[PanCamSDK instance] stopPublishStreaming];
                _liveSwitch_YouTube.on = NO;
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"LIVE_FAILED", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Sure", nil) otherButtonTitles:nil, nil];
                [alert show];
            } else {
                _Living = YES;
                [self setToVideoOnScene];
            }
        });
    });
    
    //4.开始直播，成功后得到Share addr
    //5.将Share addr生成二维码
    
    //    "rtmp://a.rtmp.youtube.com/live2/7m5m-wuhz-ryaq-89ss"
    //    dispatch_async(dispatch_queue_create("WifiCam.GCD.Queue.getQRCodebyUrl", DISPATCH_QUEUE_SERIAL), ^{
    //        UIImage *urlImage = [self getQRCodebyUrl:@"http://www.baidu.com"];
    //        if (urlImage) {
    //            dispatch_async(dispatch_get_main_queue(), ^{
    //                _autoDownloadThumbImage.image = urlImage;
    //                _autoDownloadThumbImage.hidden = NO;
    //            });
    //        }
    //    });
}

- (void)stopYoutubeLive
{
    //1.停止推流
    //2.停止直播
    if (_Living) {
        [self showProgressHUDWithMessage:NSLocalizedString(@"Stop Live", nil)];
        
        dispatch_async(_liveQueue/*dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)*/, ^{
            _liveSwitch_YouTube.on = NO;
            int ret = [[PanCamSDK instance] stopPublishStreaming];
            
            if (ret == ICH_SUCCEED) {
                [[PanCamSDK instance] stopLive];
            } else {
                [[PanCamSDK instance] stopPublishStreaming];
                [[PanCamSDK instance] stopLive];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                _autoDownloadThumbImage.image = nil;
                _autoDownloadThumbImage.hidden = YES;
                _Living = NO;
                
                if (!_Recording) {
                    [self setToVideoOffScene];
                }
            });
        });
    }
}

- (void)showShareUrlQRCode:(NSString *)url
{
    dispatch_async(dispatch_queue_create("WifiCam.GCD.Queue.getQRCodebyUrl", DISPATCH_QUEUE_SERIAL), ^{
        UIImage *urlImage = [self getQRCodebyUrl:url];
        if (urlImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                _autoDownloadThumbImage.image = urlImage;
                _autoDownloadThumbImage.hidden = NO;
            });
        }
    });
}

- (void)liveFailedUpdateGUI
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideProgressHUD:YES];
        _autoDownloadThumbImage.image = nil;
        _autoDownloadThumbImage.hidden = YES;
        _Living = NO;
        _liveSwitch_YouTube.on = NO;
        
        if (!_Recording) {
            [self setToVideoOffScene];
        }
    });
}

- (void)liveErrorHandle:(NSInteger)obj andMessage:(id)mes
{
    NSString *title = nil;
    NSString *message = nil;
    
    switch (obj) {
        case LiveErrorCreateLiveBroadCast:
            title = NSLocalizedString(@"CreateLiveBroadCastFailed", nil);
            break;
            
        case LiveErrorBind:
            title = NSLocalizedString(@"BindFailed", nil);
            break;
            
        default:
            title = NSLocalizedString(@"LIVE_FAILED", nil);
            break;
    }
    
    [self liveFailedUpdateGUI];
    if ([mes isKindOfClass:[NSError class]]) {
        message = [NSString stringWithFormat:@"%@", mes];
    } else {
        message = mes;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Sure", nil) otherButtonTitles:nil, nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [alert show];
    });
}

- (UIImage *)getQRCodebyUrl:(NSString *)url
{
    // 1.实例化二维码滤镜
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    // 2.恢复滤镜的默认属性 (因为滤镜有可能保存上一次的属性)
    [filter setDefaults];
    
    // 3.将字符串转换成NSdata @"http://www.baidu.com"
    NSData *data  = [url dataUsingEncoding:NSUTF8StringEncoding];
    
    // 4.通过KVO设置滤镜, 传入data, 将来滤镜就知道要通过传入的数据生成二维码
    [filter setValue:data forKey:@"inputMessage"];
    
    // 5.生成二维码
    CIImage *outputImage = [filter outputImage];
    
    return [UIImage  imageWithCIImage:outputImage];
}

- (void)createLiveChannel
{
    [self showProgressHUDWithMessage:NSLocalizedString(@"Start Live", nil)];
    
    static CredentialSDK *credential = new CredentialSDK;
    credential->access_token = _accessToken.UTF8String;
    credential->refresh_token = _refreshToken.UTF8String;
    credential->client_id = kClientID.UTF8String;
    
    NSString *postUrl = [[PanCamSDK instance] createLiveChannel:*credential withResolution:@"1080p" withTitle:@"MobileCamAppTest" withVRProjection:YES];
    if (postUrl) {
        [self startYoutubeLive:postUrl];
    } else {
        [self liveErrorHandle:LiveErrorCreateLiveBroadCast andMessage:nil];
    }
}
#else
- (IBAction)liveSwitchClink:(id)sender {}
#endif

#if 0
#pragma mark - Facebook live
- (IBAction)facebookLiveSwithClick:(id)sender {
    _facebookLiveQueue = dispatch_queue_create("WifiCam.GCD.Queue.FacebookLive", DISPATCH_QUEUE_SERIAL);
    
    UISwitch *live = (UISwitch *)sender;
    if ([live isOn]) {
        if ([[PanCamSDK instance] isStreamSupportPublish] == ICH_SUCCEED) {
            [self startFacebookLive];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:@"The current video format not supported live function." delegate:self cancelButtonTitle:NSLocalizedString(@"Sure", nil) otherButtonTitles:nil, nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert show];
                _liveSwitch_Facebook.on = NO;
                self.facebookLiveImg.hidden = YES;
            });
        }
    } else {
        AppLog( @"stop  Live ...");
        [self stopFacebookLive];
        self.facebookLiveImg.hidden = YES;
    }
}

- (void)stopFacebookLive
{
    if (!_liveSwitch_Facebook.on) {
        _liveSwitch_Facebook.on = NO;
        [self showProgressHUDWithMessage:NSLocalizedString(@"StopLive",nil)];
        dispatch_async(_facebookLiveQueue, ^{
            int ret = [[PanCamSDK instance] stopPublishStreaming];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                _autoDownloadThumbImage.image = nil;
                _autoDownloadThumbImage.hidden = YES;
                
                if (ret != ICH_SUCCEED) {
                    [[PanCamSDK instance] stopPublishStreaming];
                }
            });
        });
    }
}

- (void)startFacebookLive {
    __block NSString *rtmpUrl = nil;
    if ([FBSDKAccessToken currentAccessToken])
    {
        NSString* liveVideosRequestPath = [NSString stringWithFormat:@"/%@/live_videos",[FBSDKAccessToken currentAccessToken].userID];
        AppLog(@"%@",liveVideosRequestPath);
        NSDictionary * privacy = @{@"privacy": @"{'value': 'EVERYONE'}",
                                   @"title":@"Live by iSmart DV",
                                   @"is_spherical": @"true",
                                   };
        if ([[FBSDKAccessToken currentAccessToken] hasGranted:@"publish_actions"]) {
            // publish
            [[[FBSDKGraphRequest alloc]
              initWithGraphPath:liveVideosRequestPath
              parameters: privacy
              HTTPMethod:@"POST"]
             startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                 if (!error) {
                     AppLog(@"Post id:%@", result[@"stream_url"]);
                     NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                     rtmpUrl = result[@"stream_url"];
                     // SAVE facebook rtmp URL
                     [defaults setObject:rtmpUrl forKey:@"FBRTMPURL"];
                     [defaults synchronize];
                     
                     // start publish live
                     [self showProgressHUDWithMessage:NSLocalizedString(@"StartLive",nil)];
                     dispatch_async(_facebookLiveQueue, ^{
                         AppLog(@"Start Live ...");
                         NSString * fbrtmpurl =[[NSUserDefaults standardUserDefaults] stringForKey:@"FBRTMPURL"];
                         AppLog(@"fbrtmpurl: %@",fbrtmpurl);
                         int ret = [[PanCamSDK instance] startPublishStreaming:[fbrtmpurl UTF8String]];
                         if( ret != ICH_SUCCEED){
                             // publish API fail
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 AppLog(@"main: StartLive fail");
                                 [self.liveSwitch_Facebook setOn:NO];
                                 [self hideProgressHUD:YES];
                                 NSString *message = [NSString stringWithFormat:@"%@",NSLocalizedString(@"LiveFailReason", nil) ];
                                 [self showProgressHUDNotice:NSLocalizedString(@"Error",nil) detail:message showTime:3];
                                 self.facebookLiveImg.hidden = YES;
                             });
                         }else{
                             // publish API success
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 AppLog(@"main: StartLive ok");
                                 [self hideProgressHUD:YES];
                                 self.facebookLiveImg.hidden = NO;
                             });
                         }
                     });
                 } else {
                     AppLog(@"Post url:%@ fail! reason: %@", liveVideosRequestPath,error.userInfo[FBSDKErrorDeveloperMessageKey]);
                     dispatch_async(dispatch_get_main_queue(), ^{
                         [self.liveSwitch_Facebook setOn:NO];
                         [self hideProgressHUD:YES];
                         NSString *message = [NSString stringWithFormat:@"%@ %@",NSLocalizedString(@"Error", nil), error.userInfo[FBSDKErrorDeveloperMessageKey]];
                         [self showProgressHUDNotice:NSLocalizedString(@"Error",nil) detail:message showTime:3];
                     });
                 }
             }];
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            AppLog(@"main: StartLive fail");
            [self.liveSwitch_Facebook setOn:NO];
            [self hideProgressHUD:YES];
            NSString *message = [NSString stringWithFormat:@"%@",NSLocalizedString(@"FacebookLiveErrorReason1", nil) ];
            [self showProgressHUDNotice:NSLocalizedString(@"Error",nil) detail:message showTime:3];
            self.facebookLiveImg.hidden = YES;
        });
    }
}
#else
- (IBAction)facebookLiveSwithClick:(id)sender {}
#endif
    
@end
