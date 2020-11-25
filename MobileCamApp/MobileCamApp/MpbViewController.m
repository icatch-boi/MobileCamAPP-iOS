//
//  CollectionViewController.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-5.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import "MpbViewControllerPrivate.h"
#import "MpbViewController.h"
#include "UtilsMacro.h"
#import "MpbCollectionViewCell.h"
#import "MpbCollectionHeaderView.h"
#import "MpbPopoverViewController.h"
#import "MBProgressHUD.h"
#import "VideoPlaybackViewController.h"
#import "WifiCamControl.h"

#import "UIActivityItemImage.h"
#import "UIActivityItemVideo.h"

#import "UIActivityDownload.h"
#import "UIActivityFacebook.h"
#import "UIActivityTwitter.h"
#import "UIActivityWeibo.h"
#import "UIActivityTencentWeibo.h"

#import "UIActivityShare.h"

#import "PanCamSDK.h"
#import "DiskSpaceTool.h"

static NSString *kCellID = @"cellID";

@implementation MpbViewController
@synthesize observerNo;
#pragma mark - Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    observerNo=0;
    WifiCamManager *app = [WifiCamManager instance];
    self.wifiCam = [app.wifiCams objectAtIndex:0];
    self.ctrl = _wifiCam.controler;
    self.staticData = [WifiCamStaticData instance];

    [self initPhotoGallery];
}

- (void)initPhotoGallery
{
    AppLog(@"%s", __func__);
    self.navigationItem.leftBarButtonItem = self.doneButton;
    self.title = NSLocalizedString(@"Albums", @"");
    self.editButton.title = NSLocalizedString(@"Edit", @"");
    self.doneButton.title = NSLocalizedString(@"Done", @"");
    self.mpbSemaphore = dispatch_semaphore_create(1);
    self.thumbnailQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.Thumbnail", 0);
    self.downloadQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.Download", 0);
    self.downloadPercentQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.DownloadPercent", 0);
    self.collDataArray = [[NSMutableDictionary alloc] init];
    //self.browser = [_ctrl.fileCtrl createOneMWPhotoBrowserWithDelegate:self];
    self.selItemsTable = [_ctrl.fileCtrl createOneCellsTable];
    self.mpbCache = [_ctrl.fileCtrl createCacheForMultiPlaybackWithCountLimit:100
                                                               totalCostLimit:4096];
    self.enableHeader = YES;
    self.loaded = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    AppLog(@"%s", __func__);
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO];
//    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recoverFromDisconnection)
                                             name    :@"kCameraNetworkConnectedNotification"
                                             object  :nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(destroySDKNotification)
                                             name    :@"kCameraDestroySDKNotification"
                                             object  :nil];
    self.run = YES;
    
    if (_curMpbState == MpbStateNor) {
        [_selItemsTable.selectedCells removeAllObjects];
    }
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.delegate = self;
}

-(void)destroySDKNotification
{
    AppLog(@"receive destroySDKNotification.");
    self.run = NO;
}

-(void)viewDidAppear:(BOOL)animated
{
    AppLog(@"%s", __func__);
    [super viewDidAppear:animated];
    if (!_loaded || _wifiCam.gallery.needReload) {
        [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)
                          detailsMessage:nil
                                    mode:MBProgressHUDModeIndeterminate];
        
        // Get list and udpate collection-view
        dispatch_async(_thumbnailQueue, ^{
            [self resetCollectionViewData];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                self.loaded = YES;
                self.wifiCam.gallery.needReload = NO;
                
                if (_totalCount > 0) {
                    _editButton.enabled = YES;
                    _actionButton.enabled = YES;
                } else {
                    _editButton.enabled = NO;
                    _actionButton.enabled = NO;
                    self.browser = nil;
                }
                
                [self.collectionView reloadData];
            });
        });
    } else {
        if (_totalCount > 0) {
            _editButton.enabled = YES;
            _actionButton.enabled = YES;
        } else {
            _editButton.enabled = NO;
            _actionButton.enabled = NO;
        }
        
        [self.collectionView reloadData];
    }
}

- (void)resetCollectionViewData
{
    AppLog(@"%s listFiles start ...",__func__);
    _wifiCam.gallery = [WifiCamControl createOnePhotoGallery];
    self.gallery = _wifiCam.gallery;
    
    NSUInteger photoListSize = _gallery.imageTable.fileList.size();
    NSUInteger videoListSize = _gallery.videoTable.fileList.size();
    unsigned long long totalPhotoKBytes = _gallery.imageTable.fileStorage;
    unsigned long long totalVideoKBytes = _gallery.videoTable.fileStorage;
    unsigned long long totalAllKBytes = totalPhotoKBytes + totalVideoKBytes;
    
    AppLog(@"photoListSize: %lu", (unsigned long)photoListSize);
    AppLog(@"videoListSize: %lu", (unsigned long)videoListSize);
    AppLog(@"totalPhotoKBytes : %llu", totalPhotoKBytes);
    AppLog(@"totalVideoKBytes : %llu", totalVideoKBytes);
    AppLog(@"totalAllKBytes : %llu", totalAllKBytes);
    AppLog(@"listFiles end ...");
    
    // Clean-up
    [_collDataArray removeAllObjects];
    
    if (_enableHeader) {
        
        SEL photoSinglePlaybackFunction = @selector(photoSinglePlaybackCallback:);
        NSDictionary *photoDict = @{@(SectionTitle): NSLocalizedString(@"Photos",nil),
                                    @(SectionType):@(WCFileTypeImage),
                                    @(SectionDataTable):_gallery.imageTable,
                                    @(SectionTotalFileKBytes):@(totalPhotoKBytes),
                                    @(SectionPlaybackCallback):NSStringFromSelector(photoSinglePlaybackFunction)};
        [_collDataArray setObject:photoDict forKey:@(SectionIndexPhoto)];
        
        SEL videoSinglePlaybackFunction = @selector(videoSinglePlaybackCallback:);
        NSDictionary *videoDict = @{@(SectionTitle): NSLocalizedString(@"Videos",nil),
                                    @(SectionType):@(WCFileTypeVideo),
                                    @(SectionDataTable):_gallery.videoTable,
                                    @(SectionTotalFileKBytes):@(totalVideoKBytes),
                                    @(SectionPlaybackCallback):NSStringFromSelector(videoSinglePlaybackFunction)};
        [_collDataArray setObject:videoDict forKey:@(SectionIndexVideo)];
    } else {
        SEL allPlaybackFunction = @selector(allPlaybackCallback:);
        NSDictionary *photoDict = @{@(SectionTitle): NSLocalizedString(@"Photos",nil),
                                    @(SectionType):@(WCFileTypeAll),
                                    @(SectionDataTable):_gallery.allFileTable,
                                    @(SectionTotalFileKBytes):@(totalAllKBytes),
                                    @(SectionPlaybackCallback):NSStringFromSelector(allPlaybackFunction)};
        [_collDataArray setObject:photoDict forKey:@(0)];
    }
    
    self.totalCount = photoListSize + videoListSize;
}

- (void)viewWillDisappear:(BOOL)animated
{
    AppLog(@"%s", __func__);
    [super viewWillDisappear:animated];
//    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.run = NO;
    
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
#if USE_SYSTEM_IOS7_IMPLEMENTATION
    if (_actionSheet.visible) {
        [_actionSheet dismissWithClickedButtonIndex:0 animated:NO];
    }
#else
    [_actionSheet dismissViewControllerAnimated:NO completion:nil];
#endif
    
    if (_selItemsTable.count > 0 || observerNo > 0 ) {
        [self.selItemsTable removeObserver:self forKeyPath:@"count"];
        --observerNo;
    }
}
-(void)viewDidDisappear:(BOOL)animated
{
    AppLog(@"%s", __func__);
    [super viewDidDisappear:animated];
    
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:@"kCameraNetworkConnectedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    AppLog(@"%s", __func__);
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [_mpbCache removeAllObjects];
}

-(void)dealloc
{
    AppLog(@"%s", __func__);
    [_mpbCache removeAllObjects];
    self.doneButton = nil;
    self.browser = nil;
}

-(BOOL)prefersStatusBarHidden {
    return NO;
}

-(void)recoverFromDisconnection
{
    AppLog(@"%s", __func__);
    WifiCamManager *app = [WifiCamManager instance];
    self.wifiCam = [app.wifiCams objectAtIndex:0];
    self.ctrl = _wifiCam.controler;
    self.staticData = [WifiCamStaticData instance];
    
    [self.collectionView reloadData];
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        _progressHUD.minSize = CGSizeMake(120, 120);
        _progressHUD.minShowTime = 1;
        // The sample image is based on the
        // work by: http://www.pixelpressicons.com
        // licence: http://creativecommons.org/licenses/by/2.5/ca/
        self.progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]];
        [self.view addSubview:_progressHUD];
    }
    return _progressHUD;
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
}

- (void)showProgressHUDNotice:(NSString *)message
                     showTime:(NSTimeInterval)time{
    AppLog(@"%s", __func__);
    self.navigationController.toolbar.userInteractionEnabled = NO;
    if (message) {
        [self.view bringSubviewToFront:self.progressHUD];
        [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.mode = MBProgressHUDModeText;
        self.progressHUD.dimBackground = YES;
        [self.progressHUD hide:YES afterDelay:time];
    } else {
        [self.progressHUD hide:YES];
    }
    //self.navigationController.navigationBar.userInteractionEnabled = NO;
    self.navigationController.toolbar.userInteractionEnabled = YES;
    
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    AppLog(@"%s", __func__);
    if (message) {
        if (self.progressHUD.isHidden) [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.detailsLabelText = nil;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hide:YES afterDelay:1.0];
    } else {
        [self.progressHUD hide:YES];
    }
    //self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.navigationController.toolbar.userInteractionEnabled = YES;
}

- (void)showProgressHUDWithMessage:(NSString *)message
                    detailsMessage:(NSString *)dMessage
                              mode:(MBProgressHUDMode)mode {
    AppLog(@"%s", __func__);
    self.progressHUD.labelText = message;
    self.progressHUD.detailsLabelText = dMessage;
    self.progressHUD.mode = mode;
    self.progressHUD.dimBackground = YES;
    [self.view bringSubviewToFront:self.progressHUD];
    [self.progressHUD show:YES];
    //self.navigationController.navigationBar.userInteractionEnabled = NO;
    self.navigationController.toolbar.userInteractionEnabled = NO;
    
}

- (void)updateProgressHUDWithMessage:(NSString *)message
                      detailsMessage:(NSString *)dMessage {
    AppLog(@"%s", __func__);
    if (message) {
        self.progressHUD.labelText = message;
    }
    if (dMessage) {
        self.progressHUD.progress = _downloadedPercent / 100.0;
        self.progressHUD.detailsLabelText = dMessage;
    }
}

- (void)hideProgressHUD:(BOOL)animated {
    AppLog(@"%s", __func__);
    [self.progressHUD hide:animated];
    //self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.navigationController.toolbar.userInteractionEnabled = YES;
    
}

#pragma mark - MPB
- (IBAction)goHome:(id)sender
{
    AppLog(@"%s", __func__);
    self.run = NO;
    [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)
                      detailsMessage:nil
                                mode:MBProgressHUDModeIndeterminate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        if (dispatch_semaphore_wait(_mpbSemaphore, time) != 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgressHUDCompleteMessage:NSLocalizedString(@"STREAM_WAIT_FOR_VIDEO", nil)];
            });
            
        } else {
            
            dispatch_semaphore_signal(_mpbSemaphore);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [self dismissViewControllerAnimated:YES completion:^{
                    AppLog(@"MPB QUIT ...");
                }];
                
            });
        }
        
    });
}

