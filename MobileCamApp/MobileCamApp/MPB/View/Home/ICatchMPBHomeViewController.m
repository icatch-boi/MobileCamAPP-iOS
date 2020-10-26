//
//  ICatchMPBHomeViewController.m
//  MobileCamApp-MPB
//
//  Created by ZJ on 2019/12/31.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import "ICatchMPBHomeViewController.h"
#import "ICatchFileTypeView.h"
#import "ICatchFilterPopupView.h"
#import "ICatchHomeCollectionCell.h"
#import "PopMenuView.h"
#import "MPBCommonHeader.h"
#import "ICatchFilesListViewModel.h"
#import "VideoPlaybackViewController.h"
#import "ZJDataCache.h"
#import "ICatchMPBHomeViewControllerPrivate.h"
#import "MpbPopoverViewController.h"
#import "DiskSpaceTool.h"
#import "ICatchFileFilter.h"

static const CGFloat kDateViewMinWidth = 60;
static const CGFloat kChangeDisplayWayButtonWidth = 26;

@interface ICatchMPBHomeViewController () <UICollectionViewDataSource, UICollectionViewDelegate, ICatchFileTypeViewDelegate, ICatchHomeCollectionCellDelegate, MWPhotoBrowserDelegate, VideoPlaybackControllerDelegate, AppDelegateProtocol>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *filterButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *actionButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *selectAllButtonItem;

@property (nonatomic, weak) UIButton *changeButton;

@property (nonatomic, strong) NSArray *fileTypes;
@property (nonatomic, assign) int currentIndex;
@property (nonatomic, strong) NSArray *displayWayItems;
@property (nonatomic, assign) MPBDisplayWay currentDisplayWay;
@property (nonatomic, strong) ICatchFilesListViewModel *listViewModel;
@property (nonatomic, strong) dispatch_queue_t thumbnailQueue;

@property (nonatomic, strong) WifiCam *wifiCam;
@property (nonatomic, strong) WifiCamControlCenter *ctrl;
@property (nonatomic, strong) MWPhotoBrowser *browser;
@property (nonatomic, strong) ICatchFileTable *currentFileTable;
@property (nonatomic) MBProgressHUD *progressHUD;
@property (nonatomic) UIImage *videoPlaybackThumb;
@property (nonatomic) NSUInteger downloadedPercent;
@property (nonatomic) dispatch_semaphore_t mpbSemaphore;
@property (nonatomic, getter = isRun) BOOL run;
@property (nonatomic, strong) ICatchFileFilter *fileFilter;
@property (nonatomic, assign) NSUInteger takenBy;

@end

@implementation ICatchMPBHomeViewController

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self prepareData];
    [self setupGUI];
    [self setupLocalizedString];
    [self addObserver];
}

- (void)dealloc {
    [self removeObserver];
}

// 当计算好collectionView的大小，再设置cell的大小
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.flowLayout.itemSize = self.collectionView.bounds.size;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];

    if(self.currentFileTable.totalFileCount == 0) {
        [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)
                          detailsMessage:nil mode:MBProgressHUDModeIndeterminate];
        
        dispatch_async(self.thumbnailQueue, ^{
            [self.listViewModel requestFileListOfType:[self fileTypeMap]
                                               pullup:NO
                                              takenBy:self.takenBy];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateLayout];
                [self hideProgressHUD:YES];
            });
        });
    } else {
//        [self updateLayout];
        [self.collectionView reloadData];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.run = true;
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.run = false;
    
    [self hideProgressHUD:YES];
}

- (void)setupLocalizedString {
    self.title = NSLocalizedString(@"Albums", @"");
    self.editButtonItem.title = NSLocalizedString(@"Edit", @"");
}

- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buttonStateChangeNotification:) name:kActionButtonStateChangeNotification object:nil];
}

- (void)removeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kActionButtonStateChangeNotification object:nil];
}

- (void)buttonStateChangeNotification:(NSNotification *)nc {
    BOOL state = [nc.object boolValue];

    [self updateButtonEnableState:state];
}

#pragma mark - GUI
- (void)setupGUI {
    [self setupCollectionView];
    [self loadFileTypeView];
    [self setupNavigationItem];
    
    self.toolbar.hidden = YES;
    self.deleteButtonItem.enabled = NO;
    self.actionButtonItem.enabled = NO;
    
    if ([[SDK instance] checkCameraCapabilities:ICH_CAM_NEW_PAGINATION_GET_FILE]) {
        // hide
        self.selectAllButtonItem.enabled = NO;
        self.selectAllButtonItem.title = nil;
    } else {
        // display
        self.selectAllButtonItem.enabled = YES;
        self.selectAllButtonItem.title = NSLocalizedString(@"All", nil);
        self.selectAllButtonItem.tag = 0;
    }
}

- (void)setupNavigationItem {
    UIButton *changeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    changeBtn.frame = CGRectMake(0, 0, kChangeDisplayWayButtonWidth, kChangeDisplayWayButtonWidth);
    [changeBtn addTarget:self action:@selector(changeDisplayWayClick:) forControlEvents:UIControlEventTouchUpInside];
//    [changeBtn setBackgroundImage:[UIImage imageNamed:@"icon_revocation1"] forState:UIControlStateNormal];
    UIImage *image = [UIImage imageNamed:self.displayWayItems.firstObject[@"imageName"]];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [changeBtn setImage:image forState:UIControlStateNormal];
    
    UIBarButtonItem *changeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:changeBtn];
    if ([[SDK instance] checkCameraCapabilities:ICH_CAM_NEW_PAGINATION_GET_FILE]) {
        self.navigationItem.rightBarButtonItems = @[changeButtonItem, self.filterButtonItem];
    } else {
        self.navigationItem.rightBarButtonItems = @[changeButtonItem];
    }
    
    self.changeButton = changeBtn;
    
//    [self.filterButtonItem setImage:[UIImage imageNamed:@"ic_filter_list_white_24dp"]];
}

- (void)setupCollectionView {
    self.flowLayout.itemSize = self.collectionView.bounds.size;
    self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.flowLayout.minimumLineSpacing = 0;
    self.flowLayout.minimumInteritemSpacing = 0;
    self.flowLayout.estimatedItemSize = CGSizeZero;
    
    self.collectionView.pagingEnabled = YES;
    self.collectionView.bounces = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
}

- (void)loadFileTypeView {
    CGFloat marginX = 0;
    CGFloat x = marginX;
    CGFloat h = CGRectGetHeight(self.scrollView.frame);
    CGFloat w = (CGRectGetWidth(self.scrollView.frame) - marginX * self.fileTypes.count) / self.fileTypes.count;
    
    for (int i = 0; i < self.fileTypes.count; i++) {
        ICatchFileTypeView *typeView = [ICatchFileTypeView fileTypeViewWithTitle:self.fileTypes[i]];
        typeView.delegate = self;
        
        [self.scrollView addSubview:typeView];
        
        typeView.frame = CGRectMake(x, 0, MAX(w, kDateViewMinWidth /*dateView.bounds.size.width*/), h);
        x += typeView.bounds.size.width + marginX;
    }
    
    // 设置滚动范围
    self.scrollView.contentSize = CGSizeMake(x, 0);
    self.scrollView.showsHorizontalScrollIndicator = NO;
    
    ICatchFileTypeView *view = self.scrollView.subviews[0];
    view.scale = 1.0;
}

- (void)updateButtonEnableState:(BOOL)enable {
    self.deleteButtonItem.enabled = enable;
    self.actionButtonItem.enabled = enable;
}

//- (void)updateButtonItemState {
//    self.editButtonItem.enabled = self.currentFileTable.filteredFileList.count != 0;
//}

#pragma mark - Load data
- (void)loadDataIsPullup:(BOOL)pullup {
    [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)
                      detailsMessage:nil mode:MBProgressHUDModeIndeterminate];
    
    dispatch_async(self.thumbnailQueue, ^{
        [self.currentFileTable clearFileTableData];
        [self.listViewModel requestFileListOfType:[self fileTypeMap]
                                           pullup:pullup
                                          takenBy:self.takenBy];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideProgressHUD:YES];
            [self.collectionView reloadData];
            
            //[self updateButtonItemState];
        });
    });
}

- (void)prepareData {
    self.currentDisplayWay = MPBDisplayWayTable;
    
    WifiCamManager *app = [WifiCamManager instance];
    self.wifiCam = [app.wifiCams objectAtIndex:0];
    self.ctrl = _wifiCam.controler;
}

- (void)setCurrentDisplayWay:(MPBDisplayWay)currentDisplayWay {
    _currentDisplayWay = currentDisplayWay;
    
    [self.collectionView reloadData];
}

- (void)setCurrentIndex:(int)currentIndex {
    if (_currentIndex == currentIndex) {
        return;
    }
    
    _currentIndex = currentIndex;
    [self loadDataIsPullup:NO];
}

