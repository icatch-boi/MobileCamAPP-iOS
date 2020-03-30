//
//  ICatchFilesReusableView.h
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/13.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ICatchFileGroup.h"

NS_ASSUME_NONNULL_BEGIN

@class ICatchFilesReusableView;
@protocol ICatchFilesReusableViewDelegate <NSObject>

- (void)groupHeaderViewDidClickTitleButton:(ICatchFilesReusableView *)groupHeaderView;

@end

@interface ICatchFilesReusableView : UICollectionReusableView

@property (nonatomic, strong) ICatchFileGroup *group;

@property (nonatomic, weak) id<ICatchFilesReusableViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
