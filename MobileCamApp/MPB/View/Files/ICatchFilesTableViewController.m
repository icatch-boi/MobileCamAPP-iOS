//
//  ICatchFilesTableViewController.m
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/9.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import "ICatchFilesTableViewController.h"
#import "ICatchFilesTableCell.h"
#import "ZJDataCache.h"
#import "ICatchGroupHeaderView.h"
#import <MJRefresh/MJRefresh.h>

static NSString * const kReuseIdentifier = @"FilesTableCellID";
static NSString * const kGroupHeaderReuseID = @"GroupHeader";

@interface ICatchFilesTableViewController () <ICatchGroupHeaderViewDelegate>

@property (nonatomic, copy) NSString *reuseIdentifier;

@property (nonatomic) dispatch_queue_t thumbnailQueue;
@property (nonatomic) dispatch_semaphore_t mpbSemaphore;
@property (nonatomic, getter = isRun) BOOL run;

@end

@implementation ICatchFilesTableViewController

+ (instancetype)filesTableViewControllerWithReuseIdentifier:(NSString *)identifier {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Files" bundle:nil];

    ICatchFilesTableViewController *view = [sb instantiateInitialViewController];
    view.reuseIdentifier = (identifier.length != 0) ? identifier : kReuseIdentifier;
    
    return view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self setupGUI];
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
- (void)setupGUI {
    self.tableView.rowHeight = 80;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.backgroundColor = RGB_HEX(0xF2F2F2, 1.0);
    
    [self.tableView registerClass:[ICatchGroupHeaderView class] forHeaderFooterViewReuseIdentifier:kGroupHeaderReuseID];
    
    [self setupPullupRefreshView];
    
    if (@available(iOS 11.0, *)) {
        self.tableView.estimatedRowHeight = 0;
        self.tableView.estimatedSectionFooterHeight = 0;
        self.tableView.estimatedSectionHeaderHeight = 0;
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
}

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
    self.tableView.mj_footer = footer;
    self.tableView.mj_footer.ignoredScrollViewContentInsetBottom = iPhoneX ? 34 : 0;
}

- (void)endRefresh {
    if (_currentFileTable.totalFileCount == _currentFileTable.originalFileList.count) {
        [self.tableView.mj_footer endRefreshingWithNoMoreData];
    } else {
        [self.tableView.mj_footer endRefreshing];
    }
}

#pragma mark - Data
- (void)setCurrentFileTable:(ICatchFileTable *)currentFileTable {
    _currentFileTable = currentFileTable;
    
    [self.tableView reloadData];
    
    [self endRefresh];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.currentFileTable.groups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    ICatchFileGroup *group = self.currentFileTable.groups[section];
    if (group.isVisible) {
        return group.fileInfos.count;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ICatchFilesTableCell *cell = [tableView dequeueReusableCellWithIdentifier:self.reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    cell.fileInfo = self.currentFileTable.groups[indexPath.section].fileInfos[indexPath.row];
    cell.editState = self.currentFileTable.editState;
    
    [self setupThumbnailWithCell:cell cellForRowAtIndexPath:indexPath];
    
    return cell;
}

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    return self.currentFileTable.fileDateArray[section];
//}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.reuseIdentifier isEqualToString:@"FilesTableCellID"]) {
        return 80.0;
    } else {
        return 70.0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    TRACE();
    
    if (self.currentFileTable.editState) {
        ICatchFileGroup *group = self.currentFileTable.groups[indexPath.section];
        ICatchFileInfo *fileInfo = group.fileInfos[indexPath.row];
        
        fileInfo.selected = !fileInfo.isSelected;
        
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self selectFileHandleWithFileInfo:fileInfo];
        
        fileInfo.selected ? group.selectedCount++ : group.selectedCount--;
        NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex:indexPath.section];
        [self.tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationNone];
    } else {
        if (self.singleFilePlaybackBlock) {
            self.singleFilePlaybackBlock(indexPath);
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ICatchGroupHeaderView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kGroupHeaderReuseID];
     
    header.tag = section;
     
     ICatchFileGroup *group = self.currentFileTable.groups[section];
     header.group = group;
     header.delegate = self;
     
     return header;
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

- (void)setupThumbnailWithCell:(ICatchFilesTableCell *)cell cellForRowAtIndexPath:(NSIndexPath *)indexPath {
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
        
        __block UITableViewCell *tempCell = nil;
        dispatch_sync(dispatch_get_main_queue(), ^{
            tempCell = [self.tableView cellForRowAtIndexPath:indexPath];
        });
        
        if (tempCell) {
            UIImage *image = [[SDK instance] requestThumbnail:fileInfo.file];
            
            if (image) {
                [[ZJImageCache sharedImageCache] storeImage:image forKey:cachedKey completion:nil];

                dispatch_async(dispatch_get_main_queue(), ^{
                    ICatchFilesTableCell *c = (ICatchFilesTableCell *)[self.tableView cellForRowAtIndexPath:indexPath];
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
- (void)groupHeaderViewDidClickTitleButton:(ICatchGroupHeaderView *)groupHeaderView {
    // 刷新table view
    //[self.tableView reloadData];
    
    // 局部刷新(只刷新某个组)
    // 创建一个用来表示某个组的对象
    NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex:groupHeaderView.tag];
    
    if (self.tableView.style == UITableViewStyleGrouped && groupHeaderView.tag == 0) {
        
        groupHeaderView.group = self.currentFileTable.groups[groupHeaderView.tag];
    }
    
    [self.tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationFade];
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
        
        for(int section = 0; section < self.currentFileTable.groups.count; ++section) {
            ICatchFileGroup *group = self.currentFileTable.groups[section];
            NSInteger rows = 0;
            if (group.isVisible) {
                rows = group.fileInfos.count;
            }
            for (int i = 0; i<rows; ++i) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:section];
                
                ICatchFileGroup *group = self.currentFileTable.groups[indexPath.section];
                ICatchFileInfo *fileInfo = group.fileInfos[indexPath.row];
                
                fileInfo.selected = !fileInfo.isSelected;
                
                //            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self selectFileHandleWithFileInfo:fileInfo];
                
                fileInfo.selected ? group.selectedCount++ : group.selectedCount--;
                //            NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex:indexPath.section];
                //            [self.tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationNone];
            }
        }
        [self.tableView reloadData];
    }
}

@end