- (IBAction)edit:(id)sender
{
    AppLog(@"%s", __func__);
    if (_curMpbState == MpbStateNor) {
        self.navigationItem.leftBarButtonItem = nil;
        self.title = NSLocalizedString(@"SelectItem", nil);
        self.curMpbState = MpbStateEdit;
        self.editButton.title = NSLocalizedString(@"Cancel", @"");
        self.editButton.style = UIBarButtonItemStyleDone;
        
        self.actionButton.enabled = NO;
        self.deleteButton.enabled = NO;
        [self.selItemsTable addObserver:self forKeyPath:@"count" options:0x0 context:nil];
        observerNo++;
        
    } else {
        if ([_ctrl.fileCtrl isBusy]) {
            // Cancel download
            self.cancelDownload = YES;
            [_ctrl.fileCtrl cancelDownload];
        }
        
        self.navigationItem.leftBarButtonItem = self.doneButton;
        self.title = NSLocalizedString(@"Albums", @"");
        self.curMpbState = MpbStateNor;
        self.editButton.title = NSLocalizedString(@"Edit", @"");
        
        if ([_popController isPopoverVisible]) {
            [_popController dismissPopoverAnimated:YES];
        }
        
        // Clear
        for (NSIndexPath *ip in _selItemsTable.selectedCells) {
            //      ICatchFile *file = (ICatchFile *)[[a lastObject] pointerValue];
            MpbCollectionViewCell *cell = (MpbCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:ip];
            [cell setSelectedConfirmIconHidden:YES];
            cell.tag = 0;
        }
        if (!_cancelDownload) {
            [_selItemsTable.selectedCells removeAllObjects];
        }
        
        self.selItemsTable.count = 0;
        if (observerNo > 0) {
            [self.selItemsTable removeObserver:self forKeyPath:@"count"];
            --observerNo;
            self.totalDownloadSize = 0;
        }
    }
}

-(void)showPopoverFromBarButtonItem:(UIBarButtonItem *)item
                            message:(NSString *)message
                    fireButtonTitle:(NSString *)fireButtonTitle
                           callback:(SEL)fireAction
{
    AppLog(@"%s", __func__);
    MpbPopoverViewController *contentViewController = [[MpbPopoverViewController alloc] initWithNibName:@"MpbPopover" bundle:nil];
    contentViewController.msg = message;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        contentViewController.msgColor = [UIColor blackColor];
    } else {
        contentViewController.msgColor = [UIColor whiteColor];
    }
    
    UIPopoverController *popController = [[UIPopoverController alloc] initWithContentViewController:contentViewController];
    if (fireButtonTitle) {
        UIButton *fireButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0f, 110.0f, 260.0f, 47.0f)];
        popController.popoverContentSize = CGSizeMake(270.0f, 170.0f);
        fireButton.enabled = YES;
        
        [fireButton setTitle:fireButtonTitle
                    forState:UIControlStateNormal];
        [fireButton setBackgroundImage:[[UIImage imageNamed:@"iphone_delete_button.png"] stretchableImageWithLeftCapWidth:8.0f topCapHeight:0.0f]
                              forState:UIControlStateNormal];
        [fireButton addTarget:self action:fireAction forControlEvents:UIControlEventTouchUpInside];
        [contentViewController.view addSubview:fireButton];
    } else {
        popController.popoverContentSize = CGSizeMake(270.0f, 160.0f);
    }
    
    self.popController = popController;
    [_popController presentPopoverFromBarButtonItem:item permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

-(void)showActionSheetFromBarButtonItem:(UIBarButtonItem *)item
                                message:(NSString *)message
                      cancelButtonTitle:(NSString *)cancelButtonTitle
                 destructiveButtonTitle:(NSString *)destructiveButtonTitle
                                    tag:(NSInteger)tag
{
    AppLog(@"%s", __func__);
#if USE_SYSTEM_IOS7_IMPLEMENTATION
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:message
                                                   delegate:self
                                          cancelButtonTitle:cancelButtonTitle
                                     destructiveButtonTitle:destructiveButtonTitle
                                          otherButtonTitles:nil, nil];
    _actionSheet.tag = tag;
    [_actionSheet showFromBarButtonItem:item animated:YES];
#else
    self.actionSheet = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [_actionSheet addAction:[UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:nil]];
    if (destructiveButtonTitle != nil) {
        [_actionSheet addAction:[UIAlertAction actionWithTitle:destructiveButtonTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            switch (tag) {
                case ACTION_SHEET_DOWNLOAD_ACTIONS:
                    [self downloadDetail:item];
                    break;
                    
                case ACTION_SHEET_DELETE_ACTIONS:
                    [self deleteDetail:item];
                    break;
                    
                default:
                    break;
            }
        }]];
    }
    
    [self presentViewController:_actionSheet animated:YES completion:nil];
#endif
}

-(void)showActivityViewController:(NSArray *)activityItems
                         delegate:(id <ActivityWrapperDelegate>)delegate
{
    AppLog(@"%s", __func__);
    UIActivityDownload *download = [[UIActivityDownload alloc] initWithDelegate:delegate];
    //UIActivityShare *share = [[UIActivityShare alloc] initWithDelegate:delegate];
    UIActivityFacebook *facebook = [[UIActivityFacebook alloc] initWithDelegate:delegate];
    UIActivityTwitter *twitter = [[UIActivityTwitter alloc] initWithDelegate:delegate];
    UIActivityWeibo *weibo = [[UIActivityWeibo alloc] initWithDelegate:delegate];
    UIActivityTencentWeibo *tWeibo = [[UIActivityTencentWeibo alloc] initWithDelegate:delegate];
//    UIActivityWechatSession *wechatSession = [[UIActivityWechatSession alloc] initWithDelegate:delegate];
//    UIActivityWechatTimeline *wechatMoments = [[UIActivityWechatTimeline alloc] initWithDelegate:delegate];
//    UIActivityWechatFavorite *wechatFavorite = [[UIActivityWechatFavorite alloc] initWithDelegate:delegate];
//    UIActivityQQ *qq = [[UIActivityQQ alloc] initWithDelegate:delegate];
//    UIActivityEmail *email = [[UIActivityEmail alloc] initWithDelegate:delegate];
    NSArray *appActivities = @[download, /*share,*/ facebook, twitter, weibo, tWeibo/*, wechatSession, wechatMoments, wechatFavorite, qq, email*/];
    self.activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems
                                                                    applicationActivities:appActivities];
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        self.activityViewController.popoverPresentationController.barButtonItem = _actionButton;
    }
    
    // Exclude
    /*
     self.activityViewController.excludedActivityTypes = @[UIActivityTypePostToFacebook,
     UIActivityTypePostToTwitter,
     UIActivityTypePostToWeibo,
     UIActivityTypeMessage,
     UIActivityTypeMail,
     UIActivityTypePrint,
     UIActivityTypeCopyToPasteboard,
     UIActivityTypeAssignToContact,
     UIActivityTypeSaveToCameraRoll,
     UIActivityTypeAddToReadingList,
     UIActivityTypePostToFlickr,
     UIActivityTypePostToVimeo,
     UIActivityTypePostToTencentWeibo,
     UIActivityTypeAirDrop];
     */
    [self presentViewController:_activityViewController animated:YES completion:nil];
}

//LaunchServices: invalidationHandler called
-(void)_showSLComposeViewController:(NSString *)serviceType {
    AppLog(@"%s", __func__);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SLComposeViewController *SLComposeSheet = nil;

        SLComposeSheet = [SLComposeViewController composeViewControllerForServiceType:serviceType];
        [SLComposeSheet removeAllImages];
        [SLComposeSheet removeAllURLs];
        
        // Downloading
        for (NSIndexPath *ip in _selItemsTable.selectedCells) {
            WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(ip.section)] objectForKey:@(SectionDataTable)];
            auto f = fileTable.fileList.at(ip.item);
            switch (f->getFileType()) {
                case ICH_FILE_TYPE_IMAGE: {
                    AppLog(@"Request image...");
                    UIImage *sharedImage = [_ctrl.fileCtrl requestImage:f];
                    [SLComposeSheet addImage:sharedImage];

                }
                    break;
                    
                case ICH_FILE_TYPE_VIDEO:
                    break;
                default:
                    break;
            }
        }
        
        // Done
        [SLComposeSheet setInitialText:@"Shared image from WifiCamMobileApp"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideProgressHUD:NO];
            [self presentViewController:SLComposeSheet animated:YES completion: nil];
        });
    });
}

-(void)showSLComposeViewController:(NSString *)serviceType
{
    AppLog(@"%s", __func__);
    [self showProgressHUDWithMessage:nil detailsMessage:nil mode:MBProgressHUDModeIndeterminate];
    AppLog(@"serviceType: %@", serviceType);
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [_activityViewController dismissViewControllerAnimated:YES completion:nil];
        [self _showSLComposeViewController:serviceType];
    } else {
        [_activityViewController dismissViewControllerAnimated:YES completion:^{
            [self _showSLComposeViewController:serviceType];
        }];
    }
    
}

-(void)_showDownloadConfirm:(NSString *)message
                      title:(NSString *)confrimButtonTitle
                     dBytes:(unsigned long long)downloadSizeInKBytes
                     fSpace:(double)freeDiscSpace {
    AppLog(@"%s", __func__);
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (downloadSizeInKBytes < freeDiscSpace) {
            [self showPopoverFromBarButtonItem:self.actionButton
                                       message:message
                               fireButtonTitle:confrimButtonTitle
                                      callback:@selector(downloadDetail:)];
        } else {
            [self showPopoverFromBarButtonItem:self.actionButton
                                       message:message
                               fireButtonTitle:nil
                                      callback:nil];
        }
        
    } else {
        [self showActionSheetFromBarButtonItem:self.actionButton
                                       message:message
                             cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                        destructiveButtonTitle:confrimButtonTitle
                                           tag:ACTION_SHEET_DOWNLOAD_ACTIONS];
    }
}

