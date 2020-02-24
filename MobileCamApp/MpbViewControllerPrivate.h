//
//  MpbViewController_MpbViewControllerPrivate.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-2-28.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "MpbViewController.h"
#import "MBProgressHUD.h"
#import "WifiCamCollectionViewSelectedCellTable.h"
#import "AppDelegate.h"
enum MpbState{
  MpbStateNor = 0,
  MpbStateEdit,
};

enum MpbGuiDataElement {
  SectionBaseIndex,
  SectionTitle,
  SectionType,
  SectionDataTable,
//  SectionNumber,
  SectionTotalFileKBytes,
  SectionPlaybackCallback,
};

typedef NS_ENUM(NSInteger, MpbGuiDataSectionIndex) {
  SectionIndexPhoto = 0,
  SectionIndexVideo = 1,
};


@interface MpbViewController ()
<
AppDelegateProtocol
>
@property(weak, nonatomic) IBOutlet UIBarButtonItem *actionButton;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property(strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property(weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property(nonatomic) UIPopoverController *popController;
/**
 *  20160503 zijie.feng
 *  Deprecated !
 */
#if USE_SYSTEM_IOS7_IMPLEMENTATION
//@property(nonatomic) UIActionSheet *actionSheet;
#else
@property(nonatomic) UIAlertController *actionSheet;
#endif
@property(nonatomic) UIActivityViewController *activityViewController;
@property(nonatomic) dispatch_semaphore_t mpbSemaphore;
@property(nonatomic) UIImage *videoPlaybackThumb;
@property(nonatomic) NSUInteger videoPlaybackIndex;
@property(nonatomic, strong) MWPhotoBrowser* browser;
@property(nonatomic) NSMutableDictionary *collDataArray;
@property(nonatomic) NSCache* mpbCache;
@property(nonatomic) MpbState curMpbState;
@property(nonatomic) WifiCamCollectionViewSelectedCellTable *selItemsTable;
@property(nonatomic) NSUInteger totalDownloadFileNumber;
@property(nonatomic) NSUInteger downloadedFileNumber;
@property(nonatomic) NSUInteger downloadedPercent;
@property(nonatomic) NSUInteger downloadedTotalPercent;
@property(nonatomic, getter = isRun) BOOL run;
@property(nonatomic) MBProgressHUD *progressHUD;
@property(nonatomic, getter = isFirstTimeLoaded) BOOL loaded;
@property(nonatomic) unsigned long long totalDownloadSize;
@property(nonatomic) BOOL cancelDownload;
@property(nonatomic) NSUInteger totalCount;
@property(nonatomic) WifiCam *wifiCam;
@property(nonatomic) WifiCamPhotoGallery *gallery;
@property(nonatomic) WifiCamControlCenter *ctrl;
@property(nonatomic) WifiCamStaticData *staticData;
@property(nonatomic) dispatch_queue_t thumbnailQueue;
@property(nonatomic) dispatch_queue_t downloadQueue;
@property(nonatomic) dispatch_queue_t downloadPercentQueue;
@property(nonatomic) BOOL downloadFileProcessing;
@property(nonatomic) NSMutableArray *shareFiles;
@property(nonatomic) NSMutableArray *shareFileType;
@property(nonatomic) NSInteger downloadFailedCount;
@end
