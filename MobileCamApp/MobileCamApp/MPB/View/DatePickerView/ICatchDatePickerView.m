//
//  ICatchDatePickerView.m
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/6.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import "ICatchDatePickerView.h"

@interface ICatchDatePickerView () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, strong) UIView *backgroundView;
@property (nonatomic, strong) UIView *alertView;

@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UIView *toolView;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;
@property (nonatomic, strong) UIView *lineView;

@property (nonatomic, strong) NSMutableArray *dataArray;
@property (nonatomic, copy) NSString *selectValue;

@property (nonatomic, strong) NSMutableArray *yearArray;
@property (nonatomic, strong) NSMutableArray *monthArray;
@property (nonatomic, strong) NSMutableArray *dayArray;
@property (nonatomic, strong) NSMutableArray *hourArray;
@property (nonatomic, strong) NSArray *currentDate;
@property (nonatomic, strong) NSArray *selectDate;

@property (nonatomic, copy) NSString *year;
@property (nonatomic, copy) NSString *month;
@property (nonatomic, copy) NSString *day;
@property (nonatomic, copy) NSString *hour;

@property (nonatomic, assign) BOOL isAutoSelect;
@property (nonatomic, copy) ICatchDateResultBlock resultBlock;

@end

@implementation ICatchDatePickerView

@synthesize selectValue = _selectValue;

+ (void)showDatePickerWithTitle:(NSString *)title defaultSelValue:(NSString *)defaultSelValue isAutoSelect:(BOOL)isAutoSelect resultBlock:(ICatchDateResultBlock)resultBlock {
    ICatchDatePickerView *view = [[ICatchDatePickerView alloc] initWithTitle:title defaultSelValue:defaultSelValue isAutoSelect:isAutoSelect resultBlock:resultBlock];
    [view showWithAnimation:YES];
}

- (instancetype)initWithTitle:(NSString *)title defaultSelValue:(NSString *)defaultSelValue isAutoSelect:(BOOL)isAutoSelect resultBlock:(ICatchDateResultBlock)resultBlock {
    self = [super init];
    if (self) {
        self.titleLabel.text = title;
        self.isAutoSelect = isAutoSelect;
        self.resultBlock = resultBlock;
        
        if (defaultSelValue.length > 0) {
            self.selectValue = defaultSelValue;
        } else {
            self.selectValue = [self toStringWithDate:[NSDate date]];
        }
        
        [self prepareData];
        [self setupGUI];
        [self registerForNotifications];
    }
    
    return self;
}

- (void)dealloc {
    [self unregisterFromNotifications];
}

- (void)setupGUI {
    self.frame = SCREEN_BOUNDS;
    
    [self addSubview:self.backgroundView];
    [self addSubview:self.alertView];
    
    [self.alertView addSubview:self.toolView];
    [self.toolView addSubview:self.leftButton];
    [self.toolView addSubview:self.rightButton];
    [self.toolView addSubview:self.titleLabel];
    [self.toolView addSubview:self.lineView];
    [self.alertView addSubview:self.pickerView];
}

- (void)updateLayout {
    self.frame = SCREEN_BOUNDS;
    self.backgroundView.frame = SCREEN_BOUNDS;
    self.alertView.frame = CGRectMake(0, SCREEN_HEIGHT - KDatePickerViewHeight, SCREEN_WIDTH, KDatePickerViewHeight);
    self.toolView.frame = CGRectMake(0, 0, SCREEN_WIDTH, kTopViewHeight + 0.5);
    self.leftButton.frame = CGRectMake(10, 2, 40, 40);
    self.rightButton.frame = CGRectMake(self.frame.size.width - 50, 2, 40, 40);
    self.titleLabel.frame = CGRectMake(65, 0, SCREEN_WIDTH - 130, kTopViewHeight);
    self.lineView.frame = CGRectMake(0, kTopViewHeight, SCREEN_WIDTH, 0.5);
    self.pickerView.frame = CGRectMake(0, kTopViewHeight + 0.5, SCREEN_WIDTH, KDatePickerViewHeight - kTopViewHeight - 0.5);
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

#pragma mark - 背景遮罩图层
- (UIView *)backgroundView {
    if (_backgroundView == nil) {
        _backgroundView = [[UIView alloc]initWithFrame:SCREEN_BOUNDS];
        _backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.20];
        _backgroundView.userInteractionEnabled = YES;
        UITapGestureRecognizer *myTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(didTapBackgroundView:)];
        [_backgroundView addGestureRecognizer:myTap];
    }
    
    return _backgroundView;
}

