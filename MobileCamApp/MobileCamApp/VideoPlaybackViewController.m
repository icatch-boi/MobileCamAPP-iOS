//
//  VideoPlaybackViewController.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-3-10.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "VideoPlaybackViewController.h"
#import "MpbPopoverViewController.h"
#import "VideoPlaybackSlideController.h"
#import "VideoPlaybackBufferingView.h"
#import "MBProgressHUD.h"
#import "HYOpenALHelper.h"
#import "AppDelegate.h"
#include "MpbSDKEventListener.h"
#import "GCDiscreetNotificationView.h"
#ifdef DEBUG1
#include "ICatchWificamConfig.h"
#endif
#include "WifiCamSDKEventListener.h"
#include "PCMDataPlayer.h"

#import "ICatchH264Decoder.h"

#include "StreamSDKEventListener.hpp"
#import "StreamObserver.h"
#import "WifiCamEvent.h"
#import "CustomIOS7AlertView.h"
#import "DiskSpaceTool.h"

@interface VideoPlaybackViewController () <UITableViewDelegate, UITableViewDataSource> {
    UIPopoverController *_popController;
    /**
     *  20160503 zijie.feng
     *  Deprecated !
     */
#if USE_SYSTEM_IOS7_IMPLEMENTATION
    UIActionSheet *_actionsSheet;
#else
    UIAlertController *_actionsSheet;
#endif
    
    shared_ptr<VideoPbProgressListener> videoPbProgressListener;
    shared_ptr<VideoPbProgressStateListener> videoPbProgressStateListener;
    shared_ptr<VideoPbDoneListener> videoPbDoneListener;
    shared_ptr<VideoPbServerStreamErrorListener> videoPbServerStreamErrorListener;
    shared_ptr<VideoPbInsufficientPerformanceListener> videoPbInsufficientPerformanceListener;
    
    CGPoint pointP;
    float cDistance;
    int drawableWidth;
    int drawableHeight;
}

@property(nonatomic) IBOutlet UIImageView *previewThumb;
@property(nonatomic) IBOutlet VideoPlaybackSlideController *slideController;
@property(nonatomic) IBOutlet UIView *bufferingBgView;
@property(nonatomic) IBOutlet VideoPlaybackBufferingView *bufferingView;
@property(nonatomic) IBOutlet UIView *pbCtrlPanel;
@property(nonatomic) IBOutlet UIButton *playbackButton;
@property(nonatomic) IBOutlet UILabel *videoPbTotalTime;
@property(nonatomic) IBOutlet UILabel *videoPbElapsedTime;
@property(nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property(nonatomic) IBOutlet UIBarButtonItem *actionButton;
@property(nonatomic) IBOutlet UIBarButtonItem *returnBackButton;
@property(nonatomic) IBOutlet UILabel *InsufficientPerformanceLabel;
@property(nonatomic) BOOL PlaybackRun;
@property(nonatomic, getter = isPlayed) BOOL played;
@property(nonatomic, getter = isPanCampaused) BOOL panCampaused;
@property(nonatomic) BOOL seeking;
@property(nonatomic) BOOL exceptionHappen;
@property(nonatomic, getter =  isControlHidden) BOOL controlHidden;
@property(nonatomic) dispatch_semaphore_t semaphore;
@property(nonatomic) NSTimer *pbTimer;
@property(nonatomic) NSTimer *insufficientPerformanceTimer;
@property(nonatomic) double totalSecs;
@property(nonatomic) double playedSecs;
@property(nonatomic) double curVideoPTS;
@property(nonatomic) NSUInteger downloadedPercent;
@property(nonatomic) MBProgressHUD *progressHUD;
@property(nonatomic) HYOpenALHelper *al;
@property(nonatomic) PCMDataPlayer *pcmPl;
@property(nonatomic) WifiCam *wifiCam;
@property(nonatomic) WifiCamCamera *camera;
@property(nonatomic) WifiCamPhotoGallery *gallery;
@property(nonatomic) WifiCamControlCenter *ctrl;
@property(nonatomic, retain) GCDiscreetNotificationView *notificationView;
@property(nonatomic) dispatch_group_t playbackGroup;
@property(nonatomic) dispatch_queue_t videoPlaybackQ;
@property(nonatomic) dispatch_queue_t audioQueue;
@property(nonatomic) dispatch_queue_t videoQueue;
@property(nonatomic) int times;
@property(nonatomic) int times1;
@property(nonatomic) float totalElapse;
@property(nonatomic) float totalElapse1;
@property(nonatomic) float totalDuration;
//@property(nonatomic) WifiCamObserver *streamObserver;

@property (strong, nonatomic) EAGLContext *context;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic) ICatchH264Decoder *h264Decoder;

@property (nonatomic) StreamObserver *streamPalyingStObserver;
@property (nonatomic) AVSampleBufferDisplayLayer *avslayer;
@property (nonatomic) UIView *h264View;
@property(nonatomic) BOOL downloadFileProcessing;

@property (nonatomic, weak) UIButton *panoramaTypeButton;
@property (strong, nonatomic) CustomIOS7AlertView *customIOS7AlertView;
@property (nonatomic, strong) WifiCamAlertTable *tbPanoramaTypeArray;
@property (nonatomic, strong) NSURL *localFilePath;

@end

@implementation VideoPlaybackViewController

@synthesize previewImage;
@synthesize index;

#pragma mark - Lifecycle
- (void)viewDidLoad
{
    AppLog(@"%s", __func__);
    [super viewDidLoad];
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    if (!_videoURL) {
        WifiCamManager *app = [WifiCamManager instance];
        self.wifiCam = [app.wifiCams objectAtIndex:0];
        self.camera = _wifiCam.camera;
        self.gallery = _wifiCam.gallery;
        self.ctrl = _wifiCam.controler;
        
//        auto file = _gallery.videoTable.fileList.at(index);
        self.title = [[NSString alloc] initWithFormat:@"%s", /*file*/self.currentFile->getFileName().c_str()];
    } else {
//        NSString *prefix = @"/var/mobile/Containers/Data/Application/9473B6CA-0B87-465D-9BAD-66B57DF3E941/Documents/MobileCamApp-Medias/Videos/";
//        self.title = [_videoURL.path substringFromIndex:prefix.length];
        [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    }
    /*
     AppLog(@"w:%f, h:%f", _previewThumb.bounds.size.width, _previewThumb.bounds.size.height);
     UIButton *playButton = [[UIButton alloc] initWithFrame:CGRectMake(_previewThumb.bounds.size.width/2-28,
     _previewThumb.bounds.size.height/2-28,
     56, 56)];
     [playButton setImage:[UIImage imageNamed:@"detail_play_normal"] forState:UIControlStateNormal];
     [self.view addSubview:playButton];
     */
    
    
    
    self.previewThumb = [[UIImageView alloc] initWithFrame:self.view.frame];
    _previewThumb.contentMode = UIViewContentModeScaleAspectFit;
    _previewThumb.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _previewThumb.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_previewThumb];
//    [self.view sendSubviewToBack:_previewThumb];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToHideControl:)];
    [self.view addGestureRecognizer:tapGesture];
    
    _previewThumb.image = previewImage;
    _totalSecs = 0;
    _playedSecs = 0;
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:UseSDKDecode"]) {
        // H.264
        self.avslayer = [[AVSampleBufferDisplayLayer alloc] init];
        self.avslayer.bounds = self.view.bounds;
        self.avslayer.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
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
        [self.view insertSubview:_h264View belowSubview:_previewThumb];
    }
    
    self.semaphore = dispatch_semaphore_create(1);
    self.playbackGroup = dispatch_group_create();
    self.videoPlaybackQ = dispatch_queue_create("WifiCam.GCD.Queue.Playback.Q", 0);
    self.audioQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.Audio", 0);
    self.videoQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.Video", 0);
    
#ifdef DEBUG1
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    ICatchWificamConfig::getInstance()->enableDumpMediaStream(false, documentsDirectory.UTF8String);
#endif
    
    // Insufficient performance notice lable
    self.InsufficientPerformanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height/2 - 60, self.view.frame.size.width, 120)];
    self.InsufficientPerformanceLabel.hidden = YES;
    self.InsufficientPerformanceLabel.numberOfLines = 4;
    self.InsufficientPerformanceLabel.textColor = [UIColor whiteColor];
    self.InsufficientPerformanceLabel.textAlignment = NSTextAlignmentCenter;
    self.InsufficientPerformanceLabel.font = [UIFont systemFontOfSize:10];
    [self.view addSubview:self.InsufficientPerformanceLabel];
    
    // Panel
    self.pbCtrlPanel = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 52, self.view.frame.size.width, 52)];
    _pbCtrlPanel.backgroundColor = [UIColor blackColor];
    _pbCtrlPanel.alpha = 0.75;
    [self.view addSubview:_pbCtrlPanel];
    
    
    // Buffering bg
    self.bufferingBgView = [[UIView alloc] initWithFrame:CGRectMake(_pbCtrlPanel.frame.origin.x, _pbCtrlPanel.frame.origin.y - 10, _pbCtrlPanel.frame.size.width, 11)];
    _bufferingBgView.backgroundColor = [UIColor darkGrayColor];
    [self.view addSubview:_bufferingBgView];
    
    // Buffering view
    self.bufferingView = [[VideoPlaybackBufferingView alloc] initWithFrame:_bufferingBgView.frame];
    _bufferingView.backgroundColor = [UIColor clearColor];
    _bufferingView.value = 0;
    [self.view insertSubview:_bufferingView aboveSubview:_bufferingBgView];
    
    // Slider
    
    //self.slideController = [[VideoPlaybackSlideController alloc] init];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        self.slideController = [[VideoPlaybackSlideController alloc] initWithFrame:CGRectMake(_pbCtrlPanel.frame.origin.x-5, _pbCtrlPanel.frame.origin.y - 17, _pbCtrlPanel.frame.size.width+10, 15)];
    } else {
        self.slideController = [[VideoPlaybackSlideController alloc] initWithFrame:CGRectMake(_pbCtrlPanel.frame.origin.x-5, _pbCtrlPanel.frame.origin.y - 12, _pbCtrlPanel.frame.size.width+10, 15)];
    }
    _slideController.minimumTrackTintColor = [UIColor redColor];
    _slideController.maximumTrackTintColor = [UIColor clearColor];
    [_slideController addTarget:self action:@selector(sliderValueChanged:)
               forControlEvents:UIControlEventValueChanged];
    [_slideController addTarget:self action:@selector(sliderTouchDown:)
               forControlEvents:UIControlEventTouchDown];
    [_slideController addTarget:self action:@selector(sliderTouchUpInside:)
               forControlEvents:UIControlEventTouchUpInside];
    [_slideController addTarget:self action:@selector(sliderTouchUpInside:)
               forControlEvents:UIControlEventTouchUpOutside];
    [_slideController addTarget:self action:@selector(sliderTouchUpInside:)
               forControlEvents:UIControlEventTouchCancel];
    _slideController.maximumValue = 0;
    _slideController.minimumValue = 0;
    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) {
        [_slideController setThumbImage:[UIImage imageNamed:@"bullet_white"] forState:UIControlStateNormal];
    }
    _slideController.value = 0;
