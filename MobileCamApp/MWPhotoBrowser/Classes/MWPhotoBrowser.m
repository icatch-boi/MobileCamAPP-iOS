//
//  MWPhotoBrowser.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MWCommon.h"
#import "MWPhotoBrowser.h"
#import "MWPhotoBrowserPrivate.h"
#import "SDImageCache.h"
#import <Social/Social.h>
#import "UIImage+MWPhotoBrowser.h"

#define PADDING                  10
#define ACTION_SHEET_OLD_ACTIONS 2000
#define ACTION_SHEET_DELETE_ACTIONS (ACTION_SHEET_OLD_ACTIONS+1)
static void * MWVideoPlayerObservation = &MWVideoPlayerObservation;

@implementation MWPhotoBrowser

#pragma mark - Init

- (id)init {
    if ((self = [super init])) {
        [self _initialisation];
    }
    return self;
}

- (id)initWithDelegate:(id <MWPhotoBrowserDelegate>)delegate {
    if ((self = [self init])) {
        _delegate = delegate;
	}
	return self;
}

- (id)initWithPhotos:(NSArray *)photosArray {
	if ((self = [self init])) {
		_fixedPhotosArray = photosArray;
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	if ((self = [super initWithCoder:decoder])) {
        [self _initialisation];
	}
	return self;
}

- (void)_initialisation {
    
    // Defaults
    NSNumber *isVCBasedStatusBarAppearanceNum = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"];
    if (isVCBasedStatusBarAppearanceNum) {
        _isVCBasedStatusBarAppearance = isVCBasedStatusBarAppearanceNum.boolValue;
    } else {
        _isVCBasedStatusBarAppearance = YES; // default
    }
    self.hidesBottomBarWhenPushed = YES;
    _hasBelongedToViewController = NO;
    _photoCount = NSNotFound;
    _previousLayoutBounds = CGRectZero;
    _currentPageIndex = 0;
    _previousPageIndex = NSUIntegerMax;
    _displayActionButton = YES;
    _displayNavArrows = NO;
    _zoomPhotosToFill = YES;
    _performingLayout = NO; // Reset on view did appear
    _rotating = NO;
    _viewIsActive = NO;
    _enableGrid = YES;
    _startOnGrid = NO;
    _enableSwipeToDismiss = YES;
    _delayToHideElements = 5;
    _visiblePages = [[NSMutableSet alloc] init];
    _recycledPages = [[NSMutableSet alloc] init];
    _photos = [[NSMutableArray alloc] init];
    _thumbPhotos = [[NSMutableArray alloc] init];
    _currentGridContentOffset = CGPointMake(0, CGFLOAT_MAX);
    _didSavePreviousStateOfNavBar = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // Listen for MWPhoto notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMWPhotoLoadingDidEndNotification:)
                                                 name:MWPHOTO_LOADING_DID_END_NOTIFICATION
                                               object:nil];
    
}

- (void)dealloc {
    [self clearCurrentVideo];
    _pagingScrollView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self releaseAllUnderlyingPhotos:NO];
    [[SDImageCache sharedImageCache] clearMemory]; // clear memory
}

- (void)releaseAllUnderlyingPhotos:(BOOL)preserveCurrent {
    // Create a copy in case this array is modified while we are looping through
    // Release photos
    NSArray *copy = [_photos copy];
    for (id p in copy) {
        if (p != [NSNull null]) {
            if (preserveCurrent && p == [self photoAtIndex:self.currentIndex]) {
                continue; // skip current
            }
            [p unloadUnderlyingImage];
        }
    }
    // Release thumbs
    copy = [_thumbPhotos copy];
    for (id p in copy) {
        if (p != [NSNull null]) {
            [p unloadUnderlyingImage];
        }
    }
}

- (void)didReceiveMemoryWarning {

	// Release any cached data, images, etc that aren't in use.
    [self releaseAllUnderlyingPhotos:YES];
	[_recycledPages removeAllObjects];
	
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
}

#pragma mark - View Loading

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    
    // Validate grid settings
    if (_startOnGrid) _enableGrid = YES;
    if (_enableGrid) {
        _enableGrid = [_delegate respondsToSelector:@selector(photoBrowser:thumbPhotoAtIndex:)];
    }
    if (!_enableGrid) _startOnGrid = NO;
	
	// View
	self.view.backgroundColor = [UIColor blackColor];
    self.view.clipsToBounds = YES;
	
	// Setup paging scrolling view
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
	_pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
	_pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_pagingScrollView.pagingEnabled = YES;
	_pagingScrollView.delegate = self;
	_pagingScrollView.showsHorizontalScrollIndicator = NO;
	_pagingScrollView.showsVerticalScrollIndicator = NO;
	_pagingScrollView.backgroundColor = [UIColor blackColor];
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	[self.view addSubview:_pagingScrollView];
	
    // Toolbar
    _toolbar = [[UIToolbar alloc] initWithFrame:[self frameForToolbarAtOrientation:self.interfaceOrientation]];
    _toolbar.tintColor = [UIColor whiteColor];
    _toolbar.barTintColor = nil;
    [_toolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [_toolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsLandscapePhone];
    _toolbar.barStyle = UIBarStyleBlackTranslucent;
    _toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    // Toolbar Items
    if (self.displayNavArrows) {
        NSString *arrowPathFormat = @"MWPhotoBrowser.bundle/images/UIBarButtonItemArrow%@";
        UIImage *previousButtonImage = [UIImage imageForResourcePath:[NSString stringWithFormat:arrowPathFormat, @"Left"] ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
        UIImage *nextButtonImage = [UIImage imageForResourcePath:[NSString stringWithFormat:arrowPathFormat, @"Right"] ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
        _previousButton = [[UIBarButtonItem alloc] initWithImage:previousButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(gotoPreviousPage)];
        _nextButton = [[UIBarButtonItem alloc] initWithImage:nextButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(gotoNextPage)];
    }
    if (self.displayActionButton) {
        _actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonPressed:)];
        // Added by guo.jiang
        _deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                      target:self
                                                                      action:@selector(deletePhoto:)];
    }
    
    // Marked by guo.jiang
    //[self reloadData];
    
    // Swipe to dismiss
    if (_enableSwipeToDismiss) {
        UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(doneButtonPressed:)];
        swipeGesture.direction = UISwipeGestureRecognizerDirectionDown | UISwipeGestureRecognizerDirectionUp;
        [self.view addGestureRecognizer:swipeGesture];
    }
    
	// Super
    [super viewDidLoad];
    
    //GLKView
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    [EAGLContext setCurrentContext:self.context];
    
    [self panCamSDKinit];
    
    GLKView* view = (GLKView*)self.glkView;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    NSLog(@"GLKView, view: %@", self.glkView);
    _cDistance = maxDistance;
    
    // Added by guo.jiang
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.delegate = self;
    
    // MobileCamApp
    _motionManager = [[CMMotionManager alloc] init];
    _queue = [[NSOperationQueue alloc]init];
    //[self configureGyro];
    
    _pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    
    [self preparePanoramaTypeData];
}

- (void)preparePanoramaTypeData {
    NSArray *temp = @[@"Sphere", @"Asteroid", @"VR"];
    _tbPanoramaTypeArray = [[WifiCamAlertTable alloc] initWithParameters:[NSMutableArray arrayWithArray:temp] andLastIndex:0];
}

- (void)ifAddPinchGestureRecognizer:(BOOL)state
{
    if (state) {
        [self.view addGestureRecognizer:_pinchGesture];
    } else {
        [self.view removeGestureRecognizer:_pinchGesture];
    }
}

#pragma mark ------- MobileCamApp Events --------

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    int windowW = (int)view.drawableWidth;
    int windowH = (int)view.drawableHeight;
    //NSLog(@"width: %d, height: %d", windowW, windowH);
    if (!self.paused) {
        [self configureView:windowW andHeight:windowH];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self setControlsHidden:NO animated:YES permanent:YES];
    
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
        
        [self rotate:pointC andPointPre:pointP];
        // Update Prev point
        pointP.x = pointC.x;
        pointP.y = pointC.y;
    }
    
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Nothing to do
    [self hideControlsAfterDelay];
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
            gestureRecognizer.scale = 1;
            _cDistance = [self calculateDistance:_cDistance andScale:scale];
            [self hideControlsAfterDelay];
            
            break;
        }
        case UIGestureRecognizerStateBegan:{ //
            NSLog(@"======UIGestureRecognizerStateBegan");
            [self setControlsHidden:NO animated:YES permanent:YES];
            break;
        }
        case UIGestureRecognizerStateChanged:{ //
            NSLog(@"======UIGestureRecognizerStateChanged");
            
            //gestureRecognizer.view.transform = CGAffineTransformScale(gestureRecognizer.view.transform, gestureRecognizer.scale, gestureRecognizer.scale);
            [self locate:[self calculateDistance:_cDistance andScale:scale]];
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

- (void)zoomInButton:(id)sender {
    NSLog(@"----------> zoomInButton");
    _cDistance = maxDistance;
    [self locate: maxDistance];
}

- (void)zoomOutButton:(id)sender {
    NSLog(@"----------> zoomOutButton");
    _cDistance = minDistance;
    [self locate: minDistance];
}

#pragma mark ---------- Gyro Event ------------

static double __timestampA = 0;

- (void)configureGyro
{
    if (([_motionManager isGyroAvailable])) {
        [self.motionManager startGyroUpdatesToQueue:_queue withHandler:^(CMGyroData* gyroData, NSError* error) {
            
            if (__timestampA == 0) {
                __timestampA = gyroData.timestamp;
            }
            
            long timestamp = (gyroData.timestamp - __timestampA) * 1000 * 1000 * 1000;
            //NSLog(@"%.2f, %.2f, %.2f, %ld", gyroData.rotationRate.x, gyroData.rotationRate.y, gyroData.rotationRate.z, timestamp);
            //[self rotate:gyroData.rotationRate.x andY:gyroData.rotationRate.y andZ:gyroData.rotationRate.z andTimestamp:timestamp];
            if (!self.paused) {
                float speedX = roundf(gyroData.rotationRate.x * 10) / 10;
                float speedY = roundf(gyroData.rotationRate.y * 10) / 10;
                float speedZ = roundf(gyroData.rotationRate.z * 10) / 10;
                
                __block UIInterfaceOrientation orientation;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    orientation = [[UIApplication sharedApplication] statusBarOrientation];
                });
                switch (orientation) {
                    case UIInterfaceOrientationPortrait:
                        [self rotate:0 andX:speedX andY:speedY andZ:speedZ andTimestamp:timestamp];
                        break;
                    case UIInterfaceOrientationLandscapeLeft:
                        [self rotate:3 andX:speedX andY:speedY andZ:speedZ andTimestamp:timestamp];
                        break;
                    case UIInterfaceOrientationPortraitUpsideDown:
                        [self rotate:2 andX:speedX andY:speedY andZ:speedZ andTimestamp:timestamp];
                        break;
                    case UIInterfaceOrientationLandscapeRight:
                        [self rotate:1 andX:speedX andY:speedY andZ:speedZ andTimestamp:timestamp];
                        break;
                    case UIInterfaceOrientationUnknown:
                        break;
                }
            }
        }];
    } else {
        NSLog(@"Gyro not abaliable.");
    }
}

