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
@property (nonatomic, assign) NSUInteger totalFileCount;
@property (nonatomic, strong) NSMutableArray<ICatchFileInfo *> *originalFileList;
@property (nonatomic, strong) NSMutableArray<NSString *> *fileDateArray;
@property (nonatomic, assign) BOOL editState;
@property (nonatomic, strong) NSMutableArray<ICatchFileInfo *> *selectedFiles;
@property (nonatomic) unsigned long long totalDownloadSize;

@property (nonatomic, strong) NSArray<ICatchFileGroup *> *groups;
@property (nonatomic, strong, nullable) ICatchFileFilter *fileFilter;
@property (nonatomic, strong) NSArray<ICatchFileInfo *> *filteredFileList;

- (void)clearFileTableData;
- (void)prepareFileGroupData;

@end

NS_ASSUME_NONNULL_END
