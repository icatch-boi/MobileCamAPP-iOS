//
//  WifiCamPlaybackControl.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-7-2.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface WifiCamPlaybackControl : NSObject

- (double)play:(shared_ptr<ICatchFile>)file;
- (BOOL)pause;
- (BOOL)resume;
- (BOOL)stop;
- (BOOL)seek:(double)point;
- (BOOL)videoPlaybackStreamEnabled;
- (BOOL)audioPlaybackStreamEnabled;

@end