- (void)performLayout {
    _panoramaTypeButton = [[UIBarButtonItem alloc] initWithTitle:@"Sphere" style:UIBarButtonItemStyleDone target:self action:@selector(changePanoramaTypeClick)];
    [self updatePanoramaTyprOnScreen];
    
    // Setup
    _performingLayout = YES;
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    
	// Setup pages
    [_visiblePages removeAllObjects];
    [_recycledPages removeAllObjects];
    
    // Navigation buttons
    if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
        // We're first on stack so show done button
        _doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStylePlain target:self action:@selector(doneButtonPressed:)];
        // Set appearance
        [_doneButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [_doneButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
        [_doneButton setBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
        [_doneButton setBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
        [_doneButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateNormal];
        [_doneButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateHighlighted];
        self.navigationItem.rightBarButtonItem = _deleteButton;
        self.navigationItem.leftBarButtonItem = _doneButton;
    } else {
        // We're not first so show back button
        UIViewController *previousViewController = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
        NSString *backButtonTitle = previousViewController.navigationItem.backBarButtonItem ? previousViewController.navigationItem.backBarButtonItem.title : previousViewController.title;
        UIBarButtonItem *newBackButton = [[UIBarButtonItem alloc] initWithTitle:backButtonTitle style:UIBarButtonItemStylePlain target:nil action:nil];
        // Appearance
        [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
        [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
        [newBackButton setBackButtonBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
        [newBackButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateNormal];
        [newBackButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateHighlighted];
        _previousViewControllerBackButton = previousViewController.navigationItem.backBarButtonItem; // remember previous
        previousViewController.navigationItem.backBarButtonItem = newBackButton;
        self.navigationItem.rightBarButtonItem = _panoramaTypeButton;
    }
    
    _inButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MWPhotoBrowser.bundle/images/zoomin" ofType:@"png"]] style:UIBarButtonItemStylePlain target:self action:@selector(zoomInButton:)];
    _outButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MWPhotoBrowser.bundle/images/zoomout" ofType:@"png"]] style:UIBarButtonItemStylePlain target:self action:@selector(zoomOutButton:)];
    /*
     UIBarButtonItem *flexSpace1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
     flexSpace1.width = 40;
     self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:inButton, flexSpace1, outButton, nil];
     */

    // Toolbar items
    BOOL hasItems = NO;
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
    fixedSpace.width = 32; // To balance action button
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    NSMutableArray *items = [[NSMutableArray alloc] init];

    // Left button - Grid
    if (_enableGrid) {
        hasItems = YES;
#if 0
        [items addObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageForResourcePath:@"MWPhotoBrowser.bundle/images/UIBarButtonItemGrid" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] style:UIBarButtonItemStylePlain target:self action:@selector(showGridAnimated)]];
#endif
        [items addObject: _panoramaTypeButton];
    } else {
        //[items addObject:fixedSpace];
        [items addObject:_deleteButton];
    }
    
    // Middle - Nav
    if (_previousButton && _nextButton && numberOfPhotos > 0) {
        hasItems = YES;
        //Added by guo.jiang
        /*if (_deleteButton && !(!hasItems && !self.navigationItem.leftBarButtonItem)) {
            [items addObject:_deleteButton];
        }*/
        
        [items addObject:flexSpace];
        [items addObject:_inButton];
        [items addObject:flexSpace];
        [items addObject:_outButton];
        [items addObject:flexSpace];
        [items addObject:_previousButton];
        [items addObject:flexSpace];
        [items addObject:_nextButton];
        [items addObject:flexSpace];
    } else {
        [items addObject:flexSpace];
    }
    
    // Right - Action
    if (_actionButton && !(!hasItems && !self.navigationItem.rightBarButtonItem)) {
        [items addObject:_actionButton];
    } else {
        // We're not showing the toolbar so try and show in top right
        if (_actionButton)
            //Updated by guo.jiang
            //self.navigationItem.rightBarButtonItem = _actionButton;
            self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:_actionButton, _deleteButton, nil];
        [items addObject:fixedSpace];
    }

    // Toolbar visibility
    [_toolbar setItems:items];
    BOOL hideToolbar = YES;
    for (UIBarButtonItem* item in _toolbar.items) {
        if (item != fixedSpace && item != flexSpace) {
            hideToolbar = NO;
            break;
        }
    }
    if (hideToolbar) {
        [_toolbar removeFromSuperview];
    } else {
        [self.view addSubview:_toolbar];
    }
    
    // Update nav
	[self updateNavigation];
    
    // Content offset
	_pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:_currentPageIndex];
    [self tilePages];
    _performingLayout = NO;
    
}

// Release any retained subviews of the main view.
- (void)viewDidUnload {
	_currentPageIndex = 0;
    _pagingScrollView = nil;
    _visiblePages = nil;
    _recycledPages = nil;
    _toolbar = nil;
    _previousButton = nil;
    _nextButton = nil;
    _progressHUD = nil;
    [super viewDidUnload];
}

- (BOOL)presentingViewControllerPrefersStatusBarHidden {
    UIViewController *presenting = self.presentingViewController;
    if (presenting) {
        if ([presenting isKindOfClass:[UINavigationController class]]) {
            presenting = [(UINavigationController *)presenting topViewController];
        }
    } else {
        // We're in a navigation controller so get previous one!
        if (self.navigationController && self.navigationController.viewControllers.count > 1) {
            presenting = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count-2];
        }
    }
    if (presenting) {
        return [presenting prefersStatusBarHidden];
    } else {
        return NO;
    }
}

#pragma mark - Appearance

- (void)viewWillAppear:(BOOL)animated {
    
    // Super
    [super viewWillAppear:animated];
    
    // Update --guo.jiang
    [self reloadData];
    
    // Status bar
    if (!_viewHasAppearedInitially) {
        _leaveStatusBarAlone = [self presentingViewControllerPrefersStatusBarHidden];
        // Check if status bar is hidden on first appear, and if so then ignore it
        if (CGRectEqualToRect([[UIApplication sharedApplication] statusBarFrame], CGRectZero)) {
            _leaveStatusBarAlone = YES;
        }
    }
    // Set style
    if (!_leaveStatusBarAlone && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        _previousStatusBarStyle = [[UIApplication sharedApplication] statusBarStyle];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:animated];
    }
    
    // Navigation bar appearance
    if (!_viewIsActive && [self.navigationController.viewControllers objectAtIndex:0] != self) {
        [self storePreviousNavBarAppearance];
    }
    [self setNavBarAppearance:animated];
    
    // Update UI
	[self hideControlsAfterDelay];
    
    // Initial appearance
    if (!_viewHasAppearedInitially) {
        if (_startOnGrid) {
            [self showGrid:NO];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recoverFromDisconnection)
                                             name    :@"kCameraNetworkConnectedNotification"
                                             object  :nil];
    // If rotation occured while we're presenting a modal
    // and the index changed, make sure we show the right one now
    if (_currentPageIndex != _pageIndexBeforeRotation) {
        // Marked by guo.jiang
        // We don't use grid view right now (enableGrid is NO), but this will make mwphotobrowser goto the same page after we restart.
//        [self jumpToPageAtIndex:_pageIndexBeforeRotation animated:NO];
    }
    
}

-(void)recoverFromDisconnection {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _viewIsActive = YES;
    
    // Autoplay if first is video
    if (!_viewHasAppearedInitially) {
        if (_autoPlayOnAppear) {
            MWPhoto *photo = [self photoAtIndex:_currentPageIndex];
            if ([photo respondsToSelector:@selector(isVideo)] && photo.isVideo) {
                [self playVideoAtIndex:_currentPageIndex];
            }
        }
    }
    
    _viewHasAppearedInitially = YES;
        
}

