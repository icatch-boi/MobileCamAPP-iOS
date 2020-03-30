//
//  ICatchFilterPopupView.m
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/2.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import "ICatchFilterPopupView.h"
#import "ICatchPopupCollectionCell.h"
#import "ICatchDateSelectReusableView.h"
#import "ICatchTypeSelectReusableView.h"

static NSString * const kCollectionCellID = @"PopupCollectionCell";
static NSString * const kDateSelectReusableViewID = @"DateSelectReusableView";
static NSString * const kTypeSelectReusableViewID = @"TypeSelectReusableView";
static void * ICatchFilterPopupViewContext = &ICatchFilterPopupViewContext;

@interface ICatchFilterPopupView () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *collectionView;
// 是否是单行
@property (nonatomic, assign) BOOL isSingleRow;
// 数据源是否合法（数组的元素类型只能是字符串或数组类型）
@property (nonatomic, assign) BOOL isDataSourceValid;
@property (nonatomic, strong) NSArray *dataSource;
// 是否开启自动选择
@property (nonatomic, assign) BOOL isAutoSelect;
@property (nonatomic, copy) ICatchFilterResultBlock resultBlock;
// 单行选中的项
@property (nonatomic, copy) NSString *selectedItem;
// 多行选中的项
@property (nonatomic, strong) NSMutableArray *selectedItems;
@property (nonatomic, weak) ICatchDateSelectReusableView *dateSelectReusableView;
@property (nonatomic) MBProgressHUD *progressHUD;
@property (nonatomic, copy) NSString *startDate;
@property (nonatomic, copy) NSString *endDate;

@end

@implementation ICatchFilterPopupView

+ (void)showFilterPopupViewWithDataSource:(NSArray *)dataSource
                          defaultSelValue:(_Nullable id)defaultSelValue
                                startDate:(NSString * _Nullable)startDate
                                  endDate:(NSString * _Nullable)endDate
                             isAutoSelect:(BOOL)isAutoSelect
                              resultBlock:(ICatchFilterResultBlock)resultBlock {
    ICatchFilterPopupView *view = [[self alloc] initWithDataSource:dataSource defaultSelValue:defaultSelValue startDate:startDate endDate:endDate isAutoSelect:isAutoSelect resultBlock:resultBlock];
    [view showWithAnimation:YES];
}

#pragma mark - Init Filter PopupView
- (instancetype)initWithDataSource:(NSArray *)dataSource
                   defaultSelValue:(_Nullable id)defaultSelValue
                         startDate:(NSString * _Nullable)startDate
                           endDate:(NSString * _Nullable)endDate
                      isAutoSelect:(BOOL)isAutoSelect
                       resultBlock:(ICatchFilterResultBlock)resultBlock
{
    self = [super init];
    if (self) {
        self.dataSource = dataSource;
        self.isAutoSelect = isAutoSelect;
        self.resultBlock = resultBlock;
        
        if (defaultSelValue) {
            if ([defaultSelValue isKindOfClass:[NSString class]]) {
                self.selectedItem = defaultSelValue;
            } else if ([defaultSelValue isKindOfClass:[NSArray class]]) {
                self.selectedItems = [NSMutableArray arrayWithArray:defaultSelValue];
            }
            
            if ([[defaultSelValue firstObject] length] == 0) {
                self.startDate = startDate;
                self.endDate = endDate;
            }
        }
        
        [self loadData];
        [self initGUI];
        [self registerForNotifications];
    }
    return self;
}

- (void)dealloc {
    [self unregisterFromNotifications];
    
    [self removeSelectReusableViewObserver];
}

#pragma mark - 初始化子视图
- (void)initGUI {
    [super initGUI];
    
    [self.alertView addSubview:self.collectionView];
    [self updateAlertViewHeight];
}

- (void)updateLayout {
    [super updateLayout];
    
    self.collectionView.frame = CGRectMake(0, kTopCancelBtnHeight + kTopCancelBtnMargin, SCREEN_WIDTH, self.alertViewHeight - kTopCancelBtnHeight - 2 * kTopCancelBtnMargin);
    [self updateAlertViewHeight];    
}

