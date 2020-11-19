//
//  PanCamSDK.m
//  WifiCamMobileApp
//
//  Created by ZJ on 2016/10/12.
//  Copyright © 2016年 iCatchTech. All rights reserved.
//

#import "PanCamSDK.h"
#import "H264StreamParameter.h"
#import "ICatchCameraConfig.h"

@interface PanCamSDK()

@property (nonatomic) shared_ptr<ICatchPancamSession> panCamSession;
@property (nonatomic) shared_ptr<ICatchIPancamPreview> panCamPreview;
@property (nonatomic) shared_ptr<ICatchIPancamControl> panCamControl;
@property (nonatomic) shared_ptr<ICatchIPancamVideoPlayback> panCamVPlayback;
@property (nonatomic) shared_ptr<ICatchPancamInfo> panCamSDKInfo;

@property (nonatomic) shared_ptr<ICatchIStreamPublish> panCamStreamPublish;
@property (nonatomic) shared_ptr<ICatchIStreamControl> panCamStreamControl;

@property (nonatomic) shared_ptr<ICatchIStreamProvider> panCamPreviewProvider;
@property (nonatomic) shared_ptr<ICatchIStreamProvider> panCamVPlaybackProvider;

@property (nonatomic) shared_ptr<ICatchIPancamGLTransform> streamGLTransform;
@property (nonatomic) shared_ptr<ICatchIPancamGLTransform> imageGLTransform;

@property (nonatomic) shared_ptr<ICatchFrameBuffer> videoFrameBuffer;
@property (nonatomic) shared_ptr<ICatchFrameBuffer> audioFrameBuffer;

@property (nonatomic) shared_ptr<ICatchIPancamGL> panCamGLImage;
@property (nonatomic) shared_ptr<ICatchIPancamGL> panCamGLStream;
@property (nonatomic) shared_ptr<ICatchIPancamImage> panCamImage;
@property (nonatomic) shared_ptr<ICatchSurfaceContext> surfaceContext;
@property (nonatomic) CRawImageUtil *imageUtil;

@property (nonatomic) NSMutableData *videoData;
@property (nonatomic) NSMutableData *audioData;
@property (nonatomic) NSMutableData *videoPlaybackData;
@property (nonatomic) NSMutableData *audioPlaybackData;

@property (nonatomic) BOOL isStopped;
@property (nonatomic, readwrite) dispatch_queue_t pancamSDKQueue;
@property (nonatomic, readwrite) BOOL isSDKInitialized;
@property (nonatomic, readwrite) BOOL isStreamInitialized;
@property (nonatomic, readwrite) BOOL isImageInitialized;
@property (nonatomic) BOOL isRender;

@property (nonatomic, readwrite) BOOL isPublishStreaming;

@property (nonatomic) NSRange videoRange;
@property (nonatomic) NSRange audioRange;

@property (nonatomic) shared_ptr<ICatchVideoFormat> streamInfo;

@end

@implementation PanCamSDK

#pragma mark - PanCamSDK status

+ (PanCamSDK *)instance {
    static PanCamSDK *instance = nil;
    
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        instance = [[self alloc] initSingleton];
        instance.pancamSDKQueue = dispatch_queue_create("WifiCam.GCD.Queue.panCamSDKQ", DISPATCH_QUEUE_SERIAL);
    });
    
    return instance;
}

- (id)initSingleton {
    if (self = [super init]) {
        // Init code
    }
    return self;
}

- (BOOL)initializePanCamSDK {
    BOOL ret = NO;
    int retVal = -1;
    
    do {
        if (_isSDKInitialized) {
            ret = YES;
            break;
        }
        
        AppLog(@"---START INITIALIZE PanCamSDK(Data Access Layer)---");

#if (PANCAMSDK_DEBUG==1)
        auto log = ICatchPancamLog::getInstance();
        log->setDebugMode(true);
        log->setSystemLogOutput(true);
        log->setLog(ICH_GL_LOG_TYPE_COMMON, true);
        log->setLogLevel(ICH_GL_LOG_TYPE_COMMON, ICH_GL_LOG_LEVEL_INFO);
        log->setLog(ICH_GL_LOG_TYPE_OPENGL, true);
        log->setLogLevel(ICH_GL_LOG_TYPE_OPENGL, ICH_GL_LOG_LEVEL_INFO);

        log->setLog(ICH_GL_LOG_TYPE_DEVELOP, true);
        log->setLogLevel(ICH_GL_LOG_TYPE_DEVELOP, ICH_GL_LOG_LEVEL_INFO);
        log->setLog(ICH_GL_LOG_TYPE_STREAM, true);
        log->setLogLevel(ICH_GL_LOG_TYPE_STREAM, ICH_GL_LOG_LEVEL_INFO);
#endif
        
        _panCamSession = make_shared<ICatchPancamSession>(100);
        if (!_panCamSession) {
            AppLog(@"Create session failed.");
            break;
        }
        
        auto displayPPI = make_shared<ICatchGLDisplayPPI>();
        float ppi = [self getScreenPPI];
        displayPPI->setXdpi(ppi);
        displayPPI->setYdpi(ppi);
        auto defaultColor = make_shared<ICatchGLColor>(0, 0, 0, 0);
        
//        retVal = _panCamSession->prepareSession(defaultColor, displayPPI);
        auto itrs = make_shared<ICatchINETTransport>([self getCameraIpAddr].UTF8String);
        retVal = _panCamSession->prepareSession(itrs, defaultColor, displayPPI);
        if (retVal != ICH_SUCCEED) {
            AppLog(@"prepareSession failed, retVal: %d", retVal);
            break;
        }
        
        self.panCamPreview = _panCamSession->getPreview();
        self.panCamControl = _panCamSession->getControl();
        self.panCamVPlayback = _panCamSession->getVideoPlayback();
        self.panCamSDKInfo = _panCamSession->getInfo();
        if (!_panCamPreview || !_panCamControl || !_panCamVPlayback || !_panCamSDKInfo) {
            AppLog(@"SDK objects were nil");
            break;
        }
        
//        self.videoFrameBuffer = make_shared<ICatchFrameBuffer>(640 * 480 * 2);
        self.videoFrameBuffer = make_shared<ICatchFrameBuffer>(3840 * 2160 * 2); //4K: 3840x2160
        self.audioFrameBuffer = make_shared<ICatchFrameBuffer>(640 * 480 * 2);
//        self.videoRange = NSMakeRange(0, 640 * 480 * 2);
        self.videoRange = NSMakeRange(0, 3840 * 2160 * 2);
        self.audioRange = NSMakeRange(0, 1024 * 50);
        self.videoData = [[NSMutableData alloc] init];
        self.audioData = [[NSMutableData alloc] init];
        self.videoPlaybackData = [[NSMutableData alloc] init];
        self.audioPlaybackData = [[NSMutableData alloc] init];
        
        _surfaceContext = make_shared<ICatchSurfaceContext_IosEAGL>();
        if (!_surfaceContext) {
            AppLog(@"Create surfanceContext failed !");
            break;
        }
        
        _imageUtil = [[CRawImageUtil alloc] init];
        
        _panCamPreview->getStreamPublish(_panCamStreamPublish);
        _panCamPreview->getStreamControl(_panCamStreamControl);
        
        ret = YES;
        
        AppLog(@"---- INITIALIZE END ------");
    } while (0);
    
    if (ret) {
        @synchronized(self) {
            _isSDKInitialized = YES;
        }
    } else {
        _isSDKInitialized = NO;
        AppLog(@"---INITIALIZE SDK Failed---");
        if (_panCamSession) {
            _panCamSession = NULL;
        }
    }
    
    return ret;
}

- (NSString *)getCameraIpAddr
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL enableLive = [defaults boolForKey:@"PreferenceSpecifier:YouTube_Live"];
    NSString *ipAddr = [defaults stringForKey:@"ipAddr"];
    AppLog(@"ipAddr: %@", ipAddr);
    
    if (enableLive && ipAddr) {
        return ipAddr;
    } else {
        return @"192.168.1.1";
    }
}

