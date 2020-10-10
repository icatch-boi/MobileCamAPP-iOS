//
//  ICatchFileTable.h
//  MobileCamApp
//
//  Created by ZJ on 2020/1/15.
//  Copyright © 2020 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <map>
#import "ICatchFileInfo.h"
#import "ICatchFileGroup.h"
#import "ICatchFileFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ICatchFileTable : NSObject

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<ICatchFileInfo *> *> *fileList;
@property (nonatomic, strong) NSMutableArray<ICatchFileInfo *> *originalFileList;
@property (nonatomic, strong) NSMutableArray<ICatchFileInfo *> *selectedFiles;
@property (nonatomic, strong) NSMutableArray<NSString *> *fileDateArray;
@property (nonatomic, strong) NSMutableArray<ICatchFileGroup *> *groups;
@property (nonatomic, strong) NSArray<ICatchFileInfo *> *filteredFileList;
@property (nonatomic, assign) NSUInteger totalFileCount;
@property (nonatomic) unsigned long long totalDownloadSize;
@property (nonatomic, assign) BOOL editState;
@property (nonatomic, strong, nullable) ICatchFileFilter *fileFilter;

- (void)clearFileTableData;
- (void)prepareFileGroupData;
@end

NS_ASSUME_NONNULL_END
