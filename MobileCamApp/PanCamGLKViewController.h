//
//  PanCamViewController.h
//  panCamTest
//
//  Created by ZJ on 2016/10/18.
//  Copyright © 2016年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKView.h>
#import <CoreMotion/CoreMotion.h>

#define maxDistance 5.0
#define minDistance 0.5

@class CADisplayLink;

@interface PanCamGLKViewController : UIViewController

@property (nonatomic, readonly) GLKView *glkView;
@property (nonatomic) NSInteger preferredFramesPerSecond;
@property (nonatomic, getter=isPaused) BOOL paused;

- (void)startGLKAnimation;
- (void)stopGLKAnimation;

@end