- (void)viewWillDisappear:(BOOL)animated {
    
    // Detect if rotation occurs while we're presenting a modal
    _pageIndexBeforeRotation = _currentPageIndex;
    
    // Check that we're being popped for good
    if ([self.navigationController.viewControllers objectAtIndex:0] != self &&
        ![self.navigationController.viewControllers containsObject:self]) {
        
        // State
        _viewIsActive = NO;
        
        // Bar state / appearance
        [self restorePreviousNavBarAppearance:animated];
        
    }
    
    // Controls
    [self.navigationController.navigationBar.layer removeAllAnimations]; // Stop all animations on nav bar
    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // Cancel any pending toggles from taps
    [self setControlsHidden:NO animated:NO permanent:YES];
    
    // Status bar
    if (!_leaveStatusBarAlone && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [[UIApplication sharedApplication] setStatusBarStyle:_previousStatusBarStyle animated:animated];
    }
    
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    
#if USE_SYSTEM_IOS7_IMPLEMENTATION
    if (_actionsSheet.visible) {
        [_actionsSheet dismissWithClickedButtonIndex:0 animated:NO];
    }
#else
    [_actionsSheet dismissViewControllerAnimated:NO completion:nil];
#endif
    
    // Super
    [super viewWillDisappear:animated];
        
    //if (_runFlag) {
        [self stopGLKAnimation];
        [self.motionManager stopGyroUpdates];
        [EAGLContext setCurrentContext:self.context];
        [self panCamSDKDestroy];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
    //}
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    if (parent && _hasBelongedToViewController) {
        [NSException raise:@"MWPhotoBrowser Instance Reuse" format:@"MWPhotoBrowser instances cannot be reused."];
    }
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if (!parent) {
        _hasBelongedToViewController = YES;
    }
}

#pragma mark - Nav Bar Appearance

- (void)setNavBarAppearance:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    UINavigationBar *navBar = self.navigationController.navigationBar;
    navBar.tintColor = [UIColor whiteColor];
    navBar.barTintColor = nil;
    navBar.shadowImage = nil;
    navBar.translucent = YES;
    navBar.barStyle = UIBarStyleBlackTranslucent;
    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    [navBar setBackgroundImage:nil forBarMetrics:UIBarMetricsLandscapePhone];
}

- (void)storePreviousNavBarAppearance {
    _didSavePreviousStateOfNavBar = YES;
    _previousNavBarBarTintColor = self.navigationController.navigationBar.barTintColor;
    _previousNavBarTranslucent = self.navigationController.navigationBar.translucent;
    _previousNavBarTintColor = self.navigationController.navigationBar.tintColor;
    _previousNavBarHidden = self.navigationController.navigationBarHidden;
    _previousNavBarStyle = self.navigationController.navigationBar.barStyle;
    _previousNavigationBarBackgroundImageDefault = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
    _previousNavigationBarBackgroundImageLandscapePhone = [self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsLandscapePhone];
}

- (void)restorePreviousNavBarAppearance:(BOOL)animated {
    if (_didSavePreviousStateOfNavBar) {
        [self.navigationController setNavigationBarHidden:_previousNavBarHidden animated:animated];
        UINavigationBar *navBar = self.navigationController.navigationBar;
        navBar.tintColor = _previousNavBarTintColor;
        navBar.translucent = _previousNavBarTranslucent;
        navBar.barTintColor = _previousNavBarBarTintColor;
        navBar.barStyle = _previousNavBarStyle;
        [navBar setBackgroundImage:_previousNavigationBarBackgroundImageDefault forBarMetrics:UIBarMetricsDefault];
        [navBar setBackgroundImage:_previousNavigationBarBackgroundImageLandscapePhone forBarMetrics:UIBarMetricsLandscapePhone];
        // Restore back button if we need to
        if (_previousViewControllerBackButton) {
            UIViewController *previousViewController = [self.navigationController topViewController]; // We've disappeared so previous is now top
            previousViewController.navigationItem.backBarButtonItem = _previousViewControllerBackButton;
            _previousViewControllerBackButton = nil;
        }
    }
}

#pragma mark - Layout

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self layoutVisiblePages];
}

- (void)layoutVisiblePages {
    
	// Flag
	_performingLayout = YES;
	
	// Toolbar
	_toolbar.frame = [self frameForToolbarAtOrientation:self.interfaceOrientation];
    
	// Remember index
	NSUInteger indexPriorToLayout = _currentPageIndex;
	
	// Get paging scroll view frame to determine if anything needs changing
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
	// Frame needs changing
    if (!_skipNextPagingScrollViewPositioning) {
        _pagingScrollView.frame = pagingScrollViewFrame;
    }
    _skipNextPagingScrollViewPositioning = NO;
	
	// Recalculate contentSize based on current orientation
	_pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	
	// Adjust frames and configuration of each visible page
	for (MWZoomingScrollView *page in _visiblePages) {
        NSUInteger index = page.index;
		page.frame = [self frameForPageAtIndex:index];
        if (page.captionView) {
            page.captionView.frame = [self frameForCaptionView:page.captionView atIndex:index];
        }
        if (page.selectedButton) {
            page.selectedButton.frame = [self frameForSelectedButton:page.selectedButton atIndex:index];
        }
        if (page.playButton) {
            page.playButton.frame = [self frameForPlayButton:page.playButton atIndex:index];
        }
        
        // Adjust scales if bounds has changed since last time
        if (!CGRectEqualToRect(_previousLayoutBounds, self.view.bounds)) {
            // Update zooms for new bounds
            [page setMaxMinZoomScalesForCurrentBounds];
            _previousLayoutBounds = self.view.bounds;
        }

	}
    
    // Adjust video loading indicator if it's visible
    [self positionVideoLoadingIndicator];
	
	// Adjust contentOffset to preserve page location based on values collected prior to location
	_pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:indexPriorToLayout];
	[self didStartViewingPageAtIndex:_currentPageIndex]; // initial
    
	// Reset
	_currentPageIndex = indexPriorToLayout;
	_performingLayout = NO;
    
}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
	// Remember page index before rotation
	_pageIndexBeforeRotation = _currentPageIndex;
	_rotating = YES;
    
    // In iOS 7 the nav bar gets shown after rotation, but might as well do this for everything!
    if ([self areControlsHidden]) {
        // Force hidden
        self.navigationController.navigationBarHidden = YES;
    }
	
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	// Perform layout
	_currentPageIndex = _pageIndexBeforeRotation;
	
	// Delay control holding
	[self hideControlsAfterDelay];
    
    // Layout
    [self layoutVisiblePages];
	
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	_rotating = NO;
    // Ensure nav bar isn't re-displayed
    if ([self areControlsHidden]) {
        self.navigationController.navigationBarHidden = NO;
        self.navigationController.navigationBar.alpha = 0;
    }
}

#pragma mark - Data

- (NSUInteger)currentIndex {
    return _currentPageIndex;
}

- (void)reloadData {
    
    // Reset
    _photoCount = NSNotFound;
    
    // Get data
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    [self releaseAllUnderlyingPhotos:YES];
    [_photos removeAllObjects];
    [_thumbPhotos removeAllObjects];
    for (int i = 0; i < numberOfPhotos; i++) {
        [_photos addObject:[NSNull null]];
        [_thumbPhotos addObject:[NSNull null]];
    }

    // Update current page index
    if (numberOfPhotos > 0) {
        _currentPageIndex = MAX(0, MIN(_currentPageIndex, numberOfPhotos - 1));
    } else {
        _currentPageIndex = 0;
    }
    
    // Update layout
    if ([self isViewLoaded]) {
        while (_pagingScrollView.subviews.count) {
            @autoreleasepool {
                [[_pagingScrollView.subviews lastObject] removeFromSuperview];
            }
        }
        [self performLayout];
        [self.view setNeedsLayout];
    }
    
}

- (NSUInteger)numberOfPhotos {
    if (_photoCount == NSNotFound) {
        if ([_delegate respondsToSelector:@selector(numberOfPhotosInPhotoBrowser:)]) {
            _photoCount = [_delegate numberOfPhotosInPhotoBrowser:self];
        } else if (_fixedPhotosArray) {
            _photoCount = _fixedPhotosArray.count;
        }
    }
    if (_photoCount == NSNotFound) _photoCount = 0;
    return _photoCount;
}

- (id<MWPhoto>)photoAtIndex:(NSUInteger)index {
    _currentPhotoIndex = index;
    id <MWPhoto> photo = nil;
    if (index < _photos.count) {
        if ([_photos objectAtIndex:index] == [NSNull null]) {
            if ([_delegate respondsToSelector:@selector(photoBrowser:photoAtIndex:)]) {
                photo = [_delegate photoBrowser:self photoAtIndex:index];
            } else if (_fixedPhotosArray && index < _fixedPhotosArray.count) {
                photo = [_fixedPhotosArray objectAtIndex:index];
            }
            if (photo) [_photos replaceObjectAtIndex:index withObject:photo];
        } else {
            photo = [_photos objectAtIndex:index];
        }
    }
    return photo;
}

- (id<MWPhoto>)thumbPhotoAtIndex:(NSUInteger)index {
    id <MWPhoto> photo = nil;
    if (index < _thumbPhotos.count) {
        if ([_thumbPhotos objectAtIndex:index] == [NSNull null]) {
            if ([_delegate respondsToSelector:@selector(photoBrowser:thumbPhotoAtIndex:)]) {
                photo = [_delegate photoBrowser:self thumbPhotoAtIndex:index];
            }
            if (photo) [_thumbPhotos replaceObjectAtIndex:index withObject:photo];
        } else {
            photo = [_thumbPhotos objectAtIndex:index];
        }
    }
    return photo;
}

- (MWCaptionView *)captionViewForPhotoAtIndex:(NSUInteger)index {
    MWCaptionView *captionView = nil;
    if ([_delegate respondsToSelector:@selector(photoBrowser:captionViewForPhotoAtIndex:)]) {
        captionView = [_delegate photoBrowser:self captionViewForPhotoAtIndex:index];
    } else {
        id <MWPhoto> photo = [self photoAtIndex:index];
        if ([photo respondsToSelector:@selector(caption)]) {
            if ([photo caption]) captionView = [[MWCaptionView alloc] initWithPhoto:photo];
        }
    }
    captionView.alpha = [self areControlsHidden] ? 0 : 1; // Initial alpha
    return captionView;
}