- (float)getScreenPPI {
    float ppi;
    
    CGRect rect_screen = [[UIScreen mainScreen]bounds];
    CGSize size_screen = rect_screen.size;
    
    AppLog(@"size_screen: %@", NSStringFromCGSize(size_screen));
    float w = size_screen.width;
    
    if (w == 320 || w == 480 || w == 568 || w == 667 || w == 375) {
        ppi = 326;
    } else {
        ppi = 401;
    }
    AppLog(@"ppi: %f", ppi);
    
    return ppi;
}

- (BOOL)needSetRenderParam:(RenderType)type file:(shared_ptr<ICatchFile>)f {
    BOOL needSetRenderParam = NO;
    
    if (type == RenderType_EnableGL) {
        needSetRenderParam = YES;
    } else if (type == RenderType_AutoSelect) {
        if ([self isPanoramaWithFile:f]) {
            needSetRenderParam = YES;
        }
    }
    
    return needSetRenderParam;
}

- (BOOL)isPanoramaWithFile:(shared_ptr<ICatchFile>)file {
    int w = 0;
    int h = 0;
    
    if (file != nil) {
        w = file->getFileWidth();
        h = file->getFileHeight();
    } else {
        if (_streamInfo != nullptr) {
            w = _streamInfo->getVideoW();
            h = _streamInfo->getVideoH();
        }
        
        if (w == 0 || h == 0) {
            _streamInfo = [[SDK instance] getCurrentStreamingInfo];
            
            w = _streamInfo->getVideoW();
            h = _streamInfo->getVideoH();
        }
    }
    
    float scale = w / h;
    
    if (scale == 2 || scale == 0.5) {
        return YES;
    } else {
        return NO;
    }
}

- (CGSize)getStreamSize:(ICatchFile *)f {
    int w = 0;
    int h = 0;
    
    if (f != nil) {
        w = f->getFileWidth();
        h = f->getFileHeight();
    } else {
        w = _streamInfo->getVideoW();
        h = _streamInfo->getVideoH();
        
        if (w == 0 || h == 0) {
            _streamInfo = [[SDK instance] getCurrentStreamingInfo];
            
            w = _streamInfo->getVideoW();
            h = _streamInfo->getVideoH();
        }
    }
    
    return CGSizeMake(w, h);
}

- (BOOL)initStreamWithRenderType:(RenderType)renderType isPreview:(BOOL)isPV file:(shared_ptr<ICatchFile>)f {
    BOOL ret = NO;
    int retVal = -1;
    
    do {
        if ([self initializePanCamSDK]) {
            if (_isStreamInitialized) {
                ret = YES;
                break;
            }
            
            AppLog(@"--- START INITIALIZE STREAM ---");
            if (isPV) {
                _panCamPreview = _panCamSession->getPreview();
                NSLog(@"preview: %p", _panCamPreview.get());
                if (!_panCamPreview) {
                    AppLog(@"getPreview failed !");
                    break;
                }
                
                [self enablePreviewRenderWithType:renderType file:nil];
            } else {
                [self enableVPlaybackRenderWithType:renderType file:f];
            }
            
//            if (renderType == RenderType_EnableGL) {
            if ([self needSetRenderParam:renderType file:f]) {
                retVal = _panCamGLStream->init(ICH_GL_PANORAMA_TYPE_SPHERE);
                if (retVal != ICH_SUCCEED) {
                    AppLog(@"panCamPreview init failed, retVal: %d", retVal);
                    break;
                }
                
                AppLog(@"call setFormat begin");
                retVal = _panCamGLStream->setFormat(ICH_CODEC_RGBA_8888, 720, 400);
                AppLog(@"call setFormat end");
                if (retVal != ICH_SUCCEED) {
                    AppLog(@"panCamGL setFormat failed, retVal: %d", retVal);
                    break;
                }
                
                retVal = _panCamGLStream->setSurface(ICH_GL_SURFACE_TYPE_SPHERE, _surfaceContext);
                if (retVal != ICH_SUCCEED) {
                    AppLog(@"panCamImage setSurface failed, retVal: %d", retVal);
                    break;
                }
            }

            [self setupGL];
            ret = YES;
            
            AppLog(@"---- INITIALIZE STREAM END ------");
        }
    } while (0);
    
    if (ret) {
        @synchronized(self) {
            _isStreamInitialized = YES;
        }
    } else {
        _isStreamInitialized = NO;
        AppLog(@"---INITIALIZE STREAM Failed---");
    }
    
    return ret;
}

- (BOOL)initImage {
    BOOL ret = NO;
    int retVal = -1;
    
    do {
        if ([self initializePanCamSDK]) {
            if (_isImageInitialized) {
                ret = YES;
                break;
            }
            
            AppLog(@"--- START INITIALIZE IMAGE ---");
            
            _panCamImage = _panCamSession->getImage();
            if (!_panCamImage) {
                AppLog(@"getImage failed !");
                break;
            }
            
            retVal = _panCamImage->enableGLRender(_panCamGLImage, ICH_GL_PANORAMA_TYPE_SPHERE);
            if (retVal != ICH_SUCCEED) {
                AppLog(@"enableGLRender failed !");
                break;
            }
            
            retVal = _panCamGLImage->getPancamGLTransform(_imageGLTransform);
            if (retVal != ICH_SUCCEED) {
                AppLog(@"getPancamGLTransform failed !");
                break;
            }
            
            retVal = _panCamGLImage->init();
            if (retVal != ICH_SUCCEED) {
                AppLog(@"panCamImage init failed, retVal: %d", retVal);
                break;
            }

            AppLog(@"call setFormat begin");
            retVal = _panCamGLImage->setFormat(ICH_CODEC_RGBA_8888, 720, 400);
            AppLog(@"call setFormat end");
            if (retVal != ICH_SUCCEED) {
                AppLog(@"panCamGL setFormat failed, retVal: %d", retVal);
                break;
            }

            retVal = _panCamGLImage->setSurface(ICH_GL_SURFACE_TYPE_SPHERE, _surfaceContext);
            if (retVal != ICH_SUCCEED) {
                AppLog(@"panCamImage setSurface failed, retVal: %d", retVal);
                break;
            }

//            [self setupGL];
            ret = YES;
            
            AppLog(@"---- INITIALIZE IMAGE END ------");
        }
    } while (0);
    
    if (ret) {
        @synchronized(self) {
            _isImageInitialized = YES;
        }
    } else {
        _isImageInitialized = NO;
        AppLog(@"---INITIALIZE IMAGE Failed---");
    }
    
    return ret;
}

- (void)destroypanCamSDK
{
    if (_isSDKInitialized) {
        AppLog(@"%s start\n", __func__);
        @synchronized(self) {
            _isSDKInitialized = NO;
        }

        [self destroyStream];
        [self destroyImage];
        
        if (_surfaceContext) {
            if (_isRender) {
                _surfaceContext->tearDown();
                _isRender = NO;
            }
            _surfaceContext = NULL;
        }
        
        if (_panCamSession) {
            _panCamSession->destroySession();
            _panCamSession = NULL;
        }
        
        if (_videoFrameBuffer) {
            _videoFrameBuffer = NULL;
        }
        
        if (_audioFrameBuffer) {
            _audioFrameBuffer = NULL;
        }
        
        self.panCamPreview = NULL;
        self.panCamControl = NULL;
        self.panCamVPlayback = NULL;
        self.panCamSDKInfo = NULL;
        
        AppLog(@"%s end\n", __func__);
    }
}

- (void)destroyImage {
    if (_isImageInitialized) {
        @synchronized (self) {
            _isImageInitialized = NO;
        }
        
        AppLog(@"destroyImage in\n");

        if (_panCamImage) {
            _panCamImage->clear();
            _panCamImage = NULL;
        }
        
        if (_panCamGLImage) {
            _panCamGLImage->clearFormat();
            _panCamGLImage->removeSurface(ICH_GL_SURFACE_TYPE_SPHERE, _surfaceContext);
            _panCamGLImage->release();
            _panCamGLImage = NULL;
        }
        
        if (_imageGLTransform) {
            _imageGLTransform->reset();
            _imageGLTransform = NULL;
        }
        
        AppLog(@"destroyImage out\n");
    }
}

- (void)destroyStream {
    if (_isStreamInitialized) {
        AppLog(@"destroyStream in\n");
        @synchronized (self) {
            _isStreamInitialized = NO;
        }
        
        if (_panCamGLStream) {
            _panCamGLStream->clearFormat();
            _panCamGLStream->removeSurface(ICH_GL_SURFACE_TYPE_SPHERE, _surfaceContext);
            _panCamGLStream->release();
            _panCamGLStream = NULL;
        }
        
        AppLog(@"destroyStream out\n");
    }
}

