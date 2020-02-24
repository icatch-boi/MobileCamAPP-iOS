//
//  VideoPlaybackGLKViewController.m
//  WifiCamMobileApp
//
//  Created by ZJ on 2016/11/1.
//  Copyright © 2016年 iCatchTech. All rights reserved.
//

#import "VideoPlaybackGLKViewController.h"

#import "ICatchH264Decoder.h"
#import "VideoPlaybackSlideController.h"
#import "VideoPlaybackBufferingView.h"
#import "HYOpenALHelper.h"
#import "PCMDataPlayer.h"
#import "GCDiscreetNotificationView.h"

@interface VideoPlaybackGLKViewController () {
    CGPoint pointP;
    float cDistance;
    
    VideoPbProgressListener *videoPbProgressListener;
    VideoPbProgressStateListener *videoPbProgressStateListener;
    VideoPbDoneListener *videoPbDoneListener;
    VideoPbServerStreamErrorListener *videoPbServerStreamErrorListener;
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
@property(nonatomic) BOOL PlaybackRun;
@property(nonatomic, getter = isPlayed) BOOL played;
@property(nonatomic, getter = isPanCampaused) BOOL panCampaused;
@property(nonatomic) BOOL seeking;
@property(nonatomic) BOOL exceptionHappen;
@property(nonatomic, getter =  isControlHidden) BOOL controlHidden;
@property(nonatomic) dispatch_semaphore_t semaphore;
@property(nonatomic) NSTimer *pbTimer;
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

@end

@implementation VideoPlaybackGLKViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
            