- (NSUInteger)fileTypeMap {
    NSUInteger fileType = 0x11;
#if 0
    switch (_currentIndex) {
        case MPBFileTypeVideo:
            fileType = 0x11;
            break;
            
        case MPBFileTypeImage:
            fileType = 0x12;
            break;
            
        case MPBFileTypeEmergency:
            fileType = 0x21;
            break;
            
        default:
            break;
    }
#else
    NSString *fileTypeStr = self.fileTypes[_currentIndex];
    if ([fileTypeStr isEqualToString:@"Images"]) {
        fileType = 0x12;
    } else if ([fileTypeStr isEqualToString:@"Videos"]) {
        fileType = 0x11;
    }  else if ([fileTypeStr isEqualToString:@"Emergency"]) {
        fileType = 0x21;
    }
#endif
    return fileType;
}

- (void)setFileFilter:(ICatchFileFilter *)fileFilter {
    _fileFilter = fileFilter;
    
    self.listViewModel.fileFilter = fileFilter;
}

- (void)matchCameraTypeWithFilter:(ICatchFileFilter *)fileFilter {
    if (fileFilter.cameraType.length == 0 || [fileFilter.cameraType isEqualToString:NSLocalizedString(@"kAll", nil)]) {
        _takenBy = 0x00;
    } else if ([fileFilter.cameraType isEqualToString:NSLocalizedString(@"kFront", nil)]) {
        _takenBy = 0x01;
    } else if ([fileFilter.cameraType isEqualToString:NSLocalizedString(@"kRear", nil)]) {
        _takenBy = 0x02;
    }
}

- (BOOL)capableOf:(WifiCamAbility)ability
{
//    return (self.wifiCam.camera.ability & ability) == ability ? YES : NO;
    return [_wifiCam.camera.ability containsObject:@(ability)];
}

#pragma mark - Action
- (IBAction)backClick:(id)sender {
    if ([self capableOf:WifiCamAbilityDefaultToPlayback] && [[SDK instance] checkCameraCapabilities:ICH_CAM_APP_DEFAULT_TO_PLAYBACK]) {
           [self.view.window.rootViewController dismissViewControllerAnimated:YES completion: ^{
               [[SDK instance] destroySDK];
               [[PanCamSDK instance] destroypanCamSDK];
           }];
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)editClick:(id)sender {
    self.toolbar.hidden = !self.toolbar.hidden;
    self.editButtonItem.title = self.toolbar.hidden ? NSLocalizedString(@"Edit", @"") : NSLocalizedString(@"Cancel", @"");
    self.title = self.toolbar.hidden ? NSLocalizedString(@"Albums", @"") : NSLocalizedString(@"SelectItem", nil);
    self.navigationItem.leftBarButtonItems = self.toolbar.hidden ? @[self.doneButtonItem, self.editButtonItem] : @[self.editButtonItem];
    
    self.collectionView.scrollEnabled = self.toolbar.hidden;
    self.listViewModel.imageTable.editState = !self.toolbar.hidden;
    self.listViewModel.videoTable.editState = !self.toolbar.hidden;
    self.listViewModel.emergencyVideoTable.editState = !self.toolbar.hidden;
    
    [self.collectionView reloadData];
    
    [self updateButtonEnableState:NO];
    
    if (![[SDK instance] checkCameraCapabilities:ICH_CAM_NEW_PAGINATION_GET_FILE]) {
        if(1 == self.selectAllButtonItem.tag) {
            [self selectAll:self.selectAllButtonItem];
        }
    }
}

- (IBAction)filterClick:(id)sender {
#if 1
    NSArray *dataSource = @[
        @[NSLocalizedString(@"kToday", nil), NSLocalizedString(@"kNearlyThreeDays", nil), NSLocalizedString(@"kNearlyAWeekk", nil), NSLocalizedString(@"kNearlyAMonth", nil), NSLocalizedString(@"kNearlyHalfAYear", nil)],
        @[NSLocalizedString(@"kAll", nil), NSLocalizedString(@"kFront", nil), NSLocalizedString(@"kRear", nil)]
    ];
    
    NSArray *defaultSelValue = @[self.fileFilter.timeBucket ? self.fileFilter.timeBucket : @"",
                                 self.fileFilter.cameraType ? self.fileFilter.cameraType : @"",
    ];
    
    uint sensors = [[SDK instance] numberOfSensors];
    if (sensors == 1) {
        dataSource = @[
            @[NSLocalizedString(@"kToday", nil), NSLocalizedString(@"kNearlyThreeDays", nil), NSLocalizedString(@"kNearlyAWeekk", nil), NSLocalizedString(@"kNearlyAMonth", nil), NSLocalizedString(@"kNearlyHalfAYear", nil)],
        ];
        
        defaultSelValue = @[self.fileFilter.timeBucket ? self.fileFilter.timeBucket : @"",
        ];
    }
#else
    NSArray *dataSource = @[NSLocalizedString(@"kToday", nil), NSLocalizedString(@"kNearlyThreeDays", nil),NSLocalizedString(@"kNearlyAWeekk", nil), NSLocalizedString(@"kNearlyAMonth", nil), NSLocalizedString(@"kNearlyHalfAYear", nil)];
#endif
    
    __weak typeof(self) weakSelf = self;

    [ICatchFilterPopupView showFilterPopupViewWithDataSource:dataSource defaultSelValue:defaultSelValue startDate:self.fileFilter.startDateString endDate:self.fileFilter.endDateString isAutoSelect:YES resultBlock:^(id  _Nonnull selectValue, NSString * _Nullable startDate, NSString * _Nullable endDate, PopupViewState state) {
        AppLog(@"Select item: %@", selectValue);
        AppLog(@"Start date: %@", startDate);
        AppLog(@"End date: %@", endDate);
        
        ICatchFileFilter *fileFilter = nil;
        
        switch (state) {
            case PopupViewStateConfirm:
            case PopupViewStateSelect:
                if ([[selectValue firstObject] length] != 0 ||
                    [[selectValue lastObject] length] != 0 ||
                    startDate.length != 0 || endDate.length != 0) {
                    fileFilter = [[ICatchFileFilter alloc] init];
                    
                    fileFilter.startDateString = startDate;
                    fileFilter.endDateString = endDate;
                    fileFilter.timeBucket = [selectValue firstObject];
                    fileFilter.cameraType = [selectValue count] > 1 ? [selectValue lastObject] : nil;
                }
                
                break;
                
            case PopupViewStateCancel:
                fileFilter = weakSelf.fileFilter;
                
                break;
                
            default:
                break;
        }
        
        weakSelf.currentFileTable.fileFilter = fileFilter;
//#if 0
//        [weakSelf.collectionView reloadData];
//#else
//        [self matchCameraTypeWithFilter:fileFilter];
//         
//         [weakSelf loadDataIsPullup:NO];
//#endif
        if (sensors > 1) {
            [self matchCameraTypeWithFilter:fileFilter];
             
             [weakSelf loadDataIsPullup:NO];
        } else {
            [weakSelf.collectionView reloadData];
        }
        
        if (state == PopupViewStateConfirm) {
            weakSelf.fileFilter = fileFilter;
        }
    }];
}

- (void)changeDisplayWayClick:(UIButton *)sender {
    CGRect rect = [self.navigationController.view convertRect:self.changeButton.frame fromView:self.changeButton.superview];
    NSLog(@"Rect: %@", NSStringFromCGRect(rect));
    
    CGPoint location = CGPointMake(rect.origin.x + CGRectGetWidth(rect) * 0.5, rect.origin.y + CGRectGetHeight(rect));
    __weak typeof(self) weakSelf = self;

    [PopMenuView showWithItems:self.displayWayItems
                         width:[self calcMenuViewWidth]
              triangleLocation:location
            animationDirection:PopMenuAnimationDirectionDown
                        action:^(NSInteger index) {
                            NSLog(@"点击了第%ld行", (long)index);
                            UIImage *image = [UIImage imageNamed:weakSelf.displayWayItems[index][@"imageName"]];
                            image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                            [self.changeButton setImage:image forState:UIControlStateNormal];

                            NSDictionary *dict = weakSelf.displayWayItems[index];
                            if ([dict.allKeys containsObject:@"methodName"]) {
                                NSString *methodName = dict[@"methodName"];
                                SEL action = NSSelectorFromString(methodName);
                                if (action && [weakSelf respondsToSelector:action]) {
                                    [weakSelf performSelector:action withObject:nil afterDelay:0];
                                }
                            }
        
                            if (weakSelf.currentDisplayWay != index) {
                                weakSelf.currentDisplayWay = static_cast<MPBDisplayWay>(index);
                            }
                        }];
}

- (CGFloat)calcMenuViewWidth {
    __weak typeof(self) weakSelf = self;
    __block CGFloat width = [self stringSizeWithString:self.displayWayItems.firstObject[@"title"] font:[UIFont systemFontOfSize:16]].width;
    [self.displayWayItems enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat temp = [weakSelf stringSizeWithString:obj[@"title"] font:[UIFont systemFontOfSize:16]].width;
        width = MAX(temp, width);
    }];
    
    width = 40 + width + 2 * 10;
    
    return width;
}

