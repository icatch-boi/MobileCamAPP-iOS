// ICatchGroupHeaderView.h

/**************************************************************************
 *
 *       Copyright (c) 2014-2019 by iCatch Technology, Inc.
 *
 *  This software is copyrighted by and is the property of iCatch
 *  Technology, Inc.. All rights are reserved by iCatch Technology, Inc..
 *  This software may only be used in accordance with the corresponding
 *  license agreement. Any unauthorized use, duplication, distribution,
 *  or disclosure of this software is expressly forbidden.
 *
 *  This Copyright notice MUST not be removed or modified without prior
 *  written consent of iCatch Technology, Inc..
 *
 *  iCatch Technology, Inc. reserves the right to modify this software
 *  without notice.
 *
 *  iCatch Technology, Inc.
 *  19-1, Innovation First Road, Science-Based Industrial Park,
 *  Hsin-Chu, Taiwan, R.O.C.
 *
 **************************************************************************/
 
 // Created by zj on 2019/7/24 10:23 AM.
    

#import <UIKit/UIKit.h>
#import "ICatchFileGroup.h"

NS_ASSUME_NONNULL_BEGIN

@class ICatchGroupHeaderView;
@protocol ICatchGroupHeaderViewDelegate <NSObject>

- (void)groupHeaderViewDidClickTitleButton:(ICatchGroupHeaderView *)groupHeaderView;

@end

@interface ICatchGroupHeaderView : UITableViewHeaderFooterView

@property (nonatomic, strong) ICatchFileGroup *group;

@property (nonatomic, weak) id<ICatchGroupHeaderViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