- (BOOL)changePanoramaType:(int)panoramaType isStream:(BOOL)isStream {
    int32_t retVal = ICH_UNKNOWN_ERROR;
    
    if (isStream) {
        if (_panCamGLStream) {
            retVal = _panCamGLStream->changePanoramaType(panoramaType);
        } else {
            AppLogError(AppLogTagAPP, @"_panCamGLStream is nil.");
        }
    } else {
        if (_panCamGLImage) {
            retVal = _panCamGLImage->changePanoramaType(panoramaType);
        } else {
            AppLogError(AppLogTagAPP, @"_panCamGLImage is nil.");
        }
    }
    
    AppLog(@"changePanoramaType: %d", retVal);
    
    return retVal == ICH_SUCCEED ? YES : NO;
}

#pragma mark - PanCam Log
- (void)enableLogSdkAtDiretctory:(NSString *)directoryName
                         enable:(BOOL)enable
{
    ICatchPancamLog *log = ICatchPancamLog::getInstance();
    if (enable) {
        log->setFileLogPath(string([directoryName UTF8String]));
        log->setFileLogOutput(true);
        log->setSystemLogOutput(false);
        log->setLog(ICH_GL_LOG_TYPE_DEVELOP, true);
        log->setLogLevel(ICH_GL_LOG_TYPE_DEVELOP, ICH_GL_LOG_LEVEL_INFO);
        log->setLog(ICH_GL_LOG_TYPE_STREAM, true);
        log->setLogLevel(ICH_GL_LOG_TYPE_STREAM, ICH_GL_LOG_LEVEL_INFO);
        log->setLog(ICH_GL_LOG_TYPE_COMMON, true);
        log->setLogLevel(ICH_GL_LOG_TYPE_COMMON, ICH_GL_LOG_LEVEL_INFO);
        log->setLog(ICH_GL_LOG_TYPE_OPENGL, true);
        log->setLogLevel(ICH_GL_LOG_TYPE_OPENGL, ICH_GL_LOG_LEVEL_INFO);
        log->setDebugMode(true);
    } else {
        log->setFileLogOutput(false);
        log->setSystemLogOutput(false);
        log->setLog(ICH_GL_LOG_TYPE_DEVELOP, false);
        log->setLog(ICH_GL_LOG_TYPE_STREAM, false);
        log->setLog(ICH_GL_LOG_TYPE_COMMON, false);
        log->setLog(ICH_GL_LOG_TYPE_OPENGL, false);
    }
}

#pragma mark - MEDIA
- (int)startPublishStreaming:(string)rtmpUrl
{
    int newValue = ICH_UNKNOWN_ERROR;
    if (_panCamStreamPublish) {
        AppLog(@"startPublishStreaming start.");
        newValue = _panCamStreamPublish->startPublishStreaming(rtmpUrl);
        AppLog(@"startPublishStreaming ret : %d.", newValue);
        AppLog(@"startPublishStreaming end.");
    } else {
        AppLog(@"PanCamSDK doesn't work!!!");
    }
    
    if (!newValue) {
        @synchronized(self) {
            _isPublishStreaming = YES;
        }
    }
    
    return newValue;
}

- (int)stopPublishStreaming
{
    int newValue = ICH_UNKNOWN_ERROR;
    
    if (_isPublishStreaming) {
        @synchronized(self) {
            _isPublishStreaming = NO;
        }
        
        if (_panCamStreamPublish) {
            AppLog(@"stopPublishStreaming start.");
            newValue = _panCamStreamPublish->stopPublishStreaming();
            AppLog(@"stopPublishStreaming ret : %d.", newValue);
            AppLog(@"stopPublishStreaming end.");
        } else {
            AppLog(@"PanCamSDK doesn't work!!!");
        }
    }
    
    return newValue;
}

- (int)isStreamSupportPublish
{
    int newValue = ICH_UNKNOWN_ERROR;
    
    if (_panCamStreamPublish) {
        AppLog(@"isStreamSupportPublish start.");
        newValue = _panCamStreamPublish->isStreamSupportPublish();
        AppLog(@"isStreamSupportPublish ret : %d.", newValue);
        AppLog(@"isStreamSupportPublish end.");
    } else {
        AppLog(@"PanCamSDK doesn't work!!!");
    }
    
    return newValue;
}

- (NSString *)createLiveChannel:(CredentialSDK)credential withResolution:(NSString *)resolution withTitle:(NSString *)broadCastTitle withVRProjection:(BOOL)vrProjection {
    NSString *newValue = nil;
    
    if (_panCamStreamPublish) {
        AppLog(@"createLiveChannel start.");
        string str = _panCamStreamPublish->createChannel(credential, resolution.UTF8String, broadCastTitle.UTF8String, vrProjection);
        AppLog(@"createLiveChannel ret : %s.", str.c_str());

        if (str.length()) {
            newValue = [NSString stringWithFormat:@"%s", str.c_str()];
        }
        
        AppLog(@"createLiveChannel end.");
    } else {
        AppLog(@"PanCamSDK doesn't work!!!");
    }

    return newValue;
}

- (void)deleteLiveChannel {
    if (_panCamStreamPublish) {
        AppLog(@"deleteLiveChannel start.");
        _panCamStreamPublish->deleteChannel();
        AppLog(@"deleteLiveChannel end.");
    } else {
        AppLog(@"PanCamSDK doesn't work!!!");
    }
}

- (NSString *)startLive {
    NSString *newValue = nil;
    
    if (_panCamStreamPublish) {
        AppLog(@"startLive start.");
        string str = _panCamStreamPublish->startLive();
        AppLog(@"startLive ret : %s.", str.c_str());
        
        if (str.length()) {
            newValue = [NSString stringWithFormat:@"%s", str.c_str()];
        }
        AppLog(@"startLive end.");
    } else {
        AppLog(@"PanCamSDK doesn't work!!!");
    }
    
    return newValue;
}

- (void)stopLive {
    if (_panCamStreamPublish) {
        AppLog(@"stopLive start.");
        _panCamStreamPublish->stopLive();
        AppLog(@"stopLive end.");
    } else {
        AppLog(@"PanCamSDK doesn't work!!!");
    }
}

- (BOOL)enablePreviewRenderWithType:(RenderType)renderType file:(shared_ptr<ICatchFile>)f {
    if (!_panCamPreview) {
        AppLog(@"PanCamSDK doesn't work!!!");
        return NO;
    }
    
    int retVal = ICH_UNKNOWN_ERROR;
    
    switch (renderType) {
        case RenderType_EnableNormal:
            retVal = _panCamPreview->enableRender(_surfaceContext);
            break;
            
        case RenderType_EnableGL:
            retVal = _panCamPreview->enableGLRender(_panCamGLStream, ICH_GL_PANORAMA_TYPE_SPHERE);
            if (_panCamGLStream) {
                _panCamGLStream->getPancamGLTransform(_streamGLTransform);
            } else {
                AppLog(@"panCamGLStream is NULL");
            }
            break;
            
        case RenderType_Disable:
            retVal = _panCamPreview->disableRender(_panCamPreviewProvider);
            break;
            
        case RenderType_AutoSelect:
            if ([self isPanoramaWithFile:f]) {
                retVal = _panCamPreview->enableGLRender(_panCamGLStream, ICH_GL_PANORAMA_TYPE_SPHERE);
                if (_panCamGLStream) {
                    _panCamGLStream->getPancamGLTransform(_streamGLTransform);
                } else {
                    AppLog(@"panCamGLStream is NULL");
                }
            } else {
                retVal = _panCamPreview->enableRender(_surfaceContext);
            }
            break;
            
        default:
            break;
    }

    if (retVal == ICH_SUCCEED) {
        AppLog(@"enablePreviewRenderWithType success.");
        return YES;
    } else {
        AppLog(@"enablePreviewRenderWithType failed, ret: %d.", retVal);
        return NO;
    }
}