- (CGSize)stringSizeWithString:(NSString *)str font:(UIFont *)font {
    return [str boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size;
}

- (IBAction)deleteClick:(id)sender {
    [self delete:sender];
}

- (IBAction)actionClick:(id)sender {
    [self showActionConfirm];
}

- (IBAction)selectAll:(id)sender {
    UIBarButtonItem *sel = sender;
    if (0==sel.tag) {
        sel.title = NSLocalizedString(@"Cancel", nil);
    } else {
        sel.title = NSLocalizedString(@"All", nil);
    }
    [self.collectionView reloadData];
    sel.tag = !sel.tag;
    
    NSIndexPath *ip = [NSIndexPath indexPathForItem:0 inSection:0];
    ICatchHomeCollectionCell *cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"MPBHomeCell" forIndexPath:ip];
    [cell selectAll: sel.tag==1?YES:NO];
}

#pragma mark - UICollectonViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.fileTypes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ICatchHomeCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MPBHomeCell" forIndexPath:indexPath];

    cell.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:(indexPath.row + 2) / 10.0];
    cell.currentDisplayWay = self.currentDisplayWay;
#if 0
    switch (indexPath.item) {
        case 0:
            cell.currentFileTable = self.listViewModel.imageTable;
            break;
            
        case 1:
            cell.currentFileTable = self.listViewModel.videoTable;
            break;
        
        case 2:
            cell.currentFileTable = self.listViewModel.emergencyVideoTable;
            break;
            
        default:
            break;
    }
#else
    NSString *fileType = self.fileTypes[indexPath.item];
    if ([fileType isEqualToString:@"Images"]) {
        cell.currentFileTable = self.listViewModel.imageTable;
    } else if ([fileType isEqualToString:@"Videos"]) {
        cell.currentFileTable = self.listViewModel.videoTable;
    }  else if ([fileType isEqualToString:@"Emergency"]) {
        cell.currentFileTable = self.listViewModel.emergencyVideoTable;
    }
#endif
    cell.delegate = self;
    
    return cell;
}

#pragma mark - UICollectionViewDelegate
// collectionView的代理方法
// collectionView 正在滚动
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 当前 typeView
    ICatchFileTypeView *typeView = self.scrollView.subviews[self.currentIndex];
    
//    int index = scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds);
    // 下一个 typeView
    ICatchFileTypeView *nextTypeView = nil;
    // 遍历当前可见 cell 的索引
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForVisibleItems) {
        if (indexPath.item != self.currentIndex) {
            nextTypeView = self.scrollView.subviews[indexPath.item];
            break;
        }
    }
    
    if (nextTypeView == nil) {
        return;
    }
    
    // 获取滚动的比例
    CGFloat nextScale = ABS(scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds) - self.currentIndex);
    CGFloat currentScale = 1 - nextScale;

    typeView.scale = currentScale;
    nextTypeView.scale = nextScale;
}

// 滚动结束之后，计算currentIndex
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.currentIndex = scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds);

    // 居中显示当前显示的标签
    ICatchFileTypeView *typeView = self.scrollView.subviews[self.currentIndex];
    CGFloat offset = typeView.center.x - CGRectGetWidth(scrollView.bounds) * 0.5;
    CGFloat maxOffset = self.scrollView.contentSize.width - typeView.bounds.size.width - CGRectGetWidth(scrollView.bounds);
    if (offset < 0) {
        offset = 0;
    } else if (offset > maxOffset) {
        offset = maxOffset + typeView.bounds.size.width;
    }

    [self.scrollView setContentOffset:CGPointMake(offset, 0) animated:YES];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    self.currentIndex = (scrollView.contentOffset.x + CGRectGetWidth(scrollView.bounds) * 0.5) / CGRectGetWidth(scrollView.bounds);
}

#pragma mark - ICatchFileTypeViewDelegate
- (void)clickedActionWithFileTypeView:(ICatchFileTypeView *)fileTypeView {
    if (!self.toolbar.hidden) {
        return;
    }
    
    [self.scrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (fileTypeView == obj) {
            self.currentIndex = (int)idx;
            *stop = YES;
        }
    }];

    // 居中显示当前显示的标签
    CGFloat offset = fileTypeView.center.x - CGRectGetWidth(self.collectionView.bounds) * 0.5;
    CGFloat maxOffset = self.scrollView.contentSize.width - fileTypeView.bounds.size.width - CGRectGetWidth(self.collectionView.bounds);
    if (offset < 0) {
        offset = 0;
    } else if (offset > maxOffset) {
        offset = maxOffset + fileTypeView.bounds.size.width;
    }
    
    [self.scrollView setContentOffset:CGPointMake(offset, 0) animated:YES];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentIndex inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
}

#pragma mark - ICatchHomeCollectionCellDelegate
- (void)homeCollectionCell:(ICatchHomeCollectionCell *)cell singleFilePlaybackWithIndexPath:(NSIndexPath *)indexPath {
    TRACE();
    
    auto file = [self getFileWithIndexPath:indexPath];
    
    SEL callback = nil;
    
    switch (file->getFileType()) {
        case ICH_FILE_TYPE_IMAGE:
            callback = @selector(photoSinglePlaybackCallback:);
            break;
           
        case ICH_FILE_TYPE_VIDEO:
            callback = @selector(videoSinglePlaybackCallback:);
            break;
            
        default:
            break;
    }
    
    if ([self respondsToSelector:callback]) {
        AppLog(@"callback-index: %ld", (long)indexPath.item);
        [self performSelector:callback withObject:indexPath afterDelay:0];
    } else {
        AppLog(@"It's not support to playback this file.");
    }
}

- (ICatchFileTable *)currentFileTable {
#if 0
    switch (_currentIndex) {
        case 0:
            _currentFileTable = self.listViewModel.imageTable;
            break;
            
        case 1:
            _currentFileTable = self.listViewModel.videoTable;
            break;
        
        case 2:
            _currentFileTable = self.listViewModel.emergencyVideoTable;
            break;
            
        default:
            break;
    }
#else
    NSString *fileType = self.fileTypes[_currentIndex];
    if ([fileType isEqualToString:@"Images"]) {
       _currentFileTable = self.listViewModel.imageTable;
    } else if ([fileType isEqualToString:@"Videos"]) {
        _currentFileTable = self.listViewModel.videoTable;
    }  else if ([fileType isEqualToString:@"Emergency"]) {
        _currentFileTable = self.listViewModel.emergencyVideoTable;
    }
#endif
    
    return _currentFileTable;
}

- (shared_ptr<ICatchFile>)getFileWithIndexPath:(NSIndexPath *)indexPath {
    NSString *key = self.currentFileTable.fileDateArray[indexPath.section];
    return self.currentFileTable.fileList[key][indexPath.row].file;
}

- (NSUInteger)getFileIndexWithIndexPath:(NSIndexPath *)indexPath {
    NSString *key = self.currentFileTable.fileDateArray[indexPath.section];
    auto file = self.currentFileTable.fileList[key][indexPath.row];
    return [_currentFileTable.filteredFileList indexOfObject:file];
}

- (void)photoSinglePlaybackCallback:(NSIndexPath *)indexPath {
    self.browser = [_ctrl.fileCtrl createOneMWPhotoBrowserWithDelegate:self];
    [_browser setCurrentPhotoIndex:[self getFileIndexWithIndexPath:indexPath]];
    
    [self.navigationController pushViewController:self.browser animated:YES];
}

- (void)videoSinglePlaybackCallback:(NSIndexPath *)indexPath
{
    AppLog(@"%s", __func__);
    if (![_ctrl.fileCtrl isVideoPlaybackEnabled]) {
        //[self showProgressHUDNotice:NSLocalizedString(@"ShowNoViewVideoTip", nil) showTime:1.0];
        return;
    }
    
    auto file = [self getFileWithIndexPath:indexPath];
    // ignore 8K
    if (file->getFileWidth() == 7680 && file->getFileHeight() == 4320) {
        AppLog(@"%s", __func__);
        dispatch_async(dispatch_get_main_queue(), ^{
            //[self showProgressHUDNotice:NSLocalizedString(@"ShowNoViewVideoTip", nil) showTime:2.0];
            //[self showProgressHUDCompleteMessage:NSLocalizedString(@"ShowNoViewVideoTip", nil)];
            [self showProgressHUDWithMessage:NSLocalizedString(@"Warning", nil)
                              detailsMessage:NSLocalizedString(@"ShowNoViewVideoTip", nil)
                                        mode:MBProgressHUDModeText];
            [self.progressHUD hide:YES afterDelay:1.0];
        });
        return;
    }
    
    NSString *cachedKey = [NSString stringWithFormat:@"%s", file->getFileName().c_str()]; //@(file->getFileHandle()).stringValue;
    
    UIImage *image = [[ZJImageCache sharedImageCache] imageFromCacheForKey:cachedKey];
    if (!image) {
        dispatch_suspend(self.thumbnailQueue);
        
        [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)
                          detailsMessage:nil
                                    mode:MBProgressHUDModeIndeterminate];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (!_run) {
                return;
            }
            
            dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC);
            dispatch_semaphore_wait(self.mpbSemaphore, time);
            
            UIImage *image = [_ctrl.fileCtrl requestThumbnail:file];
            if (image != nil) {
                [[ZJImageCache sharedImageCache] storeImage:image forKey:cachedKey completion:nil];
            }
            dispatch_semaphore_signal(self.mpbSemaphore);
            dispatch_resume(self.thumbnailQueue);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                _videoPlaybackThumb = image;
                //[self performSegueWithIdentifier:@"PlaybackVideoSegue" sender:nil];
                [self presentVideoPlaybackViewControllerWithFile:file];
            });
        });
    } else {
        _videoPlaybackThumb = image;
        //[self performSegueWithIdentifier:@"PlaybackVideoSegue" sender:nil];
        [self presentVideoPlaybackViewControllerWithFile:file];
    }
}