-(void)showDownloadConfirm
{
    AppLog(@"%s", __func__);
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    NSInteger fileNum = 0;
    unsigned long long downloadSizeInKBytes = 0;
    NSString *confrimButtonTitle = nil;
    NSString *message = nil;
    double freeDiscSpace = [_ctrl.comCtrl freeDiskSpaceInKBytes];
    
    if (_curMpbState == MpbStateEdit) {
        
        if (_totalDownloadSize < freeDiscSpace/2.0) {
            message = [self makeupDownloadMessageWithSize:_totalDownloadSize
                                                andNumber:_selItemsTable.count];
            confrimButtonTitle = NSLocalizedString(@"SureDownload", @"");
        } else {
            message = [self makeupNoDownloadMessageWithSize:_totalDownloadSize];
        }
        
    } else {
        
        for (int i =0; i<_collDataArray.count; ++i) {
            WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(i)] objectForKey:@(SectionDataTable)];
            fileNum += fileTable.fileList.size();
            downloadSizeInKBytes += [[[_collDataArray objectForKey:@(i)] objectForKey:@(SectionTotalFileKBytes)] longLongValue];
        }
        
        if (downloadSizeInKBytes < freeDiscSpace) {
            message = [self makeupDownloadMessageWithSize:downloadSizeInKBytes
                                                andNumber:fileNum];
            confrimButtonTitle = NSLocalizedString(@"AllDownload", @"");
        } else {
            message = [self makeupNoDownloadMessageWithSize:downloadSizeInKBytes];
        }
        
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [_activityViewController dismissViewControllerAnimated:YES completion:nil];
        [self _showDownloadConfirm:message title:confrimButtonTitle dBytes:downloadSizeInKBytes fSpace:freeDiscSpace];
    } else {
        [_activityViewController dismissViewControllerAnimated:YES completion:^{
            [self _showDownloadConfirm:message title:confrimButtonTitle dBytes:downloadSizeInKBytes fSpace:freeDiscSpace];
        }];
    }
}

-(void)showShareConfirm
{
    AppLog(@"%s", __func__);
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    self.shareFiles = [NSMutableArray array];
    self.shareFileType = [NSMutableArray array];
    
    NSInteger fileNum = 0;
    unsigned long long downloadSizeInKBytes = 0;
    NSString *confrimButtonTitle = nil;
    NSString *message = nil;
    double freeDiscSpace = [_ctrl.comCtrl freeDiskSpaceInKBytes];
    
    if (_curMpbState == MpbStateEdit) {
        
        if (_totalDownloadSize < freeDiscSpace/2.0) {
            message = [self makeupDownloadMessageWithSize:_totalDownloadSize
                                                andNumber:_selItemsTable.count];
            confrimButtonTitle = NSLocalizedString(@"SureDownload", @"");
        } else {
            message = [self makeupNoDownloadMessageWithSize:_totalDownloadSize];
        }
        
    } else {
        
        for (int i =0; i<_collDataArray.count; ++i) {
            WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(i)] objectForKey:@(SectionDataTable)];
            fileNum += fileTable.fileList.size();
            downloadSizeInKBytes += [[[_collDataArray objectForKey:@(i)] objectForKey:@(SectionTotalFileKBytes)] longLongValue];
        }
        
        if (downloadSizeInKBytes < freeDiscSpace) {
            message = [self makeupDownloadMessageWithSize:downloadSizeInKBytes
                                                andNumber:fileNum];
            confrimButtonTitle = NSLocalizedString(@"AllDownload", @"");
        } else {
            message = [self makeupNoDownloadMessageWithSize:downloadSizeInKBytes];
        }
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [_activityViewController dismissViewControllerAnimated:YES completion:nil];
        [self _showDownloadConfirm:message title:confrimButtonTitle dBytes:downloadSizeInKBytes fSpace:freeDiscSpace];
    } else {
        [_activityViewController dismissViewControllerAnimated:YES completion:^{
            [self _showDownloadConfirm:message title:confrimButtonTitle dBytes:downloadSizeInKBytes fSpace:freeDiscSpace];
        }];
    }
//    for (int i =0; i<_collDataArray.count; ++i) {
//        WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(i)] objectForKey:@(SectionDataTable)];
//        fileNum += fileTable.fileList.size();
//        downloadSizeInKBytes += [[[_collDataArray objectForKey:@(i)] objectForKey:@(SectionTotalFileKBytes)] longLongValue];
//    }
//    
//    if (downloadSizeInKBytes < freeDiscSpace) {
//        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
//            [_activityViewController dismissViewControllerAnimated:YES completion:nil];
//            [self downloadDetail:sender];
//
//        } else {
//            [_activityViewController dismissViewControllerAnimated:YES completion:^{
//                [self downloadDetail:sender];
//            }];
//        }
//    }
}

//- (void)showShareConfirm
//{
//    AppLog(@"%s", __func__);
//    if (_popController.popoverVisible) {
//        [_popController dismissPopoverAnimated:YES];
//    }
//    
//    [self showProgressHUDWithMessage:@"请稍候 ..."];
//    
//    dispatch_queue_t shareQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.Share", 0);
//    
//    dispatch_async(shareQueue, ^{
//        NSArray *shareArray = [self shareSelectedFiles];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self hideProgressHUD:YES];
//            [self showUIActivityViewController:shareArray];
//        });
//    });
//}

- (void)showUIActivityViewController:(id)sender
{
    AppLog(@"%s", __func__);
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    uint shareNum = (uint)[self.shareFiles count];
    uint assetNum = (uint)[[SDK instance] retrieveCameraRollAssetsResult].count;

    if (shareNum) {
        UIActivityViewController *activityVc = [[UIActivityViewController alloc]initWithActivityItems:self.shareFiles applicationActivities:nil];
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [self presentViewController:activityVc animated:YES completion:nil];
        } else {
            // Create pop up
            UIPopoverController *activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityVc];
            // Show UIActivityViewController in popup
//                    [activityPopoverController presentPopoverFromRect:CGRectZero inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
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
                        if (shareNum <= 5) {
                            ret = [[SDK instance] savetoAlbum:@"MobileCamApp"/*@"SBCapp"*/ andAlbumAssetNum:assetNum andShareNum:shareNum];
                        } else {
                            ret = [[SDK instance] savetoAlbum:@"MobileCamApp"/*@"SBCapp"*/ andAlbumAssetNum:assetNum andShareNum:5];
                            
                            for (int i = 5; i < shareNum; i++) {
                                [[SDK instance] addNewAssetWithURL:self.shareFiles[i] toAlbum:@"MobileCamApp"/*@"SBCapp"*/ andFileType:(ICatchFileType)[self.shareFileType[i] intValue]];
                            }
                        }

                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (ret) {
                                [self showProgressHUDCompleteMessage:NSLocalizedString(@"SavePhotoToAlbum", nil)];
                            } else {
                                [self showProgressHUDCompleteMessage:NSLocalizedString(@"SaveError", nil)];
                            }
                            
                            [self.shareFiles removeAllObjects];
                            [self.shareFileType removeAllObjects];
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
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"没有选择要分享的图片或视频 !"
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                                  otherButtonTitles:nil];
        [alertView show];
        [self.shareFiles removeAllObjects];
        [self.shareFileType removeAllObjects];
    }
}

-(NSString *)makeupDownloadMessageWithSize:(unsigned long long)sizeInKB
                                 andNumber:(NSInteger)num
{
    AppLog(@"%s", __func__);
    /*
     NSString *message = NSLocalizedString(@"DownloadConfirmMessage", nil);
     NSString *humanDownloadFileSize = [_ctrl.comCtrl translateSize:sizeInKB];
     
     double downloadTime = (double)sizeInKB/1024/60;
     message = [message stringByReplacingOccurrencesOfString:@"%1"
     withString:[NSString stringWithFormat:@"%ld", (long)num]];
     message = [message stringByReplacingOccurrencesOfString:@"%2"
     withString:[NSString stringWithFormat:@"%.2f", downloadTime]];
     message = [message stringByAppendingString:[NSString stringWithFormat:@"\n%@", humanDownloadFileSize]];
     return message;
     */
    
    NSString *message = nil;
    NSString *humanDownloadFileSize = [_ctrl.comCtrl translateSize:sizeInKB];
    unsigned long long downloadTimeInHours = (sizeInKB/1024)/3600;
    unsigned long long downloadTimeInMinutes = (sizeInKB/1024)/60 - downloadTimeInHours*60;
    unsigned long long downloadTimeInSeconds = sizeInKB/1024 - downloadTimeInHours*3600 - downloadTimeInMinutes*60;
    AppLog(@"downloadTimeInHours: %llu, downloadTimeInMinutes: %llu, downloadTimeInSeconds: %llu",
           downloadTimeInHours, downloadTimeInMinutes, downloadTimeInSeconds);
    
    if (downloadTimeInHours > 0) {
        message = NSLocalizedString(@"DownloadConfirmMessage3", nil);
        message = [message stringByReplacingOccurrencesOfString:@"%1"
                                                     withString:[NSString stringWithFormat:@"%ld", (long)num]];
        message = [message stringByReplacingOccurrencesOfString:@"%2"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInHours]];
        message = [message stringByReplacingOccurrencesOfString:@"%3"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInMinutes]];
        message = [message stringByReplacingOccurrencesOfString:@"%4"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInSeconds]];
    } else if (downloadTimeInMinutes > 0) {
        message = NSLocalizedString(@"DownloadConfirmMessage2", nil);
        message = [message stringByReplacingOccurrencesOfString:@"%1"
                                                     withString:[NSString stringWithFormat:@"%ld", (long)num]];
        message = [message stringByReplacingOccurrencesOfString:@"%2"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInMinutes]];
        message = [message stringByReplacingOccurrencesOfString:@"%3"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInSeconds]];
    } else {
        message = NSLocalizedString(@"DownloadConfirmMessage1", nil);
        message = [message stringByReplacingOccurrencesOfString:@"%1"
                                                     withString:[NSString stringWithFormat:@"%ld", (long)num]];
        message = [message stringByReplacingOccurrencesOfString:@"%2"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInSeconds]];
    }
    message = [message stringByAppendingString:[NSString stringWithFormat:@"\n%@", humanDownloadFileSize]];
    return message;
    
}

-(NSString *)makeupNoDownloadMessageWithSize:(unsigned long long)sizeInKB
{
    AppLog(@"%s", __func__);
    NSString *message = nil;
    NSString *humanDownloadFileSize = [_ctrl.comCtrl translateSize:sizeInKB];
    double freeDiscSpace = [_ctrl.comCtrl freeDiskSpaceInKBytes];
    NSString *leftSpace = [_ctrl.comCtrl translateSize:freeDiscSpace];
    message = [NSString stringWithFormat:@"%@\n Download:%@, Free:%@", NSLocalizedString(@"NotEnoughSpaceError", nil), humanDownloadFileSize, leftSpace];
    message = [message stringByAppendingString:@"\n Needs double free space"];
    return message;
}

