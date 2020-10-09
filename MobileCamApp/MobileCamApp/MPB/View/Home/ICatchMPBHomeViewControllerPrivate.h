//
//  ICatchMPBHomeViewControllerPrivate.h
//  MobileCamApp
//
//  Created by zj on 2020/2/13.
//  Copyright © 2020 iCatchTech. All rights reserved.
//

#import "ICatchMPBHomeViewController.h"

@interface ICatchMPBHomeViewController ()

@property (nonatomic) UIPopoverController *popController;
@property (nonatomic, strong) NSMutableArray *actionFiles;
@property (nonatomic, strong) NSMutableArray *actionFileType;
@property (nonatomic) UIAlertController *actionSheet;
@property (nonatomic) BOOL cancelDownload;
@property (nonatomic) NSUInteger totalDownloadFileNumber;
@property (nonatomic) NSUInteger downloadedFileNumber;
@property (nonatomic) NSUInteger downloadFailedCount;
@property (nonatomic) dispatch_queue_t downloadQueue;
@property (nonatomic) dispatch_queue_t downloadPercentQueue;
@property (nonatomic) BOOL downloadFileProcessing;

@end