//    _slideController.continuous = NO;
    [self.view insertSubview:_slideController aboveSubview:_bufferingView];
    _slideController.enabled = NO;
    
    // Playback button
    self.playbackButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_playbackButton addTarget:self action:@selector(playbackButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _playbackButton.frame = CGRectMake(10.0, 10.0, 32.0, 32.0);
    [_playbackButton setImage:[UIImage imageNamed:@"videoplayer_control_play"] forState:UIControlStateNormal];
    [_pbCtrlPanel addSubview:_playbackButton];
    
    // Elapsed time
    self.videoPbElapsedTime = [[UILabel alloc] initWithFrame:CGRectMake(_playbackButton.frame.origin.x + 50, _playbackButton.frame.origin.y + 8, 80.0, 16.0)];
    _videoPbElapsedTime.text = @"00:00:00";
    _videoPbElapsedTime.textColor = [UIColor lightTextColor];
    _videoPbElapsedTime.font = [UIFont systemFontOfSize:14.0];
    [_pbCtrlPanel addSubview:_videoPbElapsedTime];
    
    // /
    UILabel *sliceLabel = [[UILabel alloc] initWithFrame:CGRectMake(_videoPbElapsedTime.frame.origin.x + 61, _videoPbElapsedTime.frame.origin.y, 10, 16.0)];
    sliceLabel.text = @"/";
    sliceLabel.textColor = [UIColor lightTextColor];
    sliceLabel.textAlignment = NSTextAlignmentCenter;
    sliceLabel.font = [UIFont systemFontOfSize:12.0];
    [_pbCtrlPanel addSubview:sliceLabel];
    
    // Total time
    self.videoPbTotalTime = [[UILabel alloc] initWithFrame:CGRectMake(sliceLabel.frame.origin.x + 11, _videoPbElapsedTime.frame.origin.y, 80.0, 14.0)];
    _videoPbTotalTime.text = @"--:--:--";
    _videoPbTotalTime.textColor = [UIColor lightTextColor];
    _videoPbTotalTime.font = [UIFont systemFontOfSize:14.0];
    [_pbCtrlPanel addSubview:_videoPbTotalTime];
    
    // PanoramaType change switch button
    // Fixed: MOBILEAPP-19
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:UseSDKDecode"]) {
        if(_videoURL == nil && [[PanCamSDK instance] isPanoramaWithFile:/*(_gallery.videoTable.fileList.at(index))*/self.currentFile]) {
            [self setupPanoramaTypeChangeButton];
            
        } else if (_videoURL != nil) {
            CGImageRef  imageRef = [previewImage CGImage];
            float imageWidth = CGImageGetWidth(imageRef);
            float imageHeight = CGImageGetHeight(imageRef);
            float scale = imageWidth/imageHeight;
            if (scale >= 2) {
                // This is a panoramic file.
                [self setupPanoramaTypeChangeButton];
            }
            
        } else {}
    }

    if (!_videoURL) {
        self.deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteButtonPressed:)];
        self.actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction  target:self action:@selector(actionButtonPressed:)];
        self.navigationItem.rightBarButtonItems = @[_deleteButton, _actionButton];
    }
    
    if (_videoURL) {
        self.returnBackButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(returnBack:)];
        self.navigationItem.leftBarButtonItem = _returnBackButton;
    }
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.delegate = self;
    
    /*
    UIProgressView *progress = [[UIProgressView alloc] initWithFrame:CGRectMake(_pbCtrlPanel.frame.origin.x, 100, _pbCtrlPanel.frame.size.width, 11)];
    progress.progress = 0.5;
    progress.progressTintColor = [UIColor lightGrayColor];
    progress.trackTintColor = [UIColor darkGrayColor];
    [self.view addSubview:progress];
    
    VideoPlaybackProgressView *slider = [[VideoPlaybackProgressView alloc] initWithFrame:CGRectMake(_pbCtrlPanel.frame.origin.x-5, 99, _pbCtrlPanel.frame.size.width+10, 13)];
    slider.value = 0.2;
    slider.maximumTrackTintColor = [UIColor clearColor];
    slider.minimumTrackTintColor = [UIColor redColor];
    [self.view addSubview:slider];
    */
    _motionManager = [[CMMotionManager alloc] init];
    _queue = [[NSOperationQueue alloc]init];
    cDistance = maxDistance;
    
    if (_videoURL != nil || (_videoURL == nil && [[PanCamSDK instance] isPanoramaWithFile:/*(_gallery.videoTable.fileList.at(index))*/self.currentFile])) {
        UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        [self.view addGestureRecognizer:pinchGesture];
    }
    
    
}

- (void)setupPanoramaTypeChangeButton {
    CGFloat width = 50;
    CGFloat height = 32;
    CGFloat x = self.view.frame.size.width - width - 10;
    CGFloat y = (_pbCtrlPanel.bounds.size.height - height) * 0.5;
    UIButton *panoramaTypeButton = [[UIButton alloc] initWithFrame:CGRectMake(x, y, width, height)];
    [panoramaTypeButton addTarget:self action:@selector(changePanoramaTypeClick) forControlEvents:UIControlEventTouchUpInside];
    [panoramaTypeButton setTitle:@"Sphere" forState:UIControlStateNormal];
    [panoramaTypeButton setTitle:@"Sphere" forState:UIControlStateHighlighted];
    panoramaTypeButton.titleLabel.font = [UIFont boldSystemFontOfSize:12.0];
    
    _panoramaTypeButton = panoramaTypeButton;
    [_pbCtrlPanel addSubview:panoramaTypeButton];
    [self preparePanoramaTypeData];
}

- (void)preparePanoramaTypeData {
    NSArray *temp = @[@"Sphere", @"Asteroid", @"VR"];
    _tbPanoramaTypeArray = [[WifiCamAlertTable alloc] initWithParameters:[NSMutableArray arrayWithArray:temp] andLastIndex:0];
}

-(void)initControlPanel {
//    TRACE();
    _pbCtrlPanel.frame = CGRectMake(0, self.view.frame.size.height - 52, self.view.frame.size.width, 52);
    _bufferingBgView.frame = CGRectMake(_pbCtrlPanel.frame.origin.x, _pbCtrlPanel.frame.origin.y - 10, _pbCtrlPanel.frame.size.width, 11);
    _bufferingView.frame = _bufferingBgView.frame;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        _slideController.frame = CGRectMake(_pbCtrlPanel.frame.origin.x-5, _pbCtrlPanel.frame.origin.y - 17, _pbCtrlPanel.frame.size.width+10, 15);
    } else {
        _slideController.frame = CGRectMake(_pbCtrlPanel.frame.origin.x-5, _pbCtrlPanel.frame.origin.y - 12, _pbCtrlPanel.frame.size.width+10, 15);
    }
    // Something weird happened on iOS7.
    [self.view bringSubviewToFront:_slideController];
}

-(void)landscapeControlPanel {
    [self initControlPanel];
}

- (void)initGLParameter {
    //GLKView
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    [EAGLContext setCurrentContext:self.context];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:UseSDKDecode"]) {
        if (_videoURL == nil) {
            [[PanCamSDK instance] initStreamWithRenderType:RenderType_AutoSelect isPreview:NO file:/*(_gallery.videoTable.fileList.at(index))*/self.currentFile];
        } else {
            [[PanCamSDK instance] initStreamWithRenderType:/*RenderType_EnableGL*/RenderType_AutoSelect isPreview:NO file:nil];
        }
    } else {
        [[PanCamSDK instance] initStreamWithRenderType:RenderType_Disable isPreview:NO file:nil];
    }
    
    GLKView* view = (GLKView*)self.glkView;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    AppLog(@"GLKView, view: %@", self.glkView);
    [self.view sendSubviewToBack:self.glkView];
    _h264Decoder = [[ICatchH264Decoder alloc] init];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:UseSDKDecode"]) {
        self.avslayer.bounds = self.view.bounds;
        self.avslayer.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recoverFromDisconnection)
                                                 name:@"kCameraNetworkConnectedNotification"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDisconnection)
                                                 name:@"kCameraNetworkDisconnectedNotification"
                                               object:nil];
//    WifiCamSDKEventListener *listener = new WifiCamSDKEventListener(self, @selector(streamCloseCallback));
//    self.streamObserver = [[WifiCamObserver alloc] initWithListener:listener eventType:ICATCH_EVENT_MEDIA_STREAM_CLOSED isCustomized:NO isGlobal:NO];
//    [[SDK instance] addObserver:_streamObserver];
    [self initGLParameter];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self playbackButtonPressed:self.playbackButton];
    
    
}

- (IBAction)returnBack:(id)sender {
    self.PlaybackRun = NO;
    [self stopGLKAnimation];
    [self showProgressHUDWithMessage:nil detailsMessage:nil
                                mode:MBProgressHUDModeIndeterminate];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        if ((dispatch_semaphore_wait(_semaphore, time) != 0)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgressHUDNotice:@"Timeout!" showTime:2.0];
            });
        } else {
            if (_played) {
                if (_videoURL) {
                    self.played = ![[PanCamSDK instance] stop];
                } else {
                    self.played = ![_ctrl.pbCtrl stop];
                }
                [self removePlaybackObserver];
            }
            [self.pbTimer invalidate];
            [self.insufficientPerformanceTimer invalidate];
            
//            [[PanCamSDK instance] panCamStopPreview];
            [self.motionManager stopGyroUpdates];
            [EAGLContext setCurrentContext:self.context];
            
//            [[PanCamSDK instance] destroyStream];
            [[PanCamSDK instance] destroypanCamSDK];
            
            if ([EAGLContext currentContext] == self.context) {
                [EAGLContext setCurrentContext:nil];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                dispatch_semaphore_signal(self.semaphore);
                [_popController dismissPopoverAnimated:YES];
#if USE_SYSTEM_IOS7_IMPLEMENTATION
                [_actionsSheet dismissWithClickedButtonIndex:0 animated:NO];
#else
                [_actionsSheet dismissViewControllerAnimated:NO completion:nil];
#endif
                [self hideProgressHUD:NO];
                [self.navigationController setToolbarHidden:NO];
                [self hideGCDiscreetNoteView:YES];
                [self dismissViewControllerAnimated:YES completion:^{
                    
                }];
            });
        }
    });
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
//    [[SDK instance] removeObserver:_streamObserver];
//    delete _streamObserver.listener;
//    _streamObserver.listener = NULL;
//    self.streamObserver = nil;
    [self hideProgressHUD:YES];
}

-(BOOL)prefersStatusBarHidden {
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    TRACE();
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                        duration:(NSTimeInterval)duration {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
//            [self.navigationController setNavigationBarHidden:YES];
//            [[UIApplication sharedApplication] setStatusBarHidden:YES];
            [self landscapeControlPanel];
            break;
        default:
            [self.navigationController setNavigationBarHidden:NO];
//            [[UIApplication sharedApplication] setStatusBarHidden:NO];
            if (_controlHidden) {
                _pbCtrlPanel.hidden = NO;
                _bufferingBgView.hidden = NO;
                _bufferingView.hidden = NO;
                _slideController.hidden = NO;
                self.controlHidden = NO;
            }
            [self initControlPanel];
            break;
    }
    _notificationView.center = CGPointMake(self.view.center.x, _notificationView.center.y);
    _InsufficientPerformanceLabel.center = self.view.center;
    [UIView commitAnimations];
    if (_panoramaTypeButton != nil) {
        [self updatePanoramaTypeChangeButtonLayout];
    }
}