- (IBAction)actionButtonPressed:(id)sender
{
    AppLog(@"%s", __func__);
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    /*
     NSInteger fileNum = 0;
     unsigned long long downloadSizeInKBytes = 0;
     NSString *confrimButtonTitle = nil;
     NSString *message = nil;
     double freeDiscSpace = [_ctrl.comCtrl freeDiskSpaceInKBytes];
     
     if (_curMpbState == MpbStateEdit) {
     if (_totalDownloadSize < freeDiscSpace) {
     message = [self makeupDownloadMessageWithSize:_totalDownloadSize
     andNumber:_selItemsTable.count];
     confrimButtonTitle = NSLocalizedString(@"SureDownload", @"");
     } else {
     message = [self makeupNoDownloadMessageWithSize:_totalDownloadSize];
     }
     
     } else {
     
     for (int i =0; i<_collDataArray.count; ++i) {
     WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(i)] objectForKey:@(SectionDataTable)];
     fileNum += fileTable.fileList.size();
     downloadSizeInKBytes += [[[_collDataArray objectForKey:@(i)] objectForKey:@(SectionTotalFileKBytes)] longLongValue];
     }
     
     if (downloadSizeInKBytes < freeDiscSpace) {
     message = [self makeupDownloadMessageWithSize:downloadSizeInKBytes
     andNumber:fileNum];
     confrimButtonTitle = NSLocalizedString(@"AllDownload", @"");
     } else {
     message = [self makeupNoDownloadMessageWithSize:downloadSizeInKBytes];
     }
     
     }
     */
    NSMutableArray *items = [[NSMutableArray alloc] init];
    for (NSIndexPath *ip in _selItemsTable.selectedCells) {
        WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(ip.section)] objectForKey:@(SectionDataTable)];
        auto f = fileTable.fileList.at(ip.item);
        switch (f->getFileType()) {
            case ICH_FILE_TYPE_IMAGE: {
                UIActivityItemImage *sharedImage = [[UIActivityItemImage alloc] init];
//                UIImage *sharedImage = [[UIImage alloc] init];
                [items addObject:sharedImage];
            }
                break;
                
            case ICH_FILE_TYPE_VIDEO: {
                UIActivityItemVideo *sharedVideo = [[UIActivityItemVideo alloc] init];
                [items addObject:sharedVideo];
            }
                break;
            default:
                break;
        }
    }
    
    [self showActivityViewController:items delegate:self];
//    [self showUIActivityViewController:sender];
//    [self showShareConfirm:sender];
//    [self showShareConfirm];
}

- (void)requestDownloadPercent:(shared_ptr<ICatchFile>)file
{
    AppLog(@"%s", __func__);
    if (!file) {
        AppLog(@"file is null");
        return;
    }
    
    auto f = file;
    NSString *locatePath = nil;
    NSString *fileName = [NSString stringWithUTF8String:f->getFileName().c_str()];
    unsigned long long fileSize = f->getFileSize();
    //locatePath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), fileName];
    
    NSString *fileDirectory = nil;
    if ([fileName hasSuffix:@".MP4"] || [fileName hasSuffix:@".MOV"] || [fileName hasSuffix:@".AVI"]) {
        fileDirectory = [[SDK instance] createMediaDirectory][2];
    } else {
        fileDirectory = [[SDK instance] createMediaDirectory][1];
    }
    locatePath = [fileDirectory stringByAppendingPathComponent:fileName];
    
    AppLog(@"locatePath: %@, %llu", locatePath, fileSize);
    
    dispatch_async(_downloadPercentQueue, ^{
        do {
            @autoreleasepool {
                if (_cancelDownload) break;
                //self.downloadedPercent = [_ctrl.fileCtrl requestDownloadedPercent:f];
                self.downloadedPercent = [_ctrl.fileCtrl requestDownloadedPercent2:locatePath
                                                                          fileSize:fileSize];
                AppLog(@"percent: %lu", (unsigned long)self.downloadedPercent);
                
                [NSThread sleepForTimeInterval:0.2];
            }
        } while (_downloadFileProcessing);
        
    });
}

- (NSArray *)downloadAllOfType:(WCFileType)type
{
    AppLog(@"%s", __func__);
    vector<shared_ptr<ICatchFile>> fileList;
    NSInteger downloadedNum = 0;
    NSInteger downloadFailedCount = 0;
    
    switch (type) {
        case WCFileTypeImage:
            fileList = _gallery.imageTable.fileList;
            break;
            
        case WCFileTypeVideo:
            fileList = _gallery.videoTable.fileList;
            break;
            
        default:
            break;
    }
    
    if (![[SDK instance] openFileTransChannel]) {
        return nil;
    }
    
    for(vector<shared_ptr<ICatchFile>>::iterator it = fileList.begin();
        it != fileList.end();
        ++it) {
        if (_cancelDownload) {
            break;
        }
        
        auto file = (*it);
        
        self.downloadFileProcessing = YES;
        [self requestDownloadPercent:file];
        if (![_ctrl.fileCtrl downloadFile2:file]) {
            ++downloadFailedCount;
            self.downloadFileProcessing = NO;
            continue;
        }
        self.downloadFileProcessing = NO;
        [NSThread sleepForTimeInterval:0.5];
        
        ++downloadedNum;
        // [self.shareFiles addObject:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithUTF8String:file->getFileName().c_str()]]]];
        // [self.shareFileType addObject:[NSNumber numberWithInt:type]];
        self.downloadedFileNumber = [_ctrl.fileCtrl retrieveDownloadedTotalNumber];
    }
    
    if (![[SDK instance] closeFileTransChannel]) {
        return nil;
    }
    
    return [NSArray arrayWithObjects:@(downloadedNum), @(downloadFailedCount), nil];
}

- (NSArray *)downloadAll
{
    AppLog(@"%s", __func__);
    NSInteger downloadedPhotoNum = 0, downloadedVideoNum = 0;
    NSInteger downloadFailedCount = 0;
    NSArray *resultArray = nil;
    
    resultArray = [self downloadAllOfType:WCFileTypeImage];
    downloadedPhotoNum = [resultArray[0] integerValue];
    downloadFailedCount += [resultArray[1] integerValue];
    
    resultArray = [self downloadAllOfType:WCFileTypeVideo];
    downloadedVideoNum = [resultArray[0] integerValue];
    downloadFailedCount += [resultArray[1] integerValue];
    
    [_ctrl.fileCtrl resetDownoladedTotalNumber];
    return [NSArray arrayWithObjects:@(downloadedPhotoNum), @(downloadedVideoNum), @(downloadFailedCount), nil];
}

- (NSArray *)downloadSelectedFiles
{
    AppLog(@"%s", __func__);
    NSInteger downloadedPhotoNum = 0, downloadedVideoNum = 0;
    NSInteger downloadFailedCount = 0;
    
    if (![[SDK instance] openFileTransChannel]) {
        return nil;
    }
    
    for (NSIndexPath *ip in _selItemsTable.selectedCells) {
        if (_cancelDownload) break;
        
        WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(ip.section)] objectForKey:@(SectionDataTable)];
        auto f = fileTable.fileList.at(ip.item);
        
        self.downloadFileProcessing = YES;
        self.downloadedPercent = 0;//Before the download clear downloadedPercent and increase downloadedFileNumber.
//        self.downloadedFileNumber = [_ctrl.fileCtrl retrieveDownloadedTotalNumber];
        self.downloadedFileNumber ++;
        [self requestDownloadPercent:f];
        if (![_ctrl.fileCtrl downloadFile2:f]) {
            ++downloadFailedCount;
            self.downloadFileProcessing = NO;
            continue;
        }
        /*if (![[SDK instance] p_downloadFile2:&f]) {
            ++downloadFailedCount;
            self.downloadFileProcessing = NO;
            continue;
        }*/
        
        self.downloadFileProcessing = NO;
        [NSThread sleepForTimeInterval:0.5];
        
        switch (f->getFileType()) {
            case ICH_FILE_TYPE_IMAGE:
                ++downloadedPhotoNum;
                [self.shareFileType addObject:[NSNumber numberWithInt:ICH_FILE_TYPE_IMAGE]];
                break;
                
            case ICH_FILE_TYPE_VIDEO:
                ++downloadedVideoNum;
                [self.shareFileType addObject:[NSNumber numberWithInt:ICH_FILE_TYPE_VIDEO]];
                break;
                
            case ICH_FILE_TYPE_TEXT:
            case ICH_FILE_TYPE_AUDIO:
            case ICH_FILE_TYPE_ALL:
            case ICH_FILE_TYPE_UNKNOWN:
            default:
                break;
        }
        
        //[self.shareFiles addObject:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithUTF8String:f.getFileName().c_str()]]]];
    }
    
    if (![[SDK instance] closeFileTransChannel]) {
        return nil;
    }
    
    [_ctrl.fileCtrl resetDownoladedTotalNumber];
    return [NSArray arrayWithObjects:@(downloadedPhotoNum), @(downloadedVideoNum), @(downloadFailedCount), nil];
}

- (void)downloadSelectedFile:(shared_ptr<ICatchFile>)f andFailedCount:(NSInteger *)downloadFailedCount andPhotoCount:(NSInteger *)downloadedPhotoNum andVideoCount:(NSInteger *)downloadedVideoNum
{
    do {
        self.downloadedFileNumber ++;
        [self requestDownloadPercent:f];
//        if (![_ctrl.fileCtrl downloadFile2:&f]) {
//            ++(*downloadFailedCount);
//            self.downloadFileProcessing = NO;
//            continue;
//        }
        if (![[SDK instance] p_downloadFile2:f]) {
            ++downloadFailedCount;
            self.downloadFileProcessing = NO;
            continue;
        }
        
        self.downloadFileProcessing = NO;
        [NSThread sleepForTimeInterval:0.5];
        
        switch (f->getFileType()) {
            case ICH_FILE_TYPE_IMAGE:
                ++(*downloadedPhotoNum);
                [self.shareFiles addObject:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithUTF8String:f->getFileName().c_str()]]]];
                [self.shareFileType addObject:[NSNumber numberWithInt:ICH_FILE_TYPE_IMAGE]];
//                [self.shareFiles addObject:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithUTF8String:f.getFileName().c_str()]]]];
                break;
                
            case ICH_FILE_TYPE_VIDEO:
                ++(*downloadedVideoNum);
                [self.shareFiles addObject:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithUTF8String:f->getFileName().c_str()]]]];
                [self.shareFileType addObject:[NSNumber numberWithInt:ICH_FILE_TYPE_VIDEO]];
                break;
                
            case ICH_FILE_TYPE_TEXT:
            case ICH_FILE_TYPE_AUDIO:
            case ICH_FILE_TYPE_ALL:
            case ICH_FILE_TYPE_UNKNOWN:
            default:
                break;
        }
    } while (0);
}