#pragma mark - Notifications
- (void)registerForNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self selector:@selector(statusBarOrientationDidChange:)
               name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [nc addObserver:self selector:@selector(resignActiveHandle:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)unregisterFromNotifications {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    [nc removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)statusBarOrientationDidChange:(NSNotification *)notification {
    [self updateLayout];
}

- (void)resignActiveHandle:(NSNotification *)nc {
    [self dismissWithAnimation:NO];
}

#pragma mark - Update Frame
- (void)updateAlertViewHeight {
    CGFloat contentHeight = self.collectionView.collectionViewLayout.collectionViewContentSize.height;

    self.alertViewHeight = kTopCancelBtnHeight + 2 * kTopCancelBtnMargin + contentHeight;
}

- (void)setAlertViewHeight:(CGFloat)alertViewHeight {
    if (alertViewHeight > KAlertViewHeight || alertViewHeight <= 0) {
        return;
    }
    
    [super setAlertViewHeight:alertViewHeight];
    
    [self updateCollectionLayout];
}

- (void)updateCollectionLayout {
    CGRect rect = self.collectionView.frame;
    rect.size.height = self.alertViewHeight - kTopCancelBtnHeight - 2 * kTopCancelBtnMargin;
    self.collectionView.frame = rect;
}

#pragma mark - Load Data
- (void)loadData {
    if (self.dataSource == nil || self.dataSource.count == 0) {
        self.isDataSourceValid = NO;
        return;
    } else {
        self.isDataSourceValid = YES;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.dataSource enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        static Class itemType;
        if (idx == 0) {
            itemType = [obj class];
            // 判断数据源数组的第一个元素是什么类型

            if ([obj isKindOfClass:[NSArray class]]) {
                weakSelf.isSingleRow = NO;
            } else if ([obj isKindOfClass:[NSString class]]) {
                weakSelf.isSingleRow = YES;
            } else {
                weakSelf.isDataSourceValid = NO;
                return;
            }
        } else {
            // 判断数组的元素类型是否相同
            if (itemType != [obj class]) {
                weakSelf.isDataSourceValid = NO;
                *stop = YES;
                return;
            }
            
            if ([obj isKindOfClass:[NSArray class]]) {
                if (((NSArray *)obj).count == 0) {
                    weakSelf.isDataSourceValid = NO;
                    *stop = YES;
                    return;
                } else {
                    for (id subObj in obj) {
                        if (![subObj isKindOfClass:[NSString class]]) {
                            weakSelf.isDataSourceValid = NO;
                            *stop = YES;
                            return;
                        }
                    }
                }
            }
        }
    }];
    
    if (self.isSingleRow) {
        if (self.selectedItem == nil) {
#if 0
            self.selectedItem = _dataSource.firstObject;
#endif
        }
    } else {
        BOOL isSelectedItemsValid = YES;
        
        for (id obj in self.selectedItems) {
            if (![obj isKindOfClass:[NSString class]]) {
                isSelectedItemsValid = NO;
                break;
            }
        }
        
        if (self.selectedItems == nil || self.selectedItems.count != self.dataSource.count || !isSelectedItemsValid) {
            NSMutableArray *mutableArray = [NSMutableArray array];
            for (NSArray *sectionItem in _dataSource) {
#if 0
                [mutableArray addObject:sectionItem.firstObject];
#else
                [mutableArray addObject:@""];
#endif
            }
            
            self.selectedItems = [NSMutableArray arrayWithArray:mutableArray];
        }
    }
}

#pragma mark - 弹出视图
- (void)showWithAnimation:(BOOL)animation {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    
    [keyWindow addSubview:self];
    
    if (animation) {
        CGRect rect = self.alertView.frame;
        rect.origin.y = SCREEN_HEIGHT;
        self.alertView.frame = rect;
        
        [UIView animateWithDuration:0.3 animations:^{
            CGRect rect = self.alertView.frame;
            rect.origin.y -= self.alertViewHeight + kBottomViewHeight;
            self.alertView.frame = rect;
        }];
    }
}

#pragma mark - 关闭视图
- (void)dismissWithAnimation:(BOOL)animation {
    if (animation) {
        [UIView animateWithDuration:0.2 animations:^{
            CGRect rect = self.alertView.frame;
            rect.origin.y += self.alertViewHeight + kBottomViewHeight;
            self.alertView.frame = rect;
            
            self.backgroundView.alpha = 0;
        } completion:^(BOOL finished) {
            [self clearSubviews];
        }];
    } else {
        [self clearSubviews];
    }
}

- (void)clearSubviews {
    [self.leftButton removeFromSuperview];
    [self.rightButton removeFromSuperview];
    [self.lineView removeFromSuperview];
    [self.bottomView removeFromSuperview];
    [self.alertView removeFromSuperview];
    [self.backgroundView removeFromSuperview];
    [self removeFromSuperview];
    
    self.leftButton = nil;
    self.rightButton = nil;
    self.lineView = nil;
    self.bottomView = nil;
    self.alertView = nil;
    self.backgroundView = nil;
}

#pragma mark - 背景视图的点击事件
- (void)didTapBackgroundView:(UITapGestureRecognizer *)sender {
    [self dismissWithAnimation:YES];
    
    AppLog(@"TapBackgroundView");
    if (_resultBlock) {
        if (self.isSingleRow) {
            _resultBlock([self.selectedItem copy], self.dateSelectReusableView.startTextField.text, self.dateSelectReusableView.endTextField.text, PopupViewStateCancel);
        } else {
            _resultBlock([self.selectedItems copy], self.dateSelectReusableView.startTextField.text, self.dateSelectReusableView.endTextField.text, PopupViewStateCancel);
        }
    }
}


#pragma mark - 重置按钮的点击事件
- (void)clickLeftButton {
//    [self dismissWithAnimation:YES];
    AppLog(@"Clicked reset button");
    [self clearSelected];
    
    [self.collectionView reloadData];
    
    self.dateSelectReusableView.startTextField.text = @"";
    self.dateSelectReusableView.endTextField.text = @"";
    
    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    
    if (_resultBlock) {
        if (self.isSingleRow) {
            _resultBlock([self.selectedItem copy], self.dateSelectReusableView.startTextField.text, self.dateSelectReusableView.endTextField.text, PopupViewStateSelect);
        } else {
            _resultBlock([self.selectedItems copy], self.dateSelectReusableView.startTextField.text, self.dateSelectReusableView.endTextField.text, PopupViewStateSelect);
        }
    }
}

#pragma mark - 确定按钮的点击事件
- (void)clickRightButton {
    AppLog(@"点击确定按钮后，执行block回调");
    [self dismissWithAnimation:YES];
    
    if (_resultBlock) {
        if (self.isSingleRow) {
            _resultBlock([self.selectedItem copy], self.dateSelectReusableView.startTextField.text, self.dateSelectReusableView.endTextField.text, PopupViewStateConfirm);
        } else {
            _resultBlock([self.selectedItems copy], self.dateSelectReusableView.startTextField.text, self.dateSelectReusableView.endTextField.text, PopupViewStateConfirm);
        }
    }
}

#pragma mark - 取消按钮的点击事件
- (void)clickCancelButton {
    [self dismissWithAnimation:YES];
    
    AppLog(@"Clicked cancel button");
    if (_resultBlock) {
        if (self.isSingleRow) {
            _resultBlock([self.selectedItem copy], self.dateSelectReusableView.startTextField.text, self.dateSelectReusableView.endTextField.text, PopupViewStateCancel);
        } else {
            _resultBlock([self.selectedItems copy], self.dateSelectReusableView.startTextField.text, self.dateSelectReusableView.endTextField.text, PopupViewStateCancel);
        }
    }
}

#pragma mark - CollectionView
- (UICollectionView *)collectionView {
    if (_collectionView == nil) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, kTopCancelBtnHeight + kTopCancelBtnMargin, SCREEN_WIDTH, self.alertViewHeight - kTopCancelBtnHeight - 2 * kTopCancelBtnMargin) collectionViewLayout:[self makeCollctionLayout]];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        // 多选
        _collectionView.allowsMultipleSelection = YES;
        [_collectionView registerClass:ICatchPopupCollectionCell.class forCellWithReuseIdentifier:kCollectionCellID];
        [_collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([ICatchDateSelectReusableView class]) bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kDateSelectReusableViewID];
        [_collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([ICatchTypeSelectReusableView class]) bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kTypeSelectReusableViewID];

        [self defaultSelected];
    }
    
    return _collectionView;
}