- (BOOL)photoIsSelectedAtIndex:(NSUInteger)index {
    BOOL value = NO;
    if (_displaySelectionButtons) {
        if ([self.delegate respondsToSelector:@selector(photoBrowser:isPhotoSelectedAtIndex:)]) {
            value = [self.delegate photoBrowser:self isPhotoSelectedAtIndex:index];
        }
    }
    return value;
}

- (void)setPhotoSelected:(BOOL)selected atIndex:(NSUInteger)index {
    if (_displaySelectionButtons) {
        if ([self.delegate respondsToSelector:@selector(photoBrowser:photoAtIndex:selectedChanged:)]) {
            [self.delegate photoBrowser:self photoAtIndex:index selectedChanged:selected];
        }
    }
}

- (UIImage *)imageForPhoto:(id<MWPhoto>)photo {
	if (photo) {
		// Get image or obtain in background
		if ([photo underlyingImage]) {
			return [photo underlyingImage];
		} else {
            [photo loadUnderlyingImageAndNotify];
		}
	}
	return nil;
}

- (void)loadAdjacentPhotosIfNecessary:(id<MWPhoto>)photo {
    MWZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        // If page is current page then initiate loading of previous and next pages
        NSUInteger pageIndex = page.index;
        if (_currentPageIndex == pageIndex) {
            if (pageIndex > 0) {
                // Preload index - 1
                id <MWPhoto> photo = [self photoAtIndex:pageIndex-1];
                if (![photo underlyingImage]) {
                    [photo loadUnderlyingImageAndNotify];
                    MWLog(@"Pre-loading image at index %lu", (unsigned long)pageIndex-1);
                }
            }
            if (pageIndex < [self numberOfPhotos] - 1) {
                // Preload index + 1
                id <MWPhoto> photo = [self photoAtIndex:pageIndex+1];
                if (![photo underlyingImage]) {
                    [photo loadUnderlyingImageAndNotify];
                    MWLog(@"Pre-loading image at index %lu", (unsigned long)pageIndex+1);
                }
            }
        }
    }
}

#pragma mark - MWPhoto Loading Notification

- (void)handleMWPhotoLoadingDidEndNotification:(NSNotification *)notification {
    id <MWPhoto> photo = [notification object];
    MWZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        if ([photo underlyingImage]) {
            // Successful load
            [page displayImage];
            [self loadAdjacentPhotosIfNecessary:photo];
        } else {
            
            // Failed to load
            [page displayImageFailure];
        }
        // Update nav
        [self updateNavigation];
    }
}

#pragma mark - Paging

- (void)tilePages {
	
	// Calculate which pages should be visible
	// Ignore padding as paging bounces encroach on that
	// and lead to false page loads
	CGRect visibleBounds = _pagingScrollView.bounds;
	NSInteger iFirstIndex = (NSInteger)floorf((CGRectGetMinX(visibleBounds)+PADDING*2) / CGRectGetWidth(visibleBounds));
	NSInteger iLastIndex  = (NSInteger)floorf((CGRectGetMaxX(visibleBounds)-PADDING*2-1) / CGRectGetWidth(visibleBounds));
    if (iFirstIndex < 0) iFirstIndex = 0;
    if (iFirstIndex > [self numberOfPhotos] - 1) iFirstIndex = [self numberOfPhotos] - 1;
    if (iLastIndex < 0) iLastIndex = 0;
    if (iLastIndex > [self numberOfPhotos] - 1) iLastIndex = [self numberOfPhotos] - 1;
	
	// Recycle no longer needed pages
    NSInteger pageIndex;
	for (MWZoomingScrollView *page in _visiblePages) {
        pageIndex = page.index;
		if (pageIndex < (NSUInteger)iFirstIndex || pageIndex > (NSUInteger)iLastIndex) {
			[_recycledPages addObject:page];
            [page.captionView removeFromSuperview];
            [page.selectedButton removeFromSuperview];
            [page.playButton removeFromSuperview];
            [page prepareForReuse];
			[page removeFromSuperview];
			MWLog(@"Removed page at index %lu", (unsigned long)pageIndex);
		}
	}
	[_visiblePages minusSet:_recycledPages];
    while (_recycledPages.count > 2) // Only keep 2 recycled pages
        [_recycledPages removeObject:[_recycledPages anyObject]];
	
	// Add missing pages
	for (NSUInteger index = (NSUInteger)iFirstIndex; index <= (NSUInteger)iLastIndex; index++) {
		if (![self isDisplayingPageForIndex:index]) {
            
            // Add new page
			MWZoomingScrollView *page = [self dequeueRecycledPage];
			if (!page) {
				page = [[MWZoomingScrollView alloc] initWithPhotoBrowser:self];
			}
			[_visiblePages addObject:page];
			[self configurePage:page forIndex:index];

			[_pagingScrollView addSubview:page];
			MWLog(@"Added page at index %lu", (unsigned long)index);
            
            // Add caption
            MWCaptionView *captionView = [self captionViewForPhotoAtIndex:index];
            if (captionView) {
                captionView.frame = [self frameForCaptionView:captionView atIndex:index];
                [_pagingScrollView addSubview:captionView];
                page.captionView = captionView;
            }
            
            // Add play button if needed
            if (page.displayingVideo) {
                UIButton *playButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [playButton setImage:[UIImage imageForResourcePath:@"MWPhotoBrowser.bundle/images/PlayButtonOverlayLarge" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] forState:UIControlStateNormal];
                [playButton setImage:[UIImage imageForResourcePath:@"MWPhotoBrowser.bundle/images/PlayButtonOverlayLargeTap" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] forState:UIControlStateHighlighted];
                [playButton addTarget:self action:@selector(playButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                [playButton sizeToFit];
                playButton.frame = [self frameForPlayButton:playButton atIndex:index];
                [_pagingScrollView addSubview:playButton];
                page.playButton = playButton;
            }
            
            // Add selected button
            if (self.displaySelectionButtons) {
                UIButton *selectedButton = [UIButton buttonWithType:UIButtonTypeCustom];
                [selectedButton setImage:[UIImage imageForResourcePath:@"MWPhotoBrowser.bundle/images/ImageSelectedOff" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] forState:UIControlStateNormal];
                UIImage *selectedOnImage;
                if (self.customImageSelectedIconName) {
                    selectedOnImage = [UIImage imageNamed:self.customImageSelectedIconName];
                } else {
                    selectedOnImage = [UIImage imageForResourcePath:@"MWPhotoBrowser.bundle/images/ImageSelectedOn" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
                }
                [selectedButton setImage:selectedOnImage forState:UIControlStateSelected];
                [selectedButton sizeToFit];
                selectedButton.adjustsImageWhenHighlighted = NO;
                [selectedButton addTarget:self action:@selector(selectedButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
                selectedButton.frame = [self frameForSelectedButton:selectedButton atIndex:index];
                [_pagingScrollView addSubview:selectedButton];
                page.selectedButton = selectedButton;
                selectedButton.selected = [self photoIsSelectedAtIndex:index];
            }
            
		}
	}
	
}

- (void)updateVisiblePageStates {
    NSSet *copy = [_visiblePages copy];
    for (MWZoomingScrollView *page in copy) {
        
        // Update selection
        page.selectedButton.selected = [self photoIsSelectedAtIndex:page.index];
        
    }
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
	for (MWZoomingScrollView *page in _visiblePages)
		if (page.index == index) return YES;
	return NO;
}

- (MWZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index {
	MWZoomingScrollView *thePage = nil;
	for (MWZoomingScrollView *page in _visiblePages) {
		if (page.index == index) {
			thePage = page; break;
		}
	}
	return thePage;
}

- (MWZoomingScrollView *)pageDisplayingPhoto:(id<MWPhoto>)photo {
	MWZoomingScrollView *thePage = nil;
	for (MWZoomingScrollView *page in _visiblePages) {
		if (page.photo == photo) {
			thePage = page; break;
		}
	}
	return thePage;
}

- (void)configurePage:(MWZoomingScrollView *)page forIndex:(NSUInteger)index {
	page.frame = [self frameForPageAtIndex:index];
    page.index = index;
    page.photo = [self photoAtIndex:index];
}

- (MWZoomingScrollView *)dequeueRecycledPage {
	MWZoomingScrollView *page = [_recycledPages anyObject];
	if (page) {
		[_recycledPages removeObject:page];
	}
	return page;
}

// Handle page changes
- (void)didStartViewingPageAtIndex:(NSUInteger)index {
    
    // Handle 0 photos
    if (![self numberOfPhotos]) {
        // Show controls
        [self setControlsHidden:NO animated:YES permanent:YES];
        return;
    }
    
    // Handle video on page change
    if (!_rotating || index != _currentVideoIndex) {
        [self clearCurrentVideo];
    }
    
    // Release images further away than +/-1
    NSUInteger i;
    if (index > 0) {
        // Release anything < index - 1
        for (i = 0; i < index-1; i++) { 
            id photo = [_photos objectAtIndex:i];
            if (photo != [NSNull null]) {
                [photo unloadUnderlyingImage];
                [_photos replaceObjectAtIndex:i withObject:[NSNull null]];
                MWLog(@"Released underlying image at index %lu", (unsigned long)i);
            }
        }
    }
    if (index < [self numberOfPhotos] - 1) {
        // Release anything > index + 1
        for (i = index + 2; i < _photos.count; i++) {
            id photo = [_photos objectAtIndex:i];
            if (photo != [NSNull null]) {
                [photo unloadUnderlyingImage];
                [_photos replaceObjectAtIndex:i withObject:[NSNull null]];
                MWLog(@"Released underlying image at index %lu", (unsigned long)i);
            }
        }
    }
    
    // Load adjacent images if needed and the photo is already
    // loaded. Also called after photo has been loaded in background
    id <MWPhoto> currentPhoto = [self photoAtIndex:index];
    if ([currentPhoto underlyingImage]) {
        // photo loaded so load ajacent now
        [self loadAdjacentPhotosIfNecessary:currentPhoto];
    }
    
    // Notify delegate
    if (index != _previousPageIndex) {
        if ([_delegate respondsToSelector:@selector(photoBrowser:didDisplayPhotoAtIndex:)])
            [_delegate photoBrowser:self didDisplayPhotoAtIndex:index];
        _previousPageIndex = index;
    }
    
    // Update nav
    [self updateNavigation];
    
}

#pragma mark - Frame Calculations

- (CGRect)frameForPagingScrollView {
    CGRect frame = self.view.bounds;// [[UIScreen mainScreen] bounds];
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return CGRectIntegral(frame);
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    CGRect bounds = _pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return CGRectIntegral(pageFrame);
}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = _pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self numberOfPhotos], bounds.size.height);
}

- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index {
	CGFloat pageWidth = _pagingScrollView.bounds.size.width;
	CGFloat newOffset = index * pageWidth;
	return CGPointMake(newOffset, 0);
}

- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation {
    CGFloat height = 44;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
        UIInterfaceOrientationIsLandscape(orientation)) height = 32;
	return CGRectIntegral(CGRectMake(0, self.view.bounds.size.height - height, self.view.bounds.size.width, height));
}

- (CGRect)frameForCaptionView:(MWCaptionView *)captionView atIndex:(NSUInteger)index {
    CGRect pageFrame = [self frameForPageAtIndex:index];
    CGSize captionSize = [captionView sizeThatFits:CGSizeMake(pageFrame.size.width, 0)];
    CGRect captionFrame = CGRectMake(pageFrame.origin.x,
                                     pageFrame.size.height - captionSize.height - (_toolbar.superview?_toolbar.frame.size.height:0),
                                     pageFrame.size.width,
                                     captionSize.height);
    return CGRectIntegral(captionFrame);
}

- (CGRect)frameForSelectedButton:(UIButton *)selectedButton atIndex:(NSUInteger)index {
    CGRect pageFrame = [self frameForPageAtIndex:index];
    CGFloat padding = 20;
    CGFloat yOffset = 0;
    if (![self areControlsHidden]) {
        UINavigationBar *navBar = self.navigationController.navigationBar;
        yOffset = navBar.frame.origin.y + navBar.frame.size.height;
    }
    CGRect selectedButtonFrame = CGRectMake(pageFrame.origin.x + pageFrame.size.width - selectedButton.frame.size.width - padding,
                                            padding + yOffset,
                                            selectedButton.frame.size.width,
                                            selectedButton.frame.size.height);
    return CGRectIntegral(selectedButtonFrame);
}

- (CGRect)frameForPlayButton:(UIButton *)playButton atIndex:(NSUInteger)index {
    CGRect pageFrame = [self frameForPageAtIndex:index];
    return CGRectMake(floorf(CGRectGetMidX(pageFrame) - playButton.frame.size.width / 2),
                      floorf(CGRectGetMidY(pageFrame) - playButton.frame.size.height / 2),
                      playButton.frame.size.width,
                      playButton.frame.size.height);
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	
    // Checks
	if (!_viewIsActive || _performingLayout || _rotating) return;
	
	// Tile pages
	[self tilePages];
	
	// Calculate current page
	CGRect visibleBounds = _pagingScrollView.bounds;
	NSInteger index = (NSInteger)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
    if (index < 0) index = 0;
	if (index > [self numberOfPhotos] - 1) index = [self numberOfPhotos] - 1;
	NSUInteger previousCurrentPage = _currentPageIndex;
	_currentPageIndex = index;
	if (_currentPageIndex != previousCurrentPage) {
        [self didStartViewingPageAtIndex:index];
    }
	
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// Hide controls when dragging begins
	[self setControlsHidden:YES animated:YES permanent:NO];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	// Update nav when page changes
	[self updateNavigation];
}

#pragma mark - Navigation

- (void)updateNavigation {
    
	// Title
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    if (_gridController) {
        if (_gridController.selectionMode) {
            self.title = NSLocalizedString(@"Select Photos", nil);
        } else {
            NSString *photosText;
            if (numberOfPhotos == 1) {
                photosText = NSLocalizedString(@"item", @"Used in the context: '1 photo'");
            } else {
                photosText = NSLocalizedString(@"items", @"Used in the context: '3 photos'");
            }
            self.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)numberOfPhotos, photosText];
        }
    } else if (numberOfPhotos > 1) {
        if ([_delegate respondsToSelector:@selector(photoBrowser:titleForPhotoAtIndex:)]) {
            self.title = [_delegate photoBrowser:self titleForPhotoAtIndex:_currentPageIndex];
        } else {
            self.title = [NSString stringWithFormat:@"%lu %@ %lu", (unsigned long)(_currentPageIndex+1), NSLocalizedString(@"of", @"Used in the context: 'Showing 1 of 3 items'"), (unsigned long)numberOfPhotos];
        }
	} else {
		self.title = nil;
	}
	
	// Buttons
	_previousButton.enabled = (_currentPageIndex > 0);
	_nextButton.enabled = (_currentPageIndex < numberOfPhotos - 1);
    
    // Disable action button if there is no image or it's a video
    MWPhoto *photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage] == nil /*|| ([photo respondsToSelector:@selector(isVideo)] && photo.isVideo)*/) {
        _actionButton.enabled = NO;
        _deleteButton.enabled = NO;
        _actionButton.tintColor = [UIColor clearColor]; // Tint to hide button
    } else {
        _actionButton.enabled = YES;
        _deleteButton.enabled = YES;
        _actionButton.tintColor = nil;
    }
	
    if (self.enableGrid) {
        if (self.startOnGrid && _gridController) {
            _deleteButton.enabled = NO;
        } else if (!self.startOnGrid && !_gridController) {
            _deleteButton.enabled = YES;
        }
    }
}