- (void)presentVideoPlaybackViewControllerWithFile:(shared_ptr<ICatchFile>)file {
    UIStoryboard  *mainStoryboard = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    } else {
        mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    }
    
    UINavigationController *nc = [mainStoryboard instantiateViewControllerWithIdentifier:@"PlaybackVideoID"];;
    nc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nc.modalPresentationStyle = UIModalPresentationFullScreen;
    VideoPlaybackViewController *vpvc = (VideoPlaybackViewController *)nc.topViewController;
    vpvc.delegate = self;
    vpvc.previewImage = _videoPlaybackThumb;
    vpvc.currentFile = file;
    
    [self presentViewController:nc animated:YES completion:nil];
}

- (void)pullupRefreshActionWithHomeCollectionCell:(ICatchHomeCollectionCell *)cell {
    [self loadDataIsPullup:YES];
}

#pragma mark - VideoPlaybackControllerDelegate
- (BOOL)videoPlaybackController:(VideoPlaybackViewController *)controller deleteVideoFile:(shared_ptr<ICatchFile>)file {
    AppLog(@"%s", __func__);

    if (file.get() == nullptr) {
        AppLog(@"Video file is empty.");
        return NO;
    }
    
    BOOL ret = [_ctrl.fileCtrl deleteFile:file];
    if (ret) {
//        NSString *cachedKey = [NSString stringWithFormat:@"ID%d", file->getFileHandle()];
//        [_mpbCache removeObjectForKey:cachedKey];
//        [self resetCollectionViewData];
    }
    
    return ret;
}

#pragma mark - MWPhotoBrowserDataSource
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    AppLog(@"%s", __func__);
    return _currentFileTable.filteredFileList.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    AppLog(@"%s(%lu)", __func__, (unsigned long)index);
    
    MWPhoto *photo = nil;
    unsigned long listSize = 0;

    listSize = _currentFileTable.filteredFileList.count;
    shared_ptr<ICatchFile> file = _currentFileTable.filteredFileList[index].file;
    
    if (index < listSize) {
        photo = [MWPhoto photoWithURL:[NSURL URLWithString:@"sdk://test"] funcBlock:^{
            return [_ctrl.fileCtrl requestImage:file];
        }];
    }
    
    return photo;
}

- (void)showShareConfirmForphotoBrowser
{
    auto f = _currentFileTable.selectedFiles.firstObject.file;
    
    NSString *fileName = [NSString stringWithUTF8String:f->getFileName().c_str()];
    NSString *tmpDirectoryContents = nil;
    if ([fileName hasSuffix:@".MP4"] || [fileName hasSuffix:@".MOV"]) {
        tmpDirectoryContents = [[SDK instance] createMediaDirectory][2];
    } else {
        tmpDirectoryContents = [[SDK instance] createMediaDirectory][1];
    }
    
    NSString *locatePath = [tmpDirectoryContents stringByAppendingPathComponent:fileName];
    
    BOOL isDir = NO;
    BOOL isDirExist= NO;
    
    isDirExist = [[NSFileManager defaultManager] fileExistsAtPath:locatePath isDirectory:&isDir];
    
    long long tempSize = [DiskSpaceTool fileSizeAtPath:locatePath];
    long long fileSize = f->getFileSize();
    
    if (isDirExist && (tempSize == fileSize)) {
        [self.actionFiles addObject:[NSURL fileURLWithPath:locatePath]];
    } else {
        if (![[SDK instance] openFileTransChannel]) {
            return;
        }
        
        self.downloadFileProcessing = YES;
        self.downloadedPercent = 0;
        
        NSString *path = [[SDK instance] p_downloadFile2:f];
        if (path) {
            [self.actionFiles addObject:[NSURL fileURLWithPath:path]];
        }
        
        if (![[SDK instance] closeFileTransChannel]) {
            return;
        }
    }
}

#pragma mark - MWPhotoBrowserDelegate
-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
    AppLog(@"%s", __func__);
    
    [self.actionFiles removeAllObjects];
    [_currentFileTable.selectedFiles removeAllObjects];
    
    ICatchFileInfo *fileInfo = _currentFileTable.filteredFileList[index];
    [_currentFileTable.selectedFiles addObject:fileInfo];
}

- (BOOL)photoBrowser      :(MWPhotoBrowser *)photoBrowser
        deletePhotoAtIndex:(NSUInteger)index
{
    AppLog(@"%s", __func__);
    NSUInteger i = 0;
    unsigned long listSize = 0;
    BOOL ret = NO;
    
    listSize = _currentFileTable.filteredFileList.count;
    if (listSize>0) {
        i = MAX(0, MIN(index, listSize - 1));
        auto file = _currentFileTable.filteredFileList[i].file;
        ret = [_ctrl.fileCtrl deleteFile:file];
        if (ret) {
            NSString *cachedKey = [NSString stringWithFormat:@"%s", file->getFileName().c_str()];
            [[ZJImageCache sharedImageCache] removeImageForKey:cachedKey completion:nil];
            
            [self.currentFileTable clearFileTableData];
            [self.listViewModel requestFileListOfType:[self fileTypeMap] pullup:NO takenBy:self.takenBy];
            [self.currentFileTable.selectedFiles removeAllObjects];
        }
    }
    
    return ret;
}

-(BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser downloadPhotoAtIndex:(NSUInteger)index
{
    AppLog(@"%s", __func__);
    [self showActionConfirm];
    
    return _downloadFailedCount>0?NO:YES;
}

-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser sharePhotoAtIndex:(NSUInteger)index serviceType:(NSString *)serviceType{
    AppLog(@"%s", __func__);
    [self showActivityViewController:photoBrowser.actionButton];
}

-(void)photoBrowser:(MWPhotoBrowser *)photoBrowser shareImageAtIndex:(NSUInteger)index {
    AppLog(@"%s", __func__);
//    [self showShareConfirm];
    [self showActivityViewController:photoBrowser.actionButton];
}

-(void)shareImage:(MWPhotoBrowser *)photoBrowser {
    AppLog(@"%s", __func__);
    [self showShareConfirmForphotoBrowser];;
}

- (void)panCamSDKinit {
    [[PanCamSDK instance] initImage];
}

- (BOOL)changePanoramaType:(int)panoramaType {
    return [[PanCamSDK instance] changePanoramaType:panoramaType isStream:NO];
}

- (void)createICatchImage:(UIImage *)image {
    [[PanCamSDK instance] panCamcreateICatchImage:image];
}

- (void)configureGLKView:(int)width andHeight:(int)height {
    //[[PanCamSDK instance] panCamSetViewPort:width andHeight:height];
    [[PanCamSDK instance] panCamSetViewPort:0 andY:44 andWidth:width andHeight:height - 88];
    [[PanCamSDK instance] panCamRender];
}

- (void)rotate:(CGPoint) pointC andPointPre:(CGPoint)pointP {
    [[PanCamSDK instance] panCamRotate:pointC andPointPre:pointP andType:PCFileTypeImage];
}

- (void)rotate:(int)orientation andX:(float)x andY:(float)y andZ:(float)z andTimestamp:(long)timestamp {
    [[PanCamSDK instance] panCamRotate:orientation andSpeedX:x andSpeedY:y andSpeedZ:z andTamp:timestamp andType:PCFileTypeImage];
}

- (void)locate:(float)distance {
    [[PanCamSDK instance] panCamLocate: distance andType:PCFileTypeImage];
}

- (void)panCamSDKDestroy {
//    [[PanCamSDK instance] destroyImage];
    [[PanCamSDK instance] destroypanCamSDK];
}

#pragma mark - Rotation
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self updateLayout];
}

- (void)updateLayout {
    [self updateCollectionViewLayout];
    [self updateFileTypeViewLayout];
}

- (void)updateCollectionViewLayout {
    [self.collectionView reloadData];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentIndex inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
}

- (void)updateFileTypeViewLayout {
    CGFloat marginX = 0;
    CGFloat x = marginX;
    CGFloat h = CGRectGetHeight(self.scrollView.frame);
    CGFloat w = (CGRectGetWidth(self.scrollView.frame) - marginX * self.fileTypes.count) / self.fileTypes.count;
    
    for (int i = 0; i < self.fileTypes.count; i++) {
        ICatchFileTypeView *typeView = self.scrollView.subviews[i];
                
        typeView.frame = CGRectMake(x, 0, MAX(w, kDateViewMinWidth), h);
        x += typeView.bounds.size.width + marginX;
    }
    
    // 设置滚动范围
    self.scrollView.contentSize = CGSizeMake(x, 0);
    self.scrollView.contentOffset = CGPointZero;
}