- (UICollectionViewFlowLayout *)makeCollctionLayout {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(70, 28);
    layout.minimumLineSpacing = 12;
    layout.minimumInteritemSpacing = 12;
    layout.sectionInset = UIEdgeInsetsMake(5, 12, 5, 12);
//        layout.headerReferenceSize = CGSizeMake(SCREEN_WIDTH, 62);
    
    return layout;
}

- (void)defaultSelected {
    __weak typeof(self) weakSelf = self;
    if (self.isSingleRow) {
        [_dataSource enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([weakSelf.selectedItem isEqualToString:obj]) {
                [weakSelf.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                *stop = YES;
            }
        }];
    } else {
        [self.selectedItems enumerateObjectsUsingBlock:^(NSString *selectedItem, NSUInteger section, BOOL * _Nonnull stop) {
            [_dataSource[section] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([selectedItem isEqualToString:obj]) {
                    [weakSelf.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:idx inSection:section] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                    *stop = YES;
                }
            }];
        }];
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (self.isSingleRow) {
        return 1;
    } else {
        return _dataSource.count;
    }
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.isSingleRow) {
        return _dataSource.count;
    } else {
        return [_dataSource[section] count];
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ICatchPopupCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCollectionCellID forIndexPath:indexPath];

    if (self.isSingleRow) {
        cell.title = _dataSource[indexPath.item];
    } else {
        cell.title = _dataSource[indexPath.section][indexPath.item];
    }
    
    if (indexPath.section == 0) {
        BOOL enable = (self.dateSelectReusableView.startTextField.text.length == 0) && (self.dateSelectReusableView.endTextField.text.length == 0);
        cell.enabled = enable;
    }
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *view = [UICollectionReusableView new];

    if (kind == UICollectionElementKindSectionHeader) {
        if (indexPath.section == 0) {
            if (self.dateSelectReusableView != nil) {
                return self.dateSelectReusableView;
            }
            
            view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kDateSelectReusableViewID forIndexPath:indexPath];
            self.dateSelectReusableView = (ICatchDateSelectReusableView *)view;
            self.dateSelectReusableView.startTextField.text = self.startDate;
            self.dateSelectReusableView.endTextField.text = self.endDate;
        } else {
            view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kTypeSelectReusableViewID forIndexPath:indexPath];
        }
    }
    
    return view;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger count = 0;
    if (self.isSingleRow) {
        count = _dataSource.count;
    } else {
        count = [[_dataSource objectAtIndex:indexPath.section] count];
    }
    
    // 根据数据 把所有的都遍历一次 如果是当前点的cell 选中 如果不是 就不选中
    for (NSInteger i = 0; i < count; i++) {
        if (i == indexPath.item) {
            [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:indexPath.section] animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        } else {
            [self.collectionView deselectItemAtIndexPath:[NSIndexPath indexPathForItem:i inSection:indexPath.section] animated:NO];
        }
    }
    
    if (self.isSingleRow) {
        self.selectedItem = _dataSource[indexPath.item];
    } else {
        self.selectedItems[indexPath.section] = ((NSArray *)_dataSource[indexPath.section])[indexPath.item];
    }
    
    if (self.isAutoSelect) {
        if (_resultBlock) {
            if (self.isSingleRow) {
                _resultBlock([self.selectedItem copy], self.dateSelectReusableView.startTextField.text, self.dateSelectReusableView.endTextField.text, PopupViewStateSelect);
            } else {
                _resultBlock([self.selectedItems copy], self.dateSelectReusableView.startTextField.text, self.dateSelectReusableView.endTextField.text, PopupViewStateSelect);
            }
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
   // 如果点击了当前已经选中的cell 就忽略
    [collectionView selectItemAtIndexPath:[NSIndexPath indexPathForItem:indexPath.item inSection:indexPath.section] animated:YES scrollPosition:UICollectionViewScrollPositionNone];
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return CGSizeMake(SCREEN_WIDTH, 72);
    } else {
        return CGSizeMake(SCREEN_WIDTH, 42);
    }
}