- (void)jumpToPageAtIndex:(NSUInteger)index animated:(BOOL)animated {
	
	// Change page
	if (index < [self numberOfPhotos]) {
		CGRect pageFrame = [self frameForPageAtIndex:index];
        [_pagingScrollView setContentOffset:CGPointMake(pageFrame.origin.x - PADDING, 0) animated:animated];
        
        /*MWZoomingScrollView *page = [self dequeueRecycledPage];
        if (!page) {
            page = [[MWZoomingScrollView alloc] initWithPhotoBrowser:self];
        }
        [page displayPhoto:[self photoAtIndex:index]];*/
        
		[self updateNavigation];
	}
	
	// Update timer to give more time
	[self hideControlsAfterDelay];
	
}

- (void)gotoPreviousPage {
    [self showPreviousPhotoAnimated:NO];
    if (_popController) {
        [_popController dismissPopoverAnimated:YES];
    }
}
- (void)gotoNextPage {
    [self showNextPhotoAnimated:NO];
    if (_popController) {
        [_popController dismissPopoverAnimated:YES];
    }
}

- (void)showPreviousPhotoAnimated:(BOOL)animated {
    [self jumpToPageAtIndex:_currentPageIndex-1 animated:animated];
}

- (void)showNextPhotoAnimated:(BOOL)animated {
    [self jumpToPageAtIndex:_currentPageIndex+1 animated:animated];
}

#pragma mark - Interactions

- (void)selectedButtonTapped:(id)sender {
    UIButton *selectedButton = (UIButton *)sender;
    selectedButton.selected = !selectedButton.selected;
    NSUInteger index = NSUIntegerMax;
    for (MWZoomingScrollView *page in _visiblePages) {
        if (page.selectedButton == selectedButton) {
            index = page.index;
            break;
        }
    }
    if (index != NSUIntegerMax) {
        [self setPhotoSelected:selectedButton.selected atIndex:index];
    }
}

- (void)playButtonTapped:(id)sender {
    UIButton *playButton = (UIButton *)sender;
    NSUInteger index = NSUIntegerMax;
    for (MWZoomingScrollView *page in _visiblePages) {
        if (page.playButton == playButton) {
            index = page.index;
            break;
        }
    }
    if (index != NSUIntegerMax) {
        if (!_currentVideoPlayerViewController) {
            [self playVideoAtIndex:index];
        }
    }
}

#pragma mark - Video

- (void)playVideoAtIndex:(NSUInteger)index {
    id photo = [self photoAtIndex:index];
    
    UIImage *img = [self imageForPhoto:photo];
    CGImageRef  imageRef = [img CGImage];
    float imageWidth = CGImageGetWidth(imageRef);
    float imageHeight = CGImageGetHeight(imageRef);
    float scale = imageWidth/imageHeight;
    NSLog(@"imageW: %f, imageH: %f, scale: %f", imageWidth, imageHeight, scale);
    
    if ([photo respondsToSelector:@selector(getVideoURL:)]) {
        
        // Valid for playing
        _currentVideoIndex = index;
        [self clearCurrentVideo];
        [self setVideoLoadingIndicatorVisible:YES atPageIndex:index];
        
        // Get video and play
        [photo getVideoURL:^(NSURL *url) {
            if (url) {
                dispatch_async(dispatch_get_main_queue(), ^{
//                    if (scale == 1 || scale == 2) {
//                        [self popGLKView:self andVideoURL:url];
//                    } else {
//                        [self _playVideo:url atPhotoIndex:index];
//                    }
                    [self popGLKView:self andVideoURL:url];
                });
            } else {
                [self setVideoLoadingIndicatorVisible:NO atPageIndex:index];
            }
        }];
        
    }
}

