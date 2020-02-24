//
//  WifiCamFileControl.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-30.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MWPhotoBrowser.h"
#import "WifiCamCollectionViewSelectedCellTable.h"

@interface WifiCamFileControl : NSObject

-(UIImage *)requestThumbnail:(shared_ptr<ICatchFile>)f;
-(UIImage *)requestImage:(shared_ptr<ICatchFile>)f;
-(BOOL)downloadFile:(shared_ptr<ICatchFile>)f;
-(BOOL)downloadFile2:(shared_ptr<ICatchFile>)f;
-(NSUInteger)requestDownloadedPercent:(shared_ptr<ICatchFile>)f;
-(NSUInteger)requestDownloadedPercent2:(NSString *)locatePath
                              fileSize:(unsigned long long)fileSize;
-(void)cancelDownload;
-(BOOL)deleteFile:(shared_ptr<ICatchFile>)f;


-(void)tempStoreDataForBackgroundDownload:(NSMutableArray *)downloadArray;
-(NSUInteger)retrieveDownloadedTotalNumber;
-(void)resetDownoladedTotalNumber;

-(BOOL)isVideoPlaybackEnabled;
-(BOOL)isBusy;
-(void)resetBusyToggle:(BOOL)value;

-(MWPhotoBrowser *)createOneMWPhotoBrowserWithDelegate:(id <MWPhotoBrowserDelegate>)delegate;
-(WifiCamCollectionViewSelectedCellTable *)createOneCellsTable;
-(NSCache *)createCacheForMultiPlaybackWithCountLimit:(NSUInteger)countLimit
                                       totalCostLimit:(NSUInteger)totalCostLimit;
@end