- (void)updatePanoramaTypeChangeButtonLayout {
    CGRect rect = _panoramaTypeButton.frame;
    rect.origin.x = self.view.frame.size.width - CGRectGetWidth(rect) - 10;
    _panoramaTypeButton.frame = rect;
}

-(void)recoverFromDisconnection
{
    TRACE();
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)handleDisconnection
{
    TRACE();
    if (_played) {
        [self removePlaybackObserver];
        self.PlaybackRun = NO;
        if (_videoURL) {
            self.played = [[PanCamSDK instance] stop];
        } else {
            self.played = [_ctrl.pbCtrl stop];
        }
    }
}

#pragma mark - Observer
- (void)addPlaybackObserver
{
    videoPbProgressListener = make_shared<VideoPbProgressListener>(self);
//    if (_videoURL) {
        AppLog(@"Add Observer: [id]0x%x, [listener]%p", ICH_GL_EVENT_VIDEO_PLAYBACK_CACHING_PROGRESS, videoPbProgressListener.get());
        [[PanCamSDK instance] addObserver:ICH_GL_EVENT_VIDEO_PLAYBACK_CACHING_PROGRESS listener:videoPbProgressListener isCustomize:NO];
    /*} else {
        [_ctrl.comCtrl addObserver:ICH_CAM_EVENT_VIDEO_PLAYBACK_CACHING_PROGRESS
                          listener:videoPbProgressListener
                       isCustomize:NO];
    }*/

    videoPbProgressStateListener = make_shared<VideoPbProgressStateListener>(self);
//    if (_videoURL) {
        AppLog(@"Add Observer: [id]0x%x, [listener]%p", ICH_GL_EVENT_VIDEO_PLAYBACK_CACHING_CHANGED, videoPbProgressStateListener.get());
        [[PanCamSDK instance] addObserver:ICH_GL_EVENT_VIDEO_PLAYBACK_CACHING_CHANGED listener:videoPbProgressStateListener isCustomize:NO];
    /*} else {
        [_ctrl.comCtrl addObserver:ICH_CAM_EVENT_VIDEO_PLAYBACK_CACHING_CHANGED
                          listener:videoPbProgressStateListener
                       isCustomize:NO];
    }*/
  
    videoPbDoneListener = make_shared<VideoPbDoneListener>(self);
//    if (_videoURL) {
        AppLog(@"Add Observer: [id]0x%x, [listener]%p", ICH_GL_EVENT_VIDEO_STREAM_PLAYING_ENDED, videoPbDoneListener.get());
        [[PanCamSDK instance] addObserver:ICH_GL_EVENT_VIDEO_STREAM_PLAYING_ENDED listener:videoPbDoneListener isCustomize:NO];
    /*} else {
        [_ctrl.comCtrl addObserver:ICH_CAM_EVENT_VIDEO_STREAM_PLAYING_ENDED
                          listener:videoPbDoneListener
                       isCustomize:NO];
    }*/

    videoPbServerStreamErrorListener = make_shared< VideoPbServerStreamErrorListener>(self);
//    if (_videoURL) {
        AppLog(@"Add Observer: [id]0x%x, [listener]%p", ICH_GL_EVENT_SERVER_STREAM_ERROR, videoPbServerStreamErrorListener.get());
        [[PanCamSDK instance] addObserver:ICH_GL_EVENT_SERVER_STREAM_ERROR listener:videoPbServerStreamErrorListener isCustomize:NO];
    /*} else {
        [_ctrl.comCtrl addObserver:ICH_CAM_EVENT_SERVER_STREAM_ERROR
                          listener:videoPbServerStreamErrorListener
                       isCustomize:NO];
    }*/
    
    auto streamPlayingLister = make_shared<StreamSDKEventListener>(self, @selector(streamPlayingStatusCallback:));
    self.streamPalyingStObserver = [[StreamObserver alloc] initWithListener:streamPlayingLister eventType:ICH_GL_EVENT_VIDEO_STREAM_PLAYING_STATUS isCustomized:NO isGlobal:NO];
    AppLog(@"Add Observer: [id]0x%x, [listener]%p", ICH_GL_EVENT_VIDEO_STREAM_PLAYING_STATUS, self.streamPalyingStObserver.listener.get());
    [[PanCamSDK instance] addObserver:self.streamPalyingStObserver];
    
    videoPbInsufficientPerformanceListener = make_shared<VideoPbInsufficientPerformanceListener>(self);
    AppLog(@"Add Observer: [id]0x%x, [listener]%p", ICH_GL_EVENT_VIDEO_CODEC_INSUFFICIENT_PERFORMANCE, videoPbInsufficientPerformanceListener.get());
    [[PanCamSDK instance] addObserver:ICH_GL_EVENT_VIDEO_CODEC_INSUFFICIENT_PERFORMANCE
                             listener:videoPbInsufficientPerformanceListener
                          isCustomize:NO];
}

- (void)removePlaybackObserver
{
    if (videoPbProgressListener) {
//        if (_videoURL) {
            AppLog(@"Remove Observer: [id]0x%x, [listener]%p", ICH_GL_EVENT_VIDEO_PLAYBACK_CACHING_PROGRESS, videoPbProgressListener.get());
            [[PanCamSDK instance] removeObserver:ICH_GL_EVENT_VIDEO_PLAYBACK_CACHING_PROGRESS listener:videoPbProgressListener isCustomize:NO];
        /*} else {
            [_ctrl.comCtrl removeObserver:ICH_CAM_EVENT_VIDEO_PLAYBACK_CACHING_PROGRESS
                                 listener:videoPbProgressListener
                              isCustomize:NO];
        }*/
        videoPbProgressListener.reset();
    }
    if (videoPbProgressStateListener) {
//        if (_videoURL) {
            AppLog(@"Remove Observer: [id]0x%x, [listener]%p", ICH_GL_EVENT_VIDEO_PLAYBACK_CACHING_CHANGED, videoPbProgressStateListener.get());
            [[PanCamSDK instance] removeObserver:ICH_GL_EVENT_VIDEO_PLAYBACK_CACHING_CHANGED listener:videoPbProgressStateListener isCustomize:NO];
        /*} else {
            [_ctrl.comCtrl removeObserver:ICH_CAM_EVENT_VIDEO_PLAYBACK_CACHING_CHANGED
                                 listener:videoPbProgressStateListener
                              isCustomize:NO];
        }*/
        videoPbProgressStateListener.reset();
    }
    
    if (videoPbDoneListener) {
//        if (_videoURL) {
            AppLog(@"Remove Observer: [id]0x%x, [listener]%p", ICH_GL_EVENT_VIDEO_STREAM_PLAYING_ENDED, videoPbDoneListener.get());
            [[PanCamSDK instance] removeObserver:ICH_GL_EVENT_VIDEO_STREAM_PLAYING_ENDED listener:videoPbDoneListener isCustomize:NO];
        /*} else {
            [_ctrl.comCtrl removeObserver:ICH_CAM_EVENT_VIDEO_STREAM_PLAYING_ENDED
                                 listener:videoPbDoneListener
                              isCustomize:NO];
        }*/
        videoPbDoneListener.reset();
    }
    if (videoPbServerStreamErrorListener) {
//        if (_videoURL) {
            AppLog(@"Remove Observer: [id]0x%x, [listener]%p", ICH_GL_EVENT_SERVER_STREAM_ERROR, videoPbServerStreamErrorListener.get());
            [[PanCamSDK instance] removeObserver:ICH_GL_EVENT_SERVER_STREAM_ERROR listener:videoPbServerStreamErrorListener isCustomize:NO];
        /*} else {
            [_ctrl.comCtrl removeObserver:ICH_CAM_EVENT_SERVER_STREAM_ERROR
                                 listener:videoPbServerStreamErrorListener
                              isCustomize:NO];
        }*/
        videoPbServerStreamErrorListener.reset();
    }
    
    if (self.streamPalyingStObserver) {
        AppLog(@"Remove Observer: [id]0x%x, [listener]%p", self.streamPalyingStObserver.eventType, self.streamPalyingStObserver.listener.get());
        [[PanCamSDK instance] removeObserver:self.streamPalyingStObserver];
        self.streamPalyingStObserver.listener.reset();
        self.streamPalyingStObserver = nil;
    }
    
    if(videoPbInsufficientPerformanceListener) {
        AppLog(@"Remove Observer: [id]0x%x, [listener]%p", ICH_GL_EVENT_VIDEO_CODEC_INSUFFICIENT_PERFORMANCE, videoPbInsufficientPerformanceListener.get());
        [[PanCamSDK instance] removeObserver:ICH_GL_EVENT_VIDEO_CODEC_INSUFFICIENT_PERFORMANCE
                                    listener:videoPbInsufficientPerformanceListener
                                 isCustomize:NO];
        videoPbInsufficientPerformanceListener.reset();
    }
}

- (void)streamPlayingStatusCallback:(WifiCamEvent *)event {
    BOOL isUseSDKDecode = [[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:UseSDKDecode"];
    if (isUseSDKDecode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _previewThumb.hidden = YES;
        });
    }

    if (!_seeking) {
        
        if (self.panCampaused) {
            AppLog(@"Playback is manully paused, skip play status update");
            return;
        }

        self.playedSecs = event.doubleValue1;
        
        float sliderPercent = _playedSecs/_totalSecs; // slider value
        dispatch_async(dispatch_get_main_queue(), ^{
            _videoPbElapsedTime.text = [Tool translateSecsToString:_playedSecs];
            //            AppLog(@"_playedSecs: %f", _playedSecs);
            _slideController.value = [@(_playedSecs) floatValue];
            
            if (sliderPercent > _bufferingView.value) {
                _bufferingView.value = sliderPercent;
                [_bufferingView setNeedsDisplay];
            }
            //                AppLog(@"hideGCDiscreetNoteView");
            [self hideGCDiscreetNoteView:YES];
        });

        
    } else {
        AppLog(@"seeking");
    }
}

- (void)updateVideoPbProgress:(double)value
{
    self.bufferingView.value = value/self.totalSecs;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_bufferingView setNeedsDisplay];
    });
}

- (void)updateVideoPbProgressState:(BOOL)caching
{
    if (!_played || _panCampaused) {
        return;
    }
    
    /// workaround: dispatch this task after all 'hideGCDiscreetNoteView' task run complete
    [NSThread sleepForTimeInterval:1.0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (caching) {
            //[_al pause];
            [self showGCDNoteWithMessage:@"Buffering ..." withAnimated:YES withAcvity:YES];
        } else {
            //[_al play];
            [self hideGCDiscreetNoteView:YES];
        }
    });
}