- (NSArray *)shareSelectedFiles
{
    AppLog(@"%s", __func__);
    NSInteger downloadedPhotoNum = 0, downloadedVideoNum = 0;
    NSInteger downloadFailedCount = 0;
    
    WifiCamFileTable *fileTable = nil;
//    ICatchFile f = NULL;
    NSString *fileName = nil;
    NSArray *tmpDirectoryContents = nil;
    
    if (![[SDK instance] openFileTransChannel]) {
        return nil;
    }
    
    for (NSIndexPath *ip in _selItemsTable.selectedCells) {
        if (_cancelDownload) break;
        
        fileTable = [[_collDataArray objectForKey:@(ip.section)] objectForKey:@(SectionDataTable)];
        auto f = fileTable.fileList.at(ip.item);
        
        fileName = [NSString stringWithUTF8String:f->getFileName().c_str()];
        tmpDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
        
        self.downloadFileProcessing = YES;
        self.downloadedPercent = 0;//Before the download clear downloadedPercent and increase downloadedFileNumber.
        //        self.downloadedFileNumber = [_ctrl.fileCtrl retrieveDownloadedTotalNumber];
        
        if (tmpDirectoryContents.count) {
            for (NSString *name in tmpDirectoryContents) {
                if ([name isEqualToString:fileName]) {
                    [self.shareFiles addObject:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithUTF8String:f->getFileName().c_str()]]]];
                    [self.shareFileType addObject:[NSNumber numberWithInt:f->getFileType()]];
                    //                    if (f.getFileType() == TYPE_VIDEO) {
                    //                        [self.shareFiles addObject:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithUTF8String:f.getFileName().c_str()]]]];
                    //                    } else if (f.getFileType() == TYPE_IMAGE) {
                    //                        [self.shareFiles addObject:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithUTF8String:f.getFileName().c_str()]]]];
                    //                    }
                    break;
                } else if ([name isEqualToString:[tmpDirectoryContents lastObject]]) {
                    [self downloadSelectedFile:f andFailedCount:(&downloadFailedCount) andPhotoCount:(&downloadedPhotoNum) andVideoCount:(&downloadedVideoNum)];
                }
            }
        } else {
            [self downloadSelectedFile:f andFailedCount:(&downloadFailedCount) andPhotoCount:(&downloadedPhotoNum) andVideoCount:(&downloadedVideoNum)];
        }
    }
    
    if (![[SDK instance] closeFileTransChannel]) {
        return nil;
    }
    
    [_ctrl.fileCtrl resetDownoladedTotalNumber];
    return [NSArray arrayWithObjects:@(downloadedPhotoNum), @(downloadedVideoNum), @(downloadFailedCount), nil];
}

//- (NSArray *)shareSelectedFiles:(id)sender
//{
//    AppLog(@"%s", __func__);
//    
//    NSMutableArray *shareFiles = [NSMutableArray array];
//    WifiCamFileTable *fileTable = nil;
//    ICatchFile f = NULL;
//    NSString *fileName = nil;
//    NSArray *tmpDirectoryContents = nil;
//    
//    for (NSIndexPath *ip in _selItemsTable.selectedCells) {
//        if (_cancelDownload) break;
//        
//        fileTable = [[_collDataArray objectForKey:@(ip.section)] objectForKey:@(SectionDataTable)];
//        f = fileTable.fileList.at(ip.item);
//        
//        fileName = [NSString stringWithUTF8String:f.getFileName().c_str()];
//        tmpDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
//        
//        if (tmpDirectoryContents.count) {
//            for (NSString *name in tmpDirectoryContents) {
//                if ([name isEqualToString:fileName]) {
//                    [self.shareFiles addObject:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), fileName]]];
//                    [self showUIActivityViewController:sender];
//                    break;
//                } else if ([name isEqualToString:[tmpDirectoryContents lastObject]]) {
//                    [self showDownloadShareFiles:sender];
//                }
//            }
//        } else {
//            [self showDownloadShareFiles:sender];
//        }
//    }
//    
//    return shareFiles;
//}

- (IBAction)downloadDetail:(id)sender
{
    AppLog(@"%s", __func__);
    if ([sender isKindOfClass:[UIButton self]]) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    self.cancelDownload = NO;
    
    // Prepare
    if (_curMpbState == MpbStateNor) {
        self.navigationItem.leftBarButtonItem = nil;
        self.editButton.title = NSLocalizedString(@"Cancel", @"");
        self.editButton.style = UIBarButtonItemStyleDone;
        [self.selItemsTable addObserver:self forKeyPath:@"count" options:0x0 context:nil];
        observerNo++;
        self.totalDownloadFileNumber = _totalCount;
    } else {
        self.totalDownloadFileNumber = _selItemsTable.selectedCells.count;
    }
    self.actionButton.enabled = NO;
    self.deleteButton.enabled = NO;
    self.downloadedFileNumber = 0;
    self.downloadedPercent = 0;
    [self addObserver:self forKeyPath:@"downloadedFileNumber" options:0x0 context:nil];
    [self addObserver:self forKeyPath:@"downloadedPercent" options:NSKeyValueObservingOptionNew context:nil];
    NSUInteger handledNum = MIN(_downloadedFileNumber, _totalDownloadFileNumber);
    NSString *msg = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)handledNum, (unsigned long)_totalDownloadFileNumber];
    
    // Show processing notice
    if (!handledNum) {
//        [self showProgressHUDWithMessage:@"请稍候 ..."];
        [self showProgressHUDWithMessage:@"请稍候 ..."
                          detailsMessage:nil
                                    mode:MBProgressHUDModeDeterminate];
    } else {
        [self showProgressHUDWithMessage:msg
                          detailsMessage:nil
                                    mode:MBProgressHUDModeDeterminate];
    }
    // Just in case, _selItemsTable.selectedCellsn wouldn't be destoried after app enter background
    [_ctrl.fileCtrl tempStoreDataForBackgroundDownload:_selItemsTable.selectedCells];
    
    dispatch_async(_downloadQueue, ^{
        NSInteger downloadedPhotoNum = 0, downloadedVideoNum = 0;
        NSInteger downloadFailedCount = 0;
        UIBackgroundTaskIdentifier downloadTask;
        NSArray *resultArray = nil;
        
        [_ctrl.fileCtrl resetBusyToggle:YES];
        // -- Request more time to excute task within background
        UIApplication  *app = [UIApplication sharedApplication];
        downloadTask = [app beginBackgroundTaskWithExpirationHandler: ^{
            
            AppLog(@"-->Expiration");
            NSArray *oldNotifications = [app scheduledLocalNotifications];
            // Clear out the old notification before scheduling a new one
            if ([oldNotifications count] > 5) {
                [app cancelAllLocalNotifications];
            }
            
            NSString *noticeMessage = [NSString stringWithFormat:@"[Progress: %lu/%lu] - App is about to exit. Please bring it to foreground to continue dowloading.", (unsigned long)handledNum, (unsigned long)_totalDownloadFileNumber];
            [_ctrl.comCtrl scheduleLocalNotice:noticeMessage];
        }];
        
        
        // ---------- Downloading
        if (_curMpbState == MpbStateNor) {
            self.curMpbState = MpbStateEdit;
            resultArray = [self downloadAll];
        } else {
            resultArray = [self downloadSelectedFiles];
            //resultArray = [self shareSelectedFiles];
        }
        downloadedPhotoNum = [resultArray[0] integerValue];
        downloadedVideoNum = [resultArray[1] integerValue];
        downloadFailedCount = [resultArray[2] integerValue];
        self.downloadFailedCount = downloadFailedCount;
        // -----------
        
        
        // Download is completed, notice & update GUI
        self.totalDownloadSize = 0;
        // Post local notification
        dispatch_async(dispatch_get_main_queue(), ^{
            if (app.applicationState == UIApplicationStateBackground) {
                NSString *noticeMessage = NSLocalizedString(@"SavePhotoToAlbum", @"Download complete.");
                [_ctrl.comCtrl scheduleLocalNotice:noticeMessage];
            }
        });
        // HUD notification
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeObserver:self forKeyPath:@"downloadedFileNumber"];
            [self removeObserver:self forKeyPath:@"downloadedPercent"];
            
            //[self showUIActivityViewController:self.actionButton];
            // Clear
            for (NSIndexPath *ip in _selItemsTable.selectedCells) {
                MpbCollectionViewCell *cell = (MpbCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:ip];
                [cell setSelectedConfirmIconHidden:YES];
                cell.tag = 0;
            }
            [_selItemsTable.selectedCells removeAllObjects];
            self.selItemsTable.count = 0;
            
            if (!_cancelDownload) {
                NSString *message = nil;
                if (downloadFailedCount > 0) {
                    NSString *message = NSLocalizedString(@"DownloadSelectedError", nil);
                    message = [message stringByReplacingOccurrencesOfString:@"%d" withString:[NSString stringWithFormat:@"%ld", (long)downloadFailedCount]];
                    [self showProgressHUDNotice:message showTime:0.5];
                    
                } else {
                    if (self.downloadedFileNumber) {
                        message = NSLocalizedString(@"DownloadDoneMessage", nil);
                        NSString *photoNum = [NSString stringWithFormat:@"%ld", (long)downloadedPhotoNum];
                        NSString *videoNum = [NSString stringWithFormat:@"%ld", (long)downloadedVideoNum];
                        message = [message stringByReplacingOccurrencesOfString:@"%1"
                                                                     withString:photoNum];
                        message = [message stringByReplacingOccurrencesOfString:@"%2"
                                                                     withString:videoNum];
                    }
                        [self showProgressHUDCompleteMessage:message];
                }
                
            } else {
                [self hideProgressHUD:YES];
            }
        });
        
        [_ctrl.fileCtrl resetBusyToggle:NO];
        [[UIApplication sharedApplication] endBackgroundTask:downloadTask];
    });
}

- (IBAction)delete:(id)sender
{
    AppLog(@"%s", __func__);
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    NSString *message = NSLocalizedString(@"DeleteMultiAsk", nil);
    NSString *replaceString = [NSString stringWithFormat:@"%ld", (long)_selItemsTable.count];
    message = [message stringByReplacingOccurrencesOfString:@"%d"
                                                 withString:replaceString];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self showPopoverFromBarButtonItem:sender
                                   message:message
                           fireButtonTitle:NSLocalizedString(@"SureDelete", @"")
                                  callback:@selector(deleteDetail:)];
    } else {
        [self showActionSheetFromBarButtonItem:sender
                                       message:message
                             cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                        destructiveButtonTitle:NSLocalizedString(@"SureDelete", @"")
                                           tag:ACTION_SHEET_DELETE_ACTIONS];
    }
}

