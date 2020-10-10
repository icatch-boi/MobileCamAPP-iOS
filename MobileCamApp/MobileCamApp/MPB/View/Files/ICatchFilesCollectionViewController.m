//
//  ICatchFilesCollectionViewController.m
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/13.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import "ICatchFilesCollectionViewController.h"
#import "ICatchFilesCollectionCell.h"
#import "ICatchFilesReusableView.h"
#import "ZJDataCache.h"
#import <MJRefresh/MJRefresh.h>

@interface ICatchFilesCollectionViewController () <ICatchFilesReusableViewDelegate>

@property (nonatomic) dispatch_queue_t thumbnailQueue;
@property (nonatomic) dispatch_semaphore_t mpbSemaphore;
@property (nonatomic, getter = isRun) BOOL run;

@end

@implementation ICatchFilesCollectionViewController

static NSString * const reuseIdentifier = @"FilesCollectionCell";
static NSString * const kHeaderReuseIdentifier = @"FilesHeaderView";

+ (instancetype)filesCollectionViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Files" bundle:nil];

    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
//    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
    [self setupPullupRefreshView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.run = true;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.run = false;
}

#pragma mark - GUI
- (void)setupPullupRefreshView {
    WEAK_SELF(self);
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        if (weakself.pullupRefreshBlock) {
            weakself.pullupRefreshBlock();
        }
    }];
    
    // 设置文字
    [footer setTitle:@"Click or drag up to refresh" forState:MJRefreshStateIdle];
    [footer setTitle:@"Loading more ..." forState:MJRefreshStateRefreshing];
    [footer setTitle:@"No more data" forState:MJRefreshStateNoMoreData];
    
    // 设置字体
    footer.stateLabel.font = [UIFont systemFontOfSize:15];
    
    // 设置颜色
    footer.stateLabel.textColor = RGB_HEX(0x9b9b9b, 1.0);
    
    // 设置footer
    self.collectionView.mj_footer = footer;
    self.collectionView.mj_footer.ignoredScrollViewContentInsetBottom = iPhoneX ? 34 : 0;
}

- (void)endRefresh {
    if (_currentFileTable.totalFileCount == _currentFileTable.originalFileList.count) {
        [self.collectionView.mj_footer endRefreshingWithNoMoreData];
    } else {
        [self.collectionView.mj_footer endRefreshing];
    }
}

#pragma mark - Data
- (void)setCurrentFileTable:(ICatchFileTable *)currentFileTable {
    _currentFileTable = currentFileTable;
    
    [self.collectionView reloadData];
    
    [self endRefresh];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.currentFileTable.groups.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    ICatchFileGroup *group = self.currentFileTable.groups[section];
    if (group.isVisible) {
        return group.fileInfos.count;
    } else {
        return 0;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ICatchFilesCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    cell.fileInfo = self.currentFileTable.groups[indexPath.section].fileInfos[indexPath.row];
    cell.editState = self.currentFileTable.editState;

    [self setupThumbnailWithCell:cell cellForRowAtIndexPath:indexPath];

    return cell;
}

#pragma mark <UICollectionViewDelegate>
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    ICatchFilesReusableView *reusableView = nil;
    
    if (kind == UICollectionElementKindSectionHeader) {
        reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kHeaderReuseIdentifier forIndexPath:indexPath];

        reusableView.tag = indexPath.section;

        ICatchFileGroup *group = self.currentFileTable.groups[indexPath.section];
        reusableView.group = group;
        reusableView.delegate = self;
    }
    
//    return reusableView;
    if (reusableView) {
        return reusableView;
    } else {
        AppLog(@"Some exception message for unexpected 'UICollectionReusableView'");
        abort();
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:true];
    TRACE();
    
    if (self.currentFileTable.editState) {
        ICatchFileGroup *group = self.currentFileTable.groups[indexPath.section];
        ICatchFileInfo *fileInfo = group.fileInfos[indexPath.row];
        
        fileInfo.selected = !fileInfo.isSelected;
        
        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
        [self selectFileHandleWithFileInfo:fileInfo];
        
        fileInfo.selected ? group.selectedCount++ : group.selectedCount--;
        NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex:indexPath.section];
        [self.collectionView reloadSections:idxSet];
    } else {
        if (self.singleFilePlaybackBlock) {
            self.singleFilePlaybackBlock(indexPath);
        }
    }
}