- (void)stopVideoPb
{
    if (self.seeking) {
        return;
    }
    if (_played) {
        self.PlaybackRun = NO;
        self.paused = YES;
        [self showProgressHUDWithMessage:nil detailsMessage:nil
                                    mode:MBProgressHUDModeIndeterminate];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
            if (dispatch_semaphore_wait(_semaphore, time) != 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showProgressHUDNotice:@"Timeout!" showTime:2.0];
                });
            } else {
                [self removePlaybackObserver];
                
//                [[PanCamSDK instance] panCamStopPreview];
                
                [self.motionManager stopGyroUpdates];
                
                if (_videoURL) {
                    [[PanCamSDK instance] stop];
                } else {
                     [_ctrl.pbCtrl stop];
                }
                self.played = NO;
                

                dispatch_async(dispatch_get_main_queue(), ^{
                    _deleteButton.enabled = YES;
                    _actionButton.enabled = YES;
                    
                    dispatch_semaphore_signal(self.semaphore);
                    [_playbackButton setImage:[UIImage imageNamed:@"videoplayer_control_play"]
                                     forState:UIControlStateNormal];
                    [self.pbTimer invalidate];
                    [self.insufficientPerformanceTimer invalidate];
                    _videoPbElapsedTime.text = @"00:00:00";
                    _bufferingView.value = 0; [_bufferingView setNeedsDisplay];
                    self.curVideoPTS = 0;
                    self.playedSecs = 0;
                    _slideController.value = 0;
                    _slideController.enabled = NO;
                    _previewThumb.hidden = NO;
                    _InsufficientPerformanceLabel.hidden = YES;
                    [self hideProgressHUD:YES];
                });
            }
        });
    }
    
}

- (void)showServerStreamError
{
    AppLog(@"server error!");
    self.exceptionHappen = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showProgressHUDNotice:NSLocalizedString(@"CameraPbError", nil)
                           showTime:2.0];
    });
    [self stopVideoPb];
}

-(void)notifyInsufficientPerformanceInfo:(long long)codec
                                   width:(long long)width
                                  height:(long long)height
                           frameInterval:(double)frameInterval
                              decodeTime:(double)decodeTime{
    AppLog(@"Insufficient performance: %lld, %lld", width, height);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self.InsufficientPerformanceLabel.hidden
           && width > 0
           && height > 0
           && frameInterval > 0
           && decodeTime > 0) {
            NSString *notice = [NSString stringWithFormat:@"Warning, Insufficient performance.\nVideo width: %lld, height: %lld.\n Frame interval:%f, decode time: %f.\nThe playback will stutter.", width, height, frameInterval, decodeTime];
            self.InsufficientPerformanceLabel.hidden = NO;
            self.InsufficientPerformanceLabel.text = notice;
            
            self.insufficientPerformanceTimer = [NSTimer scheduledTimerWithTimeInterval:MIN(_totalSecs/2, 5)
                                                                                 target:self
                                                                               selector:@selector(hideInsufficientPerformanceInfo)
                                                                               userInfo:nil
                                                                                repeats:NO];
        }
    });
}

- (void)hideInsufficientPerformanceInfo {
    if(videoPbInsufficientPerformanceListener) {
        AppLog(@"Remove Observer: [id]0x%x, [listener]%p", ICH_GL_EVENT_VIDEO_CODEC_INSUFFICIENT_PERFORMANCE, videoPbInsufficientPerformanceListener.get());
        [[PanCamSDK instance] removeObserver:ICH_GL_EVENT_VIDEO_CODEC_INSUFFICIENT_PERFORMANCE
                                    listener:videoPbInsufficientPerformanceListener
                                 isCustomize:NO];
        videoPbInsufficientPerformanceListener.reset();
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.InsufficientPerformanceLabel.hidden = YES;
        [self.insufficientPerformanceTimer invalidate];
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if([keyPath isEqualToString:@"downloadedPercent"]) {
        [self updateProgressHUDWithMessage:nil detailsMessage:nil];
    }
}

#pragma mark - Action Progress

- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view.window];
        _progressHUD.minSize = CGSizeMake(120, 120);
        _progressHUD.minShowTime = 1;
        _progressHUD.dimBackground = YES;
        
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
    if (message) {
        [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.mode = MBProgressHUDModeText;
        [self.progressHUD hide:YES afterDelay:time];
    } else {
        [self.progressHUD hide:YES];
    }
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

- (void)showProgressHUDWithMessage:(NSString *)message
                    detailsMessage:(NSString *)dMessage
                              mode:(MBProgressHUDMode)mode{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_progressHUD.alpha == 0 ) {
            self.progressHUD.labelText = message;
            self.progressHUD.detailsLabelText = dMessage;
            self.progressHUD.mode = mode;
            [self.progressHUD show:YES];
            
            self.navigationController.navigationBar.userInteractionEnabled = NO;
        }
    });
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    if (message) {
        if (self.progressHUD.isHidden) [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.detailsLabelText = nil;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hide:YES afterDelay:1.0];
    } else {
        [self.progressHUD hide:YES];
    }
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

- (void)updateProgressHUDWithMessage:(NSString *)message
                      detailsMessage:(NSString *)dMessage {
    if (message) {
        self.progressHUD.labelText = message;
    }
    if (dMessage) {
        self.progressHUD.detailsLabelText = dMessage;
    }
    self.progressHUD.progress = _downloadedPercent / 100.0;
}

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hide:animated];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.navigationController.toolbar.userInteractionEnabled = YES;
}

#pragma mark - VideoPB
- (IBAction)sliderValueChanged:(VideoPlaybackSlideController *)slider {

    /*
    if (_played) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.seeking = YES;
            BOOL retVal = [_ctrl.pbCtrl seek:slider.value];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (retVal) {
                    AppLog(@"Seek succeed.");
                    self.playedSecs = slider.value;
                    self.curVideoPTS = _playedSecs;
                    _videoPbElapsedTime.text = [Tool translateSecsToString:_playedSecs];
                } else {
                    AppLog(@"Seek failed.");
                    [self showProgressHUDNotice:@"Seek failed" showTime:2.0];
                }
                self.pbTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                              target  :self
                                                              selector:@selector(updateTimeInfo:)
                                                              userInfo:nil
                                                              repeats :YES];
            });
            self.seeking = NO;
        });
    }
     */

    _videoPbElapsedTime.text = [Tool translateSecsToString:slider.value];

}

- (IBAction)sliderTouchDown:(id)sender {
    TRACE();
    if (_played) {
        [_pbTimer invalidate];
        [self hideGCDiscreetNoteView:YES];
        self.seeking = YES;
    }
}

- (IBAction)sliderTouchUpInside:(VideoPlaybackSlideController *)slider {
    if (self.bufferingView.value == 1) {
        self.seeking = NO;
        return;
    }
    TRACE();
    if (_played) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            self.seeking = YES;
            BOOL retVal;
            __block float value;
            dispatch_sync(dispatch_get_main_queue(), ^{
                value = slider.value;
            });
            if (_videoURL) {
                retVal = [[PanCamSDK instance] seek:value];
            } else {
                retVal = [_ctrl.pbCtrl seek:value];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (retVal) {
                    AppLog(@"Seek succeed.");
                    self.playedSecs = slider.value;
                    self.curVideoPTS = _playedSecs;
                    _videoPbElapsedTime.text = [Tool translateSecsToString:_playedSecs];
                } else {
                    AppLog(@"Seek failed.");
                    [self showProgressHUDNotice:@"Seek failed" showTime:2.0];
                }
                
                if (![[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:UseSDKDecode"]
                    && ![_pbTimer isValid]) {
                    self.pbTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                  target  :self
                                                                  selector:@selector(updateTimeInfo:)
                                                                  userInfo:nil
                                                                  repeats :YES];
                }
            });
            self.seeking = NO;
        });
    }
}

- (void)updateTimeInfo:(NSTimer *)sender {
    if (!_seeking) {
        self.playedSecs = _curVideoPTS;
        
        float sliderPercent = _playedSecs/_totalSecs; // slider value
        dispatch_async(dispatch_get_main_queue(), ^{
            _videoPbElapsedTime.text = [Tool translateSecsToString:_playedSecs];
//            AppLog(@"_playedSecs: %f", _playedSecs);
            _slideController.value = [@(_playedSecs) floatValue];
            
            if (sliderPercent > _bufferingView.value) {
                _bufferingView.value = sliderPercent;
                [_bufferingView setNeedsDisplay];
            }
            
            [self hideGCDiscreetNoteView:YES];
        });
    } else {
        AppLog(@"seeking");
    }
    if (++_times == 10) {
        AppLog(@"-------> times: %d", _times1);
        _times1 = 0;
        _times = 0;
    }
#if RUN_DEBUG
    if (++_times == 200) {
        AppLog(@"Time Interval: %fs, getDataTime: %fms, \nstotalElapse: %fms, totalDuration: %fms, D-value: %fms, times: %d", _times * 0.1, _totalElapse1/_times1, _totalElapse/_times1, _totalDuration/_times1, _totalElapse/_times1 - _totalElapse1/_times1, _times1/*_totalDuration - _totalElapse*/);
        _times = 0;
        _times1 = 0;
        _totalDuration = 0.0;
        _totalElapse = 0.0;
        _totalElapse1 = 0.0;
    }
#else
#endif
}

