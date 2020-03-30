//
//  ICatchFilesTableCell.h
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/9.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ICatchFileInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface ICatchFilesTableCell : UITableViewCell

@property (nonatomic, strong) ICatchFileInfo *fileInfo;
@property (nonatomic, strong) UIImage *thumbnail;
@property (nonatomic, assign) BOOL editState;

@end

NS_ASSUME_NONNULL_END