- (void)_playVideo:(NSURL *)videoURL atPhotoIndex:(NSUInteger)index {

    // Setup player
    _currentVideoPlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:videoURL];
    [_currentVideoPlayerViewController.moviePlayer prepareToPlay];
    _currentVideoPlayerViewController.moviePlayer.shouldAutoplay = YES;
    _currentVideoPlayerViewController.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    _currentVideoPlayerViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    // Remove the movie player view controller from the "playback did finish" notification observers
    // Observe ourselves so we can get it to use the crossfade transition
    [[NSNotificationCenter defaultCenter] removeObserver:_currentVideoPlayerViewController
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:_currentVideoPlayerViewController.moviePlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoFinishedCallback:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:_currentVideoPlayerViewController.moviePlayer];

    // Show
    [self presentViewController:_currentVideoPlayerViewController animated:YES completion:nil];

}

- (void)videoFinishedCallback:(NSNotification*)notification {
    
    // Remove observer
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:_currentVideoPlayerViewController.moviePlayer];
    
    // Clear up
    [self clearCurrentVideo];
    
    // Dismiss
    BOOL error = [[[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue] == MPMovieFinishReasonPlaybackError;
    if (error) {
        // Error occured so dismiss with a delay incase error was immediate and we need to wait to dismiss the VC
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
}

- (void)clearCurrentVideo {
    if (!_currentVideoPlayerViewController) return;
    [_currentVideoLoadingIndicator removeFromSuperview];
    _currentVideoPlayerViewController = nil;
    _currentVideoLoadingIndicator = nil;
    _currentVideoIndex = NSUIntegerMax;
}

- (void)setVideoLoadingIndicatorVisible:(BOOL)visible atPageIndex:(NSUInteger)pageIndex {
    if (_currentVideoLoadingIndicator && !visible) {
        [_currentVideoLoadingIndicator removeFromSuperview];
        _currentVideoLoadingIndicator = nil;
    } else if (!_currentVideoLoadingIndicator && visible) {
        _currentVideoLoadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
        [_currentVideoLoadingIndicator sizeToFit];
        [_currentVideoLoadingIndicator startAnimating];
        [_pagingScrollView addSubview:_currentVideoLoadingIndicator];
        [self positionVideoLoadingIndicator];
    }
}

- (void)positionVideoLoadingIndicator {
    if (_currentVideoLoadingIndicator && _currentVideoIndex != NSUIntegerMax) {
        CGRect frame = [self frameForPageAtIndex:_currentVideoIndex];
        _currentVideoLoadingIndicator.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    }
}

#pragma mark - Grid

- (void)showGridAnimated {
    [self showGrid:YES];
    //[self panCamSDKDestroy];
    
    //pause GLKView
    self.paused = YES;
    [self.motionManager stopGyroUpdates];
}

- (void)showGrid:(BOOL)animated {

    if (_gridController) return;
    
    // Init grid controller
    _gridController = [[MWGridViewController alloc] init];
    _gridController.initialContentOffset = _currentGridContentOffset;
    _gridController.browser = self;
    _gridController.selectionMode = _displaySelectionButtons;
    _gridController.view.frame = self.view.bounds;
    _gridController.view.frame = CGRectOffset(_gridController.view.frame, 0, (self.startOnGrid ? -1 : 1) * self.view.bounds.size.height);

    // Stop specific layout being triggered
    _skipNextPagingScrollViewPositioning = YES;
    
    // Add as a child view controller
    [self addChildViewController:_gridController];
    [self.view addSubview:_gridController.view];
    
    // Perform any adjustments
    [_gridController.view layoutIfNeeded];
    [_gridController adjustOffsetsAsRequired];
    
    // Hide action button on nav bar if it exists
    if (self.navigationItem.rightBarButtonItem == _actionButton) {
        _gridPreviousRightNavItem = _actionButton;
        [self.navigationItem setRightBarButtonItem:nil animated:YES];
    } else {
        _gridPreviousRightNavItem = nil;
    }
    
    // Update
    [self updateNavigation];
    [self setControlsHidden:NO animated:YES permanent:YES];
    
    // Animate grid in and photo scroller out
    [_gridController willMoveToParentViewController:self];
    [UIView animateWithDuration:animated ? 0.3 : 0 animations:^(void) {
        _gridController.view.frame = self.view.bounds;
        CGRect newPagingFrame = [self frameForPagingScrollView];
        newPagingFrame = CGRectOffset(newPagingFrame, 0, (self.startOnGrid ? 1 : -1) * newPagingFrame.size.height);
        _pagingScrollView.frame = newPagingFrame;
    } completion:^(BOOL finished) {
        [_gridController didMoveToParentViewController:self];
    }];
    
}

- (void)hideGrid {
    
    if (!_gridController) return;
    
    // Remember previous content offset
    _currentGridContentOffset = _gridController.collectionView.contentOffset;
    
    // Restore action button if it was removed
    if (_gridPreviousRightNavItem == _actionButton && _actionButton) {
        [self.navigationItem setRightBarButtonItem:_gridPreviousRightNavItem animated:YES];
    }
    
    // Position prior to hide animation
    CGRect newPagingFrame = [self frameForPagingScrollView];
    newPagingFrame = CGRectOffset(newPagingFrame, 0, (self.startOnGrid ? 1 : -1) * newPagingFrame.size.height);
    _pagingScrollView.frame = newPagingFrame;
    
    // Remember and remove controller now so things can detect a nil grid controller
    MWGridViewController *tmpGridController = _gridController;
    _gridController = nil;
    
    // Update
    [self updateNavigation];
    [self updateVisiblePageStates];
    
    // Animate, hide grid and show paging scroll view
    [UIView animateWithDuration:0.3 animations:^{
        tmpGridController.view.frame = CGRectOffset(self.view.bounds, 0, (self.startOnGrid ? -1 : 1) * self.view.bounds.size.height);
        _pagingScrollView.frame = [self frameForPagingScrollView];
    } completion:^(BOOL finished) {
        [tmpGridController willMoveToParentViewController:nil];
        [tmpGridController.view removeFromSuperview];
        [tmpGridController removeFromParentViewController];
        [self setControlsHidden:NO animated:YES permanent:NO]; // retrigger timer
    }];

}

#pragma mark - Control Hiding / Showing

// If permanent then we don't set timers to hide again
// Fades all controls on iOS 5 & 6, and iOS 7 controls slide and fade
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {
    
    // Force visible
    if (![self numberOfPhotos] || _gridController || _alwaysShowControls)
        hidden = NO;
    
    // Cancel any timers
    [self cancelControlHiding];
    
    // Animations & positions
    CGFloat animatonOffset = 20;
    CGFloat animationDuration = (animated ? 0.35 : 0);
    
    // Status bar
    if (!_leaveStatusBarAlone) {

        // Hide status bar
        if (!_isVCBasedStatusBarAppearance) {
            
            // Non-view controller based
            [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone];
            
        } else {
            
            // View controller based so animate away
            _statusBarShouldBeHidden = hidden;
            [UIView animateWithDuration:animationDuration animations:^(void) {
                [self setNeedsStatusBarAppearanceUpdate];
            } completion:^(BOOL finished) {}];
            
        }

    }
    
    // Toolbar, nav bar and captions
    // Pre-appear animation positions for sliding
    if ([self areControlsHidden] && !hidden && animated) {
        
        // Toolbar
        _toolbar.frame = CGRectOffset([self frameForToolbarAtOrientation:self.interfaceOrientation], 0, animatonOffset);
        
        // Captions
        for (MWZoomingScrollView *page in _visiblePages) {
            if (page.captionView) {
                MWCaptionView *v = page.captionView;
                // Pass any index, all we're interested in is the Y
                CGRect captionFrame = [self frameForCaptionView:v atIndex:0];
                captionFrame.origin.x = v.frame.origin.x; // Reset X
                v.frame = CGRectOffset(captionFrame, 0, animatonOffset);
            }
        }
        
    }
    [UIView animateWithDuration:animationDuration animations:^(void) {
        
        CGFloat alpha = hidden ? 0 : 1;

        // Nav bar slides up on it's own on iOS 7+
        [self.navigationController.navigationBar setAlpha:alpha];
        
        // Toolbar
        _toolbar.frame = [self frameForToolbarAtOrientation:self.interfaceOrientation];
        if (hidden) _toolbar.frame = CGRectOffset(_toolbar.frame, 0, animatonOffset);
        _toolbar.alpha = alpha;

        // Captions
        for (MWZoomingScrollView *page in _visiblePages) {
            if (page.captionView) {
                MWCaptionView *v = page.captionView;
                // Pass any index, all we're interested in is the Y
                CGRect captionFrame = [self frameForCaptionView:v atIndex:0];
                captionFrame.origin.x = v.frame.origin.x; // Reset X
                if (hidden) captionFrame = CGRectOffset(captionFrame, 0, animatonOffset);
                v.frame = captionFrame;
                v.alpha = alpha;
            }
        }
        
        // Selected buttons
        for (MWZoomingScrollView *page in _visiblePages) {
            if (page.selectedButton) {
                UIButton *v = page.selectedButton;
                CGRect newFrame = [self frameForSelectedButton:v atIndex:0];
                newFrame.origin.x = v.frame.origin.x;
                v.frame = newFrame;
            }
        }

    } completion:^(BOOL finished) {}];
    
	// Control hiding timer
	// Will cancel existing timer but only begin hiding if
	// they are visible
	if (!permanent) [self hideControlsAfterDelay];
	
}

- (BOOL)prefersStatusBarHidden {
    if (!_leaveStatusBarAlone) {
        return _statusBarShouldBeHidden;
    } else {
        return [self presentingViewControllerPrefersStatusBarHidden];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    return UIStatusBarAnimationSlide;
}

- (void)cancelControlHiding {
	// If a timer exists then cancel and release
	if (_controlVisibilityTimer) {
		[_controlVisibilityTimer invalidate];
		_controlVisibilityTimer = nil;
	}
}

// Enable/disable control visiblity timer
- (void)hideControlsAfterDelay {
	if (![self areControlsHidden]) {
        [self cancelControlHiding];
		_controlVisibilityTimer = [NSTimer scheduledTimerWithTimeInterval:self.delayToHideElements target:self selector:@selector(hideControls) userInfo:nil repeats:NO];
	}
}

- (BOOL)areControlsHidden { return (_toolbar.alpha == 0); }
- (void)hideControls {
    [self setControlsHidden:YES animated:YES permanent:NO];
    if (_popController) {
        [_popController dismissPopoverAnimated:YES];
    }
    if (_actionsSheet) {
#if USE_SYSTEM_IOS7_IMPLEMENTATION
        [_actionsSheet dismissWithClickedButtonIndex:_actionsSheet.cancelButtonIndex animated:YES];
#else
        [_actionsSheet dismissViewControllerAnimated:NO completion:nil];
#endif
    }
}
- (void)toggleControls { [self setControlsHidden:![self areControlsHidden] animated:YES permanent:NO]; }

#pragma mark - Properties

- (void)setCurrentPhotoIndex:(NSUInteger)index {
    // Validate
    NSLog(@"set current index to %lu", (unsigned long)index);
    NSUInteger photoCount = [self numberOfPhotos];
    if (photoCount == 0) {
        index = 0;
    } else {
        if (index >= photoCount)
            index = [self numberOfPhotos]-1;
    }
    _currentPageIndex = index;
	if ([self isViewLoaded]) {
        [self jumpToPageAtIndex:index animated:NO];
        //[self popGLKView:self];

        if (!_viewIsActive)
             [self tilePages]; // Force tiling if view is not visible
            //[self popGLKView:self];
    }
}

#pragma mark - Misc

- (void)doneButtonPressed:(id)sender {
    // Only if we're modal and there's a done button
    if (_doneButton) {
        //pause GLKView
        self.paused = YES;
        [self.motionManager stopGyroUpdates];

        // See if we actually just want to show/hide grid
        if (self.enableGrid) {
            if (self.startOnGrid && !_gridController) {
                [self showGrid:YES];
                //[self panCamSDKDestroy];
                return;
            } else if (!self.startOnGrid && _gridController) {
                [self hideGrid];
                return;
            }
        }
        
        // Dismiss view controller
        if ([_delegate respondsToSelector:@selector(photoBrowserDidFinishModalPresentation:)]) {
            // Call delegate method and let them dismiss us
            [_delegate photoBrowserDidFinishModalPresentation:self];
        } else  {
            [self dismissViewControllerAnimated:YES completion:^{
                /*[self panCamSDKDestroy];
                
                if ([EAGLContext currentContext] == self.context) {
                    [EAGLContext setCurrentContext:nil];
                }*/
            }];
        }
    }
}

#pragma mark - Actions

- (void)actionButtonPressed:(id)sender {
    if (_popController) {
        [_popController dismissPopoverAnimated:YES];
    }
    if (_actionsSheet) {
#if USE_SYSTEM_IOS7_IMPLEMENTATION
        [_actionsSheet dismissWithClickedButtonIndex:_actionsSheet.cancelButtonIndex animated:YES];
#else
        [_actionsSheet dismissViewControllerAnimated:YES completion:nil];
#endif
    } else {
        
        // Only react when image has loaded
        id <MWPhoto> photo = [self photoAtIndex:_currentPageIndex];
        if ([self numberOfPhotos] > 0 && [photo underlyingImage]) {
            
            // If they have defined a delegate method then just message them
            if ([self.delegate respondsToSelector:@selector(photoBrowser:actionButtonPressedForPhotoAtIndex:)]) {
                
                // Let delegate handle things
                [self.delegate photoBrowser:self actionButtonPressedForPhotoAtIndex:_currentPageIndex];
                [self showProgressHUDWithMessage:@"请稍候 ..."];
//                [self showDownloadConfirm];
                dispatch_queue_t shareQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.Share", 0);
                dispatch_async(shareQueue, ^{
                    if ([self.delegate respondsToSelector:@selector(shareImage:)]) {
                        [self.delegate shareImage:self];
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self hideProgressHUD:YES];
                        [self showShareConfirm];
                    });
                });
            } else {
                
                // Show activity view controller
                NSMutableArray *items = nil;
                if (photo.isVideo) {
                    items = [NSMutableArray arrayWithObject:photo.videoURL];
                } else {
                    items = [NSMutableArray arrayWithObject:[photo underlyingImage]];
                }
                if (photo.caption) {
                    [items addObject:photo.caption];
                }
                self.activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
                // Show loading spinner after a couple of seconds
                double delayInSeconds = 0.5; // change 2.0s to 0.5s, To showProgressHUDCompleteMessage after saved
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    if (self.activityViewController) {
                        [self showProgressHUDWithMessage:nil];
                    }
                });
                
                // Show
                typeof(self) __weak weakSelf = self;
                [self.activityViewController setCompletionHandler:^(NSString *activityType, BOOL completed) {
                    weakSelf.activityViewController = nil;
                    [weakSelf hideControlsAfterDelay];
                    [weakSelf hideProgressHUD:YES];
                }];
                // iOS 8 - Set the Anchor Point for the popover
                if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8")) {
                    self.activityViewController.popoverPresentationController.barButtonItem = _actionButton;
                }
                [self presentViewController:self.activityViewController animated:YES completion:nil];
                
            }
            
            
            
            // Keep controls hidden
            [self setControlsHidden:NO animated:YES permanent:YES];
            
        }
    }
}

