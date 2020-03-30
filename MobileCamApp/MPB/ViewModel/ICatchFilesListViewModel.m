//
//  ICatchFilesListViewModel.m
//  MobileCamApp
//
//  Created by ZJ on 2020/1/15.
//  Copyright © 2020 iCatchTech. All rights reserved.
//

#import "ICatchFilesListViewModel.h"

static const int kOnceRequestMaxNumber = 20;
static NSString * const kOriginalDateFormat = @"yyyyMMdd'T'HHmmss"; //@"yyyyMMdd'T'HH:mm:ss.SSS'Z'";
static NSString * const kCurrentDateFormat = @"yyyy-MM-dd";

@interface ICatchFilesListViewModel ()

@property (nonatomic, strong) ICatchFileTable *imageTable;
@property (nonatomic, strong) ICatchFileTable *videoTable;
@property (nonatomic, strong) ICatchFileTable *emergencyVideoTable;
@property (nonatomic, strong) WifiCam *wifiCam;

@end

@implementation ICatchFilesListViewModel

- (void)requestFileListOfType:(NSUInteger)fileType pullup:(BOOL)pullup takenBy:(NSUInteger)takenBy {
    if ([self capableOf:WifiCamAbilityDefaultToPlayback]) {
        [[SDK instance] setFileListAttribute:fileType order:0x01 takenBy:takenBy];
    }
    
    vector<shared_ptr<ICatchFile>> allList;
    
    vector<shared_ptr<ICatchFile>> photoList;
    
    vector<shared_ptr<ICatchFile>> videoList;
    
    int startIndex = 1;
    int endIndex = kOnceRequestMaxNumber;

    if (![self capableOf:WifiCamAbilityDefaultToPlayback] || ![self capableOf:WifiCamAbilityGetFileByPagination] || ![[SDK instance] checkCameraCapabilities:ICH_CAM_SUPPORT_GET_FILE_BY_PAGINATION]) {
        pullup = NO;
    }
    
    switch (fileType) {
            // video
        case 0x11:
            if (!pullup) {
#if 1
                [self.videoTable clearFileTableData];
#else
                if (self.videoTable.fileList.count != 0) {
                    return;
                }
#endif
                if ([self capableOf:WifiCamAbilityDefaultToPlayback]) {
                    self.videoTable.totalFileCount = [[SDK instance] requestFileCount];
                }
                
                endIndex = MIN((int)self.videoTable.totalFileCount, endIndex);
            } else {
                size_t currentCount = self.videoTable.originalFileList.count;
                startIndex += currentCount;
                if (self.videoTable.totalFileCount > currentCount + kOnceRequestMaxNumber) {
                    endIndex = int(currentCount + kOnceRequestMaxNumber);
                } else if (self.videoTable.totalFileCount > currentCount) {
                    endIndex = (int)self.videoTable.totalFileCount;
                } else {
                    return;
                }
            }
            break;
        case 0x21:
            if (!pullup) {
#if 1
                [self.emergencyVideoTable clearFileTableData];
#else
                if (self.emergencyVideoTable.fileList.count != 0) {
                    return;
                }
#endif
                if ([self capableOf:WifiCamAbilityDefaultToPlayback]) {
                    self.emergencyVideoTable.totalFileCount = [[SDK instance] requestFileCount];
                }
                endIndex = MIN((int)self.emergencyVideoTable.totalFileCount, endIndex);
            } else {
                size_t currentCount = self.emergencyVideoTable.originalFileList.count;
                startIndex += currentCount;
                if (self.emergencyVideoTable.totalFileCount > currentCount + kOnceRequestMaxNumber) {
                    endIndex = int(currentCount + kOnceRequestMaxNumber);
                } else if (self.emergencyVideoTable.totalFileCount > currentCount) {
                    endIndex = (int)self.emergencyVideoTable.totalFileCount;
                } else {
                    return;
                }
            }
            break;
            
            // image
        case 0x12:
            if (!pullup) {
#if 1
                [self.imageTable clearFileTableData];
#else
                if (self.imageTable.fileList.count != 0) {
                    return;
                }
#endif
                if ([self capableOf:WifiCamAbilityDefaultToPlayback]) {
                    self.imageTable.totalFileCount = [[SDK instance] requestFileCount];
                }
                endIndex = MIN((int)self.imageTable.totalFileCount, endIndex);
            } else {
                size_t currentCount = self.imageTable.originalFileList.count;
                startIndex += currentCount;
                if (self.imageTable.totalFileCount > currentCount + kOnceRequestMaxNumber) {
                    endIndex = int(currentCount + kOnceRequestMaxNumber);
                } else if (self.imageTable.totalFileCount > currentCount) {
                    endIndex = (int)self.imageTable.totalFileCount;
                } else {
                    return;
                }
            }
            break;
        case 0x22:
            break;
            
            // media
        case 0x13:
        case 0x23:
            break;
            
        case 0xff:
            break;
            
        default:
            break;
    }
    
    [self requestFileListOfType:fileType startIndex:startIndex endIndex:endIndex];
}

