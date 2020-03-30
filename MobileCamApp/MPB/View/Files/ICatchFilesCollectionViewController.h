//
//  ICatchFilesCollectionViewController.h
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/13.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPBCommonHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface ICatchFilesCollectionViewController : UICollectionViewController

@property (nonatomic, strong) ICatchFileTable *currentFileTable;
@property (nonatomic, copy) ICatchSingleFilePlaybackBlock singleFilePlaybackBlock;
@property (nonatomic, copy) ICatchPullupRefreshBlock pullupRefreshBlock;

+ (instancetype)filesCollectionViewController;

@end

NS_ASSUME_NONNULL_END