#if USE_SYSTEM_IOS7_IMPLEMENTATION
#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == ACTION_SHEET_OLD_ACTIONS) {
        // Old Actions
        _actionsSheet = nil;
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            if (buttonIndex == actionSheet.firstOtherButtonIndex) {
                [self savePhoto]; return;
            } else if (buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
                [self copyPhoto]; return;
            } else if (buttonIndex == actionSheet.firstOtherButtonIndex + 2) {
                [self emailPhoto]; return;
            }
        }
    } else if (actionSheet.tag == ACTION_SHEET_DELETE_ACTIONS) {
        _actionsSheet = nil;
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            [self deleteDetail]; return;
        }
    }
    [self hideControlsAfterDelay]; // Continue as normal...
}
#else
#endif

#pragma mark - Action Progress

- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        _progressHUD.minSize = CGSizeMake(60, 60);
        _progressHUD.minShowTime = 1;
        // The sample image is based on theœ
        // work by: http://www.pixelpressicons.com
        // licence: http://creativecommons.org/licenses/by/2.5/ca/
        self.progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]];
        [self.view addSubview:_progressHUD];
    }
    return _progressHUD;
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.labelText = message;
    self.progressHUD.dimBackground = YES;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
}

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hide:animated];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    if (message) {
        if (self.progressHUD.isHidden) [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hide:YES afterDelay:1.5];
    } else {
        [self.progressHUD hide:YES];
    }
    self.navigationController.navigationBar.userInteractionEnabled = YES;
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
}

#pragma mark - Actions

- (void)savePhoto {
    id <MWPhoto> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"DownloadingTitle", @"Displayed with ellipsis as 'Saving...' when an item is in the process of being saved")]];
        [self performSelector:@selector(actuallySavePhoto:) withObject:photo afterDelay:0];
    }
}

- (void)actuallySavePhoto:(id<MWPhoto>)photo {
    if ([photo underlyingImage]) {
        UIImageWriteToSavedPhotosAlbum([photo underlyingImage], self,
                                       @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error
  contextInfo:(void *)contextInfo {
    [self showProgressHUDCompleteMessage: error ? NSLocalizedString(@"Failed", @"Informing the user a process has failed") : NSLocalizedString(@"SavePhotoToAlbum", @"Informing the user an item has been saved")];
    [self hideControlsAfterDelay]; // Continue as normal...
}

- (void)deletePhoto:(id)sender {
    id <MWPhoto> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            if (_popController.popoverVisible) {return;}
            UIViewController *vc = [[UIViewController alloc] init];
            UIButton *testButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0f, 5.0f, 260.0f, 47.0f)];
            [testButton setTitle:NSLocalizedString(@"SureDelete", @"") forState:UIControlStateNormal];
            [testButton setBackgroundImage:[[UIImage imageNamed:@"iphone_delete_button.png"] stretchableImageWithLeftCapWidth:8.0f topCapHeight:0.0f] forState:UIControlStateNormal];
            [testButton addTarget:self action:@selector(deleteDetail) forControlEvents:UIControlEventTouchUpInside];
            [vc.view addSubview:testButton];
            
            UIPopoverController *popController = [[UIPopoverController alloc] initWithContentViewController:vc];
            popController.popoverContentSize = CGSizeMake(270.0f, 67.0f);
            _popController = popController;
            [_popController presentPopoverFromBarButtonItem:_deleteButton
                                   permittedArrowDirections:UIPopoverArrowDirectionAny
                                                   animated:YES];
        } else {
#if USE_SYSTEM_IOS7_IMPLEMENTATION
            _actionsSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:NSLocalizedString(@"SureDelete", @"") otherButtonTitles:nil, nil];
            _actionsSheet.tag = ACTION_SHEET_DELETE_ACTIONS;
            [_actionsSheet showFromBarButtonItem:sender animated:YES];
#else
            _actionsSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            [_actionsSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")  style:UIAlertActionStyleCancel handler:nil]];
            [_actionsSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"SureDelete", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self deleteDetail];
            }]];
            
            [self presentViewController:_actionsSheet animated:YES completion:nil];
#endif
        }
        
    }
}

