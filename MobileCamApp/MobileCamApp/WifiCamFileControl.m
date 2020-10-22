//
//  WifiCamFileControl.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-30.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamFileControl.h"

@implementation WifiCamFileControl

- (UIImage *)requestThumbnail:(shared_ptr<ICatchFile>)f
{
  return [[SDK instance] requestThumbnail:f];
}

- (UIImage *)requestImage:(shared_ptr<ICatchFile>)f
{
  return [[SDK instance] requestImage:f];
}

-(BOOL)downloadFile:(shared_ptr<ICatchFile>)f
{
  return [[SDK instance] downloadFile:f];
}

-(BOOL)downloadFile2:(shared_ptr<ICatchFile>)f
{
    return [[SDK instance] downloadFile2:f];
}

- (NSUInteger)requestDownloadedPercent:(shared_ptr<ICatchFile>)f
{
  float progress = 0;
  NSString *locatePath = nil;
  NSString *fileName = nil;
  NSDictionary *attrs = nil;
  unsigned long long downloadedBytes;
  
  if (f != NULL) {
    fileName = [NSString stringWithUTF8String:f->getFileName().c_str()];
    locatePath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), fileName];
    attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:locatePath error:nil];
    downloadedBytes = [[attrs objectForKey:@"NSFileSize"] longLongValue];
    if (f->getFileSize() > 0) {
      progress = (float)downloadedBytes / (float)f->getFileSize();
    }
  }
  
  return MAX(0, MIN(100, progress*100));
}

-(NSUInteger)requestDownloadedPercent2:(NSString *)locatePath fileSize:(unsigned long long)fileSize
{
  float progress = 0;
  NSDictionary *attrs = nil;
  unsigned long long downloadedBytes = 0;
  
  if (locatePath) {
    attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:locatePath error:nil];
    downloadedBytes = [[attrs objectForKey:@"NSFileSize"] longLongValue];
    if (fileSize > 0) {
      progress = (float)downloadedBytes / (float)fileSize;
    }
//    AppLog(@"downloadedBytes: %llu", downloadedBytes);
  }
  
  return MAX(0, MIN(100, progress*100));
}

-(void)cancelDownload
{
  [[SDK instance] cancelDownload];
}

-(BOOL)deleteFile:(shared_ptr<ICatchFile>)f
{
  return [[SDK instance] deleteFile:f];
}

-(void)tempStoreDataForBackgroundDownload:(NSMutableArray *)downloadArray
{
  SDK *sdk = [SDK instance];
  [sdk.downloadArray setArray:downloadArray];
}

-(NSUInteger)retrieveDownloadedTotalNumber
{
  return [[SDK instance] downloadedTotalNumber];
}

-(void)resetDownoladedTotalNumber
{
  [[SDK instance] setDownloadedTotalNumber:0];
}

-(BOOL)isVideoPlaybackEnabled
{
  return [[SDK instance] videoPlaybackEnabled];
}

-(BOOL)isBusy
{
  BOOL retVal = [[SDK instance] isBusy];
  AppLog(@"isDownloading: %d", retVal);
  return retVal;
}

-(void)resetBusyToggle:(BOOL)value
{
  [[SDK instance] setIsBusy:value];
}

- (MWPhotoBrowser *)createOneMWPhotoBrowserWithDelegate:(id <MWPhotoBrowserDelegate>)delegate
{
  MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:delegate];
  browser.displayActionButton = YES;
  browser.displayNavArrows = YES;
  browser.displaySelectionButtons = NO;
  browser.alwaysShowControls = NO;
  browser.zoomPhotosToFill = YES;
  browser.enableGrid = NO;
  browser.startOnGrid = NO;
  return browser;
}

-(WifiCamCollectionViewSelectedCellTable *)createOneCellsTable
{
  NSMutableArray *array = [[NSMutableArray alloc] init];
  WifiCamCollectionViewSelectedCellTable *cellsTable = \
  [[WifiCamCollectionViewSelectedCellTable alloc] initWithParameters:array
                                                            andCount:0];
  return cellsTable;
}

-(NSCache *)createCacheForMultiPlaybackWithCountLimit:(NSUInteger)countLimit
                                       totalCostLimit:(NSUInteger)totalCostLimit
{
  NSCache *cache = [[NSCache alloc] init];
  [cache setCountLimit:countLimit];       // 100: Magic Number
  [cache setTotalCostLimit:totalCostLimit];  // 4096: Magic Number
  return cache;
}


@end