- (IBAction)deleteDetail:(id)sender
{
    AppLog(@"%s", __func__);
    __block int failedCount = 0;
    
    if ([sender isKindOfClass:[UIButton self]]) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    self.run = NO;
    [self showProgressHUDWithMessage:NSLocalizedString(@"Deleting", nil)
                      detailsMessage:nil
                                mode:MBProgressHUDModeIndeterminate];
    
    //  NSMutableArray *toDeletedIndexPaths = [[NSMutableArray alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *cachedKey = nil;
        
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        dispatch_semaphore_wait(_mpbSemaphore, time);
        
        // Real delete icatch file & remove NSCache item
        
        for (NSIndexPath *ip in _selItemsTable.selectedCells) {
            //      int type = [[a objectAtIndex:1] intValue];
            WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(ip.section)] objectForKey:@(SectionDataTable)];
            auto f = fileTable.fileList.at(ip.item);
            //ICatchFile *file = (ICatchFile *)[[a lastObject] pointerValue];
            if ([_ctrl.fileCtrl deleteFile:f] == NO) {
                ++failedCount;
            }
            cachedKey = [NSString stringWithFormat:@"ID%d", f->getFileHandle()];
            /*
             switch (type) {
             case WCFileTypeImage:
             if (!_enableHeader) {
             ip = [_ctrl.fileCtrl requestSplitedIndexPathOfType:WCFileTypeImage
             withIndex:ip.item];
             }
             [_ctrl.fileCtrl requestDeleteFileOfType:WCFileTypeImage withIndex:ip.item];
             cachedKey = [_ctrl.fileCtrl requestFileIdOfType:WCFileTypeImage
             withIndex:ip.item];
             break;
             case WCFileTypeVideo:
             if (!_enableHeader) {
             ip = [_ctrl.fileCtrl requestSplitedIndexPathOfType:WCFileTypeVideo
             withIndex:ip.item];
             }
             [_ctrl.fileCtrl requestDeleteFileOfType:WCFileTypeVideo withIndex:ip.item];
             cachedKey = [_ctrl.fileCtrl requestFileIdOfType:WCFileTypeVideo
             withIndex:ip.item];
             break;
             default:
             break;
             }
             [toDeletedIndexPaths addObject:ip];
             */
            
            [_mpbCache removeObjectForKey:cachedKey];
        }
        
        // Update the UICollectionView's data source
        [self resetCollectionViewData];
        dispatch_semaphore_signal(_mpbSemaphore);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failedCount != _selItemsTable.selectedCells.count) {
                [_selItemsTable.selectedCells removeAllObjects];
                self.run = YES;
                [self.collectionView reloadData];
            }
            
            NSString *noticeMessage = nil;
            
            if (failedCount > 0) {
                noticeMessage = NSLocalizedString(@"DeleteMultiError", nil);
                NSString *failedCountString = [NSString stringWithFormat:@"%d", failedCount];
                noticeMessage = [noticeMessage stringByReplacingOccurrencesOfString:@"%d" withString:failedCountString];
            } else {
                noticeMessage = NSLocalizedString(@"DeleteDoneMessage", nil);
            }
            [self showProgressHUDCompleteMessage:noticeMessage];
//            self.selItemsTable.count = 0;
            
            if (_totalCount == 0) {
                _editButton.enabled = NO;
                _actionButton.enabled = NO;
                self.browser = nil;
                
                (self.curMpbState == MpbStateEdit) ? [self edit:nil] : void();
            }
        });
        
    });
}

-(void)prepareForAction
{
    AppLog(@"%s", __func__);
    NSInteger selectedPhotoNum = 0;
    NSInteger selectedVideoNum = 0;
    
    self.deleteButton.enabled = YES;
    self.actionButton.enabled = YES;
    
    for (NSIndexPath *ip in _selItemsTable.selectedCells) {
        WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(ip.section)] objectForKey:@(SectionDataTable)];
        auto f = fileTable.fileList.at(ip.item);
        //    int type = [[a objectAtIndex:1] intValue];
        //    ICatchFile *file = (ICatchFile *)[[a lastObject] pointerValue];
        switch (f->getFileType()) {
            case ICH_FILE_TYPE_IMAGE:
                ++selectedPhotoNum;
                break;
                
            case ICH_FILE_TYPE_VIDEO:
                ++selectedVideoNum;
                break;
            default:
                break;
        }
    }
    AppLog(@"VIDEO: %ld, IMAGE: %ld", (long)selectedVideoNum, (long)selectedPhotoNum);
    
    if ((selectedPhotoNum > 0) && (selectedVideoNum > 0)) {
        NSString  *demoTitle = NSLocalizedString(@"SelectedItems", nil);
        NSString  *items = [NSString stringWithFormat:@"%ld", (long)(selectedPhotoNum + selectedVideoNum)];
        self.title = [demoTitle stringByReplacingOccurrencesOfString:@"%d" withString:items];
        
    } else if (selectedPhotoNum > 0) {
        if (selectedPhotoNum == 1) {
            self.title = NSLocalizedString(@"SelectedOnePhoto", nil);
        } else {
            NSString  *demoTitle = NSLocalizedString(@"SelectedPhotos", nil);
            NSString  *items = [NSString stringWithFormat:@"%ld", (long)selectedPhotoNum];
            self.title = [demoTitle stringByReplacingOccurrencesOfString:@"%d" withString:items];
        }
    } else if (selectedVideoNum > 0) {
        if (selectedVideoNum == 1) {
            self.title = NSLocalizedString(@"SelectedOneVideo", nil);
        } else {
            NSString  *demoTitle = NSLocalizedString(@"SelectedVideos", nil);
            NSString  *items = [NSString stringWithFormat:@"%ld", (long)selectedVideoNum];
            self.title = [demoTitle stringByReplacingOccurrencesOfString:@"%d" withString:items];
        }
    }
}

-(void)prepareForCancelAction
{
    AppLog(@"%s", __func__);
    if (_curMpbState == MpbStateEdit) {
        self.deleteButton.enabled = NO;
        self.actionButton.enabled = NO;
        if (_totalCount > 0) {
            self.title = NSLocalizedString(@"SelectItem", nil);
        } else {
            self.curMpbState = MpbStateNor;
            self.title = NSLocalizedString(@"Albums", @"");
            self.editButton.title = NSLocalizedString(@"Edit", @"");
            self.editButton.enabled = NO;
            self.navigationItem.leftBarButtonItem = self.doneButton;
        }
    } else {
        self.deleteButton.enabled = NO;
        self.actionButton.enabled = _totalCount > 0 ? YES : NO;
    }
}

#pragma mark - Observer
- (void)observeValueForKeyPath:(NSString *)keyPath
        ofObject              :(id)object
        change                :(NSDictionary *)change
        context               :(void *)context
{
    AppLog(@"%s", __func__);
    if ([keyPath isEqualToString:@"count"]) {
        if (_selItemsTable.count > 0) {
            [self prepareForAction];
        } else {
            [self prepareForCancelAction];
        }
    } else if ([keyPath isEqualToString:@"downloadedFileNumber"]) {
        NSUInteger handledNum = MIN(_downloadedFileNumber, _totalDownloadFileNumber);
        NSString *msg = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)handledNum, (unsigned long)_totalDownloadFileNumber];
        [self updateProgressHUDWithMessage:msg detailsMessage:nil];
    } else if([keyPath isEqualToString:@"downloadedPercent"]) {
        // TODO: NSKeyValueChangeNewKey
        //AppLog(@"xxx : %d", [[change objectForKey:@"NSKeyValueChangeNewKey"] intValue]);
        
        NSString *msg = [NSString stringWithFormat:@"%lu%%", (unsigned long)_downloadedPercent];
        if (self.downloadedFileNumber) {
            [self updateProgressHUDWithMessage:nil detailsMessage:msg];
        }
    }
}

#if USE_SYSTEM_IOS7_IMPLEMENTATION
#pragma mark - UIActionSheetDelegate

- (void)actionSheet         :(UIActionSheet *)actionSheet
        clickedButtonAtIndex:(NSInteger)buttonIndex
{
    AppLog(@"%s", __func__);
    _actionSheet = nil;
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
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    _popController = nil;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    AppLog(@"%s", __func__);
    NSUInteger count = _collDataArray.count;
    
    if (count > 0 && !_enableHeader) {
        count = 1;
    }
    
    AppLog(@"numberOfSectionsInCollectionView: %lu", (unsigned long)count);
    return count;
}

- (NSInteger) collectionView        :(UICollectionView *)collectionView
              numberOfItemsInSection:(NSInteger)section
{
    AppLog(@"%s", __func__);
    WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(section)] objectForKey:@(SectionDataTable)];
    NSInteger num = fileTable.fileList.size();
    AppLog(@"numberOfItemsInSection: %ld", (long)num);
    return num;
}

- (void)setCellTag:(MpbCollectionViewCell *)cell
         indexPath:(NSIndexPath *)indexPath {
    if ([_selItemsTable.selectedCells containsObject:indexPath]) {
        [cell setSelectedConfirmIconHidden:NO];
        cell.tag = 1;
    } else {
        [cell setSelectedConfirmIconHidden:YES];
        cell.tag = 0;
    }
}
/*
 - (WCFileType)calcType:(int)sectionType
 cell:(MpbCollectionViewCell *)cell
 indexPath:(NSIndexPath *)indexPath
 {
 WCFileType type = WCFileTypeUnknow;
 switch (sectionType) {
 case WCFileTypeVideo:
 type = WCFileTypeVideo;
 [cell setVideoStaticIconHidden:NO];
 [self setCellTag:cell indexPath:indexPath withType:WCFileTypeVideo];
 break;
 case WCFileTypeImage:
 type = WCFileTypeImage;
 [cell setVideoStaticIconHidden:YES];
 [self setCellTag:cell indexPath:indexPath withType:WCFileTypeImage];
 break;
 case WCFileTypeAudio:
 type = WCFileTypeAudio;
 [cell setVideoStaticIconHidden:YES];
 [self setCellTag:cell indexPath:indexPath withType:WCFileTypeAudio];
 break;
 case WCFileTypeText:
 type = WCFileTypeText;
 [cell setVideoStaticIconHidden:YES];
 [self setCellTag:cell indexPath:indexPath withType:WCFileTypeText];
 break;
 case WCFileTypeAll:
 [self calcType:[_ctrl.fileCtrl requestFileTypeAtAll:indexPath.item] cell:cell indexPath:indexPath];
 type = WCFileTypeAll;
 default:
 break;
 }
 
 return type;
 }
 */

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MpbCollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:kCellID
                                                                forIndexPath:indexPath];
    //  WCFileType type = WCFileTypeUnknow;
    //  int sectionType = [[[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionType)] intValue];
    //  type = [self calcType:sectionType cell:cell indexPath:indexPath];
    
    WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionDataTable)];
    auto file = fileTable.fileList.at(indexPath.item);
    
    [self setCellTag:cell indexPath:indexPath];
    switch (file->getFileType()) {
        case ICH_FILE_TYPE_IMAGE:
            [cell setVideoStaticIconHidden:YES];
            break;
            
        case ICH_FILE_TYPE_VIDEO:
            [cell setVideoStaticIconHidden:NO];
            break;
            
        default:
            break;
    }
    
    NSString *cachedKey = [NSString stringWithFormat:@"ID%d", file->getFileHandle()];
    UIImage *image = [_mpbCache objectForKey:cachedKey];
    
    
    if (image) {
        cell.imageView.image = image;
    } else {
        cell.imageView.image = [UIImage imageNamed:@"empty_photo"];
        
        double delayInSeconds = 0.05;
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(delayTime, _thumbnailQueue, ^{
            if (!_run) {
                AppLog(@"bypass...");
                return;
            }
            
            dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC);
            dispatch_semaphore_wait(_mpbSemaphore, time);
            // Just in case, make sure the cell for this indexPath is still On-Screen.
            __block UICollectionViewCell *tempCell = nil;
            dispatch_sync(dispatch_get_main_queue(), ^{
                tempCell = [cv cellForItemAtIndexPath:indexPath];
            });
            
//            dispatch_async(dispatch_get_main_queue(), ^{
                if (/*[cv cellForItemAtIndexPath:indexPath]*/tempCell) {
                    UIImage *image = [_ctrl.fileCtrl requestThumbnail:file];
                    if (image) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [_mpbCache setObject:image forKey:cachedKey];
                            MpbCollectionViewCell *c = (MpbCollectionViewCell *)[cv cellForItemAtIndexPath:indexPath];
                            if (c) {
                                c.imageView.image = image;
                            }
                        });
                    } else {
                        AppLog(@"request thumbnail failed");
                    }
                }