#pragma mark - Action Handle
- (void)showActionConfirm
{
    AppLog(@"%s", __func__);
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    [self.actionFiles removeAllObjects];
    
    [self.actionFileType removeAllObjects];
    
    unsigned long long downloadSizeInKBytes = 0;
    NSString *confrimButtonTitle = nil;
    NSString *message = nil;
    double freeDiscSpace = [_ctrl.comCtrl freeDiskSpaceInKBytes];
    
    if (self.currentFileTable.totalDownloadSize < freeDiscSpace/2.0) {
        message = [self makeupDownloadMessageWithSize:self.currentFileTable.totalDownloadSize
                                            andNumber:self.currentFileTable.selectedFiles.count];
        confrimButtonTitle = NSLocalizedString(@"SureDownload", @"");
    } else {
        message = [self makeupNoDownloadMessageWithSize:self.currentFileTable.totalDownloadSize];
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [self _showDownloadConfirm:message title:confrimButtonTitle dBytes:downloadSizeInKBytes fSpace:freeDiscSpace];
    } else {
        [self _showDownloadConfirm:message title:confrimButtonTitle dBytes:downloadSizeInKBytes fSpace:freeDiscSpace];
    }
}

- (void)_showDownloadConfirm:(NSString *)message
                      title:(NSString *)confrimButtonTitle
                     dBytes:(unsigned long long)downloadSizeInKBytes
                     fSpace:(double)freeDiscSpace {
    AppLog(@"%s", __func__);
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (downloadSizeInKBytes < freeDiscSpace) {
            [self showPopoverFromBarButtonItem:self.actionButtonItem
                                       message:message
                               fireButtonTitle:confrimButtonTitle
                                      callback:@selector(downloadDetail:)];
        } else {
            [self showPopoverFromBarButtonItem:self.actionButtonItem
                                       message:message
                               fireButtonTitle:nil
                                      callback:nil];
        }
        
    } else {
        [self showActionSheetFromBarButtonItem:self.actionButtonItem
                                       message:message
                             cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                        destructiveButtonTitle:confrimButtonTitle
                                           tag:ACTION_SHEET_DOWNLOAD_ACTIONS];
    }
}

- (void)showPopoverFromBarButtonItem:(UIBarButtonItem *)item
                            message:(NSString *)message
                    fireButtonTitle:(NSString *)fireButtonTitle
                           callback:(SEL)fireAction
{
    AppLog(@"%s", __func__);
    MpbPopoverViewController *contentViewController = [[MpbPopoverViewController alloc] initWithNibName:@"MpbPopover" bundle:nil];
    contentViewController.msg = message;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        contentViewController.msgColor = [UIColor blackColor];
    } else {
        contentViewController.msgColor = [UIColor whiteColor];
    }
    
    UIPopoverController *popController = [[UIPopoverController alloc] initWithContentViewController:contentViewController];
    if (fireButtonTitle) {
        UIButton *fireButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0f, 110.0f, 260.0f, 47.0f)];
        popController.popoverContentSize = CGSizeMake(270.0f, 170.0f);
        fireButton.enabled = YES;
        
        [fireButton setTitle:fireButtonTitle
                    forState:UIControlStateNormal];
        [fireButton setBackgroundImage:[[UIImage imageNamed:@"iphone_delete_button.png"] stretchableImageWithLeftCapWidth:8.0f topCapHeight:0.0f]
                              forState:UIControlStateNormal];
        [fireButton addTarget:self action:fireAction forControlEvents:UIControlEventTouchUpInside];
        [contentViewController.view addSubview:fireButton];
    } else {
        popController.popoverContentSize = CGSizeMake(270.0f, 160.0f);
    }
    
    self.popController = popController;
    [_popController presentPopoverFromBarButtonItem:item permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)showActionSheetFromBarButtonItem:(UIBarButtonItem *)item
                                message:(NSString *)message
                      cancelButtonTitle:(NSString *)cancelButtonTitle
                 destructiveButtonTitle:(NSString *)destructiveButtonTitle
                                    tag:(NSInteger)tag
{
    AppLog(@"%s", __func__);
    self.actionSheet = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [_actionSheet addAction:[UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:nil]];
    if (destructiveButtonTitle != nil) {
        [_actionSheet addAction:[UIAlertAction actionWithTitle:destructiveButtonTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            switch (tag) {
                case ACTION_SHEET_DOWNLOAD_ACTIONS:
                    [self downloadDetail:item];
                    break;
                    
                case ACTION_SHEET_DELETE_ACTIONS:
                    [self deleteDetail:item];
                    break;
                    
                default:
                    break;
            }
        }]];
    }
    
    [self presentViewController:_actionSheet animated:YES completion:nil];
}

- (NSString *)makeupNoDownloadMessageWithSize:(unsigned long long)sizeInKB
{
    AppLog(@"%s", __func__);
    NSString *message = nil;
    NSString *humanDownloadFileSize = [_ctrl.comCtrl translateSize:sizeInKB];
    double freeDiscSpace = [_ctrl.comCtrl freeDiskSpaceInKBytes];
    NSString *leftSpace = [_ctrl.comCtrl translateSize:freeDiscSpace];
    message = [NSString stringWithFormat:@"%@\n Download:%@, Free:%@", NSLocalizedString(@"NotEnoughSpaceError", nil), humanDownloadFileSize, leftSpace];
    message = [message stringByAppendingString:@"\n Needs double free space"];
    return message;
}

- (NSString *)makeupDownloadMessageWithSize:(unsigned long long)sizeInKB
                                 andNumber:(NSInteger)num
{
    AppLog(@"%s", __func__);
    
    NSString *message = nil;
    NSString *humanDownloadFileSize = [self translateSize:sizeInKB];
    unsigned long long downloadTimeInHours = (sizeInKB/1024)/3600;
    unsigned long long downloadTimeInMinutes = (sizeInKB/1024)/60 - downloadTimeInHours*60;
    unsigned long long downloadTimeInSeconds = sizeInKB/1024 - downloadTimeInHours*3600 - downloadTimeInMinutes*60;
    AppLog(@"downloadTimeInHours: %llu, downloadTimeInMinutes: %llu, downloadTimeInSeconds: %llu",
           downloadTimeInHours, downloadTimeInMinutes, downloadTimeInSeconds);
    
    if (downloadTimeInHours > 0) {
        message = NSLocalizedString(@"DownloadConfirmMessage3", nil);
        message = [message stringByReplacingOccurrencesOfString:@"%1"
                                                     withString:[NSString stringWithFormat:@"%ld", (long)num]];
        message = [message stringByReplacingOccurrencesOfString:@"%2"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInHours]];
        message = [message stringByReplacingOccurrencesOfString:@"%3"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInMinutes]];
        message = [message stringByReplacingOccurrencesOfString:@"%4"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInSeconds]];
    } else if (downloadTimeInMinutes > 0) {
        message = NSLocalizedString(@"DownloadConfirmMessage2", nil);
        message = [message stringByReplacingOccurrencesOfString:@"%1"
                                                     withString:[NSString stringWithFormat:@"%ld", (long)num]];
        message = [message stringByReplacingOccurrencesOfString:@"%2"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInMinutes]];
        message = [message stringByReplacingOccurrencesOfString:@"%3"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInSeconds]];
    } else {
        message = NSLocalizedString(@"DownloadConfirmMessage1", nil);
        message = [message stringByReplacingOccurrencesOfString:@"%1"
                                                     withString:[NSString stringWithFormat:@"%ld", (long)num]];
        message = [message stringByReplacingOccurrencesOfString:@"%2"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInSeconds]];
    }
    message = [message stringByAppendingString:[NSString stringWithFormat:@"\n%@", humanDownloadFileSize]];
    return message;
}

- (NSString *)translateSize:(unsigned long long)sizeInKB
{
    NSString *humanDownloadFileSize = nil;
    double temp = (double)sizeInKB/1024; // MB
    if (temp > 1024) {
        temp /= 1024;
        humanDownloadFileSize = [NSString stringWithFormat:@"%.2fGB", temp];
    } else {
        humanDownloadFileSize = [NSString stringWithFormat:@"%.2fMB", temp];
    }
    return humanDownloadFileSize;
}

#pragma mark - ActivityView
- (int)videoAtPathIsCompatibleWithSavedPhotosAlbum:(int)saveNum {
    if (self.actionFileType != nil && self.actionFileType.count > 0) {
        ICatchFileType fileType = (ICatchFileType)[self.actionFileType.firstObject intValue];
        if (fileType != ICH_FILE_TYPE_VIDEO) {
            return saveNum;
        }
    } else {
        return saveNum;
    }
    
    int inCompatible = 0;
    int inCompatibleExceed = 0;
    NSString *path = nil;
    
    if (saveNum == self.actionFiles.count) {
        for (NSURL *temp in self.actionFiles) {
            path = temp.path;
            if (path != nil && !UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
                inCompatible ++;
            }
        }
    } else {
        NSURL *fileURL = nil;
        for (int i = 0; i < saveNum; i++) {
            fileURL = self.actionFiles[i];
            path = fileURL.path;
            if (path != nil && !UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
                inCompatible ++;
            }
        }
        
        for (int i = saveNum; i < self.actionFiles.count; i++) {
            fileURL = self.actionFiles[i];
            path = fileURL.path;
            if (path != nil && !UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
                inCompatibleExceed ++;
            }
        }
    }
    
    if (inCompatible || inCompatibleExceed) {
        NSString *msg = [NSString stringWithFormat:@"There is %d specified video can not be saved to user’s Camera Roll album", inCompatible + inCompatibleExceed];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAlertViewWithTitle:NSLocalizedString(@"Warning",nil) message:msg cancelButtonTitle:NSLocalizedString(@"Sure", nil)];
        });
    }
    
    return (saveNum - inCompatible);
}