- (void)setDateSelectReusableView:(ICatchDateSelectReusableView *)dateSelectReusableView {
    if (dateSelectReusableView == nil) {
        return;
    }
    
    _dateSelectReusableView = dateSelectReusableView;
    [self addSelectReusableViewObserver];
}

- (void)addSelectReusableViewObserver {
    if (_dateSelectReusableView == nil) {
        return;
    }
    
    [_dateSelectReusableView.startTextField addObserver:self forKeyPath:NSStringFromSelector(@selector(text)) options:NSKeyValueObservingOptionNew context:ICatchFilterPopupViewContext];
    [_dateSelectReusableView.endTextField addObserver:self forKeyPath:NSStringFromSelector(@selector(text)) options:NSKeyValueObservingOptionNew context:ICatchFilterPopupViewContext];
}

- (void)removeSelectReusableViewObserver {
    if (_dateSelectReusableView == nil) {
        return;
    }
    
    [_dateSelectReusableView.startTextField removeObserver:self forKeyPath:NSStringFromSelector(@selector(text)) context:ICatchFilterPopupViewContext];
    [_dateSelectReusableView.endTextField removeObserver:self forKeyPath:NSStringFromSelector(@selector(text)) context:ICatchFilterPopupViewContext];
}

#pragma mark - Observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == ICatchFilterPopupViewContext) {
        if ([keyPath isEqualToString:@"text"]) {
            if (self.dateSelectReusableView.startTextField.text.length > 0 ||
                self.dateSelectReusableView.endTextField.text.length > 0) {
                [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
                
                if (self.dateSelectReusableView.startTextField.text.length != 0 ||
                    self.dateSelectReusableView.endTextField.text.length != 0) {
                    [self clearSelected];
                }
                
                [self checkSelectDateIsValid];
                
                if (self.isAutoSelect) {
                    if (_resultBlock) {
                        if (self.isSingleRow) {
                            _resultBlock([self.selectedItem copy], self.dateSelectReusableView.startTextField.text, self.dateSelectReusableView.endTextField.text, PopupViewStateSelect);
                        } else {
                            _resultBlock([self.selectedItems copy], self.dateSelectReusableView.startTextField.text, self.dateSelectReusableView.endTextField.text, PopupViewStateSelect);
                        }
                    }
                }
            }
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)clearSelected {
    if (self.isSingleRow) {
        self.selectedItem = nil;
    } else {
        for (int i = 0; i < self.selectedItems.count; i++) {
            [self.selectedItems replaceObjectAtIndex:i withObject:@""];
        }
    }
}

- (void)checkSelectDateIsValid {
    if (self.dateSelectReusableView.startTextField.text.length == 0 ||
        self.dateSelectReusableView.endTextField.text.length == 0) {
        AppLog(@"Start date: %@, end date: %@", self.dateSelectReusableView.startTextField.text, self.dateSelectReusableView.endTextField.text);
        return;
    }
    
    NSComparisonResult result = [self.dateSelectReusableView.startTextField.text compare:self.dateSelectReusableView.endTextField.text];
    if (result == NSOrderedDescending) {
        AppLog(@"Select date is invalid.");
        [self showInvalidDateAlertView];
    }
}

- (void)showInvalidDateAlertView {
    [self showProgressHUDWithMessage:NSLocalizedString(@"Tips", nil) detailsMessage:NSLocalizedString(@"kSelectedTimeInvalid", nil)/*@"The selected time zone is invalid, please select again."*/ showTime:2.5];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.dateSelectReusableView.startTextField.text = @"";
        self.dateSelectReusableView.endTextField.text = @"";
        [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
    });
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self];
        _progressHUD.minSize = CGSizeMake(120, 120);
        _progressHUD.minShowTime = 1;
        // The sample image is based on the
        // work by: http://www.pixelpressicons.com
        // licence: http://creativecommons.org/licenses/by/2.5/ca/
        self.progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]];
        [self addSubview:_progressHUD];
    }
    
    return _progressHUD;
}

- (void)showProgressHUDWithMessage:(NSString *)message
                    detailsMessage:(NSString *)dMessage
                              showTime:(NSTimeInterval)time {
    AppLog(@"%s", __func__);
    self.progressHUD.labelText = message;
    self.progressHUD.detailsLabelText = dMessage;
    self.progressHUD.mode = MBProgressHUDModeText;
    self.progressHUD.dimBackground = YES;
    [self bringSubviewToFront:self.progressHUD];
    [self.progressHUD show:YES];
    [self.progressHUD hide:YES afterDelay:time];
}

@end