- (void)requestFileListOfType:(NSUInteger)fileType startIndex:(int)startIndex endIndex:(int)endIndex
{
    ICatchFileTable *tempTable;
    WCFileType wcFileType;
        
    switch (fileType) {
        case 0x11:
            tempTable = self.videoTable;
            wcFileType = WCFileTypeVideo;
            break;
            
        case 0x12:
            tempTable = self.imageTable;
            wcFileType = WCFileTypeImage;
            break;
            
        case 0x21:
            tempTable = self.emergencyVideoTable;
            wcFileType = WCFileTypeVideo;
            break;
            
        default:
            wcFileType = WCFileTypeUnknow;
            break;
    }
    
//    vector<shared_ptr<ICatchFile>> fileList = [[SDK instance] requestFileListOfType:wcFileType];
    AppLog(@"Start getFileList from startIndex: %d to endIndex: %d", startIndex, endIndex);
//    vector<shared_ptr<ICatchFile>> fileList = [[SDK instance] requestFileListOfType:wcFileType startIndex:startIndex endIndex:endIndex];
    vector<shared_ptr<ICatchFile>> fileList;
    if ([self capableOf:WifiCamAbilityDefaultToPlayback] && [self capableOf:WifiCamAbilityGetFileByPagination] && [[SDK instance] checkCameraCapabilities:ICH_CAM_SUPPORT_GET_FILE_BY_PAGINATION]) {
        fileList = [[SDK instance] requestFileListOfType:wcFileType startIndex:startIndex endIndex:endIndex];
    } else {
        fileList = [[SDK instance] requestFileListOfType:wcFileType];
    }
    AppLog(@"End getFileList, file count: %lu", fileList.size());

   for (vector<shared_ptr<ICatchFile>>::iterator it = fileList.begin(); it != fileList.end(); ++it) {
       auto f = *it;
       // 20160219T000000
       // @"yyyyMMdd'T'HHmmss"
       NSString *dateString = [self dateTransformFromString:[NSString stringWithUTF8String:f->getFileDate().c_str()]];
       ICatchFileInfo *fileInfo = [ICatchFileInfo fileInfoWithFile:f];
       
       if ([tempTable.fileList.allKeys containsObject:dateString]) {
           NSMutableArray *files = [NSMutableArray arrayWithArray:tempTable.fileList[dateString]];
           [files addObject:fileInfo];
           tempTable.fileList[dateString] = files.copy;
       } else {
           tempTable.fileList[dateString] = @[fileInfo];
       }
       
       [tempTable.originalFileList addObject:fileInfo];
       
       if (![tempTable.fileDateArray containsObject:dateString]) {
           [tempTable.fileDateArray addObject:dateString];
       }
   }
    
    if (![self capableOf:WifiCamAbilityDefaultToPlayback]) {
        tempTable.totalFileCount = fileList.size();
    }
    
    [tempTable prepareFileGroupData];
}

- (NSString *)dateTransformFromString:(NSString *)originalDateStr {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:kOriginalDateFormat];
    NSDate *originalDate = [formatter dateFromString:originalDateStr];
    
    [formatter setDateFormat:kCurrentDateFormat];
    
    return [formatter stringFromDate:originalDate];
}

- (void)setFileFilter:(ICatchFileFilter *)fileFilter {
    _fileFilter = fileFilter;
    
    self.imageTable.fileFilter = fileFilter;
    self.videoTable.fileFilter = fileFilter;
    self.emergencyVideoTable.fileFilter = fileFilter;
}

#pragma mark - Init
- (ICatchFileTable *)imageTable {
    if (_imageTable == nil) {
        _imageTable = [[ICatchFileTable alloc] init];
    }
    
    return _imageTable;
}

- (ICatchFileTable *)videoTable {
    if (_videoTable == nil) {
        _videoTable = [[ICatchFileTable alloc] init];
    }
    
    return _videoTable;
}

- (ICatchFileTable *)emergencyVideoTable {
    if (_emergencyVideoTable == nil) {
        _emergencyVideoTable = [[ICatchFileTable alloc] init];
    }
    
    return _emergencyVideoTable;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        WifiCamManager *app = [WifiCamManager instance];
        self.wifiCam = [app.wifiCams objectAtIndex:0];
    }
    return self;
}

- (BOOL)capableOf:(WifiCamAbility)ability
{
//    return (self.wifiCam.camera.ability & ability) == ability ? YES : NO;
    return [_wifiCam.camera.ability containsObject:@(ability)];
}

@end