- (IBAction)playbackButtonPressed:(UIButton *)pbButton {
    [self showProgressHUDWithMessage:nil
                      detailsMessage:nil
                                mode:MBProgressHUDModeIndeterminate];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        if(dispatch_semaphore_wait(self.semaphore, time) != 0)  {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgressHUDNotice:@"Timeout!" showTime:2.0];
            });
        } else {
            dispatch_semaphore_signal(self.semaphore);
            BOOL isUseSDKDecode = [[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:UseSDKDecode"];

            if (_played && !_panCampaused) {
                // Pause
                self.panCampaused = YES;
                AppLog(@"call pause");
                if (_videoURL) {
                    self.panCampaused = [[PanCamSDK instance] pause];
                } else {
                    self.panCampaused = [_ctrl.pbCtrl pause];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    _deleteButton.enabled = YES;
                    _actionButton.enabled = YES;
                    if (_panCampaused) {
                        [_pbTimer invalidate];
                        [pbButton setImage:[UIImage imageNamed:@"videoplayer_control_play"]
                                  forState:UIControlStateNormal];
                    }
                    [self hideProgressHUD:YES];
                });
            } else {
                self.PlaybackRun = YES;
                //if (_playedSecs <= 0) {
                if (!_played) {
                    // Play
                    dispatch_async(_videoPlaybackQ, ^{
                        AppLog(@"call play");
                        if (_videoURL) {
                            self.totalSecs = [[PanCamSDK instance] playFile:self.videoURL enableAudio:YES isRemote:NO];
                            [[PanCamSDK instance] seek:0]; // JIRA: MOBILEAPP-90 workaround
                        } else {
//                            auto file = _gallery.videoTable.fileList.at(index);
//                            auto file1 = make_shared<ICatchFile>(*file.get());
                            self.totalSecs = [_ctrl.pbCtrl play:/*file1*/self.currentFile];
                        }
                        if (_totalSecs <= 0) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self showProgressHUDNotice:@"Failed to play" showTime:2.0];
                            });
                            return;
                        }
                        dispatch_sync(dispatch_get_main_queue(), ^{
                            _slideController.enabled = YES;
                        });
                        self.played = YES;
                        self.panCampaused = NO;
                        self.exceptionHappen = NO;

                        dispatch_async(dispatch_get_main_queue(), ^{
                            _deleteButton.enabled = NO;
                            _actionButton.enabled = NO;
                            [pbButton setImage:[UIImage imageNamed:@"videoplayer_control_pause"]
                                      forState:UIControlStateNormal];
                            _videoPbElapsedTime.text = @"00:00:00";
                            _videoPbTotalTime.text = [Tool translateSecsToString:_totalSecs];
                            _slideController.maximumValue = _totalSecs;
                            [self addPlaybackObserver];
                            if (self.view.frame.size.width < self.view.frame.size.height) {
                                [self initControlPanel];
                            } else {
                                [self landscapeControlPanel];
                            }
                            
                            if (!isUseSDKDecode && ![_pbTimer isValid]) {
                                self.pbTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                              target  :self
                                                                              selector:@selector(updateTimeInfo:)
                                                                              userInfo:nil
                                                                              repeats :YES];
                            }

                            [self hideProgressHUD:YES];
                            [self showGCDNoteWithMessage:@"Buffering ..."
                                            withAnimated:YES withAcvity:YES];
                            
                            if (isUseSDKDecode) {
//                                _previewThumb.hidden = YES;
                                self.glkView.hidden = NO;
                                [self startGLKAnimation];
                                if (_videoURL != nil || (_videoURL == nil && [[PanCamSDK instance] isPanoramaWithFile:/*(_gallery.videoTable.fileList.at(index))*/self.currentFile])) {
                                    [self configureGyro];
                                }
                            }
                        });
                        
                        if (!isUseSDKDecode) {
                            if ([/*_ctrl.pbCtrl*/[PanCamSDK instance] audioPlaybackStreamEnabled]) {
                                dispatch_group_async(_playbackGroup, _audioQueue, ^{[self playAudio1];});
                            } else {
                                AppLog(@"Playback doesn't contains audio.");
                            }
                            if ([/*_ctrl.pbCtrl*/[PanCamSDK instance] videoPlaybackStreamEnabled]) {
                                dispatch_group_async(_playbackGroup, _videoQueue, ^{[self playVideo];});
                            } else {
                                AppLog(@"Playback doesn't contains video.");
                            }
                            
                            dispatch_group_notify(_playbackGroup, _videoPlaybackQ, ^{
                                
                            });
                        }
                    });
                } else {
                    // Resume
                    AppLog(@"call resume");
                    if (_videoURL) {
                        self.panCampaused = ![[PanCamSDK instance] resume];
                    } else {
                        self.panCampaused = ![_ctrl.pbCtrl resume];
                    }
                    if (!_panCampaused) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            _deleteButton.enabled = NO;
                            _actionButton.enabled = NO;
                            
                            if (!isUseSDKDecode && ![_pbTimer isValid]) {
                                self.pbTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                              target  :self
                                                                              selector:@selector(updateTimeInfo:)
                                                                              userInfo:nil
                                                                              repeats :YES];
                                
                            }

                            [pbButton setImage:[UIImage imageNamed:@"videoplayer_control_pause"]
                                      forState:UIControlStateNormal];
                            [self hideProgressHUD:YES];
                        });
                    }
                }
            }
            
        }
    });
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
//    if (!self.paused) {
//        [[PanCamSDK instance] panCamSetViewPort:0 andY:0 andWidth:(int)view.drawableWidth andHeight:(int)view.drawableHeight];
//        [[PanCamSDK instance] panCamRender];
//    }
    
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
                //NSLog(@"%.2f, %.2f, %.2f, %ld", gyroData.rotationRate.x, gyroData.rotationRate.y, gyroData.rotationRate.z, timestamp);
                float speedX = roundf(gyroData.rotationRate.x * 10) / 10;
                float speedY = roundf(gyroData.rotationRate.y * 10) / 10;
                float speedZ = roundf(gyroData.rotationRate.z * 10) / 10;
                
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
        
        if (_videoURL != nil || (_videoURL == nil && [[PanCamSDK instance] isPanoramaWithFile:/*(_gallery.videoTable.fileList.at(index))*/self.currentFile])) {
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

- (void)playVideo {
    //ICatchVideoFormat format = [_ctrl.propCtrl retrievePlaybackVideoFormat];
    auto format = [[PanCamSDK instance] getPlaybackVideoFormat];
    int width = format->getVideoW();
    int height = format->getVideoH();
    AppLog(@"width: %d, height: %d", width, height);
    
    /*if (width > 1920 || height > 1080 || width == 0 || height == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _PlaybackRun = NO;
            _previewThumb.image = nil;
            [self hideGCDiscreetNoteView:YES];

            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:@"暂不支持该尺寸视频在线播放" delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil, nil];
            
            alert.tag = 11;
            [alert show];
        });
    } else {*/
        if (format->getCodec() == ICH_CODEC_JPEG) {
            AppLog(@"playbackVideoMJPEG");
            dispatch_async(dispatch_get_main_queue(), ^{
                _previewThumb.hidden = NO;
                self.glkView.hidden = YES;
                _avslayer.hidden = YES;
            });
            
            [self playbackVideoMJPEG];
        } else if (format->getCodec() == ICH_CODEC_H264) {
            AppLog(@"playbackVideoH264");
            dispatch_async(dispatch_get_main_queue(), ^{
                _avslayer.hidden = NO;
                _avslayer.bounds = self.view.bounds;
                _avslayer.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
                
                _previewThumb.hidden = YES;
                self.glkView.hidden = YES;
                self.paused = YES;
#if 0
                [self startGLKAnimation];
                
                if (_videoURL != nil || (_videoURL == nil && [[PanCamSDK instance] isPanorama])) {
                    [self configureGyro];
                }
#endif
            });
            
            [self playbackVideoH264Normal:format];
        } else {
            AppLog(@"Unknown codec.");
        //}
    }
    
    AppLog(@"Break video");
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case 11:
            if (buttonIndex == 0) {
                [self returnBack:nil];
            }
            break;
            
        default:
            break;
    }
}

- (void)playbackVideoH264:(shared_ptr<ICatchVideoFormat>)format {
    [[PanCamSDK instance] panCamUpdateFormat:format];
    
    NSRange headerRange = NSMakeRange(0, 4);
    NSMutableData *headFrame = nil;
    uint32_t nalSize = 0;
    
    while (_PlaybackRun) {
        // HW decode
        [_h264Decoder initH264Env:format];
        for(;;) {
            @autoreleasepool {
                // 1st frame contains sps & pps data.
#if RUN_DEBUG
                NSDate *begin = [NSDate date];
                WifiCamAVData *wifiCamData = [_ctrl.propCtrl prepareDataForPlaybackVideoFrame];
                NSDate *end = [NSDate date];
                NSTimeInterval elapse = [end timeIntervalSinceDate:begin];
                AppLog(@"[V]Get %lu, elapse: %f", (unsigned long)wifiCamData.data.length, elapse);
#else
                //WifiCamAVData *wifiCamData = [_ctrl.propCtrl prepareDataForPlaybackVideoFrame];
                WifiCamAVData *wifiCamData = [[PanCamSDK instance] getPlaybackVideoData];
#endif
                if (wifiCamData.data.length > 0) {
                    self.curVideoPTS = wifiCamData.time;
                    
                    NSUInteger loc = format->getCsd_0_size() + format->getCsd_1_size();
                    nalSize = (uint32_t)(wifiCamData.data.length - loc - 4);
                    NSRange iRange = NSMakeRange(loc, wifiCamData.data.length - loc);
                    const uint8_t lengthBytes[] = {(uint8_t)(nalSize>>24),
                        (uint8_t)(nalSize>>16), (uint8_t)(nalSize>>8), (uint8_t)nalSize};
                    headFrame = [NSMutableData dataWithData:[wifiCamData.data subdataWithRange:iRange]];
                    [headFrame replaceBytesInRange:headerRange withBytes:lengthBytes];
                    [_h264Decoder decode:headFrame];
                    
                    break;
                }
            }
        }
        while (_PlaybackRun) {
            @autoreleasepool {
#if RUN_DEBUG
                NSDate *begin = [NSDate date];
                WifiCamAVData *wifiCamData = [_ctrl.propCtrl prepareDataForPlaybackVideoFrame];
                NSDate *end = [NSDate date];
                NSTimeInterval elapse = [end timeIntervalSinceDate:begin];
                AppLog(@"[V]Get %lu, elapse: %f", (unsigned long)wifiCamData.data.length, elapse);
#else
                //WifiCamAVData *wifiCamData = [_ctrl.propCtrl prepareDataForPlaybackVideoFrame];
                WifiCamAVData *wifiCamData = [[PanCamSDK instance] getPlaybackVideoData];
#endif
                if (wifiCamData.data.length > 0) {
                    _times1 ++;
                    self.curVideoPTS = wifiCamData.time;
                    nalSize = (uint32_t)(wifiCamData.data.length - 4);
                    const uint8_t lengthBytes[] = {(uint8_t)(nalSize>>24),
                        (uint8_t)(nalSize>>16), (uint8_t)(nalSize>>8), (uint8_t)nalSize};
                    [wifiCamData.data replaceBytesInRange:headerRange withBytes:lengthBytes];
                    [_h264Decoder decode:wifiCamData.data];
                }
            }
        }
        [_h264Decoder clearH264Env];
    }
}

- (void)playbackVideoH264Normal:(shared_ptr<ICatchVideoFormat>) format {
    NSRange headerRange = NSMakeRange(0, 4);
    NSMutableData *headFrame = nil;
    uint32_t nalSize = 0;
    
    while (_PlaybackRun) {
        //flush avslayer when active from background
        if (self.avslayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
            [self.avslayer flush];
        }
        
        // HW decode
        [_h264Decoder initH264Env:format];
        for(;;) {
            @autoreleasepool {
                // 1st frame contains sps & pps data.
                WifiCamAVData *avData = [[PanCamSDK instance] getPlaybackVideoData];
                if (avData.data.length > 0) {
                    self.curVideoPTS = avData.time;
                    
                    NSUInteger loc = format->getCsd_0_size() + format->getCsd_1_size();
                    nalSize = (uint32_t)(avData.data.length - loc - 4);
                    NSRange iRange = NSMakeRange(loc, avData.data.length - loc);
                    const uint8_t lengthBytes[] = {(uint8_t)(nalSize>>24),
                        (uint8_t)(nalSize>>16), (uint8_t)(nalSize>>8), (uint8_t)nalSize};
                    headFrame = [NSMutableData dataWithData:[avData.data subdataWithRange:iRange]];
                    [headFrame replaceBytesInRange:headerRange withBytes:lengthBytes];
                    [_h264Decoder decodeAndDisplayH264Frame:headFrame withDisplayLayer:_avslayer];
                    
                    break;
                }
            }
        }
        while (_PlaybackRun) {
            @autoreleasepool {
                WifiCamAVData *avData = [[PanCamSDK instance] getPlaybackVideoData];
                if (avData.data.length > 0) {
                    self.curVideoPTS = avData.time;
                    nalSize = (uint32_t)(avData.data.length - 4);
                    const uint8_t lengthBytes[] = {(uint8_t)(nalSize>>24),
                        (uint8_t)(nalSize>>16), (uint8_t)(nalSize>>8), (uint8_t)nalSize};
                    [avData.data replaceBytesInRange:headerRange withBytes:lengthBytes];
                    [_h264Decoder decodeAndDisplayH264Frame:avData.data withDisplayLayer:_avslayer];
                }
            }
        }
        [_h264Decoder clearH264Env];
    }
}