- (int)startMediaStream:(ICatchCamPreviewMode)mode enableAudio:(BOOL)enableAudio enableLive:(BOOL)enableLive {
    int startRetVal = ICH_UNKNOWN_ERROR;
    
    if (!_panCamPreview) {
        AppLog(@"PanCamSDK doesn't work!!!");
        return ICH_UNKNOWN_ERROR;
    }

    [[SDK instance] changePreviewMode:mode];
    
    auto format = [[SDK instance] getCurrentStreamingInfo];
    
    int codec = format->getCodec();
    int w = format->getVideoW();
    int h = format->getVideoH();
    int br = format->getBitrate();
    unsigned int fr = format->getFrameRate();
    AppLog(@"codec: 0x%x, w: %d, h: %d, br: %d, fr: %d", codec, w, h, br, fr);
    w = (w<=0) ? 1920 : w;
    h = (h<=0) ? 960 : h;
    br = (br<=0) ? 500000 : br;
    fr = (fr<=0) ? 15 : fr;
    
//    bool disableAudio = enableAudio == YES ? false : true;
    
    uint cacheTime = [[SDK instance] previewCacheTime];
    AppLog(@"cacheTime: %d", cacheTime);
    
//    ICatchPancamConfig::getInstance()->setPreviewCacheParam(200);
    //MOBILEAPP-114
    //ICatchPancamConfig::getInstance()->setPreviewCacheParam(0);
    ICatchPancamConfig::getInstance()->setPreviewCacheParam(400);

//    if (codec == ICH_CODEC_H264) {
//        AppLog(@"%s - start h264", __func__);
//
//        if (cacheTime > 0 && cacheTime < 200) {
//            cacheTime = 400;
//        }
//        ICatchCameraConfig::getInstance()->setPreviewCacheParam(cacheTime);
//
//    } else {
//        AppLog(@"%s - start mjpg", __func__);
//
//        if (cacheTime > 0 && cacheTime <= 200) {
//            cacheTime = 200;
//        }
//        ICatchCameraConfig::getInstance()->setPreviewCacheParam(cacheTime);
//    }
    
    if (enableLive) {
        AppLog(@"%s - current enable live function", __func__);
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *liveSize = [defaults stringForKey:@"LiveSize"];
        if (!liveSize) {
            liveSize = @"854x480";
            [defaults setObject:liveSize forKey:@"LiveSize"];
        }
        
//        NSArray *sizeAr = [liveSize componentsSeparatedByString:@"x"];
//        if ([sizeAr[0] integerValue]) {
//            w = (int)[sizeAr[0] integerValue];
//        }
//        if ([sizeAr[1] integerValue]) {
//            h = (int)[sizeAr[1] integerValue];
//        }
        
        AppLog(@"live - w: %d, h: %d", w, h);
    }

    /**
     * ICatchH264StreamParam is 16-byte aligned, 720x540 is aligned to 720x544,
     * use customized class WiFiCamH264StreamParameter  instead.
     */
    //auto param = make_shared<ICatchH264StreamParam>(w, h, br, fr);
    
    shared_ptr<ICatchStreamParam> param;
    if (codec == ICH_CODEC_H264) {
        param = make_shared<H264StreamParameter>(codec, w, h, br, fr);
    } else {
        param = make_shared<ICatchJPEGStreamParam>(w, h, br, fr);
    }
    
    AppLog(@"%s - start", __func__);
//    startRetVal = _panCamPreview->start([self getCameraIpAddr].UTF8String, param, disableAudio, true, true);
//    _panCamPreview->setPreviewParam(0, false);
    startRetVal = _panCamPreview->start(param, enableAudio);
//    [NSThread sleepForTimeInterval:7];
    
    AppLog(@"%s - retVal : %d", __func__, startRetVal);
    
    self.isStopped = NO;
    return startRetVal;
}

- (BOOL)stopMediaStream {
    
    @synchronized(self) {
        if (!self.isStopped) {
            
            AppLog(@"%s - start", __func__);
            
            if (![[SDK instance] isMediaStreamOn]) {
                AppLog(@"%s - Already stoped", __func__);
                return NO;
            }
            
            int retVal = 1;
            
            if(_panCamPreview)
                retVal = _panCamPreview->stop();
            AppLog(@"%s - retVal : %d", __func__,retVal);
            
            self.isStopped = YES;
            
            if (retVal == ICH_SUCCEED) {
                return YES;
            } else {
                AppLog(@"%s failed", __func__);
                return NO;
            }
        } else {
            return YES;
        }
    }
}

- (BOOL)videoStreamEnabled {
    return (_panCamPreviewProvider && _panCamPreviewProvider->containsVideoStream() == true) ? YES : NO;
}

- (BOOL)audioStreamEnabled {
    return (_panCamPreviewProvider && _panCamPreviewProvider->containsAudioStream() == true) ? YES : NO;
}

- (shared_ptr<ICatchVideoFormat>)getVideoFormat
{
    auto format = make_shared<ICatchVideoFormat>();
    
    if (_panCamPreviewProvider) {
        _panCamPreviewProvider->getVideoFormat(format);
        
        AppLog(@"video format: %d", format->getCodec());
        AppLog(@"video w,h: %d, %d", format->getVideoW(), format->getVideoH());
    } else {
        AppLog(@"PanCamSDK doesn't work!!!");
    }
    
    return format;
}

- (shared_ptr<ICatchAudioFormat>)getAudioFormat
{
    auto format = make_shared<ICatchAudioFormat>();
    if (_panCamPreviewProvider) {
        _panCamPreviewProvider->getAudioFormat(format);
    } else {
        AppLog(@"PanCamSDK doesn't work!!!");
    }
    
    return format;
}

- (BOOL)openAudio:(BOOL)isOpen {
    BOOL ret = NO;
    if (!_panCamPreview) {
        AppLog(@"PanCamSDK doesn't work!!!");
        return ret;
    }
    if (isOpen) {
//        ICatchAudioFormat format = [self getAudioFormat];
        ret = _panCamStreamControl->enableAudio() == ICH_SUCCEED ? YES : NO;
        AppLog(@"enableAudio: %hhd", (char)ret);
    } else {
        ret = _panCamStreamControl->disableAudio() == ICH_SUCCEED ? YES : NO;
        AppLog(@"disableAudio: %hhd", (char)ret);
    }
    return ret;
}

- (WifiCamAVData *)getVideoData {
    if (!_panCamPreviewProvider) {
        AppLog(@"PanCamSDK doesn't work!!!");
        return nil;
    }
    
    WifiCamAVData *videoFrameData = nil;
    RunLog(@"getVideoData begin");
    int retVal = _panCamPreviewProvider->getNextVideoFrame(_videoFrameBuffer);
    RunLog(@"getVideoData end");
    RunLog(@"video frame presentation time: %f", _videoFrameBuffer->getPresentationTime());
    if (retVal == ICH_SUCCEED) {
        [_videoData setLength:_videoRange.length];
        [_videoData replaceBytesInRange:_videoRange withBytes:_videoFrameBuffer->getBuffer()];
        [_videoData setLength:_videoFrameBuffer->getFrameSize()];
        videoFrameData = [[WifiCamAVData alloc] initWithData:_videoData
                                                     andTime:_videoFrameBuffer->getPresentationTime()];
    } else {
        RunLog(@"** Get video frame failed with error code %d.", retVal);
    }
    
    return videoFrameData;
}

- (WifiCamAVData *)getAudioData {
    if (!_panCamPreviewProvider) {
        AppLog(@"PanCamSDK doesn't work!!!");
        return nil;
    }
    
    WifiCamAVData *audioTrackData = nil;
    RunLog(@"getAudioData begin");
    int retVal = _panCamPreviewProvider->getNextAudioFrame(_audioFrameBuffer);
    RunLog(@"getAudioData end");
    RunLog(@"audio track presentation time: %f", _audioFrameBuffer->getPresentationTime());
    if (retVal == ICH_SUCCEED) {
        [_audioData setLength:_audioRange.length];
        [_audioData replaceBytesInRange:_audioRange withBytes:_audioFrameBuffer->getBuffer()];
        [_audioData setLength:_audioFrameBuffer->getFrameSize()];
        audioTrackData = [[WifiCamAVData alloc] initWithData:_audioData
                                                     andTime:_audioFrameBuffer->getPresentationTime()];
    } else {
        RunLog(@"** Get audio frame failed with error code %d.", retVal);
    }
    
    return audioTrackData;
}