#pragma mark - 弹出视图
- (UIView *)alertView {
    if (_alertView == nil) {
        _alertView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - KDatePickerViewHeight, SCREEN_WIDTH, KDatePickerViewHeight)];
        _alertView.backgroundColor = [UIColor whiteColor];
    }
    
    return _alertView;
}

#pragma mark - 顶部工具栏视图
- (UIView *)toolView {
    if (_toolView == nil) {
        _toolView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, kTopViewHeight + 0.5)];
        _toolView.backgroundColor = RGB_HEX(0xFDFDFD, 1.0f);
    }
    
    return _toolView;
}

#pragma mark - 左边取消按钮
- (UIButton *)leftButton {
    if (_leftButton == nil) {
        _leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _leftButton.frame = CGRectMake(10, 2, 40, 40);
        [_leftButton setImage:[UIImage imageNamed:@"icon_revocation1"] forState:UIControlStateNormal];
        [_leftButton addTarget:self action:@selector(cancelButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _leftButton;
}

#pragma mark - 右边确定按钮
- (UIButton *)rightButton {
    if (_rightButton == nil) {
        _rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _rightButton.frame = CGRectMake(self.frame.size.width - 50, 2, 40, 40);
        [_rightButton setImage:[UIImage imageNamed:@"icon_select1"] forState:UIControlStateNormal];
        [_rightButton addTarget:self action:@selector(sureButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _rightButton;
}

#pragma mark - 中间标题按钮
- (UILabel *)titleLabel {
    if (_titleLabel == nil) {
        _titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(65, 0, SCREEN_WIDTH - 130, kTopViewHeight)];
        _titleLabel.backgroundColor = [UIColor clearColor];
//        _titleLabel.font = [UIFont systemFontOfSize:14.0f];
        _titleLabel.textColor = RGB_HEX(0xFF7998, 1.0);
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    return _titleLabel;
}

#pragma mark - 分割线
- (UIView *)lineView {
    if (_lineView == nil) {
        _lineView = [[UIView alloc]initWithFrame:CGRectMake(0, kTopViewHeight, SCREEN_WIDTH, 0.5)];
        _lineView.backgroundColor  = [UIColor colorWithRed:225 / 255.0 green:225 / 255.0 blue:225 / 255.0 alpha:1.0];
        [self.alertView addSubview:_lineView];
    }
    
    return _lineView;
}

#pragma mark - 时间选择器
- (UIPickerView *)pickerView {
    if (_pickerView == nil) {
        _pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, kTopViewHeight + 0.5, SCREEN_WIDTH, KDatePickerViewHeight - kTopViewHeight - 0.5)];
        _pickerView.backgroundColor = [UIColor whiteColor];
        _pickerView.dataSource = self;
        _pickerView.delegate = self;
        _pickerView.showsSelectionIndicator = YES;
    }
    
    return _pickerView;
}

#pragma mark - Load Data
- (void)prepareData {
    self.dataArray = [NSMutableArray array];
    
    [self.dataArray addObject:self.yearArray];
    [self.dataArray addObject:self.monthArray];
    [self.dataArray addObject:self.dayArray];
    [self.dataArray addObject:self.hourArray];
}

- (void)setSelectValue:(NSString *)selectValue {
    _selectValue = selectValue;
    
    NSString *newDate = [selectValue stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    NSMutableArray *timerArray = [NSMutableArray arrayWithArray:[newDate componentsSeparatedByString:@" "]];
       [timerArray replaceObjectAtIndex:0 withObject:[NSString stringWithFormat:@"%@", timerArray[0]]];
     [timerArray replaceObjectAtIndex:1 withObject:[NSString stringWithFormat:@"%@", timerArray[1]]];
     [timerArray replaceObjectAtIndex:2 withObject:[NSString stringWithFormat:@"%@", timerArray[2]]];
     [timerArray replaceObjectAtIndex:3 withObject:[NSString stringWithFormat:@"%@", timerArray[3]]];
    self.selectDate = timerArray;
}

- (NSMutableArray *)prepareCurrentDate {
    NSString *newDate = [[self toStringWithDate:[NSDate date]] stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    NSMutableArray *timerArray = [NSMutableArray arrayWithArray:[newDate componentsSeparatedByString:@" "]];
       [timerArray replaceObjectAtIndex:0 withObject:[NSString stringWithFormat:@"%@", timerArray[0]]];
     [timerArray replaceObjectAtIndex:1 withObject:[NSString stringWithFormat:@"%@", timerArray[1]]];
     [timerArray replaceObjectAtIndex:2 withObject:[NSString stringWithFormat:@"%@", timerArray[2]]];
     [timerArray replaceObjectAtIndex:3 withObject:[NSString stringWithFormat:@"%@", timerArray[3]]];
    
    return timerArray;
}

#pragma mark - 弹出视图
- (void)showWithAnimation:(BOOL)animation {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    
    [keyWindow addSubview:self];
    [self show];
    
    if (animation) {
        CGRect rect = self.alertView.frame;
        rect.origin.y = SCREEN_HEIGHT;
        self.alertView.frame = rect;
        
        [UIView animateWithDuration:0.3 animations:^{
            CGRect rect = self.alertView.frame;
            rect.origin.y -= KDatePickerViewHeight;
            self.alertView.frame = rect;
        }];
    }
}

#pragma mark - 关闭视图
- (void)dismissWithAnimation:(BOOL)animation {
    if (animation) {
        [UIView animateWithDuration:0.2 animations:^{
            CGRect rect = self.alertView.frame;
            rect.origin.y += KDatePickerViewHeight;
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
    [self.titleLabel removeFromSuperview];
    [self.lineView removeFromSuperview];
    [self.toolView removeFromSuperview];
    [self.pickerView removeFromSuperview];
    [self.alertView removeFromSuperview];
    [self.backgroundView removeFromSuperview];
    [self removeFromSuperview];
    
    self.leftButton = nil;
    self.rightButton = nil;
    self.titleLabel = nil;
    self.lineView = nil;
    self.toolView = nil;
    self.pickerView = nil;
    self.alertView = nil;
    self.backgroundView = nil;
}

- (void)show {
    self.year = self.selectDate[0];
    self.month = [NSString stringWithFormat:@"%ld", (long)[self.selectDate[1] integerValue]];
    self.day = [NSString stringWithFormat:@"%ld", (long)[self.selectDate[2] integerValue]];
    self.hour = [NSString stringWithFormat:@"%ld", (long)[self.selectDate[3] integerValue]];
    
    [self.pickerView selectRow:[self.yearArray indexOfObject:self.year] inComponent:0 animated:NO];
    /// 重新格式化转一下，是因为如果是09月/日/时，数据源是9月/日/时,就会出现崩溃
    [self.pickerView selectRow:[self.monthArray indexOfObject:self.month] inComponent:1 animated:NO];
    [self.pickerView selectRow:[self.dayArray indexOfObject:self.day] inComponent:2 animated:NO];
    [self.pickerView selectRow:[self.hourArray indexOfObject:self.hour] inComponent:3 animated:NO];
    
    /// 刷新日
    [self refreshDay];
}

- (NSString *)selectValue {
    NSString *month = self.month.length == 2 ? [NSString stringWithFormat:@"%ld", (long)self.month.integerValue] : [NSString stringWithFormat:@"0%ld", self.month.integerValue];
    NSString *day = self.day.length == 2 ? [NSString stringWithFormat:@"%ld", (long)self.day.integerValue] : [NSString stringWithFormat:@"0%ld", self.day.integerValue];
    NSString *hour = self.hour.length == 2 ? [NSString stringWithFormat:@"%ld", (long)self.hour.integerValue] : [NSString stringWithFormat:@"0%ld", self.hour.integerValue];
    
    _selectValue = [NSString stringWithFormat:@"%ld-%@-%@ %@", (long)[self.year integerValue], month, day, hour];
    return _selectValue;
}

#pragma mark - 点击背景遮罩图层事件
- (void)didTapBackgroundView:(UITapGestureRecognizer *)sender {
    [self dismissWithAnimation:YES];
}

#pragma mark - 点击方法
/// 保存按钮点击方法
- (void)sureButtonClick {
    NSLog(@"点击了保存");
    [self dismissWithAnimation:YES];
    
    __weak typeof(self) weakSelf = self;
    if (_resultBlock) {
        _resultBlock(weakSelf.selectValue);
    }
}

/// 取消按钮点击方法
- (void)cancelButtonClick {
    NSLog(@"点击了取消");
    [self dismissWithAnimation:YES];
}

#pragma mark - UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return self.dataArray.count;
}

/// UIPickerView返回每组多少条数据
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return  [self.dataArray[component] count];
}

#pragma mark - UIPickerViewDelegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.dataArray[component][row];
}

/// UIPickerView返回每一行的高度
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 44;
}

/// UIPickerView返回每一行的View
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *titleLbl;
    if (!view) {
        titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, self.frame.size.width, 44)];
        titleLbl.font = [UIFont systemFontOfSize:15];
        titleLbl.textAlignment = NSTextAlignmentCenter;
    } else {
        titleLbl = (UILabel *)view;
    }
    titleLbl.text = self.dataArray[component][row];
    
    return titleLbl;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSInteger currentValue = [self.currentDate[component] integerValue];
    switch (component) {
        case 0: { // 年
            
            NSString *year_integerValue = self.yearArray[row%[self.dataArray[component] count]];
            if (year_integerValue.integerValue > currentValue) {
                [pickerView selectRow:[self.dataArray[component] indexOfObject:self.currentDate[component]] inComponent:component animated:YES];
                self.year = self.currentDate[component];
                
                // correction
                if (self.month.integerValue > [self.currentDate[1] integerValue]) {
                    [pickerView selectRow:[self.dataArray[1] indexOfObject:[NSString stringWithFormat:@"%ld", (long)[self.currentDate[1] integerValue]]] inComponent:1 animated:YES];
                    self.month = [NSString stringWithFormat:@"%ld", (long)[self.currentDate[1] integerValue]];
                }
                
                if (self.day.integerValue > [self.currentDate[2] integerValue]) {
                    [pickerView selectRow:[self.dataArray[2] indexOfObject:[NSString stringWithFormat:@"%ld", (long)[self.currentDate[2] integerValue]]] inComponent:2 animated:YES];
                    self.day = [NSString stringWithFormat:@"%ld", (long)[self.currentDate[2] integerValue]];
                }
                
                if (self.hour.integerValue > [self.currentDate[3] integerValue]) {
                    [pickerView selectRow:[self.dataArray[3] indexOfObject:[NSString stringWithFormat:@"%ld", (long)[self.currentDate[3] integerValue]]] inComponent:3 animated:YES];
                    self.hour = [NSString stringWithFormat:@"%ld", (long)[self.currentDate[3] integerValue]];
                }
            } else if (year_integerValue.integerValue == currentValue) {
                self.year = year_integerValue;

                // correction
                if (self.month.integerValue > [self.currentDate[1] integerValue]) {
                    [pickerView selectRow:[self.dataArray[1] indexOfObject:[NSString stringWithFormat:@"%ld", (long)[self.currentDate[1] integerValue]]] inComponent:1 animated:YES];
                    self.month = [NSString stringWithFormat:@"%ld", (long)[self.currentDate[1] integerValue]];
                }
                
                if (self.day.integerValue > [self.currentDate[2] integerValue]) {
                    [pickerView selectRow:[self.dataArray[2] indexOfObject:[NSString stringWithFormat:@"%ld", (long)[self.currentDate[2] integerValue]]] inComponent:2 animated:YES];
                    self.day = [NSString stringWithFormat:@"%ld", (long)[self.currentDate[2] integerValue]];
                }
                
                if (self.hour.integerValue > [self.currentDate[3] integerValue]) {
                    [pickerView selectRow:[self.dataArray[3] indexOfObject:[NSString stringWithFormat:@"%ld", (long)[self.currentDate[3] integerValue]]] inComponent:3 animated:YES];
                    self.hour = [NSString stringWithFormat:@"%ld", (long)[self.currentDate[3] integerValue]];
                }
            } else {
                self.year = year_integerValue;
            }
        } break;
        case 1: { // 月
            
            NSString *month_value = self.monthArray[row%[self.dataArray[component] count]];
            if ([self.year integerValue] < [self.currentDate[0] integerValue]) {
                self.month = month_value;
            } else {
                if (month_value.integerValue > currentValue) {
                    [pickerView selectRow:[self.dataArray[component] indexOfObject:[NSString stringWithFormat:@"%ld", (long)currentValue]] inComponent:component animated:YES];
                    self.month = [NSString stringWithFormat:@"%ld", (long)currentValue];
                    
                    // correction
                    if (self.day.integerValue > [self.currentDate[2] integerValue]) {
                        [pickerView selectRow:[self.dataArray[2] indexOfObject:[NSString stringWithFormat:@"%ld", (long)[self.currentDate[2] integerValue]]] inComponent:2 animated:YES];
                        self.day = [NSString stringWithFormat:@"%ld", (long)[self.currentDate[2] integerValue]];
                    }
                    
                    if (self.hour.integerValue > [self.currentDate[3] integerValue]) {
                        [pickerView selectRow:[self.dataArray[3] indexOfObject:[NSString stringWithFormat:@"%ld", (long)[self.currentDate[3] integerValue]]] inComponent:3 animated:YES];
                        self.hour = [NSString stringWithFormat:@"%ld", (long)[self.currentDate[3] integerValue]];
                    }
                } else if (month_value.integerValue == currentValue) {
                    self.month = month_value;

                    // correction
                    if (self.day.integerValue > [self.currentDate[2] integerValue]) {
                        [pickerView selectRow:[self.dataArray[2] indexOfObject:[NSString stringWithFormat:@"%ld", (long)[self.currentDate[2] integerValue]]] inComponent:2 animated:YES];
                        self.day = [NSString stringWithFormat:@"%ld", (long)[self.currentDate[2] integerValue]];
                    }
                    
                    if (self.hour.integerValue > [self.currentDate[3] integerValue]) {
                        [pickerView selectRow:[self.dataArray[3] indexOfObject:[NSString stringWithFormat:@"%ld", (long)[self.currentDate[3] integerValue]]] inComponent:3 animated:YES];
                        self.hour = [NSString stringWithFormat:@"%ld", (long)[self.currentDate[3] integerValue]];
                    }
                } else {
                    self.month = month_value;
                }
            }
            /// 刷新日
            [self refreshDay];
        } break;
        case 2: { // 日
            // 如果选择年大于当前年 就直接赋值日
            NSString *day_value = self.dayArray[row%[self.dataArray[component] count]];

            if ([self.year integerValue] < [self.currentDate[0] integerValue]) {
                self.day = day_value;
            } else if ([self.year integerValue] == [self.currentDate[0] integerValue]) {
                if ([self.month integerValue] < [self.currentDate[1] integerValue]) {
                    self.day = day_value;
                } else if ([self.month integerValue] == [self.currentDate[1] integerValue]) {
                    if (day_value.integerValue > currentValue) {
                        [pickerView selectRow:[self.dataArray[component] indexOfObject:[NSString stringWithFormat:@"%ld", (long)currentValue]] inComponent:component animated:YES];
                        self.day = [NSString stringWithFormat:@"%ld", (long)currentValue];
                        
                        // correction
                        if (self.hour.integerValue > [self.currentDate[3] integerValue]) {
                            [pickerView selectRow:[self.dataArray[3] indexOfObject:[NSString stringWithFormat:@"%ld", (long)[self.currentDate[3] integerValue]]] inComponent:3 animated:YES];
                            self.hour = [NSString stringWithFormat:@"%ld", (long)[self.currentDate[3] integerValue]];
                        }
                    } else if (day_value.integerValue == currentValue) {
                        self.day = day_value;

                        // correction
                        if (self.hour.integerValue > [self.currentDate[3] integerValue]) {
                            [pickerView selectRow:[self.dataArray[3] indexOfObject:[NSString stringWithFormat:@"%ld", (long)[self.currentDate[3] integerValue]]] inComponent:3 animated:YES];
                            self.hour = [NSString stringWithFormat:@"%ld", (long)[self.currentDate[3] integerValue]];
                        }
                    } else {
                        self.day = day_value;
                    }
                }
            }
        } break;
        case 3: { // 时
            NSString *hour_value = self.hourArray[row%[self.dataArray[component] count]];
            
            if ([self.year integerValue] < [self.currentDate[0] integerValue]) {
                self.hour = hour_value;
            } else if ([self.year integerValue] == [self.currentDate[0] integerValue]) {
                if ([self.month integerValue] < [self.currentDate[1] integerValue]) {
                    self.hour = hour_value;
                } else if ([self.month integerValue] == [self.currentDate[1] integerValue]) {
                    if ([self.day integerValue] < [self.currentDate[2] integerValue]) {
                        self.hour = hour_value;
                    } else if ([self.day integerValue] == [self.currentDate[2] integerValue]) {
                        if (hour_value.integerValue > currentValue) {
                            [pickerView selectRow:[self.dataArray[component] indexOfObject:[NSString stringWithFormat:@"%ld", (long)[self.currentDate[3] integerValue]]] inComponent:component animated:YES];
                            self.hour = [NSString stringWithFormat:@"%ld", (long)[self.currentDate[3] integerValue]];
                        } else {
                            self.hour = hour_value;
                        }
                    }
                }
            }
        } break;

        default: break;
    }
    
    if (self.isAutoSelect) {
        __weak typeof(self) weakSelf = self;
        if (_resultBlock) {
            _resultBlock(weakSelf.selectValue);
        }
    }
}

#pragma mark - 获取年份
- (NSMutableArray *)yearArray {
    if (_yearArray == nil) {
        _yearArray = [NSMutableArray array];
        
        NSInteger year = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]];
        NSInteger dVaule = 100;
        for (NSInteger i = year - dVaule; i <= year + dVaule; i++) {
            [_yearArray addObject:[NSString stringWithFormat:@"%ld", (long)i]];
        }
    }
    
    return _yearArray;
}