            if (_played && !_panCampaused) {
                // Pause
                AppLog(@"call pause");
                self.panCampaused = [[SDK instance] pause];
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
                            self.totalSecs = [[SDK instance] playFile:self.videoURL andDisableAudio:NO andRemote:NO];
                        }
                        if (_totalSecs <= 0) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self showProgressHUDNotice:@"Failed to play" showTime:2.0];
                            });
                            return;
                        }
                        _slideController.enabled = YES;
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
                            self.pbTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                                          target  :self
                                                                          selector:@selector(updateTimeInfo:)
                                                                          userInfo:nil
                                                                          repeats :YES];
                            [self hideProgressHUD:YES];
                            [self showGCDNoteWithMessage:@"Buffering ..."
                                            withAnimated:YES withAcvity:YES];
                        });
                        
                        if ([_ctrl.pbCtrl audioPlaybackStreamEnabled]) {
                            dispatch_group_async(_playbackGroup, _audioQueue, ^{[self playAudio1];});
                        } else {
                            AppLog(@"Playback doesn't contains audio.");
                        }
                        if ([_ctrl.pbCtrl videoPlaybackStreamEnabled]) {
                            dispatch_group_async(_playbackGroup, _videoQueue, ^{[self playVideo];});
                        } else {
                            AppLog(@"Playback doesn't contains video.");
                        }
                        
                        dispatch_group_notify(_playbackGroup, _videoPlaybackQ, ^{
                            
                        });
                        
                    });
                } else {
                    // Resume
                    AppLog(@"call resume");
                    self.panCampaused = ![_ctrl.pbCtrl resume];
                    if (!_panCampaused) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            _deleteButton.enabled = NO;
                            _actionButton.enabled = NO;
                            if (![_pbTimer isValid]) {
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
    if (!self.paused) {
        [[PanCamSDK instance] panCamSetViewPort:0 andY:0 andWidth:(int)view.drawableWidth andHeight:(int)view.drawableHeight];
        [[PanCamSDK instance] panCamRender];
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
                
                switch ([[UIApplication sharedApplication] statusBarOrientation]) {
                    case UIInterfaceOrientationPortrait:
                        [[PanCamSDK instance] panCamRotate:0 andSpeedX:gyroData.rotationRate.x andSpeedY:gyroData.rotationRate.y andSpeedZ:gyroData.rotationRate.z andTamp:timestamp andType:PCFileTypeStream];
                        break;
                    case UIInterfaceOrientationLandscapeLeft:
                        [[PanCamSDK instance] panCamRotate:3 andSpeedX:gyroData.rotationRate.x andSpeedY:gyroData.rotationRate.y andSpeedZ:gyroData.rotationRate.z andTamp:timestamp andType:PCFileTypeStream];
                        break;
                    case UIInterfaceOrientationPortraitUpsideDown:
                        [[PanCamSDK instance] panCamRotate:2 andSpeedX:gyroData.rotationRate.x andSpeedY:gyroData.rotationRate.y andSpeedZ:gyroData.rotationRate.z andTamp:timestamp andType:PCFileTypeStream];
                        break;
                    case UIInterfaceOrientationLandscapeRight:
                        [[PanCamSDK instance] panCamRotate:1 andSpeedX:gyroData.rotationRate.x andSpeedY:gyroData.rotationRate.y andSpeedZ:gyroData.rotationRate.z andTamp:timestamp andType:PCFileTypeStream];
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
        
        [[PanCamSDK instance] panCamRotate:pointC andPointPre:pointP andType:PCFileTypeStream];
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
    ICatchVideoFormat format = [_ctrl.propCtrl retrievePlaybackVideoFormat];
    if (format.getCodec() == ICATCH_CODEC_JPEG) {
        AppLog(@"playbackVideoMJPEG");
        dispatch_async(dispatch_get_main_queue(), ^{
            _previewThumb.hidden = NO;
            self.glkView.hidden = YES;
        });
        
        [self playbackVideoMJPEG];
    } else if (format.getCodec() == ICATCH_CODEC_H264) {
        AppLog(@"playbackVideoH264");
        dispatch_async(dispatch_get_main_queue(), ^{
            _previewThumb.hidden = YES;
            self.glkView.hidden = NO;
            [self startGLKAnimation];
            [self configureGyro];
        });
        
        [self playbackVideoH264:format];
    } else {
        AppLog(@"Unknown codec.");
    }
    
    AppLog(@"Break video");
}

- (void)playbackVideoH264:(ICatchVideoFormat)format {
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
                WifiCamAVData *wifiCamData = [_ctrl.propCtrl prepareDataForPlaybackVideoFrame];
#endif
                if (wifiCamData.data.length > 0) {
                    self.curVideoPTS = wifiCamData.time;
                    
                    NSUInteger loc = (4+_spsSize)+(4+_ppsSize);
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
                WifiCamAVData *wifiCamData = [_ctrl.propCtrl prepareDataForPlaybackVideoFrame];
#endif
                if (wifiCamData.data.length > 0) {
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
            WifiCamAVData *wifiCamData = [_ctrl.propCtrl prepareDataForPlaybackVideoFrame];
            
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

#pragma mark - Observer
- (void)addPlaybackObserver
{
    videoPbProgressListener = new VideoPbProgressListener(self);
    [_ctrl.comCtrl addObserver:ICATCH_EVENT_VIDEO_PLAYBACK_CACHING_PROGRESS
                      listener:videoPbProgressListener
                   isCustomize:NO];
    videoPbProgressStateListener = new VideoPbProgressStateListener(self);
    [_ctrl.comCtrl addObserver:ICATCH_EVENT_VIDEO_PLAYBACK_CACHING_CHANGED
                      listener:videoPbProgressStateListener
                   isCustomize:NO];
    videoPbDoneListener = new VideoPbDoneListener(self);
    [_ctrl.comCtrl addObserver:ICATCH_EVENT_VIDEO_STREAM_PLAYING_ENDED
                      listener:videoPbDoneListener
                   isCustomize:NO];
    videoPbServerStreamErrorListener = new VideoPbServerStreamErrorListener(self);
    [_ctrl.comCtrl addObserver:ICATCH_EVENT_SERVER_STREAM_ERROR
                      listener:videoPbServerStreamErrorListener
                   isCustomize:NO];
}

- (void)removePlaybackObserver
{
    if (videoPbProgressListener) {
        [_ctrl.comCtrl removeObserver:ICATCH_EVENT_VIDEO_PLAYBACK_CACHING_PROGRESS
                             listener:videoPbProgressListener
                          isCustomize:NO];
        delete videoPbProgressListener; videoPbProgressListener = NULL;
    }
    if (videoPbProgressStateListener) {
        [_ctrl.comCtrl removeObserver:ICATCH_EVENT_VIDEO_PLAYBACK_CACHING_CHANGED
                             listener:videoPbProgressStateListener
                          isCustomize:NO];
        delete videoPbProgressStateListener; videoPbProgressStateListener = NULL;
    }
    if (videoPbDoneListener) {
        [_ctrl.comCtrl removeObserver:ICATCH_EVENT_VIDEO_STREAM_PLAYING_ENDED
                             listener:videoPbDoneListener
                          isCustomize:NO];
        delete videoPbDoneListener; videoPbDoneListener = NULL;
    }
    if (videoPbServerStreamErrorListener) {
        [_ctrl.comCtrl removeObserver:ICATCH_EVENT_SERVER_STREAM_ERROR
                             listener:videoPbServerStreamErrorListener
                          isCustomize:NO];
        delete videoPbServerStreamErrorListener; videoPbServerStreamErrorListener = NULL;
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
                [[PanCamSDK instance] panCamStopPreview];
                [self.motionManager stopGyroUpdates];
                
                self.played = ![_ctrl.pbCtrl stop];
                [self removePlaybackObserver];
                dispatch_async(dispatch_get_main_queue(), ^{
                    _deleteButton.enabled = YES;
                    _actionButton.enabled = YES;
                    
                    dispatch_semaphore_signal(self.semaphore);
                    [_playbackButton setImage:[UIImage imageNamed:@"videoplayer_control_play"]
                                     forState:UIControlStateNormal];
                    [_pbTimer invalidate];
                    _videoPbElapsedTime.text = @"00:00:00";
                    _bufferingView.value = 0; [_bufferingView setNeedsDisplay];
                    self.curVideoPTS = 0;
                    self.playedSecs = 0;
                    _slideController.value = 0;
                    _slideController.enabled = NO;
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
    if (_progressHUD.alpha == 0 ) {
        self.progressHUD.labelText = message;
        self.progressHUD.detailsLabelText = dMessage;
        self.progressHUD.mode = mode;
        [self.progressHUD show:YES];
        
        self.navigationController.navigationBar.userInteractionEnabled = NO;
    }
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

@end
