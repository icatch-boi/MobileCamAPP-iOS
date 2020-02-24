//
//  PanCamSDK.h
//  WifiCamMobileApp
//
//  Created by ZJ on 2016/10/12.
//  Copyright © 2016年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GLKit/GLKit.h>
#import "SDKPrivate.h"
#import "ICatchtekReliant.h"
#import "ICatchtekControl.h"
#import "WifiCamAVData.h"
#import "StreamObserver.h"
#import <Photos/Photos.h>

#import "CRawImageUtil.h"
#import <CoreMotion/CoreMotion.h>

#import "CRawImageUtil.h"

enum PCFileType {
    PCFileTypeImage  = 0,
    PCFileTypeStream,
    PCFileTypeVideoPlayback,
    PCFileTypeUnknow,
};

enum RenderType {
    RenderType_EnableNormal,
    RenderType_EnableGL,
    RenderType_Disable,
    RenderType_AutoSelect,
};

@interface PanCamSDK : NSObject

@property (nonatomic) BOOL isBusy;
@property (nonatomic, readonly) dispatch_queue_t pancamSDKQueue;
@property (nonatomic, readonly) BOOL isSDKInitialized;
@property (nonatomic, readonly) BOOL isStreamInitialized;
@property (nonatomic, readonly) BOOL isImageInitialized;

#pragma mark - PanCamSDK
+ (PanCamSDK *)instance;
- (BOOL)initializePanCamSDK;
- (BOOL)isPanoramaWithFile:(shared_ptr<ICatchFile>)file;
- (BOOL)initStreamWithRenderType:(RenderType)renderType isPreview:(BOOL)isPV file:(shared_ptr<ICatchFile>)f;
- (BOOL)initImage;
- (BOOL)changePanoramaType:(int)panoramaType isStream:(BOOL)isStream;
- (void)destroypanCamSDK;
- (void)destroyImage;
- (void)destroyStream;
- (void)enableLogSdkAtDiretctory:(NSString *)directoryName
                         enable:(BOOL)enable;

#pragma mark - MEDIA
- (int)startPublishStreaming:(string)rtmpUrl;
- (int)stopPublishStreaming;
- (int)isStreamSupportPublish;
- (NSString *)createLiveChannel:(CredentialSDK)credential withResolution:(NSString *)resolution withTitle:(NSString *)broadCastTitle withVRProjection:(BOOL)vrProjection;
- (void)deleteLiveChannel;
- (NSString *)startLive;
- (void)stopLive;
- (int)startMediaStream:(ICatchCamPreviewMode)mode enableAudio:(BOOL)enableAudio enableLive:(BOOL)enableLive;
- (BOOL)stopMediaStream;
- (BOOL)videoStreamEnabled;
- (BOOL)audioStreamEnabled;
- (shared_ptr<ICatchVideoFormat>)getVideoFormat;
- (shared_ptr<ICatchAudioFormat>)getAudioFormat;
- (BOOL)openAudio:(BOOL)isOpen;
- (WifiCamAVData *)getVideoData;
- (WifiCamAVData *)getAudioData;

#pragma mark - CONTROL
- (void)addObserver:(ICatchGLEventID)eventTypeId listener:(shared_ptr<ICatchIPancamListener>)listener isCustomize:(BOOL)isCustomize;
- (void)addObserver:(StreamObserver *)observer;;
- (void)removeObserver:(StreamObserver *)observer;
- (void)removeObserver:(ICatchGLEventID)eventTypeId listener:(shared_ptr<ICatchIPancamListener>)listener isCustomize:(BOOL)isCustomize;

#pragma mark - Video PB
- (double)play:(shared_ptr<ICatchFile>)file enableAudio:(BOOL)enableAudio isRemote:(BOOL)isRemote;
- (double)playFile:(NSURL *)fileURL enableAudio:(BOOL)enableAudio isRemote:(BOOL)isRemote;
- (double)play:(shared_ptr<ICatchFile>)file;
- (BOOL)pause;
- (BOOL)resume;
- (BOOL)stop;
- (BOOL)seek:(double)point;
- (WifiCamAVData *)getPlaybackVideoData;
- (WifiCamAVData *)getPlaybackAudioData;
- (shared_ptr<ICatchFrameBuffer>)getPlaybackAudioData1;
- (shared_ptr<ICatchVideoFormat>)getPlaybackVideoFormat;
- (shared_ptr<ICatchAudioFormat>)getPlaybackAudioFormat;
- (BOOL)videoPlaybackStreamEnabled;
- (BOOL)audioPlaybackStreamEnabled;

#pragma mark - SurfaceContext
- (BOOL)panCamRender;
- (BOOL)panCamRenderWithNeedJudge:(BOOL)isNeed;
- (BOOL)panCamSetViewPort:(int)x andY:(int)y andWidth:(int)width andHeight:(int)height;
- (BOOL)panCamSetViewPort:(int)x andY:(int)y andWidth:(int)width andHeight:(int)height needJudge:(BOOL)isNeed;
- (BOOL)panCamImageUpdate:(shared_ptr<ICatchGLImage>)image;
- (BOOL)panCamcreateICatchImage:(UIImage *)img;
- (BOOL)panCamRotate:(int)orientation andSpeedX:(float)speedX andSpeedY:(float)speedY andSpeedZ:(float)speedZ andTamp:(float)timestamp andType:(PCFileType)type;
- (BOOL)panCamRotate:(CGPoint)pointC andPointPre:(CGPoint)pointP andType:(PCFileType)type;
- (BOOL)panCamLocate:(float)distance andType:(PCFileType)type;

#if 1
- (BOOL)panCamUpdateFormat;
- (BOOL)panCamUpdateFormat:(shared_ptr<ICatchVideoFormat>)format;
- (BOOL)panCamUpdateFrame:(uint8_t *)imgY andImageYsize:(int32_t)imgYsize
                andImageU:(uint8_t *)imgU andImageUsize:(int32_t)imgUsize
                andImageV:(uint8_t *)imgV andImageVsize:(int32_t)imgVsize;
- (BOOL)panCamStopPreview;
#endif

#pragma mark - Photo Album
- (void)createNewAssetCollection;
- (BOOL)addNewAssetWithURL:(NSURL *)fileURL toAlbum:(NSString *)albumName andFileType:(ICatchFileType)fileType;
- (BOOL)savetoAlbum:(NSString *)albumName andAlbumAssetNum:(uint)assetNum andShareNum:(uint)shareNum;
- (BOOL)addNewAssettoAlbum:(NSString *)albumName andNumber:(int)num;
- (PHFetchResult *)retrieveCameraRollAssetsResult;
- (NSArray *)createMediaDirectory;

#pragma mark clean TempData
- (void)cleanUpDownloadDirectory;

@end
