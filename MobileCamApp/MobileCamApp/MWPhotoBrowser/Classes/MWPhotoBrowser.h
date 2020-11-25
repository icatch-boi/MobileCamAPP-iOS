//
//  MWPhotoBrowser.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWPhoto.h"
#import "MWPhotoProtocol.h"
#import "MWCaptionView.h"
#import <MessageUI/MessageUI.h>
#import "../../AppDelegate.h"
#import "../../ActivityWrapper.h"

#import "PanCamViewController.h"

// Debug Logging
#if 0 // Set to 1 to enable debug logging
#define MWLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define MWLog(x, ...)
#endif

@class MWPhotoBrowser;

@protocol MWPhotoBrowserDelegate <NSObject>

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser;
- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;

@optional

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index;
- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index;
- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index;
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index;
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected;
// Added by guo.jiang
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser deletePhotoAtIndex:(NSUInteger)index;
- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser downloadPhotoAtIndex:(NSUInteger)index;
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser sharePhotoAtIndex:(NSUInteger)index serviceType:(NSString *)serviceType;
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser shareImageAtIndex:(NSUInteger)index;
- (void)shareImage:(MWPhotoBrowser *)photoBrowser;
//GLKView
- (void)panCamSDKinit;
- (void)createICatchImage:(UIImage *)image;
- (void)configureGLKView:(int)width andHeight:(int)height;
- (void)rotate:(CGPoint)pointC andPointPre:(CGPoint)pointPre;
- (void)rotate:(int)orientation andX:(float)x andY:(float)y andZ:(float)z andTimestamp:(long)timestamp;
- (void)locate:(float)distance;
- (void)panCamSDKDestroy;
- (void)destroyDataForEnterBackground;
- (BOOL)changePanoramaType:(int)panoramaType;

- (void)popGLKViewByphotoBrowser:(MWPhotoBrowser *)photoBrowser andVideoURL:(NSURL *)videoURL andThumb:(UIImage *)thumb;

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser;
@end

@interface MWPhotoBrowser : PanCamViewController <UIPopoverControllerDelegate, UIScrollViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, AppDelegateProtocol, ActivityWrapperDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet id<MWPhotoBrowserDelegate> delegate;
@property (nonatomic) BOOL zoomPhotosToFill;
@property (nonatomic) BOOL displayNavArrows;
@property (nonatomic) BOOL displayActionButton;
@property (nonatomic) BOOL displaySelectionButtons;
@property (nonatomic) BOOL alwaysShowControls;
@property (nonatomic) BOOL enableGrid;
@property (nonatomic) BOOL enableSwipeToDismiss;
@property (nonatomic) BOOL startOnGrid;
@property (nonatomic) BOOL autoPlayOnAppear;
@property (nonatomic) NSUInteger delayToHideElements;
@property (nonatomic) UIBarButtonItem *actionButton;
@property (nonatomic, readonly) NSUInteger currentIndex;
@property (nonatomic) NSUInteger currentPhotoIndex;

//MobileCamApp
@property (nonatomic) float cDistance;
@property (strong, nonatomic) EAGLContext *context;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic) UIBarButtonItem *inButton, *outButton;
@property (nonatomic) BOOL runFlag;
@property (nonatomic) UIPinchGestureRecognizer *pinchGesture;

// Customise image selection icons as they are the only icons with a colour tint
// Icon should be located in the app's main bundle
@property (nonatomic, strong) NSString *customImageSelectedIconName;
@property (nonatomic, strong) NSString *customImageSelectedSmallIconName;

// Init
- (id)initWithPhotos:(NSArray *)photosArray;
- (id)initWithDelegate:(id <MWPhotoBrowserDelegate>)delegate;

// Reloads the photo browser and refetches data
- (void)reloadData;

// Set page that photo browser starts on
- (void)setCurrentPhotoIndex:(NSUInteger)index;

// Navigation
- (void)showNextPhotoAnimated:(BOOL)animated;
- (void)showPreviousPhotoAnimated:(BOOL)animated;

//GLKView
- (void)configureView:(int)width andHeight:(int)height;
- (void)createICatchImage:(UIImage *)image;
- (void)panCamSDKinit;
- (void)popGLKView:(MWPhotoBrowser *)browser andVideoURL:(NSURL *)videoURL;
- (void)locate:(float)distance;
- (void)configureGyro;
- (void)ifAddPinchGestureRecognizer:(BOOL)state;

- (UIImage *)getNextPhoto;
- (UIImage *)getPreviousPhoto;
- (NSUInteger)numberOfPhotos;

@end
