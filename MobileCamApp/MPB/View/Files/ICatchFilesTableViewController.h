//
//  ICatchFilesTableViewController.h
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/9.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPBCommonHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface ICatchFilesTableViewController : UITableViewController

@property (nonatomic, strong) ICatchFileTable *currentFileTable;
@property (nonatomic, copy) ICatchSingleFilePlaybackBlock singleFilePlaybackBlock;
@property (nonatomic, copy) ICatchPullupRefreshBlock pullupRefreshBlock;

+ (instancetype)filesTableViewControllerWithReuseIdentifier:(NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