- (void)playbackVideoMJPEG
{
    UIImage *receivedImage = nil;
//    NSTimeInterval oneMinute = 0;
//    __block uint frameCount = 0;
    
    while (_PlaybackRun/* && _played && !_paused*/) {
        @autoreleasepool {
#if RUN_DEBUG
            NSDate *begin = [NSDate date];
            WifiCamAVData *wifiCamData = [_ctrl.propCtrl prepareDataForPlaybackVideoFrame];
            
            /*
             if (_exceptionHappen) {
             break;
             }
             if ((wifiCamData.state != ICH_SUCCEED) && (wifiCamData.state != ICH_TRY_AGAIN)) {
             if ((wifiCamData.state != ICH_VIDEO_STREAM_CLOSED)
             && (wifiCamData.state != ICH_AUDIO_STREAM_CLOSED)) {
             AppLog(@"wifiCamData.state: %d", wifiCamData.state);
             
             } else {
             AppLog(@"Exception happened!");
             self.exceptionHappen = YES;
             }
             break;
             }
             */
            
            
            if (wifiCamData.data.length > 0) {
                self.curVideoPTS = wifiCamData.time;
                receivedImage = [[UIImage alloc] initWithData:wifiCamData.data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (receivedImage) {
                        _previewThumb.image = receivedImage;
                    }
                });
                receivedImage = nil;
                //            ++frameCount;
            }
            NSDate *end = [NSDate date];
            NSTimeInterval elapse = [end timeIntervalSinceDate:begin];
            AppLog(@"[V]Get %lu, elapse: %f", (unsigned long)wifiCamData.data.length, elapse * 1000);
#else
            //WifiCamAVData *wifiCamData = [_ctrl.propCtrl prepareDataForPlaybackVideoFrame];
            WifiCamAVData *wifiCamData = [[PanCamSDK instance] getPlaybackVideoData];

            if (wifiCamData.data.length > 0) {
                self.curVideoPTS = wifiCamData.time;
                receivedImage = [[UIImage alloc] initWithData:wifiCamData.data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (receivedImage) {
                        _previewThumb.image = receivedImage;
                    }
                });
                receivedImage = nil;
            }
#endif
            //        NSDate *end = [NSDate date];
            //        NSTimeInterval elapse = [end timeIntervalSinceDate:begin];
            //        oneMinute += elapse;
            //        if (oneMinute >= 0.99) {
            //            AppLog(@"[MJPG] frameCount: %d", frameCount);
            //            frameCount = 0;
            //            oneMinute = 0;
            //        }
        }
    }
    AppLog(@"quit video");
}

- (void)playAudio1
{
    NSMutableData *audioBuffer = [[NSMutableData alloc] init];

    //ICatchAudioFormat format = [_ctrl.propCtrl retrievePlaybackAudioFormat];
    auto format =  [[PanCamSDK instance] getPlaybackAudioFormat];
    AppLog(@"Codec:%x, freq: %d, chl: %d, bit:%d", format->getCodec(), format->getFrequency(), format->getNChannels(), format->getSampleBits());
    
    _pcmPl = [[PCMDataPlayer alloc] initWithFreq:format->getFrequency() channel:format->getNChannels() sampleBit:format->getSampleBits()];
    if (!_pcmPl) {
        AppLog(@"Init audioQueue failed.");
        return;
    }
    
    while (_PlaybackRun) {
        @autoreleasepool {
            NSDate *begin = [NSDate date];
            [audioBuffer setLength:0];
            
            for (int i = 0; i < 4; i++) {
                NSDate *begin1 = [NSDate date];
                //ICatchFrameBuffer *buff = [_ctrl.propCtrl prepareDataForPlaybackAudioTrack1];
                auto buff = [[PanCamSDK instance] getPlaybackAudioData1];
                NSDate *end1 = [NSDate date];
                NSTimeInterval elapse1 = [end1 timeIntervalSinceDate:begin1] * 1000;
                RunLog(@"getNextAudioFrame time: %fms", elapse1);
                _totalElapse1 += elapse1;
                
                if (buff != NULL) {
                    [audioBuffer appendBytes:buff->getBuffer() length:buff->getFrameSize()];
                    if (audioBuffer.length > MIN_SIZE_PER_FRAME) {
                        break;
                    }
                }
            }
            
            if (audioBuffer.length > 0) {
                [_pcmPl play:(void *)audioBuffer.bytes length:audioBuffer.length];
            }
            
            NSDate *end = [NSDate date];
            NSTimeInterval elapse = [end timeIntervalSinceDate:begin] * 1000;
            float duration = audioBuffer.length/4.0/format->getFrequency() * 1000;
            RunLog(@"[A]Get %lu, elapse: %fms, duration: %fms", (unsigned long)audioBuffer.length, elapse, duration);
            _totalElapse += elapse;
            _totalDuration += duration;
            //_times1 ++;
        }
    }
    
    if (_pcmPl) {
        [_pcmPl stop];
    }
    _pcmPl = nil;
    
    AppLog(@"quit audio");
}

- (void)playAudio
{
    NSMutableData *audioDataBuffer = [[NSMutableData alloc] init];
    
    self.al = [[HYOpenALHelper alloc] init];
    //ICatchAudioFormat format = [_ctrl.propCtrl retrievePlaybackAudioFormat];
    auto format = [[PanCamSDK instance] getPlaybackAudioFormat];
    AppLog(@"Codec:%x, freq: %d, chl: %d, bit:%d", format->getCodec(), format->getFrequency(), format->getNChannels(), format->getSampleBits());

    if (![_al initOpenAL:format->getFrequency() channel:format->getNChannels() sampleBit:format->getSampleBits()]) {
        AppLog(@"Init openAL failed.");
        return;
    }
    
    while (_PlaybackRun) {
        @autoreleasepool {
            NSDate *begin = [NSDate date];
            [audioDataBuffer setLength:0];
            
            for (int i = 0; i < 4; i++) {
                //ICatchFrameBuffer *buf = [_ctrl.propCtrl prepareDataForPlaybackAudioTrack1];
                auto buf = [[PanCamSDK instance] getPlaybackAudioData1];
                if (buf != NULL) {
                    [audioDataBuffer appendBytes:buf->getBuffer() length:buf->getFrameSize()];
                }
            }
            
            NSDate *end1 = [NSDate date];
            AppLog(@"getNextAudioFrame time: %fms", [end1 timeIntervalSinceDate:begin] * 1000);
            
            if (audioDataBuffer.length > 0) {
                [_al insertPCMDataToQueue:audioDataBuffer.bytes size:audioDataBuffer.length];
                if ([_al getInfo]) {
                    [_al play];
                }
            }
            
            NSDate *end = [NSDate date];
            NSTimeInterval elapse = [end timeIntervalSinceDate:begin] * 1000;
            float duration = audioDataBuffer.length/4.0/format->getFrequency() * 1000;
            AppLog(@"[A]Get %lu, elapse: %fms, duration: %fms, setData: %fms", (unsigned long)audioDataBuffer.length, elapse, duration, [end timeIntervalSinceDate:end1] * 1000);
            _totalElapse += elapse;
            _totalDuration += duration;
        }
    }

    AppLog(@"quit audio");
    [_al clean];
    self.al = nil;
}
//- (void)playAudio
//{
////    NSData *audioBufferData = nil;
//    double audioT = 0.0;
//    double averageT = 0.0;
//    int times = 4;
//    WifiCamAVData *audioBufferData = nil;
//    NSMutableData *audioBuffer = [[NSMutableData alloc] init];
//    self.al = [[HYOpenALHelper alloc] init];
//    ICatchAudioFormat format = [_ctrl.propCtrl retrievePlaybackAudioFormat];
//    AppLog(@"Codec:%x, freq: %d, chl: %d, bit:%d", format.getCodec(), format.getFrequency(), format.getNChannels(), format.getSampleBits());
//    
//    if (![_al initOpenAL:format.getFrequency() channel:format.getNChannels() sampleBit:format.getSampleBits()]) {
//        AppLog(@"Init openAL failed.");
//        return;
//    }
//    
//    while (_PlaybackRun/* && _played && !_paused && !_exceptionHappen*/) {
//        NSDate *begin = [NSDate date];
//        
//        int count = [_al getInfo];
//        if(count < times + 1) {
//            if (count == 1) {
//                [_al play];
//            }
//           
//            audioT = 0.0;
//            [audioBuffer setLength:0];
//            
//            for (int i=0; i<times; ++i) {
//                
////                NSDate *begin = [NSDate date];
//                audioBufferData = [_ctrl.propCtrl prepareDataForPlaybackAudioTrack];
////                NSDate *end = [NSDate date];
////                NSTimeInterval elapse = [end timeIntervalSinceDate:begin];
////                AppLog(@"[A]Get %lu, elapse: %f", (unsigned long)audioBufferData.data.length, elapse);
//                
//                if (audioBufferData) {
//                    audioT += audioBufferData.time;
//                    [audioBuffer appendData:audioBufferData.data];
//                }
//            }
//            
//            if(audioBuffer.length>0) {
//                [_al insertPCMDataToQueue:audioBuffer.bytes
//                                     size:audioBuffer.length];
//            }
//            averageT = audioT/times;
//            
//        } else {
////            [_al play];
//            if ((_curVideoPTS - averageT <= 0.15 || averageT - _curVideoPTS <= 0.15 ) && _curVideoPTS != 0) {
////                [NSThread sleepForTimeInterval:0.005];
//                [_al play];
//            }
//            
////            if (averageT - _curVideoPTS >= 0.15 && _curVideoPTS != 0) {
////                [_al pause];
////            }
//            else if (averageT - _curVideoPTS > 0.15 && _curVideoPTS != 0){
////                [NSThread sleepForTimeInterval:0.002];
//                times ++;
//                [_al pause];
//            } else if (_curVideoPTS - averageT > 0.15 && _curVideoPTS != 0) {
//                times --;
//            }
//        }
//        
//        NSDate *end = [NSDate date];
//        NSTimeInterval elapse = [end timeIntervalSinceDate:begin] * 1000;
//        float duration = audioBuffer.length/4.0/format.getFrequency() * 1000;
//        AppLog(@"[A]Get %lu, elapse: %fms, duration: %fms", (unsigned long)audioBuffer.length, elapse, duration);
//        _totalElapse += elapse;
//        _totalDuration += duration;
//    }
//    AppLog(@"quit audio, %d, %d, %d", _played, _paused, _exceptionHappen);
//    
////        NSDate *begin = [NSDate date];
////        WifiCamAVData *wifiCamData = [_ctrl.propCtrl prepareDataForPlaybackAudioTrack];
////        NSDate *end = [NSDate date];
////        NSTimeInterval elapse = [end timeIntervalSinceDate:begin];
////        AppLog(@"[A]Get %lu, elapse: %f", (unsigned long)wifiCamData.data.length, elapse);
////        
////        if (wifiCamData.data.length > 0) {
////            [_al insertPCMDataToQueue:wifiCamData.data.bytes
////                                 size:wifiCamData.data.length];
////            if((wifiCamData.time >= _curVideoPTS - 0.25 && _curVideoPTS != 0) ||
////               (wifiCamData.time <= _curVideoPTS + 0.25 && _curVideoPTS != 0)) {
////                [_al play];
////            } else {
////                [_al pause];
////            }
////        }
////        
////    }
////    AppLog(@"quit audio, %d, %d, %d", _played, _paused, _exceptionHappen);
//    
//    [_al clean];
//    self.al = nil;
//
//}