- (IBAction)deleteDetail
{
    id <MWPhoto> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [_popController dismissPopoverAnimated:YES];
        // Buttons
        _previousButton.enabled = NO;
        _nextButton.enabled = NO;
        _actionButton.enabled = NO;
        _deleteButton.enabled = NO;
        [self setControlsHidden:NO animated:YES permanent:YES];
        
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"Deleting", @"Displayed with ellipsis as 'Deleting...' when an item is in the process of being copied")]];
        //[self performSelector:@selector(actuallyDeletePhoto:) withObject:photo afterDelay:0];
        [self performSelectorInBackground:@selector(actuallyDeletePhoto:) withObject:photo];
    }
    
}

-(void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    _popController = nil;
}

- (void)actuallyDeletePhoto:(id<MWPhoto>)photo {
    if ([photo underlyingImage]) {
        if([_delegate respondsToSelector:@selector(photoBrowser:deletePhotoAtIndex:)]) {
            if (![self.delegate photoBrowser:self deletePhotoAtIndex:_currentPageIndex]) {
                [self performSelectorOnMainThread:@selector(deleteFailed) withObject:nil waitUntilDone:NO];
            } else {
                [self performSelectorOnMainThread:@selector(deleteSucceed) withObject:nil waitUntilDone:NO];
            }
        }
        
    }
}

- (void)deleteSucceed
{
    if (_photoCount > 1) {
        [self reloadData];
        [self showProgressHUDCompleteMessage:NSLocalizedString(@"Deleted", @"Informing the user an item has finished deleting")];
    } else {
        [self hideProgressHUD:NO];
        [self.navigationController popToRootViewControllerAnimated:YES];
        if ([self.navigationController.viewControllers objectAtIndex:0] == self) {
            [self doneButtonPressed:nil];
            [_gridController.collectionView reloadData];
            _photoCount = 0;
            _deleteButton.enabled = NO;
        }
    }
}

- (void)deleteFailed
{
    [self showProgressHUDNotice:NSLocalizedString(@"DeleteError", nil) showTime:2.0];
}


- (void)copyPhoto {
    id <MWPhoto> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"Copying", @"Displayed with ellipsis as 'Copying...' when an item is in the process of being copied")]];
        [self performSelector:@selector(actuallyCopyPhoto:) withObject:photo afterDelay:0];
    }
}

- (void)actuallyCopyPhoto:(id<MWPhoto>)photo {
    if ([photo underlyingImage]) {
        [[UIPasteboard generalPasteboard] setData:UIImagePNGRepresentation([photo underlyingImage])
                                forPasteboardType:@"public.png"];
        [self showProgressHUDCompleteMessage:NSLocalizedString(@"Copied", @"Informing the user an item has finished copying")];
        [self hideControlsAfterDelay]; // Continue as normal...
    }
}

- (void)emailPhoto {
    id <MWPhoto> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"Preparing", @"Displayed with ellipsis as 'Preparing...' when an item is in the process of being prepared")]];
        [self performSelector:@selector(actuallyEmailPhoto:) withObject:photo afterDelay:0];
    }
}

- (void)actuallyEmailPhoto:(id<MWPhoto>)photo {
    if ([photo underlyingImage]) {
        MFMailComposeViewController *emailer = [[MFMailComposeViewController alloc] init];
        emailer.mailComposeDelegate = self;
        [emailer setSubject:NSLocalizedString(@"Photo", nil)];
        //[emailer addAttachmentData:UIImagePNGRepresentation([photo underlyingImage]) mimeType:@"png" fileName:@"Photo.png"];
        [emailer addAttachmentData:UIImageJPEGRepresentation([photo underlyingImage], 0.0) mimeType:@"jpg" fileName:@"Photo.jpg"];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            emailer.modalPresentationStyle = UIModalPresentationPageSheet;
        }
        //[self presentModalViewController:emailer animated:YES];
        [self hideProgressHUD:NO];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    if (result == MFMailComposeResultFailed) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Email", nil)
                                                        message:NSLocalizedString(@"Email failed to send. Please try again.", nil)
                                                       delegate:nil cancelButtonTitle:NSLocalizedString(@"Dismiss", nil) otherButtonTitles:nil];
        [alert show];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Listener Callback
-(NSString *)notifyConnectionBroken {
    [self recoverFromDisconnection];
    return nil;
}

-(void)showDownloadConfirm {
    if ([self.delegate respondsToSelector:@selector(photoBrowser:downloadPhotoAtIndex:)]) {
        
        // Let delegate handle things
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"DownloadingTitle", @"Displayed with ellipsis as 'Saving...' when an item is in the process of being saved")]];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BOOL retVal = [self.delegate photoBrowser:self downloadPhotoAtIndex:_currentPageIndex];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgressHUDCompleteMessage: retVal ? NSLocalizedString(@"SavePhotoToAlbum", @"Informing the user a process has failed") : NSLocalizedString(@"Failed", @"Informing the user an item has been saved")];
            });
        });
        
    } else {
        [self savePhoto];
    }
}

-(void)showSLComposeViewController:(NSString *)serviceType {
    if ([self.delegate respondsToSelector:@selector(photoBrowser:sharePhotoAtIndex:serviceType:)]) {
        [self.delegate photoBrowser:self sharePhotoAtIndex:_currentPageIndex serviceType:serviceType];
    }
}

- (void)showShareConfirm
{
    if ([self.delegate respondsToSelector:@selector(photoBrowser:shareImageAtIndex:)]) {
        [self.delegate photoBrowser:self shareImageAtIndex:_currentPageIndex];
    }
}

#pragma mark -------- GLKView delegate --------
- (void)panCamSDKinit
{
    if ([self.delegate respondsToSelector:@selector(panCamSDKinit)]) {
        [self.delegate panCamSDKinit];
    }
}

- (void)createICatchImage:(UIImage *)image
{
    if ([self.delegate respondsToSelector:@selector(createICatchImage:)]) {
        [self.delegate createICatchImage:image];
    }
}

- (void)configureView:(int)width andHeight:(int)height
{
    if ([self.delegate respondsToSelector:@selector(configureGLKView:andHeight:)]) {
        [self.delegate configureGLKView:width andHeight:height];
    }
}

- (void)rotate:(CGPoint)pointC andPointPre:(CGPoint)pointPre
{
    if ([self.delegate respondsToSelector:@selector(rotate:andPointPre:)]) {
        [self.delegate rotate:pointC andPointPre:pointPre];
    }
}

- (void)rotate:(int)orientation andX:(float)x andY:(float)y andZ:(float)z andTimestamp:(long)timestamp
{
    if ([self.delegate respondsToSelector:@selector(rotate:andX:andY:andZ:andTimestamp:)]) {
        [self.delegate rotate:orientation andX:x andY:y andZ:z andTimestamp:timestamp];
    }
}

- (void)locate:(float)distance
{
    if ([self.delegate respondsToSelector:@selector(locate:)]) {
        [self.delegate locate:distance];
    }
}

- (void)panCamSDKDestroy
{
    if ([self.delegate respondsToSelector:@selector(panCamSDKDestroy)]) {
        [self.delegate panCamSDKDestroy];
    }
}

- (void)popGLKView:(MWPhotoBrowser *)browser andVideoURL:(NSURL *)videoURL {
    if ([self.delegate respondsToSelector:@selector(popGLKViewByphotoBrowser:andVideoURL:)]) {
        [self.delegate popGLKViewByphotoBrowser:browser andVideoURL:videoURL];
    }
}

- (UIImage *)getNextPhoto {
    int index = (int)_currentPhotoIndex + 1;
    int total = (int)[self numberOfPhotos];
    NSLog(@"index: %d, total: %d", index, total);
    
    if (index < total) {
        id <MWPhoto> photo = [self photoAtIndex: index];
        _currentPhotoIndex = index;
        return [self imageForPhoto:photo];
    } else return nil;
}

- (UIImage *)getPreviousPhoto {
    int index = (int)_currentPhotoIndex - 1;
    int total = (int)[self numberOfPhotos];
    NSLog(@"index: %d, total: %d", index, total);
    
    if (index >= 0) {
        id <MWPhoto> photo = [self photoAtIndex: index];
        _currentPhotoIndex = index;
        return [self imageForPhoto:photo];
    } else return nil;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self stopGLKAnimation];
    [self.motionManager stopGyroUpdates];
    [EAGLContext setCurrentContext:self.context];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([self.delegate respondsToSelector:@selector(destroyDataForEnterBackground)]) {
            [self.delegate destroyDataForEnterBackground];
        }
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
    });
}

#pragma mark PanoramaType
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
        [self showProgressHUDWithMessage:nil];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#if 0
            self.paused = YES;
            [self.motionManager stopGyroUpdates];
            [self panCamSDKDestroy];
        
            _tbPanoramaTypeArray.lastIndex = indexPath.row;
        
            int panoramaType = 0;
            switch (_tbPanoramaTypeArray.lastIndex) {
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
        
            [self panCamSDKinitWithPanoramaType:panoramaType];
        
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [self updatePanoramaTyprOnScreen];
                
//                [self tilePages];
                for (MWZoomingScrollView *page in _visiblePages) {
                    if (page.index == _currentPageIndex) {
                        [self configurePage:page forIndex:page.index];
                    }
                }
            });
#endif
            self.paused = YES;
            [self.motionManager stopGyroUpdates];
            
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
            
            BOOL isSuccess = YES;
            if ([self.delegate respondsToSelector:@selector(changePanoramaType:)]) {
                isSuccess = [self.delegate changePanoramaType:panoramaType];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                for (MWZoomingScrollView *page in _visiblePages) {
                    if (page.index == _currentPageIndex) {
                        [self configurePage:page forIndex:page.index];
                    }
                }
                
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
    
    self.panoramaTypeButton.title = panoramaTypeArray[_tbPanoramaTypeArray.lastIndex];
    
    _inButton.enabled = _outButton.enabled = _tbPanoramaTypeArray.lastIndex ? NO : YES;
}

@end