- (UIImage *)getPreviewThumbnail {
    UIImage *thumbnail = nil;
    
    if (!_panCamPreview) {
        AppLog(@"PanCamSDK doesn't work!!!");
        return thumbnail;
    }
    
    int ret = _panCamPreview->getThumbnail(_videoFrameBuffer, 10);
    if (ret == ICH_SUCCEED) {
        AppLog(@"Get preview thumbnail success, size: %d", _videoFrameBuffer->getFrameSize());

        NSData *data = [[NSData alloc] initWithBytes:_videoFrameBuffer->getBuffer() length:_videoFrameBuffer->getFrameSize()];
        if (data) {
            thumbnail = [[UIImage alloc] initWithData:data];
        }
    } else {
        AppLog(@"Get preview thumbnail failed, ret: %d", ret);
    }
    
    return thumbnail;
}

#pragma mark - CONTROL
- (void)addObserver:(ICatchGLEventID)eventTypeId listener:(shared_ptr<ICatchIPancamListener>)listener isCustomize:(BOOL)isCustomize
{
//    TRACE();
    if (listener && _panCamControl) {
        
//        if (isCustomize) {
//            AppLog(@"add customize eventTypeId: 0x%x", eventTypeId);
//            _control->addCustomEventListener(eventTypeId, listener);
//        } else {
//            _control->addEventListener(eventTypeId, listener);
        int ret = _panCamControl->addEventListener(eventTypeId, listener);
        if (ret == ICH_SUCCEED) {
            AppLog(@"add eventTypeId: 0x%x listener succeeed.", eventTypeId);
        } else {
            AppLog(@"add eventTypeId: 0x%x listener failed, ret: %d", eventTypeId, ret);
        }
//        }
    } else  {
        AppLog(@"listener is null");
    }
    
}

- (void)addObserver:(StreamObserver *)observer;
{
    if (observer.listener) {
        if (observer.isGlobal) {
            int ret = ICH_UNKNOWN_ERROR;
            ret = ICatchPancamSession::addEventListener(observer.eventType, observer.listener, true);
            if (ret == ICH_SUCCEED) {
                AppLog(@"Add global event(0x%x,%p) listener succeed.", observer.eventType, observer);
            } else {
                AppLog(@"Add global event(0x%x,%p) listener failed.", observer.eventType, observer);
            }
            return;
        } else {
            if (_panCamControl) {
                int ret = ICH_UNKNOWN_ERROR;

                if (observer.isCustomized) {
                    AppLog(@"add customize eventTypeId: %d", observer.eventType);
//                    _panCamControl->addCustomEventListener(observer.eventType, observer.listener);
                } else {
                    AppLog(@"observer.eventType: 0x%x, observer.listener: %p", observer.eventType, observer.listener.get());
                    ret = _panCamControl->addEventListener(observer.eventType, observer.listener);
                    if (ret == ICH_SUCCEED) {
                        AppLog(@"add eventTypeId: 0x%x listener succeeed.", observer.eventType);
                    } else {
                        AppLog(@"add eventTypeId: 0x%x listener failed, ret: %d", observer.eventType, ret);
                    }
                }
            } else {
                AppLog(@"SDK isn't working.");
            }
        }
    } else  {
        AppLog(@"listener is null");
    }
}

- (void)removeObserver:(StreamObserver *)observer {
    if (observer.listener) {
        if (observer.isGlobal) {
            int ret = ICH_UNKNOWN_ERROR;
            ret = ICatchPancamSession::delEventListener(observer.eventType, observer.listener, true);
            if (ret == ICH_SUCCEED) {
                AppLog(@"Remove global event(0x%x,%p) listener succeed.", observer.eventType, observer);
            } else {
                AppLog(@"Remove global event(0x%x,%p) listener failed.", observer.eventType, observer);
            }
            return;
        } else {
            if (_panCamControl) {
                int ret = ICH_UNKNOWN_ERROR;

                if (observer.isCustomized) {
                    AppLog(@"Remove customize eventTypeId: %d", observer.eventType);
//                    _panCamControl->delCustomEventListener(observer.eventType, observer.listener);
                } else {
                    ret = _panCamControl->removeEventListener(observer.eventType, observer.listener);
                    if (ret == ICH_SUCCEED) {
                        AppLog(@"Remove eventTypeId: 0x%x listener succeed.", observer.eventType);
                    } else {
                        AppLog(@"Remove eventTypeId: 0x%x listener failed, ret: %d", observer.eventType, ret);
                    }
                }
            } else {
                AppLog(@"SDK isn't working.");
            }
            
        }
    } else  {
        AppLog(@"listener is null");
    }
}

- (void)removeObserver:(ICatchGLEventID)eventTypeId listener:(shared_ptr<ICatchIPancamListener>)listener isCustomize:(BOOL)isCustomize
{
//    TRACE();
    if (listener && _panCamControl) {
        if (isCustomize) {
//            _panCamControl->delCustomEventListener(eventTypeId, listener);
        } else {
            int ret = _panCamControl->removeEventListener(eventTypeId, listener);
            if (ret == ICH_SUCCEED) {
                AppLog(@"Remove eventTypeId: 0x%x listener succeed.", eventTypeId);
            } else {
                AppLog(@"Remove eventTypeId: 0x%x listener failed, ret: %d", eventTypeId, ret);
            }
        }
    } else  {
        AppLog(@"listener is null");
    }
}

#pragma mark - Video PB
- (double)play:(shared_ptr<ICatchFile>)file enableAudio:(BOOL)enableAudio isRemote:(BOOL)isRemote {
    double videoFileTotalSecs = 0;
    if (!_panCamVPlayback) {
        AppLog(@"PanCamSDK doesn't work!!!");
        return 0;
    }
    
    bool disableAudio = enableAudio == YES ? false : true;
    bool fromRemote = isRemote == YES ? true : false;
    
    int ret = _panCamVPlayback->play(file, disableAudio, fromRemote);
    if (ret != ICH_SUCCEED) {
        AppLog(@"play failed, ret: %d", ret);
    } else {
        _panCamVPlayback->getLength(videoFileTotalSecs);
        AppLog(@"videoFileTotalSecs: %f", videoFileTotalSecs);
    }
    
    return videoFileTotalSecs;
}

- (double)playFile:(NSURL *)fileURL enableAudio:(BOOL)enableAudio isRemote:(BOOL)isRemote {
    double videoFileTotalSecs = 0;
    if (!_panCamVPlayback) {
        AppLog(@"PanCamSDK doesn't work!!!");
        return 0;
    }
    
    bool disableAudio = enableAudio == YES ? false : true;
    bool fromRemote = isRemote == YES ? true : false;
    
    NSString *filePath = fileURL.path;
    AppLog(@"filePath: %@", filePath);
    
    auto file = make_shared<ICatchFile>(0, WCFileTypeVideo, filePath.UTF8String, NSIntegerMax);
    
    int ret = _panCamVPlayback->play(file, disableAudio, fromRemote);
    if (ret != ICH_SUCCEED) {
        AppLog(@"play failed, ret: %d", ret);
    } else {
        ret = _panCamVPlayback->getLength(videoFileTotalSecs);
        AppLog(@"videoFileTotalSecs: %f, ret: %d", videoFileTotalSecs, ret);
    }
    
    return videoFileTotalSecs;
}

- (double)play:(shared_ptr<ICatchFile>)file {
    return [self play:file enableAudio:YES isRemote:YES];
}

- (BOOL)pause {
    int ret = ICH_UNKNOWN_ERROR;
    if (_panCamVPlayback != NULL) {
        ret = _panCamVPlayback->pause();
    }
    AppLog(@"PAUSE %@", ret == ICH_SUCCEED ? @"Succeed.":@"Failed.");
    return ret == ICH_SUCCEED ? YES : NO;
}

- (BOOL)resume {
    int ret = ICH_UNKNOWN_ERROR;
    if (_panCamVPlayback) {
        ret = _panCamVPlayback->resume();
    }
    AppLog(@"RESUME %@", ret == ICH_SUCCEED ? @"Succeed.":@"Failed.");
    return ret == ICH_SUCCEED ? YES : NO;
}