//            });
            dispatch_semaphore_signal(_mpbSemaphore);
        });
        
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)cv
           viewForSupplementaryElementOfKind:(NSString *)kind
                                 atIndexPath:(NSIndexPath *)indexPath
{
    AppLog(@"%s", __func__);
    UICollectionReusableView *reusableView = nil;
    
    if (_enableHeader && kind == UICollectionElementKindSectionHeader) {
        
        MpbCollectionHeaderView *headerView = [cv dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                     withReuseIdentifier:@"headerView"
                                                                            forIndexPath:indexPath];
        WifiCamFileTable *dataTable = [[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionDataTable)];
        NSInteger totalNum = dataTable.fileList.size();
        if (totalNum > 0) {
            
            headerView.title.text = [NSString stringWithFormat:@"%@ : %ld",
                                     [[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionTitle)],
                                     (long)totalNum];
            
        } else {
            int type = [[[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionType)] intValue];
            headerView.title.text = [_staticData.noFileNoticeDict objectForKey:@(type)];
            if (!headerView.title.text) {
                headerView.title.text = NSLocalizedString(@"No files", nil);
            }
        }
        
        reusableView = headerView;
    } else if (_enableFooter && kind == UICollectionElementKindSectionFooter) {
        // ...
    }
    
    if (reusableView) {
        return reusableView;
    } else {
        AppLog(@"Some exception message for unexpected tableView");
        abort();
    }
}


#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout*)collectionViewLayout
referenceSizeForHeaderInSection:(NSInteger)section
{
    AppLog(@"%s", __func__);
    if (_enableHeader && _totalCount > 0) {
        return CGSizeMake(self.collectionView.bounds.size.width, 50);
    } else {
        return CGSizeMake(0, 0);
    }
}

-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout
referenceSizeForFooterInSection:(NSInteger)section
{
    AppLog(@"%s", __func__);
    if (_enableFooter && _totalCount > 0) {
        return CGSizeMake(self.collectionView.bounds.size.width, 50);
    } else {
        return CGSizeMake(0, 0);
    }
}


#pragma mark - UICollectionViewDelegate

- (void)photoSinglePlaybackCallback:(NSIndexPath *)indexPath {
    self.browser = [_ctrl.fileCtrl createOneMWPhotoBrowserWithDelegate:self];
    [_browser setCurrentPhotoIndex:indexPath.item];
    
    [self.navigationController pushViewController:self.browser animated:YES];
//    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:_browser];
//    nc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
//    [self presentViewController:nc animated:YES completion:nil];
}

- (void)videoSinglePlaybackCallback:(NSIndexPath *)indexPath
{
    AppLog(@"%s", __func__);
    if (![_ctrl.fileCtrl isVideoPlaybackEnabled]) {
        [self showProgressHUDNotice:NSLocalizedString(@"ShowNoViewVideoTip", nil) showTime:1.0];
        return;
    }
    
    WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionDataTable)];
    auto file = fileTable.fileList.at(indexPath.item);
    
    NSString *cachedKey = [NSString stringWithFormat:@"ID%d", file->getFileHandle()];
    _videoPlaybackIndex = indexPath.item;
    
    UIImage *image = [_mpbCache objectForKey:cachedKey];
    if (!image) {
        dispatch_suspend(_thumbnailQueue);
        
        [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)
                          detailsMessage:nil
                                    mode:MBProgressHUDModeIndeterminate];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (!_run) {
                return;
            }
            
            dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC);
            dispatch_semaphore_wait(_mpbSemaphore, time);
            
            UIImage *image = [_ctrl.fileCtrl requestThumbnail:file];
            if (image != nil) {
                [_mpbCache setObject:image forKey:cachedKey];
            }
            dispatch_semaphore_signal(_mpbSemaphore);
            dispatch_resume(_thumbnailQueue);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                _videoPlaybackThumb = image;
                [self performSegueWithIdentifier:@"PlaybackVideoSegue" sender:nil];
            });
        });
    } else {
        _videoPlaybackThumb = image;
        [self performSegueWithIdentifier:@"PlaybackVideoSegue" sender:nil];
    }
}

- (void)allPlaybackCallback:(NSIndexPath *)indexPath
{
    AppLog(@"%s", __func__);
    WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionDataTable)];
    auto file = fileTable.fileList.at(indexPath.item);
    
    switch (file->getFileType()) {
        case ICH_FILE_TYPE_IMAGE:
            [self photoSinglePlaybackCallback:indexPath];
            break;
            
        case ICH_FILE_TYPE_VIDEO:
            [self videoSinglePlaybackCallback:indexPath];
            break;
            
        default:
            [self nonePlaybackCallback:indexPath];
            break;
    }
}

- (void)nonePlaybackCallback:(NSIndexPath *)indexPath
{
    AppLog(@"%s", __func__);
    [self showProgressHUDCompleteMessage:NSLocalizedString(@"It's not supported yet.", nil)];
}

- (void)collectionView          :(UICollectionView *)cv
        didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AppLog(@"%s", __func__);
    if (_curMpbState == MpbStateNor) {
        NSString *callbackName = [[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionPlaybackCallback)];
        SEL callback = NSSelectorFromString(callbackName);
        if ([self respondsToSelector:callback]) {
            AppLog(@"callback-index: %ld", (long)indexPath.item);
            [self performSelector:callback withObject:indexPath afterDelay:0];
        } else {
            AppLog(@"It's not support to playback this file.");
        }
    } else {
        WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionDataTable)];
        auto file = fileTable.fileList.at(indexPath.item);
        
        /*
         WCFileType type = WCFileTypeUnknow;
         int sectionType = [[[_collDataArray objectForKey:@(indexPath.section)] objectForKey:@(SectionType)] intValue];
         switch (sectionType) {
         case WCFileTypeVideo:
         type = WCFileTypeVideo;
         break;
         
         case WCFileTypeImage:
         type = WCFileTypeImage;
         break;
         
         case WCFileTypeAll:
         type = [_ctrl.fileCtrl requestFileTypeAtAll:indexPath.item];
         break;
         
         case WCFileTypeAudio:
         case WCFileTypeText:
         default:
         break;
         }
         
         NSArray *a = @[indexPath, @(type)];
         */
        //    NSArray *fileCell = @[indexPath, [NSValue valueWithPointer:&file]];
        MpbCollectionViewCell *cell = (MpbCollectionViewCell *)[cv cellForItemAtIndexPath:indexPath];
        if (cell.tag == 1) { // It's selected.
            cell.tag = 0;
            [cell setSelectedConfirmIconHidden:YES];
            [_selItemsTable.selectedCells removeObject:indexPath];
            _totalDownloadSize -= file->getFileSize()>>10;
        } else {
            cell.tag = 1;
            [cell setSelectedConfirmIconHidden:NO];
            [_selItemsTable.selectedCells addObject:indexPath];
            _totalDownloadSize += file->getFileSize()>>10;
        }
        
        self.selItemsTable.count = _selItemsTable.selectedCells.count;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    AppLog(@"%s", __func__);
    if ([[segue identifier] isEqualToString:@"PlaybackVideoSegue"]) {
        UINavigationController *navVC = [segue destinationViewController];
        VideoPlaybackViewController *vpvc = (VideoPlaybackViewController *)navVC.topViewController;
        vpvc.delegate = self;
        vpvc.previewImage = _videoPlaybackThumb;
        vpvc.index = _videoPlaybackIndex;
    }
}

#pragma mark - VideoPlaybackControllerDelegate
-(BOOL)videoPlaybackController:(VideoPlaybackViewController *)controller
            deleteVideoAtIndex:(NSUInteger)index
{
    AppLog(@"%s", __func__);
    NSUInteger i = 0;
    unsigned long listSize = 0;
    BOOL ret = NO;
    
    /*
     if (_enableHeader) {
     WifiCamFileTable *dataTable = [[_collDataArray objectForKey:@(SectionIndexVideo)] objectForKey:@(SectionDataTable)];
     listSize = dataTable.fileList.size();
     file = &(dataTable.fileList.at(index));
     } else {
     listSize = _gallery.videoTable.fileList.size();
     file = &(_gallery.videoTable.fileList.at(index));
     }
     */
    
    listSize = _gallery.videoTable.fileList.size();  
    if (listSize>0) {
        i = MAX(0, MIN(index, listSize - 1));
        auto file = _gallery.videoTable.fileList.at(i);
        ret = [_ctrl.fileCtrl deleteFile:file];
        if (ret) {
            NSString *cachedKey = [NSString stringWithFormat:@"ID%d", file->getFileHandle()];
            [_mpbCache removeObjectForKey:cachedKey];
            [self resetCollectionViewData];
        }
    }
    
    return ret;
}

- (BOOL)videoPlaybackController:(VideoPlaybackViewController *)controller deleteVideoFile:(shared_ptr<ICatchFile>)file {
    AppLog(@"%s", __func__);

    if (file.get() == nullptr) {
        AppLog(@"Video file is empty.");
        return NO;
    }
    
    BOOL ret = [_ctrl.fileCtrl deleteFile:file];
    if (ret) {
        NSString *cachedKey = [NSString stringWithFormat:@"ID%d", file->getFileHandle()];
        [_mpbCache removeObjectForKey:cachedKey];
        [self resetCollectionViewData];
    }
    
    return ret;
}

