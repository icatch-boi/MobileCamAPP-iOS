//
//  ICatchFilesListViewModel.h
//  MobileCamApp
//
//  Created by ZJ on 2020/1/15.
//  Copyright © 2020 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICatchFileTable.h"
#import "ICatchFileFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface ICatchFilesListViewModel : NSObject

@property (nonatomic, strong, readonly) ICatchFileTable *imageTable;
@property (nonatomic, strong, readonly) ICatchFileTable *videoTable;
@property (nonatomic, strong, readonly) ICatchFileTable *emergencyVideoTable;
@property (nonatomic, strong, nullable) ICatchFileFilter *fileFilter;

- (void)requestFileListOfType:(NSUInteger)fileType pullup:(BOOL)pullup takenBy:(NSUInteger)takenBy;

@end

NS_ASSUME_NONNULL_END