- (BOOL)stop {
    int ret = ICH_UNKNOWN_ERROR;
    if (_panCamVPlayback) {
        ret = _panCamVPlayback->stop();
    }
    AppLog(@"STOP %@", ret == ICH_SUCCEED ? @"Succeed.":@"Failed.");
    return ret == ICH_SUCCEED ? YES : NO;
}

- (BOOL)seek:(double)point {
    int ret = ICH_UNKNOWN_ERROR;
    if (_panCamVPlayback) {
        AppLog(@"call seek...");
        ret = _panCamVPlayback->seek(point);
    }
    AppLog(@"SEEK %@", ret == ICH_SUCCEED ? @"Succeed.":@"Failed.");
    return ret == ICH_SUCCEED ? YES : NO;
}

- (BOOL)enableVPlaybackRenderWithType:(RenderType)renderType file:(shared_ptr<ICatchFile>)f {
    if (!_panCamVPlayback) {
        AppLog(@"PanCamSDK doesn't work!!!");
        return NO;
    }
    
    int retVal = ICH_UNKNOWN_ERROR;
    
    switch (renderType) {
        case RenderType_EnableNormal:
            retVal = _panCamVPlayback->enableRender(_surfaceContext);
            break;
            
        case RenderType_EnableGL:
            retVal = _panCamVPlayback->enableGLRender(_panCamGLStream);
            if (_panCamGLStream) {
                _panCamGLStream->getPancamGLTransform(_streamGLTransform);
            } else {
                AppLog(@"panCamGLStream is NULL.");
            }
            break;
            
        case RenderType_Disable:
            retVal = _panCamVPlayback->disableRender(_panCamVPlaybackProvider);
            break;
            
        case RenderType_AutoSelect:
//            ICatchVideoFormat format = [[SDK instance] getCurrentStreamingInfo];
//            int w = format->getVideoW();
//            int h = format->getVideoH();
//            float scale = w / h;
            if ([self isPanoramaWithFile:f]) {
                retVal = _panCamVPlayback->enableGLRender(_panCamGLStream);
                if (_panCamGLStream) {
                    _panCamGLStream->getPancamGLTransform(_streamGLTransform);
                } else {
                    AppLog(@"panCamGLStream is NULL.");
                }
            } else {
                retVal = _panCamVPlayback->enableRender(_surfaceContext);
            }
            break;
            
        default:
            break;
    }
    
    if (retVal == ICH_SUCCEED) {
        AppLog(@"enableVPlaybackRenderWithType success.");
        return YES;
    } else {
        AppLog(@"enableVPlaybackRenderWithType failed, ret: %d.", retVal);
        return NO;
    }
}

- (WifiCamAVData *)getPlaybackVideoData {
    if (!_panCamVPlaybackProvider) {
        AppLog(@"PanCamSDK doesn't work!!!");
        return nil;
    }
    WifiCamAVData *videoFrameData = nil;
    double time = 0;
    int retVal;
    NSRange maxRange = NSMakeRange(0, 640 * 480 * 2);
    
    retVal = _panCamVPlaybackProvider->getNextVideoFrame(_videoFrameBuffer);
    
    if (retVal == ICH_SUCCEED) {
        if (!_videoPlaybackData) {
            self.videoPlaybackData = [NSMutableData dataWithBytes:_videoFrameBuffer->getBuffer()
                                                           length:maxRange.length];
        } else {
            _videoPlaybackData.length = maxRange.length;
            [_videoPlaybackData replaceBytesInRange:maxRange withBytes:_videoFrameBuffer->getBuffer()];
        }
        _videoPlaybackData.length = _videoFrameBuffer->getFrameSize();
        
        time = _videoFrameBuffer->getPresentationTime();
        RunLog(@"video PTS: %f", time);
        videoFrameData = [[WifiCamAVData alloc] initWithData:_videoPlaybackData andTime:time];
    } else {
        AppLog(@"--> getNextVideoFrame failed : %d", retVal);
        videoFrameData = [[WifiCamAVData alloc] init];
        videoFrameData.time = 0;
        videoFrameData.data = nil;
    }
    
    videoFrameData.state = retVal;
    return videoFrameData;
}

- (WifiCamAVData *)getPlaybackAudioData {
    if (!_panCamVPlaybackProvider) {
        AppLog(@"PanCamSDK doesn't work!!!");
        return nil;
    }
    WifiCamAVData *audioTrackData = nil;
    int retVal = ICH_UNKNOWN_ERROR;
    double time = 0;
    NSRange maxRange = NSMakeRange(0, 1024 * 50);
    
    retVal = _panCamVPlaybackProvider->getNextAudioFrame(_audioFrameBuffer);
    
    if (retVal == ICH_SUCCEED) {
        if (!_audioPlaybackData) {
            AppLog(@"Create audioPlaybackData");
            //        self.audioPlaybackData = [NSMutableData dataWithBytesNoCopy:_audioTrackBuffer->getBuffer()
            //                                                     length:_audioTrackBuffer->getFrameSize()
            //                                               freeWhenDone:NO];
            self.audioPlaybackData = [NSMutableData dataWithBytes:_audioFrameBuffer->getBuffer()
                                                           length:maxRange.length];
        } else {
            _audioPlaybackData.length = maxRange.length;
            [_audioPlaybackData replaceBytesInRange:maxRange withBytes:_audioFrameBuffer->getBuffer()];
        }
        _audioPlaybackData.length = _audioFrameBuffer->getFrameSize();
        
        time = _audioFrameBuffer->getPresentationTime();
        AppLog(@"audio PTS: %f", time);
        audioTrackData = [[WifiCamAVData alloc] initWithData:_audioPlaybackData andTime:time];
    } else {
        AppLog(@"--> getNextAudioFrame failed : %d", retVal);
    }
    
    return audioTrackData;
}

- (shared_ptr<ICatchFrameBuffer>)getPlaybackAudioData1 {
    if (!_panCamVPlaybackProvider) {
        AppLog(@"PanCamSDK doesn't work!!!");
        return nil;
    }
    
    int retVal = _panCamVPlaybackProvider->getNextAudioFrame(_audioFrameBuffer);
    
    if (retVal == ICH_SUCCEED) {
        return _audioFrameBuffer;
    } else {
        AppLog(@"--> getNextAudioFrame failed : %d", retVal);
        return NULL;
    }
}

- (shared_ptr<ICatchVideoFormat>)getPlaybackVideoFormat {
    auto format = make_shared<ICatchVideoFormat>();
    if (_panCamVPlaybackProvider) {
        _panCamVPlaybackProvider->getVideoFormat(format);
        
        AppLog(@"video format: 0x%x", format->getCodec());
        AppLog(@"video w,h: %d, %d", format->getVideoW(), format->getVideoH());
    } else {
        AppLog(@"PanCamSDK doesn't work!!!");
    }
    
    
    return format;
}

- (shared_ptr<ICatchAudioFormat>)getPlaybackAudioFormat {
    auto format = make_shared<ICatchAudioFormat>();
    if (_panCamVPlaybackProvider) {
        _panCamVPlaybackProvider->getAudioFormat(format);
    } else {
        AppLog(@"PanCamSDK doesn't work!!!");
    }
    
    return format;
}

- (BOOL)videoPlaybackStreamEnabled {
    return (_panCamVPlaybackProvider && _panCamVPlaybackProvider->containsVideoStream() == true) ? YES : NO;
}

- (BOOL)audioPlaybackStreamEnabled {
    return (_panCamVPlaybackProvider && _panCamVPlaybackProvider->containsAudioStream() == true) ? YES : NO;
}

#pragma mark - setupGL
- (void)setupGL
{
    int retVal = ICH_UNKNOWN_ERROR;
    AppLog(@"setupGL in\n");
    if (_surfaceContext && _surfaceContext->needSetup()) {
        _surfaceContext->tearDown();
        retVal = _surfaceContext->setup();
    }
    AppLog(@"setupGL out, surfaceContext: %p, retVal: %d", _surfaceContext.get(), retVal);
}