#pragma mark - MWPhotoBrowserDataSource
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    AppLog(@"%s", __func__);
    /*
     NSUInteger retVal = 0;
     if (_enableHeader) {
     WifiCamFileTable *dataTable = [[_collDataArray objectForKey:@(SectionIndexPhoto)] objectForKey:@(SectionDataTable)];
     retVal = dataTable.fileList.size();
     } else {
     retVal = _gallery.imageTable.fileList.size();
     }
     return retVal;
     */
    return _gallery.imageTable.fileList.size();
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser
                photoAtIndex:(NSUInteger)index
{
    AppLog(@"%s(%ld)", __func__, (unsigned long)index);
    MWPhoto *photo = nil;
    unsigned long listSize = 0;
    /*
     if (_enableHeader) {
     WifiCamFileTable *dataTable = [[_collDataArray objectForKey:@(SectionIndexPhoto)] objectForKey:@(SectionDataTable)];
     listSize = dataTable.fileList.size();
     } else {
     listSize = _gallery.imageTable.fileList.size();
     }
     */
    listSize = _gallery.imageTable.fileList.size();
    auto file = _gallery.imageTable.fileList.at(index);
    
    if (index < listSize) {
        photo = [MWPhoto photoWithURL:[NSURL URLWithString:@"sdk://test"] funcBlock:^{
            return [_ctrl.fileCtrl requestImage:file];
        }];
    }
    
    return photo;
}
/*
- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser
     captionViewForPhotoAtIndex:(NSUInteger)index
{
    MWCaptionView *caption = nil;
    
    return caption;
}
 */
- (void)showShareConfirmForphotoBrowser1
{
    NSIndexPath *ip = [_selItemsTable.selectedCells firstObject];
    WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(ip.section)] objectForKey:@(SectionDataTable)];
    auto f = fileTable.fileList.at(ip.item);
    
    NSString *fileName = [NSString stringWithUTF8String:f->getFileName().c_str()];
    NSArray *tmpDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
    
    self.downloadFileProcessing = YES;
    self.downloadedPercent = 0;
    if (tmpDirectoryContents.count) {
        for (NSString *name in tmpDirectoryContents) {
            if ([name isEqualToString:fileName]) {
                [self.shareFiles addObject:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithUTF8String:f->getFileName().c_str()]]]];
                break;
            } else if ([name isEqualToString:[tmpDirectoryContents lastObject]]) {
                if ([[SDK instance] p_downloadFile:f]) {
                    [self.shareFiles addObject:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithUTF8String:f->getFileName().c_str()]]]];
                }
            }
        }
    } else {
        if ([[SDK instance] p_downloadFile:f]) {
            [self.shareFiles addObject:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithUTF8String:f->getFileName().c_str()]]]];
        }
    }
}

- (void)showShareConfirmForphotoBrowser
{
    NSIndexPath *ip = [_selItemsTable.selectedCells firstObject];
    WifiCamFileTable *fileTable = [[_collDataArray objectForKey:@(ip.section)] objectForKey:@(SectionDataTable)];
    auto f = fileTable.fileList.at(ip.item);
    
    NSString *fileName = [NSString stringWithUTF8String:f->getFileName().c_str()];
    NSString *tmpDirectoryContents = nil;
    if ([fileName hasSuffix:@".MP4"] || [fileName hasSuffix:@".MOV"] || [fileName hasSuffix:@".AVI"]) {
        tmpDirectoryContents = [[SDK instance] createMediaDirectory][2];
    } else {
        tmpDirectoryContents = [[SDK instance] createMediaDirectory][1];
    }
    
    NSString *locatePath = [tmpDirectoryContents stringByAppendingPathComponent:fileName];
    
    BOOL isDir = NO;
    BOOL isDirExist= NO;
    
    isDirExist = [[NSFileManager defaultManager] fileExistsAtPath:locatePath isDirectory:&isDir];
    
    long long tempSize = [DiskSpaceTool fileSizeAtPath:locatePath];
    long long fileSize = f->getFileSize();
    
    if (isDirExist && (tempSize == fileSize)) {
        [self.shareFiles addObject:[NSURL fileURLWithPath:locatePath]];
    } else {
        if (![[SDK instance] openFileTransChannel]) {
            return;
        }
        
        self.downloadFileProcessing = YES;
        self.downloadedPercent = 0;
        
        NSString *path = [[SDK instance] p_downloadFile2:f];
        if (path) {
            [self.shareFiles addObject:[NSURL fileURLWithPath:path]];
        }
        
        if (![[SDK instance] closeFileTransChannel]) {
            return;
        }
    }
}

#pragma mark - MWPhotoBrowserDelegate
-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
    AppLog(@"%s", __func__);
    self.shareFiles = [NSMutableArray array];
//    ICatchFile file = _gallery.imageTable.fileList.at(index);
//    UIImage *image = [_ctrl.fileCtrl requestImage:(ICatchFile *)&file];
    [_selItemsTable.selectedCells removeAllObjects];
    [_selItemsTable.selectedCells addObject:[NSIndexPath indexPathForItem:index inSection:SectionIndexPhoto]];
//    UIActivityItemImage *sharedImage = [[UIActivityItemImage alloc] init];
//    [self showActivityViewController:@[sharedImage] delegate:photoBrowser];
}

- (BOOL)photoBrowser      :(MWPhotoBrowser *)photoBrowser
        deletePhotoAtIndex:(NSUInteger)index
{
    AppLog(@"%s", __func__);
    NSUInteger i = 0;
    unsigned long listSize = 0;
    BOOL ret = NO;
    
    /*
     if (_enableHeader) {
     WifiCamFileTable *dataTable = [[_collDataArray objectForKey:@(SectionIndexPhoto)] objectForKey:@(SectionDataTable)];
     listSize = dataTable.fileList.size();
     } else {
     listSize = _gallery.imageTable.fileList.size();
     }
     */
    listSize = _gallery.imageTable.fileList.size();
    if (listSize>0) {
        i = MAX(0, MIN(index, listSize - 1));
        auto file = _gallery.imageTable.fileList.at(i);
        ret = [_ctrl.fileCtrl deleteFile:file];
        if (ret) {
            NSString *cachedKey = [NSString stringWithFormat:@"ID%d", file->getFileHandle()];
            [_mpbCache removeObjectForKey:cachedKey];
            [self resetCollectionViewData];
        }
    }
    
    return ret;
}

-(BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser downloadPhotoAtIndex:(NSUInteger)index
{
    AppLog(@"%s", __func__);
    [self showShareConfirm];
    
    return _downloadFailedCount>0?NO:YES;
}
//-(BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser downloadPhotoAtIndex:(NSUInteger)index
//{
//    AppLog(@"%s", __func__);
//    NSInteger downloadFailedCount = 0;
//    NSArray *resultArray = nil;
//    UIBackgroundTaskIdentifier downloadTask;
//    
//    [_ctrl.fileCtrl resetBusyToggle:YES];
//    // -- Request more time to excute task within background
//    UIApplication  *app = [UIApplication sharedApplication];
//    downloadTask = [app beginBackgroundTaskWithExpirationHandler: ^{
//        
//        AppLog(@"-->Expiration");
//        NSArray *oldNotifications = [app scheduledLocalNotifications];
//        // Clear out the old notification before scheduling a new one
//        if ([oldNotifications count] > 5) {
//            [app cancelAllLocalNotifications];
//        }
//    }];
//    
////    resultArray = [self downloadSelectedFiles];
//    resultArray = [self shareSelectedFiles];
//    downloadFailedCount = [resultArray[2] integerValue];
//    
//    // Post local notification
//    if (app.applicationState == UIApplicationStateBackground) {
//        NSString *noticeMessage;
//        if (downloadFailedCount > 0) {
//            noticeMessage = NSLocalizedString(@"Download Failed.", @"Download failed.");
//        } else {
//            noticeMessage = NSLocalizedString(@"SavePhotoToAlbum", @"Download complete.");
//        }
//        [_ctrl.comCtrl scheduleLocalNotice:noticeMessage];
//    }
//    [_ctrl.fileCtrl resetBusyToggle:NO];
//    [[UIApplication sharedApplication] endBackgroundTask:downloadTask];
//    
//    return downloadFailedCount>0?NO:YES;
//}

-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser sharePhotoAtIndex:(NSUInteger)index serviceType:(NSString *)serviceType{
    AppLog(@"%s", __func__);
    [self showSLComposeViewController:serviceType];
}

-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser shareImageAtIndex:(NSUInteger)index {
    AppLog(@"%s", __func__);
//    [self showShareConfirm];
    [self showUIActivityViewController:photoBrowser.actionButton];
}

-(void)shareImage:(MWPhotoBrowser *)photoBrowser {
    AppLog(@"%s", __func__);
    [self showShareConfirmForphotoBrowser];;
}

- (void)panCamSDKinit {
    [[PanCamSDK instance] initImage];
}

- (BOOL)changePanoramaType:(int)panoramaType {
    return [[PanCamSDK instance] changePanoramaType:panoramaType isStream:NO];
}

- (void)createICatchImage:(UIImage *)image {
    [[PanCamSDK instance] panCamcreateICatchImage:image];
}

- (void)configureGLKView:(int)width andHeight:(int)height {
    //[[PanCamSDK instance] panCamSetViewPort:width andHeight:height];
    [[PanCamSDK instance] panCamSetViewPort:0 andY:44 andWidth:width andHeight:height - 88];
    [[PanCamSDK instance] panCamRender];
}

- (void)rotate:(CGPoint) pointC andPointPre:(CGPoint)pointP {
    [[PanCamSDK instance] panCamRotate:pointC andPointPre:pointP andType:PCFileTypeImage];
}

- (void)rotate:(int)orientation andX:(float)x andY:(float)y andZ:(float)z andTimestamp:(long)timestamp {
    [[PanCamSDK instance] panCamRotate:orientation andSpeedX:x andSpeedY:y andSpeedZ:z andTamp:timestamp andType:PCFileTypeImage];
}

- (void)locate:(float)distance {
    [[PanCamSDK instance] panCamLocate: distance andType:PCFileTypeImage];
}

- (void)panCamSDKDestroy {
//    [[PanCamSDK instance] destroyImage];
    [[PanCamSDK instance] destroypanCamSDK];
}

#pragma mark AppDelegateProtocol
- (void)sdcardRemoveCallback
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showProgressHUDNotice:NSLocalizedString(@"CARD_REMOVED", nil) showTime:2.0];
    });
    
    [self resetCollectionViewDataHandle];
}

- (void)sdcardInCallback {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showProgressHUDNotice:NSLocalizedString(@"CARD_INSERTED", nil) showTime:2.0];
    });
    
    [self resetCollectionViewDataHandle];
}

- (void)resetCollectionViewDataHandle {
    dispatch_async(_thumbnailQueue, ^{
        [self resetCollectionViewData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideProgressHUD:YES];
            
            if (_totalCount > 0) {
                _editButton.enabled = YES;
                _actionButton.enabled = YES;
            } else {
                _editButton.enabled = NO;
                _actionButton.enabled = NO;
                self.browser = nil;
            }
            
            [self.collectionView reloadData];
        });
    });
}

@end
