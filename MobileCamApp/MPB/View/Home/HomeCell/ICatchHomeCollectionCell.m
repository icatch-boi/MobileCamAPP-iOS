//
//  ICatchHomeCollectionCell.m
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/9.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import "ICatchHomeCollectionCell.h"
#import "ICatchFilesTableViewController.h"
#import "ICatchFilesCollectionViewController.h"

@interface ICatchHomeCollectionCell ()

@property (nonatomic, strong) ICatchFilesTableViewController *filesTableView;
@property (nonatomic, strong) ICatchFilesTableViewController *filesNoIconTableView;
@property (nonatomic, strong) ICatchFilesCollectionViewController *filesCollectionView;
@property (nonatomic, weak) UIViewController *currentViewController;

@end

@implementation ICatchHomeCollectionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
//    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Files" bundle:nil];
//
//#if 0
//    self.filesTableView = [sb instantiateInitialViewController];
//
//    [self.contentView addSubview:self.filesTableView.view];
//#else
//    self.filesCollectionView = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([ICatchFilesCollectionViewController class])];
//    [self.contentView addSubview:self.filesCollectionView.view];
//#endif
    [self setupGUI];
}

#pragma mark - GUI
- (void)setupGUI {
    self.currentViewController = self.filesTableView;
    [self.contentView addSubview:self.currentViewController.view];
}

- (ICatchFilesTableViewController *)filesTableView {
    if (_filesTableView == nil) {
        _filesTableView = [ICatchFilesTableViewController filesTableViewControllerWithReuseIdentifier:@"FilesTableCellID"];
        
        WEAK_SELF(self);
        _filesTableView.singleFilePlaybackBlock = ^(NSIndexPath * _Nonnull indexPath) {
            if ([weakself.delegate respondsToSelector:@selector(homeCollectionCell:singleFilePlaybackWithIndexPath:)]) {
                [weakself.delegate homeCollectionCell:weakself singleFilePlaybackWithIndexPath:indexPath];
            }
        };
        _filesTableView.pullupRefreshBlock = ^{
            if ([weakself.delegate respondsToSelector:@selector(pullupRefreshActionWithHomeCollectionCell:)]) {
                [weakself.delegate pullupRefreshActionWithHomeCollectionCell:weakself];
            }
        };
    }
    
    return _filesTableView;
}

- (ICatchFilesTableViewController *)filesNoIconTableView {
    if (_filesNoIconTableView == nil) {
        _filesNoIconTableView = [ICatchFilesTableViewController filesTableViewControllerWithReuseIdentifier:@"FilesTableCellID1"];
        
        WEAK_SELF(self);
        _filesNoIconTableView.singleFilePlaybackBlock = ^(NSIndexPath * _Nonnull indexPath) {
            if ([weakself.delegate respondsToSelector:@selector(homeCollectionCell:singleFilePlaybackWithIndexPath:)]) {
                [weakself.delegate homeCollectionCell:weakself singleFilePlaybackWithIndexPath:indexPath];
            }
        };
        _filesNoIconTableView.pullupRefreshBlock = ^{
            if ([weakself.delegate respondsToSelector:@selector(pullupRefreshActionWithHomeCollectionCell:)]) {
                [weakself.delegate pullupRefreshActionWithHomeCollectionCell:weakself];
            }
        };
    }
    
    return _filesNoIconTableView;
}

- (ICatchFilesCollectionViewController *)filesCollectionView {
    if (_filesCollectionView == nil) {
        _filesCollectionView = [ICatchFilesCollectionViewController filesCollectionViewController];
        
        WEAK_SELF(self);
        _filesCollectionView.singleFilePlaybackBlock = ^(NSIndexPath *indexPath) {
            if ([weakself.delegate respondsToSelector:@selector(homeCollectionCell:singleFilePlaybackWithIndexPath:)]) {
                [weakself.delegate homeCollectionCell:weakself singleFilePlaybackWithIndexPath:indexPath];
            }
        };
        _filesCollectionView.pullupRefreshBlock = ^{
            if ([weakself.delegate respondsToSelector:@selector(pullupRefreshActionWithHomeCollectionCell:)]) {
                [weakself.delegate pullupRefreshActionWithHomeCollectionCell:weakself];
            }
        };
    }
    
    return _filesCollectionView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 让控制器的view 的大小和cell的大小一样
//    self.filesTableView.view.frame = self.bounds;
//    self.filesCollectionView.view.frame = self.bounds;
    self.currentViewController.view.frame = self.bounds;
}

#pragma mark - Data
- (void)setCurrentFileTable:(ICatchFileTable *)currentFileTable {
    _currentFileTable = currentFileTable;
    
    switch (self.currentDisplayWay) {
        case MPBDisplayWayTable:
        case MPBDisplayWayNoIconTable: {
            ICatchFilesTableViewController *vc = (ICatchFilesTableViewController *)self.currentViewController;
            vc.currentFileTable = currentFileTable;
        }
            break;
            
        case MPBDisplayWayCollection: {
            ICatchFilesCollectionViewController *vc = (ICatchFilesCollectionViewController *)self.currentViewController;
            vc.currentFileTable = currentFileTable;
        }
            break;
            
        default:
            break;
    }
}

- (void)setCurrentDisplayWay:(MPBDisplayWay)currentDisplayWay {
    if (currentDisplayWay == _currentDisplayWay) {
        return;
    }
    
    _currentDisplayWay = currentDisplayWay;
    
    [self changeDisplayWay];
}

- (void)changeDisplayWay {
    [self.currentViewController.view removeFromSuperview];
    
    switch (self.currentDisplayWay) {
        case MPBDisplayWayTable:
            self.currentViewController = self.filesTableView;
            break;
            
        case MPBDisplayWayNoIconTable:
            self.currentViewController = self.filesNoIconTableView;
            break;
            
        case MPBDisplayWayCollection:
            self.currentViewController = self.filesCollectionView;
            break;
            
        default:
            break;
    }
    
    [self.contentView addSubview:self.currentViewController.view];
    [self layoutSubviews];
}

#pragma mark -
-(void)selectAll{
    if (self.currentViewController == self.filesTableView
        || self.currentViewController == self.filesNoIconTableView) {
        [self.filesTableView selectAll];
    } else if(self.currentViewController == self.filesCollectionView) {
        [self.filesCollectionView selectAll];
    }
}

@end