#pragma mark - SurfaceContext
- (BOOL)panCamSetViewPort:(int)x andY:(int)y andWidth:(int)width andHeight:(int)height needJudge:(BOOL)isNeed {
    //int  ret = _surfaceContext->setViewPort(0, 44, width, height - 88);
    if (!_surfaceContext) {
        AppLog(@"initializePanCamSDK doesn't work!!!");
        return NO;
    }
    
    int ret = ICH_UNKNOWN_ERROR;
    
    if (isNeed) {
        if (_surfaceContext->needSetup()) {
            _surfaceContext->tearDown();
            _surfaceContext->setup();
            ret = _surfaceContext->setViewPort(x, y, width, height);
        }
    } else {
        ret = _surfaceContext->setViewPort(x, y, width, height);
    }
    
    if (ret != ICH_SUCCEED) {
        //        AppLog(@"setViewPort failed, ret: %d", ret);
        return NO;
    } else return YES;
}

- (BOOL)panCamSetViewPort:(int)x andY:(int)y andWidth:(int)width andHeight:(int)height {
    return [self panCamSetViewPort:x andY:y andWidth:width andHeight:height needJudge:NO];
}

- (BOOL)panCamRenderWithNeedJudge:(BOOL)isNeed {
    if (!_surfaceContext) {
        AppLog(@"initializePanCamSDK doesn't work!!!");
        return NO;
    }
    
    int ret = ICH_UNKNOWN_ERROR;
    
    if (isNeed) {
        if (_surfaceContext->needRender()) {
            ret = _surfaceContext->render();
        }
    } else {
        ret = _surfaceContext->render();
    }
    
    if (ret != ICH_SUCCEED) {
        //        AppLog(@"render failed, ret: %d", ret);
        _isRender = NO;
        return NO;
    } else {
        _isRender = YES;
        return YES;
    }
}

- (BOOL)panCamRender {
    return [self panCamRenderWithNeedJudge:NO];
}

#pragma mark - PanCamImage

- (BOOL)panCamImageUpdate:(shared_ptr<ICatchGLImage>)image {
    if (!_panCamImage) {
        AppLog(@"initImage doesn't work!!!");
        return NO;
    }
    
    int ret = _panCamImage->update(image);
    if (ret != ICH_SUCCEED) {
        AppLog(@"panCamImage update failed, ret: %d", ret);
        return NO;
    } else return YES;
}

- (BOOL)panCamcreateICatchImage:(UIImage *)img {
    BOOL ret = NO;
    int retVal = -1;
    
    AppLog(@"----- createICatchImage begin ------");
    if (!_panCamImage) {
        AppLog(@"initImage doesn't work!!!");
        return ret;
    }
    
    retVal = _panCamImage->clear();
    if (ICH_SUCCEED != retVal) {
        AppLog(@"ICatchPancamImage clear failed, retVal: %d", retVal);
        return ret;
    }

    if (![_imageUtil initImage1:img]) {
        AppLog(@"initImage1 failed !");
        return ret;
    }
    AppLog(@"imageW: %d, imageH: %d", [_imageUtil getImageWidth], [_imageUtil getImageHeight]);
    
    auto image = make_shared<ICatchGLImage>(ICH_CODEC_RGBA_8888, [_imageUtil getImageWidth], [_imageUtil getImageHeight],
                                            [_imageUtil getImageWidth] * [_imageUtil getImageHeight] * 4);
    if (retVal != ICH_SUCCEED) {
        AppLog(@"ICatchGLImage init failed, retVal: %d", retVal);
        return ret;
    }
    
    retVal = image->putData([_imageUtil getImageData], [_imageUtil getImageWidth] * [_imageUtil getImageHeight] * 4);
    if (retVal != ICH_SUCCEED) {
        AppLog(@"ICatchGLImage putData failed, retVal: %d", retVal);
        return ret;
    }
    
    AppLog(@"call setFormat begin");
    retVal = _panCamGLImage->setFormat(ICH_CODEC_RGBA_8888, [_imageUtil getImageWidth], [_imageUtil getImageHeight]);
    AppLog(@"call setFormat end");
    if (retVal != ICH_SUCCEED) {
        AppLog(@"panCamGL setFormat failed, retVal: %d", retVal);
        return retVal;
    }
    
    [self setupGL];
    
    retVal = _panCamImage->update(image);
    if (retVal != ICH_SUCCEED) {
        AppLog(@"ICatchGLImage update failed, retVal: %d", retVal);
        return ret;
    }
    
    [_imageUtil uninitImage];
    ret = YES;
    AppLog(@"----- createICatchImage end ------");
    
    return ret;
}

#pragma mark - PanCamStream
- (BOOL)panCamUpdateFormat {
//    if (!_panCamPreview) {
//        AppLog(@"initStream doesn't work!!!");
//        return NO;
//    }
//
//    int ret = _panCamPreview->updateFormat(1920, 960, ICH_CODEC_YUV_NV12);
//    if (ret != ICH_SUCCEED) {
//        AppLog(@"panCamUpdateFormat failed, ret: %d", ret);
//        return NO;
//    } else return YES;
    return NO;
}

- (BOOL)panCamUpdateFormat:(shared_ptr<ICatchVideoFormat>)format {
//    if (!_panCamPreview) {
//        AppLog(@"initStream doesn't work!!!");
//        return NO;
//    }
//
//    int h = format->getVideoH();
//    if (format->getVideoW() == 1920 && h == 1080) {
//        h = 960;
//    }
//
//    int ret = _panCamPreview->updateFormat(format->getVideoW(), h, ICH_CODEC_YUV_NV12);
//    if (ret != ICH_SUCCEED) {
//        AppLog(@"panCamUpdateFormat failed, ret: %d", ret);
//        return NO;
//    } else return YES;
    return NO;
}

- (BOOL)panCamUpdateFrame:(uint8_t *)imgY andImageYsize:(int32_t)imgYsize
                andImageU:(uint8_t *)imgU andImageUsize:(int32_t)imgUsize
                andImageV:(uint8_t *)imgV andImageVsize:(int32_t)imgVsize {
//    if (!_panCamPreview) {
//        AppLog(@"initStream doesn't work!!!");
//        return NO;
//    }
//
//    int ret = _panCamPreview->updateFrame(imgY, imgYsize, imgU, imgUsize, imgV, imgVsize);
//    if (ret != ICH_SUCCEED) {
//        AppLog(@"panCamUpdateFrame failed, ret: %d", ret);
//        return NO;
//    } else return YES;
    return NO;
}

- (BOOL)panCamStopPreview {
    if (!_panCamPreview) {
        AppLog(@"PanCamSDK doesn't work!!!");
        return NO;
    }
    int ret = _panCamPreview->stop();
    if (ret != ICH_SUCCEED) {
        AppLog(@"panCamStopPreview failed, ret: %d", ret);
        return NO;
    } else {
        AppLog(@"panCamStopPreview succeed.");
        return YES;
    }
}

#pragma mark - PanCam Operate

- (BOOL)panCamRotate:(int)orientation andSpeedX:(float)speedX andSpeedY:(float)speedY andSpeedZ:(float)speedZ andTamp:(float)timestamp andType:(PCFileType)type{
    int ret = -1;
    
    switch (type) {
        case PCFileTypeImage:
            if (_panCamGLImage) {
                //ret = _panCamGL->rotate(speedX, speedX, speedZ, timestamp);
                ret = _imageGLTransform->rotate(orientation, speedX, speedY, speedZ, timestamp);
            }
            break;
            
        case PCFileTypeStream:
            if (_panCamGLStream) {
                ret = _streamGLTransform->rotate(orientation, speedX, speedY, speedZ, timestamp);
            }
            break;
            
        case PCFileTypeVideoPlayback:

            break;
            
        default:
            break;
    }
    
    return ret == ICH_SUCCEED ? YES : NO;
}

- (BOOL)panCamRotate:(CGPoint)pointC andPointPre:(CGPoint)pointP andType:(PCFileType)type {
    int ret = -1;
    
    CGFloat scale = [UIScreen mainScreen].scale;
    auto pointGLC = make_shared<ICatchGLPoint>(pointC.x * scale, pointC.y * scale);
    auto pointGLP = make_shared<ICatchGLPoint>(pointP.x * scale, pointP.y * scale);
    
    switch (type) {
        case PCFileTypeImage:
            // Rotate
            if (_panCamGLImage) {
                ret = _imageGLTransform->rotate(pointGLP, pointGLC);
            }
            break;
            
        case PCFileTypeStream:
            // Rotate
            if (_panCamGLStream) {
                ret = _streamGLTransform->rotate(pointGLP, pointGLC);
            }
            break;
        case PCFileTypeVideoPlayback:

            break;
            
        default:
            break;
    }
    

    return ret == ICH_SUCCEED ? YES : NO;
}

