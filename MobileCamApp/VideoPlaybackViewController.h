//
//  VideoPlaybackViewController.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-3-10.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

#import "PanCamGLKViewController.h"
@class VideoPlaybackViewController;

@protocol VideoPlaybackControllerDelegate <NSObject>
- (BOOL)videoPlaybackController:(VideoPlaybackViewController *)controller
             deleteVideoAtIndex:(NSUInteger)index;
- (BOOL)videoPlaybackController:(VideoPlaybackViewController *)controller deleteVideoFile:(shared_ptr<ICatchFile>)file;
@end

@interface VideoPlaybackViewController : PanCamGLKViewController <UIActionSheetDelegate, UIPopoverControllerDelegate, AppDelegateProtocol>
@property (nonatomic, weak) IBOutlet id<VideoPlaybackControllerDelegate> delegate;
@property (nonatomic) UIImage *previewImage;
@property (nonatomic) NSUInteger index;
@property (nonatomic) NSURL *videoURL;

@property (nonatomic) shared_ptr<ICatchFile> currentFile;

//
- (void)updateVideoPbProgress:(double)value;
- (void)updateVideoPbProgressState:(BOOL)caching;
- (void)stopVideoPb;
- (void)showServerStreamError;
-(void)notifyInsufficientPerformanceInfo:(long long)codec
                                   width:(long long)width
                                  height:(long long)height
                           frameInterval:(double)frameInterval
                              decodeTime:(double)decodeTime;
@end