- (void)selectFileHandleWithFileInfo:(ICatchFileInfo *)fileInfo {
    if (fileInfo.selected) {
        if (![self.currentFileTable.selectedFiles containsObject:fileInfo]) {
            [self.currentFileTable.selectedFiles addObject:fileInfo];
            self.currentFileTable.totalDownloadSize += fileInfo.file->getFileSize()>>10;
        }
    } else {
        if ([self.currentFileTable.selectedFiles containsObject:fileInfo]) {
            [self.currentFileTable.selectedFiles removeObject:fileInfo];
            self.currentFileTable.totalDownloadSize -= fileInfo.file->getFileSize()>>10;
        }
    }
    
    if (self.currentFileTable.selectedFiles.count > 0) {
        [self postButtonStateChangeNotification:YES];
    } else {
        [self postButtonStateChangeNotification:NO];
    }
}

- (void)setupThumbnailWithCell:(ICatchFilesCollectionCell *)cell cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ICatchFileInfo *fileInfo = self.currentFileTable.groups[indexPath.section].fileInfos[indexPath.row];
    
    NSString *cachedKey = [NSString stringWithFormat:@"%s", fileInfo.file->getFileName().c_str()]; //@(fileInfo.file->getFileHandle()).stringValue;
    UIImage *image = [[ZJImageCache sharedImageCache] imageFromCacheForKey:cachedKey];
    if (image) {
        cell.thumbnail = image;
    } else {
        cell.thumbnail = [UIImage imageNamed:@"empty_photo"];
        
        [self requestThumbnailHandleWithFileInfo:fileInfo cellForRowAtIndexPath:indexPath];
    }
}

- (void)requestThumbnailHandleWithFileInfo:(ICatchFileInfo *)fileInfo cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cachedKey = [NSString stringWithFormat:@"%s", fileInfo.file->getFileName().c_str()]; //@(fileInfo.file->getFileHandle()).stringValue;

    double delayInSeconds = 0.05;
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(delayTime, self.thumbnailQueue, ^{
        if (!_run) {
            AppLog(@"bypass...");
            return;
        }
        
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC);
        // Just in case, make sure the cell for this indexPath is still On-Screen.
        dispatch_semaphore_wait(self.mpbSemaphore, time);
        
        __block UICollectionViewCell *tempCell = nil;
        dispatch_sync(dispatch_get_main_queue(), ^{
            tempCell = [self.collectionView cellForItemAtIndexPath:indexPath];
        });
        
        if (tempCell) {
            UIImage *image = [[SDK instance] requestThumbnail:fileInfo.file];
            
            if (image) {
                [[ZJImageCache sharedImageCache] storeImage:image forKey:cachedKey completion:nil];

                dispatch_async(dispatch_get_main_queue(), ^{
                    ICatchFilesCollectionCell *c = (ICatchFilesCollectionCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
                    if (c) {
                        c.thumbnail = image;
                    }
                });
            } else {
                AppLog(@"request thumbnail failed");
            }
        }
        
        dispatch_semaphore_signal(self.mpbSemaphore);
    });
}

- (void)postButtonStateChangeNotification:(BOOL)state
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kActionButtonStateChangeNotification
                                                        object:@(state)];
}

#pragma mark - ICatchGroupHeaderViewDelegate
- (void)groupHeaderViewDidClickTitleButton:(ICatchFilesReusableView *)groupHeaderView {
    // 刷新table view
    //[self.tableView reloadData];
    
    // 局部刷新(只刷新某个组)
    // 创建一个用来表示某个组的对象
    NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex:groupHeaderView.tag];
    
    [self.collectionView reloadSections:idxSet];
}

#pragma mark - Lazy load
- (dispatch_queue_t)thumbnailQueue {
    if (_thumbnailQueue == nil) {
        _thumbnailQueue = dispatch_queue_create("MobileCamApp.GCD.Queue.Playback.Thumbnail", 0);
    }
    
    return _thumbnailQueue;
}

- (dispatch_semaphore_t)mpbSemaphore {
    if (_mpbSemaphore == nil) {
        _mpbSemaphore = dispatch_semaphore_create(1);
    }
    
    return _mpbSemaphore;
}

#pragma mark -
-(void)selectAll {
    if (self.currentFileTable.editState) {
        
        for (int i = 0; i<_currentFileTable.totalFileCount; ++i) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            
            ICatchFileGroup *group = self.currentFileTable.groups[indexPath.section];
            ICatchFileInfo *fileInfo = group.fileInfos[indexPath.row];
            
            fileInfo.selected = !fileInfo.isSelected;
            
            //        [collectionView reloadItemsAtIndexPaths:@[indexPath]];
            [self selectFileHandleWithFileInfo:fileInfo];
            
            fileInfo.selected ? group.selectedCount++ : group.selectedCount--;
            //        NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex:indexPath.section];
            //        [self.collectionView reloadSections:idxSet];
        }
        [self.collectionView reloadData];
    }
}

@end