- (void)showActivityViewController:(id)sender
{
    AppLog(@"%s", __func__);
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    uint shareNum = (uint)[self.actionFiles count];
    uint assetNum = (uint)[[SDK instance] retrieveCameraRollAssetsResult].count;
    
    if (shareNum) {
        UIActivityViewController *activityVc = [[UIActivityViewController alloc]initWithActivityItems:self.actionFiles applicationActivities:nil];
        
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            [self presentViewController:activityVc animated:YES completion:nil];
        } else {
            // Create pop up
            UIPopoverController *activityPopoverController = [[UIPopoverController alloc] initWithContentViewController:activityVc];
            // Show UIActivityViewController in popup
            [activityPopoverController presentPopoverFromBarButtonItem:(UIBarButtonItem *)sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
        
        activityVc.completionWithItemsHandler = ^(NSString *activityType,
                                                  BOOL completed,
                                                  NSArray *returnedItems,
                                                  NSError *error) {
            if (completed) {
                AppLog(@"We used activity type: %@", activityType);
                
                if ([activityType isEqualToString:@"com.apple.UIKit.activity.SaveToCameraRoll"]) {
                    dispatch_async(dispatch_queue_create("WifiCam.GCD.Queue.Share", DISPATCH_QUEUE_SERIAL), ^{
                        [self showProgressHUDWithMessage:NSLocalizedString(@"PhotoSavingWait", nil)];
                        
                        BOOL ret;
                        AppLog(@"shareNum: %d", shareNum);
                        ret = [[SDK instance] savetoAlbum:@"MobileCamApp" andAlbumAssetNum:assetNum andShareNum:[self videoAtPathIsCompatibleWithSavedPhotosAlbum:shareNum]];
                        /*
                        if (shareNum <= 5) {
                            ret = [[SDK instance] savetoAlbum:@"iSmart DV" andAlbumAssetNum:assetNum andShareNum:[self videoAtPathIsCompatibleWithSavedPhotosAlbum:shareNum]];
                        } else {
                            ret = [[SDK instance] savetoAlbum:@"iSmart DV" andAlbumAssetNum:assetNum andShareNum:[self videoAtPathIsCompatibleWithSavedPhotosAlbum:5]];
                            
                            for (int i = 5; i < shareNum; i++) {
                                NSURL *fileURL = self.shareFiles[i];
                                if (fileURL == nil) {
                                    continue;
                                }
                                
                                ICatchFileType fileType = (ICatchFileType)[self.shareFileType[i] intValue];
                                if (fileType == TYPE_VIDEO) {
                                    NSString *path = fileURL.path;
                                    if (path && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path)) {
                                        [[SDK instance] addNewAssetWithURL:fileURL toAlbum:@"SBCapp" andFileType:fileType];
                                    } else {
                                        AppLog(@"The specified video can not be saved to user’s Camera Roll album");
                                    }
                                } else {
                                    [[SDK instance] addNewAssetWithURL:fileURL toAlbum:@"SBCapp" andFileType:fileType];
                                }
                            }
                        }
                        */
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"kCameraDownloadCompleteNotification"
                                                                                object:[NSNumber numberWithInt:ret]];
                            
                            if (ret) {
                                [self showProgressHUDCompleteMessage:NSLocalizedString(@"SavePhotoToAlbum", nil)];
                            } else {
                                [self showProgressHUDCompleteMessage:NSLocalizedString(@"SaveError", nil)];
                            }
                            
                            [self.actionFiles removeAllObjects];
                            [self.actionFileType removeAllObjects];
                        });
                    });
                }
            } else {
                AppLog(@"We didn't want to share anything after all.");
            }
            
            if (error) {
                AppLog(@"An Error occured: %@, %@", error.localizedDescription, error.localizedFailureReason);
            }
        };
    } else {
//        [self showAlertViewWithTitle:NSLocalizedString(@"SaveError", nil) message:nil cancelButtonTitle:NSLocalizedString(@"Sure", @"")];
        
        [self.actionFiles removeAllObjects];
        [self.actionFileType removeAllObjects];
    }
}

- (void)showAlertViewWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - Download Handle
- (void)downloadDetail:(id)sender
{
    AppLog(@"%s", __func__);
    if ([sender isKindOfClass:[UIButton self]]) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    self.cancelDownload = NO;
    
    // Prepare

    self.totalDownloadFileNumber = self.currentFileTable.selectedFiles.count;

    self.downloadedFileNumber = 0;
    self.downloadedPercent = 0;
    [self addObserver:self forKeyPath:@"downloadedFileNumber" options:0x0 context:nil];
    [self addObserver:self forKeyPath:@"downloadedPercent" options:NSKeyValueObservingOptionNew context:nil];
    NSUInteger handledNum = MIN(_downloadedFileNumber, _totalDownloadFileNumber);
    NSString *msg = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)handledNum, (unsigned long)_totalDownloadFileNumber];
    
    // Show processing notice
    if (!handledNum) {
//        [self showProgressHUDWithMessage:NSLocalizedString(@"STREAM_WAIT_FOR_VIDEO", nil)
//                          detailsMessage:nil
//                                    mode:MBProgressHUDModeDeterminate];
        [self showDownloadHUDWithMessage:NSLocalizedString(@"STREAM_WAIT_FOR_VIDEO", nil)];
    } else {
//        [self showProgressHUDWithMessage:msg
//                          detailsMessage:nil
//                                    mode:MBProgressHUDModeDeterminate];
        [self showDownloadHUDWithMessage:msg];
    }
    // Just in case, _selItemsTable.selectedCellsn wouldn't be destoried after app enter background
    [_ctrl.fileCtrl tempStoreDataForBackgroundDownload:self.currentFileTable.selectedFiles];
    
    dispatch_async(self.downloadQueue, ^{
        NSInteger downloadedPhotoNum = 0, downloadedVideoNum = 0;
        NSInteger downloadFailedCount = 0;
        UIBackgroundTaskIdentifier downloadTask;
        NSArray *resultArray = nil;
        
        [_ctrl.fileCtrl resetBusyToggle:YES];
        // -- Request more time to excute task within background
        UIApplication  *app = [UIApplication sharedApplication];
        downloadTask = [app beginBackgroundTaskWithExpirationHandler: ^{
            
            AppLog(@"-->Expiration");
            NSArray *oldNotifications = [app scheduledLocalNotifications];
            // Clear out the old notification before scheduling a new one
            if ([oldNotifications count] > 5) {
                [app cancelAllLocalNotifications];
            }
            
            NSString *noticeMessage = [NSString stringWithFormat:@"[Progress: %lu/%lu] - App is about to exit. Please bring it to foreground to continue dowloading.", (unsigned long)handledNum, (unsigned long)_totalDownloadFileNumber];
            [_ctrl.comCtrl scheduleLocalNotice:noticeMessage];
        }];
        
        // ---------- Downloading
        resultArray = [self downloadSelectedFiles];

        downloadedPhotoNum = [resultArray[0] integerValue];
        downloadedVideoNum = [resultArray[1] integerValue];
        downloadFailedCount = [resultArray[2] integerValue];
        self.downloadFailedCount = downloadFailedCount;
        // -----------

        // Download is completed, notice & update GUI
        self.currentFileTable.totalDownloadSize = 0;

        // HUD notification
        dispatch_async(dispatch_get_main_queue(), ^{
            // Post local notification
            if (app.applicationState == UIApplicationStateBackground) {
                NSString *noticeMessage = NSLocalizedString(@"SavePhotoToAlbum", @"Download complete.");
                [_ctrl.comCtrl scheduleLocalNotice:noticeMessage];
            }
            
            [self removeObserver:self forKeyPath:@"downloadedFileNumber"];
            [self removeObserver:self forKeyPath:@"downloadedPercent"];
            
            [self showActivityViewController:self.actionButtonItem];
            // Clear
            for (ICatchFileInfo *fileInfo in self.currentFileTable.selectedFiles) {
                fileInfo.selected = false;
            }
            [self.collectionView reloadData];
            
            [self.currentFileTable.selectedFiles removeAllObjects];
//            self.selItemsTable.count = 0;
            [self updateButtonEnableState:NO];
            
            if (![[SDK instance] checkCameraCapabilities:ICH_CAM_NEW_PAGINATION_GET_FILE]) {
                if(1 == self.selectAllButtonItem.tag) {
                    UIBarButtonItem *sel = self.selectAllButtonItem;
                    if (0==sel.tag) {
                        sel.title = NSLocalizedString(@"Cancel", nil);
                    } else {
                        sel.title = NSLocalizedString(@"All", nil);
                    }
                    sel.tag = !sel.tag;
                }
            }
            
            if (!_cancelDownload) {
                NSString *message = nil;
                if (downloadFailedCount > 0) {
                    NSString *message = NSLocalizedString(@"DownloadSelectedError", nil);
                    message = [message stringByReplacingOccurrencesOfString:@"%d" withString:[NSString stringWithFormat:@"%ld", (long)downloadFailedCount]];
                    [self showProgressHUDNotice:message showTime:0.5];
                    
                } else {
                    if (self.downloadedFileNumber) {
                        message = NSLocalizedString(@"DownloadDoneMessage", nil);
                        NSString *photoNum = [NSString stringWithFormat:@"%ld", (long)downloadedPhotoNum];
                        NSString *videoNum = [NSString stringWithFormat:@"%ld", (long)downloadedVideoNum];
                        message = [message stringByReplacingOccurrencesOfString:@"%1"
                                                                     withString:photoNum];
                        message = [message stringByReplacingOccurrencesOfString:@"%2"
                                                                     withString:videoNum];
                    }
                    [self showProgressHUDCompleteMessage:message];
                }
                
            } else {
                [self hideProgressHUD:YES];
                [self showAlertViewWithTitle:NSLocalizedString(@"CanceledDownload", nil)
                                     message:nil
                           cancelButtonTitle:NSLocalizedString(@"Sure", @"")];
            }
        });
        
        [_ctrl.fileCtrl resetBusyToggle:NO];
        [[UIApplication sharedApplication] endBackgroundTask:downloadTask];
    });
}