- (IBAction)deleteButtonPressed:(UIBarButtonItem *)sender {
    if (_played && !_panCampaused) {
        [self playbackButtonPressed:_playbackButton];
    }
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIViewController *vc = [[UIViewController alloc] init];
        UIButton *testButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 260.0f, 47.0f)];
        [testButton setTitle:NSLocalizedString(@"SureDelete", @"") forState:UIControlStateNormal];
        [testButton setBackgroundImage:[[UIImage imageNamed:@"iphone_delete_button.png"] stretchableImageWithLeftCapWidth:8.0f
                                                                                                             topCapHeight:0.0f]
                              forState:UIControlStateNormal];
        [testButton addTarget:self action:@selector(deleteDetail:) forControlEvents:UIControlEventTouchUpInside];
        [vc.view addSubview:testButton];
        
        UIPopoverController *popController = [[UIPopoverController alloc] initWithContentViewController:vc];
        popController.popoverContentSize = CGSizeMake(260.0f, 47.0f);
        _popController = popController;
        [_popController presentPopoverFromBarButtonItem:_deleteButton
                               permittedArrowDirections:UIPopoverArrowDirectionAny
                                               animated:YES];
    } else {
        
#if USE_SYSTEM_IOS7_IMPLEMENTATION
        _actionsSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                      destructiveButtonTitle:NSLocalizedString(@"SureDelete", @"")
                                           otherButtonTitles:nil, nil];
        _actionsSheet.tag = ACTION_SHEET_DELETE_ACTIONS;
        [_actionsSheet showFromBarButtonItem:sender animated:YES];
#else
        _actionsSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [_actionsSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
        [_actionsSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"SureDelete", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self deleteDetail:self];
        }]];
        
        [self presentViewController:_actionsSheet animated:YES completion:nil];
#endif
        
    }
}

- (IBAction)deleteDetail:(id)sender
{
    if ([sender isKindOfClass:[UIButton self]]) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    [self showProgressHUDWithMessage:NSLocalizedString(@"Deleting", nil) detailsMessage:nil mode:MBProgressHUDModeIndeterminate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL deleteResult = NO;
        
        [self stopVideoPb];
#if USE_NEW_MPB
        if ([_delegate respondsToSelector:@selector(videoPlaybackController:deleteVideoFile:)]) {
            deleteResult = [self.delegate videoPlaybackController:self deleteVideoFile:self.currentFile];
        }
#else
        if([_delegate respondsToSelector:@selector(videoPlaybackController:deleteVideoAtIndex:)]) {
            deleteResult = [self.delegate videoPlaybackController:self deleteVideoAtIndex:index];
        }
#endif
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (deleteResult) {
                [self hideProgressHUD:YES];
//                [self.navigationController popToRootViewControllerAnimated:YES];
#if 0
                [self dismissViewControllerAnimated:YES completion:nil];
#else
                [self returnBack:nil];
#endif
            } else {
                [self showProgressHUDNotice:NSLocalizedString(@"DeleteError", nil) showTime:2.0];
            }
            
        });
        
    });
}


- (IBAction)actionButtonPressed:(UIBarButtonItem *)sender {
    if (_played && !_panCampaused) {
        [self playbackButtonPressed:_playbackButton];
    }
    
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    
//    auto file = _gallery.videoTable.fileList.at(index);
    unsigned long long size = /*file*/self.currentFile->getFileSize() >> 20;
    double downloadTime = ((double)size)/60;
    //downloadTime = MAX(1, downloadTime);
    
    NSString *confrimButtonTitle = nil;
    NSString *message = NSLocalizedString(@"DownloadConfirmMessage", nil);
    message = [message stringByReplacingOccurrencesOfString:@"%1"
                                                 withString:[[NSString alloc] initWithFormat:@"%d", 1]];
    message = [message stringByReplacingOccurrencesOfString:@"%2"
                                                 withString:[[NSString alloc] initWithFormat:@"%.2f", downloadTime]];
    confrimButtonTitle = NSLocalizedString(@"SureDownload", @"");
    
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        MpbPopoverViewController *contentViewController = [[MpbPopoverViewController alloc] initWithNibName:@"MpbPopover" bundle:nil];
        contentViewController.msg = message;
        
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
            contentViewController.msgColor = [UIColor blackColor];
        } else {
            contentViewController.msgColor = [UIColor whiteColor];
        }
        
        UIButton *downloadConfirmButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0f, 120.0f, 260.0f, 47.0f)];
        [downloadConfirmButton setTitle:confrimButtonTitle
                               forState:UIControlStateNormal];
        [downloadConfirmButton setBackgroundImage:[[UIImage imageNamed:@"iphone_delete_button.png"] stretchableImageWithLeftCapWidth:8.0f topCapHeight:0.0f]
                                         forState:UIControlStateNormal];
        [downloadConfirmButton addTarget:self action:@selector(downloadDetail:) forControlEvents:UIControlEventTouchUpInside];
        [contentViewController.view addSubview:downloadConfirmButton];
        
        UIPopoverController *popController = [[UIPopoverController alloc] initWithContentViewController:contentViewController];
        popController.popoverContentSize = CGSizeMake(270.0f, 170.0f);
        _popController = popController;
        [_popController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        NSString *msg = message;
        
#if USE_SYSTEM_IOS7_IMPLEMENTATION
        _actionsSheet = [[UIActionSheet alloc] initWithTitle:msg
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                      destructiveButtonTitle:confrimButtonTitle
                                           otherButtonTitles:nil, nil];
        _actionsSheet.tag = ACTION_SHEET_DOWNLOAD_ACTIONS;
        //[self.sheet showInView:self.view];
        //[self.sheet showInView:[UIApplication sharedApplication].keyWindow];
        [_actionsSheet showFromBarButtonItem:_actionButton animated:YES];
#else
        _actionsSheet = [UIAlertController alertControllerWithTitle:msg message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [_actionsSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
        [_actionsSheet addAction:[UIAlertAction actionWithTitle:confrimButtonTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self downloadDetail:self];
        }]];
        [self presentViewController:_actionsSheet animated:YES completion:nil];
#endif
        
    }
}

- (IBAction)downloadDetail:(id)sender
{
//    dispatch_queue_t downloadQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.Donwload", 0);
    
    if ([sender isKindOfClass:[UIButton self]]) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    [self addObserver:self
           forKeyPath:@"downloadedPercent"
              options:NSKeyValueObservingOptionNew
              context:nil];
    [self showProgressHUDWithMessage:NSLocalizedString(@"DownloadingTitle", @"")
                      detailsMessage:nil
                                mode:MBProgressHUDModeAnnularDeterminate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_videoURL) {
            [[SDK instance] setIsBusy:YES];
        } else {
            [_ctrl.fileCtrl resetBusyToggle:YES];
        }
        
        UIApplication  *app = [UIApplication sharedApplication];
        UIBackgroundTaskIdentifier downloadTask = [app beginBackgroundTaskWithExpirationHandler:^{
            AppLog(@"-->Expirationed.");
            NSArray *oldNotifications = [app scheduledLocalNotifications];
            // Clear out the old notification before scheduling a new one
            if ([oldNotifications count] > 5) {
                [app cancelAllLocalNotifications];
            }
            
            UILocalNotification *alarm = [[UILocalNotification alloc] init];
            if (alarm) {
                alarm.fireDate = [NSDate date];
                alarm.timeZone = [NSTimeZone defaultTimeZone];
                alarm.repeatInterval = 0;
                NSString *str = [[NSString alloc] initWithFormat:@"App is about to exit .Please bring it to foreground to continue dowloading."];
                alarm.alertBody = str;
                alarm.soundName = UILocalNotificationDefaultSoundName;
                
                [app scheduleLocalNotification:alarm];
            }
        }];
        
#if 0
        BOOL downloadResult = YES;
        _downloadFileProcessing = YES;
        // Download percent!
//        auto file = _gallery.videoTable.fileList.at(index);
        shared_ptr<ICatchFile>pFile = /*file*/self.currentFile;
        
        // add calc download Percent new func
        NSString *fileName = [NSString stringWithUTF8String:pFile->getFileName().c_str()];
        unsigned long long fileSize = pFile->getFileSize();
        
        NSString *fileDirectory = nil;
        if ([fileName hasSuffix:@".MP4"] || [fileName hasSuffix:@".MOV"] || [fileName hasSuffix:@".AVI"]) {
            fileDirectory = [[SDK instance] createMediaDirectory][2];
        } else {
            fileDirectory = [[SDK instance] createMediaDirectory][1];
        }
        
        NSString *locatePath = [fileDirectory stringByAppendingPathComponent:fileName];
        AppLog(@"locatePath: %@, %llu", locatePath, fileSize);
        
        dispatch_async(downloadQueue, ^{
            while (_downloadFileProcessing) {
                @autoreleasepool {
//                    self.downloadedPercent = [_ctrl.fileCtrl requestDownloadedPercent:pFile];
                    self.downloadedPercent = [_ctrl.fileCtrl requestDownloadedPercent2:locatePath fileSize:fileSize];
                }
            }
        });
        // Downloading...
        if (![[SDK instance] openFileTransChannel]) {
            return;
        }
        
        downloadResult = [_ctrl.fileCtrl downloadFile2:pFile];
        _downloadFileProcessing = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeObserver:self forKeyPath:@"downloadedPercent"];
            NSString *message = nil;
            if (downloadResult) {
                message = NSLocalizedString(@"Download complete", nil);
            } else {
                //SaveError
                message = NSLocalizedString(@"SaveError", nil);
            }
            [self showProgressHUDCompleteMessage:message];
        });
        
        [_ctrl.fileCtrl resetBusyToggle:NO];
        [[UIApplication sharedApplication] endBackgroundTask:downloadTask];
        //downloadTask = UIBackgroundTaskInvalid;
        
        if (![[SDK instance] closeFileTransChannel]) {
            return;
        }
#else
        BOOL downloadResult = [self downloadHandle];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeObserver:self forKeyPath:@"downloadedPercent"];
            NSString *message = nil;
            if (downloadResult) {
                message = NSLocalizedString(@"Download complete", nil);
            } else {
                //SaveError
                message = NSLocalizedString(@"SaveError", nil);
            }
            [self showProgressHUDCompleteMessage:message];
            
            if (downloadResult) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self showActivityViewController:self.actionButton];
                });
            }
        });
        
        if (_videoURL) {
            [[SDK instance] setIsBusy:NO];
        } else {
            [_ctrl.fileCtrl resetBusyToggle:NO];
        }
        [[UIApplication sharedApplication] endBackgroundTask:downloadTask];
#endif
    });
}

