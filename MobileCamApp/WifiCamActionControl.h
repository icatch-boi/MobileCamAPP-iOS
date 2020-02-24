//
//  WifiCamActionControl.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-23.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WifiCamActionControl : NSObject


-(int)startPreview:(ICatchCamPreviewMode)mode withAudioEnabled:(BOOL)enableAudio enableLive:(BOOL)isEnableLive;
-(BOOL)stopPreview;
-(void)capturePhoto;
-(void)triggerCapturePhoto;
-(BOOL)formatSD;
-(BOOL)startMovieRecord;
-(BOOL)stopMovieRecord;
-(BOOL)startTimelapseRecord;
-(BOOL)stopTimelapseRecord;
-(void)cleanUpDownloadDirectory;
-(BOOL)zoomIn;
-(BOOL)zoomOut;

// --
-(UIImage *)getAutoDownloadImage;

@end