- (NSArray *)downloadSelectedFiles
{
    AppLog(@"%s", __func__);
    NSInteger downloadedPhotoNum = 0, downloadedVideoNum = 0, downloadFailedCount = 0;
    
    shared_ptr<ICatchFile> f = nullptr;
    NSString *fileName = nil;
    NSArray *mediaDirectoryContents = nil;
    
    if (![[SDK instance] openFileTransChannel]) {
        return nil;
    }
    
    for (ICatchFileInfo *fileInfo in self.currentFileTable.selectedFiles) {
        if (_cancelDownload) break;
        
        f = fileInfo.file;
        
        fileName = [NSString stringWithUTF8String:f->getFileName().c_str()];
        
        NSString *fileDirectory = nil;
        if ([fileName hasSuffix:@".MP4"] || [fileName hasSuffix:@".MOV"]) {
            fileDirectory = [[SDK instance] createMediaDirectory][2];
        } else {
            fileDirectory = [[SDK instance] createMediaDirectory][1];
        }
        mediaDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fileDirectory error:nil];

        self.downloadFileProcessing = YES;
        self.downloadedPercent = 0;//Before the download clear downloadedPercent and increase downloadedFileNumber.
        
        if (mediaDirectoryContents.count) {
            for (NSString *name in mediaDirectoryContents) {
                if ([name isEqualToString:fileName]) {
                    NSString *filePath = [fileDirectory stringByAppendingPathComponent:fileName];
                    long long tempSize = [DiskSpaceTool fileSizeAtPath:filePath];
                    long long fileSize = f->getFileSize();
                    
                    if (tempSize == fileSize) {
                        [self.actionFiles addObject:[NSURL fileURLWithPath:filePath]];
                        [self.actionFileType addObject:[NSNumber numberWithInt:f->getFileType()]];
                    } else {
                        [self downloadSelectedFile:f andFailedCount:(&downloadFailedCount)
                                     andPhotoCount:(&downloadedPhotoNum)
                                     andVideoCount:(&downloadedVideoNum)];
                    }
                    break;
                } else if ([name isEqualToString:[mediaDirectoryContents lastObject]]) {
                    [self downloadSelectedFile:f andFailedCount:(&downloadFailedCount)
                                 andPhotoCount:(&downloadedPhotoNum)
                                 andVideoCount:(&downloadedVideoNum)];
                }
            }
        } else {
            [self downloadSelectedFile:f andFailedCount:(&downloadFailedCount)
                         andPhotoCount:(&downloadedPhotoNum)
                         andVideoCount:(&downloadedVideoNum)];
        }
    }
    
    if (![[SDK instance] closeFileTransChannel]) {
        return nil;
    }
    
    [_ctrl.fileCtrl resetDownoladedTotalNumber];
    return [NSArray arrayWithObjects:@(downloadedPhotoNum), @(downloadedVideoNum), @(downloadFailedCount), nil];
}

- (void)downloadSelectedFile:(shared_ptr<ICatchFile>)f
              andFailedCount:(NSInteger *)downloadFailedCount
               andPhotoCount:(NSInteger *)downloadedPhotoNum
               andVideoCount:(NSInteger *)downloadedVideoNum
{
    do {
        self.downloadedFileNumber ++;
        [self requestDownloadPercent:f];
        //        if (![_ctrl.fileCtrl downloadFile2:&f]) {
        //            ++(*downloadFailedCount);
        //            self.downloadFileProcessing = NO;
        //            continue;
        //        }
        if (![[SDK instance] p_downloadFile2:f]) {
            ++downloadFailedCount;
            self.downloadFileProcessing = NO;
            break;
        }
        
        self.downloadFileProcessing = NO;
        [NSThread sleepForTimeInterval:0.5];
        
        NSString *fileDirectory = nil;
        NSString *locatePath = nil;
        NSString *fileName = [NSString stringWithUTF8String:f->getFileName().c_str()];
                
        switch (f->getFileType()) {
            case ICH_FILE_TYPE_IMAGE:
                ++(*downloadedPhotoNum);
                fileDirectory = [[SDK instance] createMediaDirectory][1];
                [self.actionFileType addObject:[NSNumber numberWithInt:ICH_FILE_TYPE_IMAGE]];
                break;
                
            case ICH_FILE_TYPE_VIDEO:
                ++(*downloadedVideoNum);
                fileDirectory = [[SDK instance] createMediaDirectory][2];
                [self.actionFileType addObject:[NSNumber numberWithInt:ICH_FILE_TYPE_VIDEO]];
                break;
                
            case ICH_FILE_TYPE_TEXT:
            case ICH_FILE_TYPE_AUDIO:
            case ICH_FILE_TYPE_ALL:
            case ICH_FILE_TYPE_UNKNOWN:
            default:
                break;
        }
        
        locatePath = [fileDirectory stringByAppendingPathComponent:fileName];
        [self.actionFiles addObject:[NSURL fileURLWithPath:locatePath]];
        
    } while (0);
}

- (void)requestDownloadPercent:(shared_ptr<ICatchFile>)file
{
    AppLog(@"%s", __func__);
    if (!file) {
        AppLog(@"file is null");
        return;
    }
    
    NSString *locatePath = nil;
    NSString *fileName = [NSString stringWithUTF8String:file->getFileName().c_str()];
    unsigned long long fileSize = file->getFileSize();
    //locatePath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), fileName];
    
    NSString *fileDirectory = nil;
    if ([fileName hasSuffix:@".MP4"] || [fileName hasSuffix:@".MOV"]) {
        fileDirectory = [[SDK instance] createMediaDirectory][2];
    } else {
        fileDirectory = [[SDK instance] createMediaDirectory][1];
    }
    locatePath = [fileDirectory stringByAppendingPathComponent:fileName];
    
    AppLog(@"locatePath: %@, filesize: %llu", locatePath, fileSize);
    
    dispatch_async(self.downloadPercentQueue, ^{
        do {
            @autoreleasepool {
                if (_cancelDownload) break;
                //self.downloadedPercent = [_ctrl.fileCtrl requestDownloadedPercent:f];
                self.downloadedPercent = [_ctrl.fileCtrl requestDownloadedPercent2:locatePath
                                                                          fileSize:fileSize];
//                AppLog(@"percent: %lu", (unsigned long)self.downloadedPercent);
                
                [NSThread sleepForTimeInterval:0.2];
            }
        } while (_downloadFileProcessing);
    });
}

#pragma mark - Delete Handle
- (void)delete:(id)sender
{
    AppLog(@"%s", __func__);
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    NSString *message = NSLocalizedString(@"DeleteMultiAsk", nil);
    NSString *replaceString = [NSString stringWithFormat:@"%ld", (long)self.currentFileTable.selectedFiles.count];
    message = [message stringByReplacingOccurrencesOfString:@"%d"
                                                 withString:replaceString];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self showPopoverFromBarButtonItem:sender
                                   message:message
                           fireButtonTitle:NSLocalizedString(@"SureDelete", @"")
                                  callback:@selector(deleteDetail:)];
    } else {
        [self showActionSheetFromBarButtonItem:sender
                                       message:message
                             cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                        destructiveButtonTitle:NSLocalizedString(@"SureDelete", @"")
                                           tag:ACTION_SHEET_DELETE_ACTIONS];
    }
}