- (BOOL)downloadHandle {
    NSString *fileName = [NSString stringWithUTF8String:self.currentFile->getFileName().c_str()];
    long long fileSize = self.currentFile->getFileSize();

    NSString *fileDirectory = nil;
    if ([fileName hasSuffix:@".MP4"] || [fileName hasSuffix:@".MOV"] || [fileName hasSuffix:@".AVI"]) {
        fileDirectory = [[SDK instance] createMediaDirectory][2];
    } else {
        fileDirectory = [[SDK instance] createMediaDirectory][1];
    }
    
    NSString *filePath = [fileDirectory stringByAppendingPathComponent:fileName];

    NSArray *mediaDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fileDirectory error:nil];
    
    if (mediaDirectoryContents.count) {
        for (NSString *name in mediaDirectoryContents) {
            if ([name isEqualToString:fileName]) {
                long long tempSize = [DiskSpaceTool fileSizeAtPath:filePath];
                
                if (fileSize == tempSize) {
                    AppLog(@"Local already exist file: %@", fileName);
                    AppLog(@"locatePath: %@, %llu", filePath, fileSize);
                    
                    self.localFilePath = [NSURL fileURLWithPath:filePath];
                    return YES;
                }
            }
        }
    }
    
    BOOL downloadResult = YES;
    _downloadFileProcessing = YES;
    AppLog(@"locatePath: %@, %llu", filePath, fileSize);
    
    dispatch_queue_t downloadQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.Donwload", 0);
    dispatch_async(downloadQueue, ^{
        while (_downloadFileProcessing) {
            @autoreleasepool {
                self.downloadedPercent = [_ctrl.fileCtrl requestDownloadedPercent2:filePath fileSize:fileSize];
            }
        }
    });
    
    // Downloading...
    if (![[SDK instance] openFileTransChannel]) {
        return downloadResult;
    }
    
//    downloadResult = [_ctrl.fileCtrl downloadFile2:self.currentFile];
    if ([[SDK instance] p_downloadFile2:self.currentFile] == nil) {
        downloadResult = NO;
    }
    _downloadFileProcessing = NO;
    
    self.localFilePath = downloadResult ? [NSURL fileURLWithPath:filePath] : nil;
        
    if (![[SDK instance] closeFileTransChannel]) {
        return downloadResult;
    }
    
    return downloadResult;
}

- (void)showActivityViewController:(id)sender
{
    AppLog(@"%s", __func__);
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    uint shareNum = 1;
    uint assetNum = (uint)[[SDK instance] retrieveCameraRollAssetsResult].count;
    
    if (self.localFilePath != nil) {
        
        if (self.localFilePath != nil && !UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(self.localFilePath.path)) {
            shareNum = 0;
        }
        
        UIActivityViewController *activityVc = [[UIActivityViewController alloc]initWithActivityItems:@[self.localFilePath] applicationActivities:nil];
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [self presentViewController:activityVc animated:YES completion:nil];
        } else {
            // Create pop up
            UIPopoverController *activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityVc];
            // Show UIActivityViewController in popup
            [activityPopoverController presentPopoverFromBarButtonItem:(UIBarButtonItem *)sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
        
        activityVc.completionWithItemsHandler = ^(NSString *activityType,
                                                  BOOL completed,
                                                  NSArray *returnedItems,
                                                  NSError *error) {
            if (completed) {
                AppLog(@"We used activity type: %@", activityType);
                
                if ([activityType isEqualToString:@"com.apple.UIKit.activity.SaveToCameraRoll"]) {
                    dispatch_async(dispatch_queue_create("WifiCam.GCD.Queue.Share", DISPATCH_QUEUE_SERIAL), ^{
                        [self showProgressHUDWithMessage:NSLocalizedString(@"PhotoSavingWait", nil)];
                        
                        BOOL ret;
                        AppLog(@"shareNum: %d", shareNum);
                        ret = [[SDK instance] savetoAlbum:@"MobileCamApp" andAlbumAssetNum:assetNum andShareNum:shareNum];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"kCameraDownloadCompleteNotification"
                                                                                object:[NSNumber numberWithInt:ret]];
                            
                            if (ret) {
                                [self showProgressHUDCompleteMessage:NSLocalizedString(@"SavePhotoToAlbum", nil)];
                            } else {
                                [self showProgressHUDCompleteMessage:NSLocalizedString(@"SaveError", nil)];
                            }
                            
                            self.localFilePath = nil;
                        });
                    });
                }
            } else {
                AppLog(@"We didn't want to share anything after all.");
            }
            
            if (error) {
                AppLog(@"An Error occured: %@, %@", error.localizedDescription, error.localizedFailureReason);
            }
        };
    } else {
        [self showAlertViewWithTitle:NSLocalizedString(@"SaveError", nil) message:nil cancelButtonTitle:NSLocalizedString(@"Sure", @"")];
        
        self.localFilePath = nil;
    }
}

- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - GCDiscreetNotificationView
-(GCDiscreetNotificationView *)notificationView {
    if (!_notificationView) {
        _notificationView = [[GCDiscreetNotificationView alloc] initWithText:nil
                                                                showActivity:NO
                                                          inPresentationMode:GCDiscreetNotificationViewPresentationModeTop
                                                                      inView:self.view];
    }
    return _notificationView;
}

- (void)showGCDNoteWithMessage:(NSString *)message
                  withAnimated:(BOOL)animated
                    withAcvity:(BOOL)activity{
    
    [self.notificationView setTextLabel:message];
    [self.notificationView setShowActivity:activity];
    [self.notificationView show:animated];
    
}

- (void)showGCDNoteWithMessage:(NSString *)message
                       andTime:(NSTimeInterval) timeInterval
                    withAcvity:(BOOL)activity{
    [self.notificationView setTextLabel:message];
    [self.notificationView setShowActivity:activity];
    [self.notificationView showAndDismissAfter:timeInterval];
    
}

- (void)hideGCDiscreetNoteView:(BOOL)animated {
    [self.notificationView hide:animated];
}

#pragma mark - Gesture
- (IBAction)tapToHideControl:(UITapGestureRecognizer *)sender {
    TRACE();
//    if (UIDeviceOrientationIsPortrait([UIDevice currentDevice].orientation)) {
    if (self.view.frame.size.width < self.view.frame.size.height) {
        return;
    }
    if (_controlHidden) {
        [self.navigationController setNavigationBarHidden:NO];
//        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        _pbCtrlPanel.hidden = NO;
        _bufferingBgView.hidden = NO;
        _bufferingView.hidden = NO;
        _slideController.hidden = NO;
        [self landscapeControlPanel];
    } else {
        [self.navigationController setNavigationBarHidden:YES];
//        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        _pbCtrlPanel.hidden = YES;
        _bufferingBgView.hidden = YES;
        _bufferingView.hidden = YES;
        _slideController.hidden = YES;
    }
    self.controlHidden = !_controlHidden;
}

- (IBAction)panToFastMove:(UIPanGestureRecognizer *)sender {
    AppLog(@"%s", __func__);
    
}

//-(BOOL)prefersStatusBarHidden {
//    if (_controlHidden) {
//        return NO;
//    } else {
//        return YES;
//    }
//}

#if USE_SYSTEM_IOS7_IMPLEMENTATION

#pragma mark - UIActionSheetDelegate
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    _actionsSheet = nil;
    
    switch (actionSheet.tag) {
        case ACTION_SHEET_DOWNLOAD_ACTIONS:
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                [self downloadDetail:self];
            }
            break;
            
        case ACTION_SHEET_DELETE_ACTIONS:
            if (buttonIndex == actionSheet.destructiveButtonIndex) {
                [self deleteDetail:self];
            }
            break;
            
        default:
            break;
    }
    
}
#else
#endif

#pragma mark - UIPopoverControllerDelegate
-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    _popController = nil;
}

#pragma mark -
-(void)streamCloseCallback {
    self.PlaybackRun = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showProgressHUDNotice:@"Streaming is stopped unexpected." showTime:2.0];
    });
}

#pragma mark - PanoramaType
- (void)changePanoramaTypeClick {
    NSLog(@"-- %s", __FUNCTION__);
    
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tbPanoramaTypeArray.array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:nil];
    
    [cell.textLabel setText:[_tbPanoramaTypeArray.array objectAtIndex:indexPath.row]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self selectPanoramaTypeAtIndexPath:indexPath];
    
    [_customIOS7AlertView close];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_tbPanoramaTypeArray.lastIndex == indexPath.row) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

- (void)selectPanoramaTypeAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row != _tbPanoramaTypeArray.lastIndex) {
        [self showProgressHUDWithMessage:nil detailsMessage:nil mode:MBProgressHUDModeIndeterminate];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            int panoramaType = 0;
            switch (indexPath.row) {
                case 0:
                    panoramaType = 0x01;
                    break;
                    
                case 1:
                    panoramaType = 0x04;
                    break;
                    
                case 2:
                    panoramaType = 0x06;
                    break;
                    
                default:
                    break;
            }
            
            BOOL isSuccess = [[PanCamSDK instance] changePanoramaType:panoramaType isStream:YES];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (isSuccess) {
                    _tbPanoramaTypeArray.lastIndex = indexPath.row;
                    
                    [self hideProgressHUD:YES];
                    [self updatePanoramaTyprOnScreen];
                } else {
                    [self showProgressHUDNotice:@"changePanoramaType failed." showTime:2.0];
                }
            });
        });
    }
}

- (void)updatePanoramaTyprOnScreen {
    NSArray *panoramaTypeArray = _tbPanoramaTypeArray.array;
    
    NSString *title = panoramaTypeArray[_tbPanoramaTypeArray.lastIndex];
    [_panoramaTypeButton setTitle:title forState:UIControlStateNormal];
    [_panoramaTypeButton setTitle:title forState:UIControlStateHighlighted];
}

#pragma mark - AppDelegateProtocol
-(void)applicationDidEnterBackground:(UIApplication *)application {
    AppLog(@"App enter background");

//    self.PlaybackRun = NO;
//    [self stopGLKAnimation];
////    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
////    if ((dispatch_semaphore_wait(_semaphore, time) != 0)) {
////        AppLog(@"Timeout!");
////    } else {
////            dispatch_semaphore_signal(self.semaphore);
//            [self.pbTimer invalidate];
//            [self.insufficientPerformanceTimer invalidate];
//            
//            if(_played) {
//                [self removePlaybackObserver];
//                if (_videoURL) {
//                    self.played = ![[PanCamSDK instance] stop];
//                } else {
//                    self.played = ![_ctrl.pbCtrl stop];
//                }
//            }
//            
//            [[SDK instance] destroySDK];
//            
//            //            [[PanCamSDK instance] panCamStopPreview];
//            [self.motionManager stopGyroUpdates];
//            [EAGLContext setCurrentContext:self.context];
//            
//            [[PanCamSDK instance] destroypanCamSDK];
//            
//            if ([EAGLContext currentContext] == self.context) {
//                [EAGLContext setCurrentContext:nil];
//            }
////    }
}

- (void)sdcardRemoveCallback
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.wifiCam.gallery.needReload = YES;
        
        [self showProgressHUDNotice:NSLocalizedString(@"CARD_REMOVED", nil) showTime:2.0];
    });
    
    [self returnBack:nil];
}

- (void)sdcardInCallback {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.wifiCam.gallery.needReload = YES;

        [self showProgressHUDNotice:NSLocalizedString(@"CARD_INSERTED", nil) showTime:2.0];
    });
}

- (shared_ptr<ICatchFile>)currentFile {
#if USE_NEW_MPB
    return _currentFile;
#else
    return _gallery.videoTable.fileList.at(index);
#endif
}

@end
