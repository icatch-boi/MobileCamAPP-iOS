//
//  ICatchHomeCollectionCell.h
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/9.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPBCommonHeader.h"

NS_ASSUME_NONNULL_BEGIN

@class ICatchHomeCollectionCell;
@protocol ICatchHomeCollectionCellDelegate <NSObject>

- (void)homeCollectionCell:(ICatchHomeCollectionCell *)cell singleFilePlaybackWithIndexPath:(NSIndexPath *)indexPath;
- (void)pullupRefreshActionWithHomeCollectionCell:(ICatchHomeCollectionCell *)cell;

@end

@interface ICatchHomeCollectionCell : UICollectionViewCell

@property (nonatomic, assign) MPBDisplayWay currentDisplayWay;
@property (nonatomic, strong) ICatchFileTable *currentFileTable;

@property (nonatomic, weak) id<ICatchHomeCollectionCellDelegate> delegate;

-(void)selectAll;
@end

NS_ASSUME_NONNULL_END