- (BOOL)panCamLocate:(float)distance andType:(PCFileType)type {
    int ret = -1;
    
    switch (type) {
        case PCFileTypeImage:
            if (_panCamGLImage) {
                ret = _imageGLTransform->locate(1/distance);
            }
            break;
          
        case PCFileTypeStream:
            if (_panCamGLStream) {
                ret = _streamGLTransform->locate(1/distance);
            }
            break;
            
        case PCFileTypeVideoPlayback:

            break;
        default:
            break;
    }
    
    return ret == ICH_SUCCEED ? YES : NO;
}

#pragma mark - Photo Album
- (void)createNewAssetCollection
{
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    for (int i=0; i<topLevelUserCollections.count; ++i) {
        PHCollection *collection = [topLevelUserCollections objectAtIndex:i];
        if ([collection.localizedTitle isEqualToString:@"MobileCamApp"/*@"SBCapp"*//*@"WiFiCam"*/]) {
            return;
        }
    }
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:@"MobileCamApp"/*@"SBCapp"*//*@"WiFiCam"*/];
    } completionHandler:^(BOOL success, NSError *error) {
        NSLog(@"Finished adding asset collection. %@", (success ? @"Success" : error));
    }];
}

- (BOOL)addNewAssetWithURL:(NSURL *)fileURL toAlbum:(NSString *)albumName andFileType:(ICatchFileType)fileType
{
    NSError *error;
    BOOL retVal = [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        // Request creating an asset from the image.
        PHAssetChangeRequest *createAssetRequest = nil;
        if (fileType == ICH_FILE_TYPE_IMAGE) {
            createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:fileURL];
        } else if (fileType == ICH_FILE_TYPE_VIDEO) {
            createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL];
        } else {
            AppLog(@"Unknown file type to save.");
            return;
        }
        
        PHAssetCollection *myAssetCollection = nil;
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        for (int i=0; i<topLevelUserCollections.count; ++i) {
            PHCollection *collection = [topLevelUserCollections objectAtIndex:i];
            if ([collection.localizedTitle isEqualToString:albumName]) {
                PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
                myAssetCollection = assetCollection;
                break;
            }
        }
        if (myAssetCollection && createAssetRequest) {
            // Request editing the album.
            PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:myAssetCollection];
            // Get a placeholder for the new asset and add it to the album editing request.
            PHObjectPlaceholder *assetPlaceholder = [createAssetRequest placeholderForCreatedAsset];
            [albumChangeRequest addAssets:@[ assetPlaceholder ]];
        }
        
    } error:&error];
    
    if (!retVal) {
        AppLog(@"Failed to save. %@", error.localizedDescription);
    }
    return retVal;
}

- (BOOL)savetoAlbum:(NSString *)albumName andAlbumAssetNum:(uint)assetNum andShareNum:(uint)shareNum
{
    /*static dispatch_once_t onceToken;
     dispatch_once(&onceToken, ^{
     [self createNewAssetCollection];
     });*/
    [self createNewAssetCollection];
    
    NSUInteger cameraTotalNum = 0;
    while (assetNum + shareNum != cameraTotalNum) {
        @autoreleasepool {
            [NSThread sleepForTimeInterval:0.5];
            cameraTotalNum = [self retrieveCameraRollAssetsResult].count;
            AppLog(@"cameraTotalNum: %ld", (unsigned long)cameraTotalNum);
        }
    }
    
    return [self addNewAssettoAlbum:albumName andNumber:shareNum];
}

- (BOOL)addNewAssettoAlbum:(NSString *)albumName andNumber:(int)num
{
    NSError *error;
    BOOL retVal = [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        
        PHAssetCollection *myAssetCollection = nil;
        PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
        for (int i=0; i<topLevelUserCollections.count; ++i) {
            PHCollection *collection = [topLevelUserCollections objectAtIndex:i];
            if ([collection.localizedTitle isEqualToString:albumName]) {
                PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
                myAssetCollection = assetCollection;
                break;
            }
        }
        
        // 获得相机胶卷
        PHAssetCollection *cameraRoll = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].lastObject;
        
        PHFetchResult *assetResult = [PHAsset fetchAssetsInAssetCollection:cameraRoll options:[PHFetchOptions new]];
        for (int i = 0; i < num; i++) {
            [assetResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    //获取相册的照片
                    if (idx == [assetResult count] - (num - i)) {
                        if (myAssetCollection && obj) {
                            // Request editing the album.
                            PHAssetCollectionChangeRequest *albumChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:myAssetCollection];
                            // Get a placeholder for the new asset and add it to the album editing request.
                            [albumChangeRequest addAssets:@[obj]];
                        }
                    }
                } completionHandler:^(BOOL success, NSError *error) {
                    // NSLog(@"Error: %@", error);
                }];
            }];
        }
    } error:&error];
    
    if (!retVal) {
        AppLog(@"Failed to save. %@", error.localizedDescription);
    }
    
    return retVal;
}

- (PHFetchResult *)retrieveCameraRollAssetsResult
{
    PHAssetCollection *cameraRoll = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].lastObject;
    return  [PHAsset fetchAssetsInAssetCollection:cameraRoll options:[PHFetchOptions new]];
}

- (NSArray *)createMediaDirectory
{
    BOOL isDir = NO;
    BOOL isDirExist= NO;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *mediaDirectory = [documentsDirectory stringByAppendingPathComponent:@"MobileCamApp-Medias"];
    
    isDirExist = [[NSFileManager defaultManager] fileExistsAtPath:mediaDirectory isDirectory:&isDir];
    if (!(isDir && isDirExist)) {
        BOOL bCreateDir = [[NSFileManager defaultManager] createDirectoryAtPath:mediaDirectory withIntermediateDirectories:NO attributes:nil error:nil];
        if(!bCreateDir){
            AppLog(@"Create MobileCamApp-Medias Directory Failed.");
        } else
            AppLog(@"Create MobileCamApp-Medias Directory path: %@",mediaDirectory);
    }
    
    NSString *photoDirectory = [mediaDirectory stringByAppendingPathComponent:@"Photos"];
    isDirExist = [[NSFileManager defaultManager] fileExistsAtPath:photoDirectory isDirectory:&isDir];
    if (!(isDir && isDirExist)) {
        BOOL bCreateDir = [[NSFileManager defaultManager] createDirectoryAtPath:photoDirectory withIntermediateDirectories:NO attributes:nil error:nil];
        if(!bCreateDir){
            AppLog(@"Create MobileCamApp-Medias/Photos Directory Failed.");
        } else
            AppLog(@"Create MobileCamApp-Medias/Photos Directory path: %@",photoDirectory);
    }
    
    NSString *videoDirectory = [mediaDirectory stringByAppendingPathComponent:@"Videos"];
    isDirExist = [[NSFileManager defaultManager] fileExistsAtPath:videoDirectory isDirectory:&isDir];
    if (!(isDir && isDirExist)) {
        BOOL bCreateDir = [[NSFileManager defaultManager] createDirectoryAtPath:videoDirectory withIntermediateDirectories:NO attributes:nil error:nil];
        if(!bCreateDir){
            AppLog(@"Create MobileCamApp-Medias/Videos Directory Failed.");
        } else
            AppLog(@"Create MobileCamApp-Medias/Videos Directory path: %@",videoDirectory);
    }
    
    return @[mediaDirectory, photoDirectory, videoDirectory];
}

#pragma mark clean TempData
- (void)cleanUpDownloadDirectory
{
    [self cleanTemp];
}

- (void)cleanTemp
{
    NSArray *tmpDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
    for (NSString *file in  tmpDirectoryContents) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:nil];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSString *logFilePath = nil;
    for (NSString *fileName in  documentsDirectoryContents) {
        if (![fileName isEqualToString:@"Camera.sqlite"] && ![fileName isEqualToString:@"Camera.sqlite-shm"] && ![fileName isEqualToString:@"Camera.sqlite-wal"]) {
            
            logFilePath = [documentsDirectory stringByAppendingPathComponent:fileName];
            [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:nil];
        }
    }
}

@end