#pragma mark - 获取月份
- (NSMutableArray *)monthArray {
    if (_monthArray == nil) {
        _monthArray = [NSMutableArray array];
        for (int i = 1; i <= 12; i++) {
            [_monthArray addObject:[NSString stringWithFormat:@"%d", i]];
        }
    }
    
    return _monthArray;
}

#pragma mark - 获取当月天数
- (NSMutableArray *)dayArray {
    if (_dayArray == nil) {
        _dayArray = [NSMutableArray array];
        for (int i = 1; i <= 31; i++) {
            [_dayArray addObject:[NSString stringWithFormat:@"%d", i]];
        }
    }
    
    return _dayArray;
}

#pragma mark - 获取小时
- (NSMutableArray *)hourArray {
    if (_hourArray == nil) {
        _hourArray = [NSMutableArray array];
        for (int i = 0; i < 24; i++) {
            [_hourArray addObject:[NSString stringWithFormat:@"%d", i]];
        }
    }
    
    return _hourArray;
}

- (NSArray *)currentDate {
    if (_currentDate == nil) {
        _currentDate = [self prepareCurrentDate].copy; //[NSArray array];
    }
    
    return _currentDate;
}

#pragma mark - 格式转换：NSDate --> NSString
- (NSString *)toStringWithDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH"];
    NSString *destDateString = [dateFormatter stringFromDate:date];
    
    return destDateString;
}

- (void)refreshDay {
    NSMutableArray *arr = [NSMutableArray array];
    for (int i = 1; i < [self getDayNumber:self.year.integerValue month:self.month.integerValue].integerValue + 1; i ++) {
        [arr addObject:[NSString stringWithFormat:@"%d", i]];
    }
    
    [self.dataArray replaceObjectAtIndex:2 withObject:arr];
    [self.pickerView reloadComponent:2];
}

- (NSString *)getDayNumber:(NSInteger)year month:(NSInteger)month {
    NSArray *days = @[@"31", @"28", @"31", @"30", @"31", @"30", @"31", @"31", @"30", @"31", @"30", @"31"];
    if (2 == month && 0 == (year % 4) && (0 != (year % 100) || 0 == (year % 400))) {
        return @"29";
    }
    return days[month - 1];
}

@end
