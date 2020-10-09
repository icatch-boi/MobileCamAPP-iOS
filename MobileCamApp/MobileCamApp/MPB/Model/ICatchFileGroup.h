//
//  ICatchFileGroup.h
//  MobileCamApp
//
//  Created by zj on 2020/2/14.
//  Copyright © 2020 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICatchFileInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface ICatchFileGroup : NSObject

@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, strong, readonly) NSArray<ICatchFileInfo *> *fileInfos;

// 表示这个组是否可见
@property (nonatomic, assign, getter=isVisible) BOOL visible;

@property (nonatomic, assign) BOOL editState;
@property (nonatomic, assign) NSUInteger selectedCount;

+ (instancetype)fileGroupWithTitle:(NSString *)title fileInfos:(NSArray<ICatchFileInfo *> *)fileInfos;
- (void)updateFileInfos:(NSArray<ICatchFileInfo *> *)fileInfos;

@end

NS_ASSUME_NONNULL_END
