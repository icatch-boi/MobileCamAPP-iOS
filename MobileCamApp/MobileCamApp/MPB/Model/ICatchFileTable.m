//
//  ICatchFileTable.m
//  MobileCamApp
//
//  Created by ZJ on 2020/1/15.
//  Copyright © 2020 iCatchTech. All rights reserved.
//

#import "ICatchFileTable.h"

@implementation ICatchFileTable

- (void)clearFileTableData {
    [self.fileList removeAllObjects];
    [self.originalFileList removeAllObjects];
    [self.fileDateArray removeAllObjects];
//    [self.selectedFiles removeAllObjects];
    self.totalFileCount = 0;
    self.totalDownloadSize = 0;
#if 0
    self.groups = [NSArray array];
#else
    [self clearSelectedState];
#endif
}

- (void)clearSelectedState {
    for (ICatchFileGroup *group in self.groups) {
        group.selectedCount = 0;
    }
}

- (void)prepareFileGroupData {
    if (self.fileFilter != nil) {
        [self filterFilesHandle];
        return;
    }
    
    NSMutableArray *temp = [NSMutableArray array];
    
#if 0
    for (NSString *title in self.fileDateArray) {
        ICatchFileGroup *group = [ICatchFileGroup fileGroupWithTitle:title fileInfos:self.fileList[title]];
        group.editState = self.editState;
        if (group != nil) {
            [temp addObject:group];
        }
    }
#else
    for (NSString *title in self.fileDateArray) {
        ICatchFileGroup *group = [self fileGroupWithTitle:title];
        if (group == nil) {
            group = [ICatchFileGroup fileGroupWithTitle:title fileInfos:self.fileList[title]];
        } else {
            [group updateFileInfos:self.fileList[title]];
        }
        
        group.editState = self.editState;
        if (group != nil) {
            [temp addObject:group];
        }
    }
#endif
    
    self.groups = temp.copy;
    self.filteredFileList = self.originalFileList.copy;
}

- (void)setFileFilter:(ICatchFileFilter *)fileFilter {
    _fileFilter = fileFilter;
    
    [self prepareFileGroupData];
}

- (NSString *)stringFromDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH";
    
    return [formatter stringFromDate:date];
}

- (NSDate *)dateFromString:(NSString *)string {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyyMMdd'T'HHmmss";
    
    return [formatter dateFromString:string];
}

- (NSString *)dateTransformFromDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    
    return [formatter stringFromDate:date];
}

- (void)filterFilesHandle {
    NSString *startDateString = self.fileFilter.startDateString;
    NSString *endDateString = self.fileFilter.endDateString;

    AppLog(@"--> startDateString: %@", startDateString);
    AppLog(@"--> endDateString: %@", endDateString);

//    if (startDateString == nil) {
//        startDateString = [self stringFromDate:[NSDate date]];
//    }
    
    if (endDateString.length == 0) {
        endDateString = [self stringFromDate:[NSDate date]];
    }
    
    NSMutableDictionary<NSString *,NSArray<ICatchFileInfo *> *> *fileInfos = [NSMutableDictionary dictionary];
    NSMutableArray<ICatchFileInfo *> *filteredFileList = [NSMutableArray array];
    
    for (ICatchFileInfo *fileInfo in self.originalFileList) {
        NSString *dateString = [NSString stringWithFormat:@"%s", fileInfo.file->getFileDate().c_str()];
        NSDate *date = [self dateFromString:dateString];
        dateString = [self stringFromDate:date];
        
//        AppLog(@"--> dateString: %@", dateString);

        NSComparisonResult startResult = [dateString compare:startDateString];
        NSComparisonResult endResult = [dateString compare:endDateString];
        
        if ((startResult == NSOrderedDescending || startResult == NSOrderedSame) && (endResult == NSOrderedAscending || endResult == NSOrderedSame)) {
            dateString = [self dateTransformFromDate:date];
            
            if ([fileInfos.allKeys containsObject:dateString]) {
                NSMutableArray *files = [NSMutableArray arrayWithArray:fileInfos[dateString]];
                [files addObject:fileInfo];
                fileInfos[dateString] = files.copy;
            } else {
                fileInfos[dateString] = @[fileInfo];
            }
            
            [filteredFileList addObject:fileInfo];
        }
    }
    
    NSMutableArray *temp = [NSMutableArray array];
    NSArray *keys = [fileInfos.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj2 compare:obj1];
    }];
    for (NSString *title in keys) {
        ICatchFileGroup *group = [self fileGroupWithTitle:title];
        if (group == nil) {
            group = [ICatchFileGroup fileGroupWithTitle:title fileInfos:fileInfos[title]];
        } else {
            [group updateFileInfos:fileInfos[title]];
        }
        
        group.editState = self.editState;
        if (group != nil) {
            [temp addObject:group];
        }
    }
    
    AppLog(@"Group count: %lu", (unsigned long)temp.count);
    
    self.groups = temp.copy;
    self.filteredFileList = filteredFileList.copy;
}


- (ICatchFileGroup *)fileGroupWithTitle:(NSString *)title {
    __block ICatchFileGroup *group = nil;
    [self.groups enumerateObjectsUsingBlock:^(ICatchFileGroup * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.title isEqualToString:title]) {
            group = obj;
            *stop = YES;
        }
    }];
    
    return group;
}

- (void)updateFileGroupEditState {
    for (ICatchFileGroup *group in self.groups) {
        group.editState = self.editState;
        
        if (self.editState == false) {
            group.selectedCount = 0;
        }
    }
}

- (void)setEditState:(BOOL)editState {
    _editState = editState;
    
    if (editState == false) {
        [_originalFileList enumerateObjectsUsingBlock:^(ICatchFileInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.selected = false;
        }];
        
        [_selectedFiles removeAllObjects];
    }
    
    [self updateFileGroupEditState];
}

- (NSMutableDictionary<NSString *,NSArray<ICatchFileInfo *> *> *)fileList {
    if (_fileList == nil) {
        _fileList = [NSMutableDictionary dictionary];
    }
    
    return _fileList;
}

- (NSMutableArray<ICatchFileInfo *> *)originalFileList {
    if (_originalFileList == nil) {
        _originalFileList = [NSMutableArray array];
    }
    
    return _originalFileList;
}

- (NSMutableArray<NSString *> *)fileDateArray {
    if (_fileDateArray == nil) {
        _fileDateArray = [NSMutableArray array];
    }
    
    return _fileDateArray;
}

- (NSMutableArray<ICatchFileInfo *> *)selectedFiles {
    if (_selectedFiles == nil) {
        _selectedFiles = [NSMutableArray array];
    }
    
    return _selectedFiles;
}

@end