- (void)deleteDetail:(id)sender
{
    AppLog(@"%s", __func__);
    __block int failedCount = 0;
    
    if ([sender isKindOfClass:[UIButton self]]) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    self.run = NO;
    [self showProgressHUDWithMessage:NSLocalizedString(@"Deleting", nil)
                      detailsMessage:nil
                                mode:MBProgressHUDModeIndeterminate];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *cachedKey = nil;
        
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
        dispatch_semaphore_wait(self.mpbSemaphore, time);
        
        // Real delete icatch file & remove NSCache item
        
        for (ICatchFileInfo *fileInfo in self.currentFileTable.selectedFiles) {
            if ([_ctrl.fileCtrl deleteFile:fileInfo.file] == NO) {
                ++failedCount;
            } else {
                cachedKey = [NSString stringWithFormat:@"%s", fileInfo.file->getFileName().c_str()]; //@(fileInfo.file->getFileHandle()).stringValue;
                [[ZJImageCache sharedImageCache] removeImageForKey:cachedKey completion:nil];
            }
        }
        
        // Update the UICollectionView's data source
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.currentFileTable clearFileTableData];
//            [self loadDataIsPullup:NO];
//        });
        
        // TODO: Delete those files instead of delete all
        [self.currentFileTable clearFileTableData];
        [self.listViewModel requestFileListOfType:[self fileTypeMap] pullup:NO takenBy:self.takenBy];
        
        dispatch_semaphore_signal(self.mpbSemaphore);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
            if (failedCount != self.currentFileTable.selectedFiles.count) {
                [self.currentFileTable.selectedFiles removeAllObjects];
                [self updateButtonEnableState:NO];
                self.run = YES;
//                [self.tableView reloadData];
            }
            
            NSString *noticeMessage = nil;
            if (failedCount > 0) {
                noticeMessage = NSLocalizedString(@"DeleteMultiError", nil);
                NSString *failedCountString = [NSString stringWithFormat:@"%d", failedCount];
                noticeMessage = [noticeMessage stringByReplacingOccurrencesOfString:@"%d" withString:failedCountString];
            } else {
                noticeMessage = NSLocalizedString(@"DeleteDoneMessage", nil);
            }
            [self showProgressHUDCompleteMessage:noticeMessage];
//            self.selItemsTable.count = 0;
        });
    });
}

#pragma mark - Observer
- (void)observeValueForKeyPath:(NSString *)keyPath
        ofObject              :(id)object
        change                :(NSDictionary *)change
        context               :(void *)context
{
//    AppLog(@"%s", __func__);
    if ([keyPath isEqualToString:@"count"]) {
//        if (self.selItemsTable.count > 0) {
//            [self prepareForAction];
//        } else {
//        }
    } else if ([keyPath isEqualToString:@"downloadedFileNumber"]) {
        NSUInteger handledNum = MIN(_downloadedFileNumber, _totalDownloadFileNumber);
        NSString *msg = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)handledNum, (unsigned long)_totalDownloadFileNumber];
        [self updateProgressHUDWithMessage:msg detailsMessage:nil];
    } else if([keyPath isEqualToString:@"downloadedPercent"]) {
        NSString *msg = [NSString stringWithFormat:@"%lu%%", (unsigned long)_downloadedPercent];
        if (self.downloadedFileNumber) {
            [self updateProgressHUDWithMessage:nil detailsMessage:msg];
        }
    }
}

#pragma mark AppDelegateProtocol
- (void)sdcardRemoveCallback
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showProgressHUDNotice:NSLocalizedString(@"CARD_REMOVED", nil) showTime:2.0];
        
        [self loadDataIsPullup:NO];
    });
}

- (void)sdcardInCallback {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showProgressHUDNotice:NSLocalizedString(@"CARD_INSERTED", nil) showTime:2.0];
        
        [self loadDataIsPullup:NO];
    });
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
        _progressHUD.minSize = CGSizeMake(140, 140);
        _progressHUD.minShowTime = 1;
        // The sample image is based on the
        // work by: http://www.pixelpressicons.com
        // licence: http://creativecommons.org/licenses/by/2.5/ca/
        self.progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]];
        [self.navigationController.view addSubview:_progressHUD];
    }
    
    return _progressHUD;
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
}

- (void)showProgressHUDNotice:(NSString *)message
                     showTime:(NSTimeInterval)time{
    AppLog(@"%s", __func__);
    self.navigationController.toolbar.userInteractionEnabled = NO;
    if (message) {
        self.progressHUD.showActionButton = NO;
        [self.view bringSubviewToFront:self.progressHUD];
        [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.mode = MBProgressHUDModeText;
        self.progressHUD.dimBackground = YES;
        [self.progressHUD hide:YES afterDelay:time];
    } else {
        [self.progressHUD hide:YES];
    }
    //self.navigationController.navigationBar.userInteractionEnabled = NO;
    self.navigationController.toolbar.userInteractionEnabled = YES;
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    AppLog(@"%s", __func__);
    if (message) {
        self.progressHUD.showActionButton = NO;
        if (self.progressHUD.isHidden) [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.detailsLabelText = nil;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hide:YES afterDelay:1.0];
    } else {
        [self.progressHUD hide:YES];
    }
    //self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.navigationController.toolbar.userInteractionEnabled = YES;
}

- (void)showProgressHUDWithMessage:(NSString *)message
                    detailsMessage:(NSString *)dMessage
                              mode:(MBProgressHUDMode)mode {
//    AppLog(@"%s", __func__);
    self.progressHUD.showActionButton = NO;
    self.progressHUD.labelText = message;
    self.progressHUD.detailsLabelText = dMessage;
    self.progressHUD.mode = mode;
    self.progressHUD.dimBackground = YES;
    [self.view bringSubviewToFront:self.progressHUD];
    [self.progressHUD show:YES];
    //self.navigationController.navigationBar.userInteractionEnabled = NO;
    self.navigationController.toolbar.userInteractionEnabled = NO;
}

- (void)showDownloadHUDWithMessage:(NSString *)message {
//    AppLog(@"%s", __func__);
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeAction;
    self.progressHUD.dimBackground = YES;
    [self.view bringSubviewToFront:self.progressHUD];
    self.progressHUD.showActionButton = YES;
    [self.progressHUD setActionButtonPressedCallback:@selector(progressHUDactionButtonPressed)
                                            onTarget:self withObject:nil];
    [self.progressHUD show:YES];
    self.navigationController.toolbar.userInteractionEnabled = NO;
}

- (void)updateProgressHUDWithMessage:(NSString *)message
                      detailsMessage:(NSString *)dMessage {
//    AppLog(@"%s", __func__);
    if (message) {
        self.progressHUD.labelText = message;
    }
    if (dMessage) {
        self.progressHUD.progress = _downloadedPercent / 100.0;
        self.progressHUD.detailsLabelText = dMessage;
    }
}

- (void)hideProgressHUD:(BOOL)animated {
//    AppLog(@"%s", __func__);
    [self.progressHUD hide:animated];
    //self.navigationController.navigationBar.userInteractionEnabled = YES;
    self.navigationController.toolbar.userInteractionEnabled = YES;
}

- (void)progressHUDactionButtonPressed {
    AppLog(@"%s", __func__);
    //TODO: cancel download
    
    self.cancelDownload = YES;
    if ([_ctrl.fileCtrl isBusy]) {
        // Cancel download
        [_ctrl.fileCtrl cancelDownload];
    }
}

#pragma mark - Lazy load
- (NSArray *)fileTypes {
    if (_fileTypes == nil) {
        if ([self capableOf:WifiCamAbilityDefaultToPlayback]) {
            _fileTypes = @[/*@"Images",*/ @"Videos", @"Emergency"];
        } else {
            _fileTypes = @[@"Images", @"Videos"];
        }
    }
    
    return _fileTypes;
}

- (NSArray *)displayWayItems {
    if (_displayWayItems == nil) {
        _displayWayItems = @[
                            @{@"title": @"", @"imageName": @"UIBarButtonItemTable", @"methodName": @"enterModifyWiFiViewWithCell:" },
                            @{@"title": @"", @"imageName": @"UIBarButtonItemList", @"methodName": @"longPressDeleteCamera:"},
                            @{@"title": @"", @"imageName": @"UIBarButtonItemGrid", @"methodName": @"longPressDeleteCamera:"},
        ];
    }
    
    return _displayWayItems;
}

- (ICatchFilesListViewModel *)listViewModel {
    if (_listViewModel == nil) {
        _listViewModel = [[ICatchFilesListViewModel alloc] init];
    }
    
    return _listViewModel;
}

- (dispatch_queue_t)thumbnailQueue {
    if (_thumbnailQueue == nil) {
        _thumbnailQueue = dispatch_queue_create("MoblieCamApp.MPB.Thumbnail", 0);
    }
    
    return _thumbnailQueue;
}

- (dispatch_semaphore_t)mpbSemaphore {
    if (_mpbSemaphore == nil) {
        _mpbSemaphore = dispatch_semaphore_create(1);
    }
    
    return _mpbSemaphore;
}

- (NSMutableArray *)actionFiles {
    if (_actionFiles == nil) {
        _actionFiles = [NSMutableArray array];
    }
    
    return _actionFiles;
}

- (NSMutableArray *)actionFileType {
    if (_actionFileType == nil) {
        _actionFileType = [NSMutableArray array];
    }
    
    return _actionFileType;
}

- (dispatch_queue_t)downloadQueue {
    if (_downloadQueue == nil) {
        _downloadQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.Download", 0);
    }
    
    return _downloadQueue;
}

- (dispatch_queue_t)downloadPercentQueue {
    if (_downloadPercentQueue == nil) {
        _downloadPercentQueue = dispatch_queue_create("WifiCam.GCD.Queue.Playback.DownloadPercent", 0);
    }
    
    return _downloadPercentQueue;
}

@end
