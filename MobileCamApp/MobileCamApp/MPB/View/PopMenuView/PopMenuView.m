//
//  PopMenuView.m
//  QQPopMenuView
//
//  Created by ZJ on 2019/10/12.
//  Copyright © 2019 ZJ. All rights reserved.
//

#import "PopMenuView.h"

#ifndef SCREEN_WIDTH
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#endif

static CGFloat const kCellHeight = 44;
static CGFloat const kIconHeight = 32;
static CGFloat const kMargin = 10;

@interface PopMenuTableViewCell : UITableViewCell

@property (nonatomic, strong) UIImageView *leftImageView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@interface PopMenuView ()<UITableViewDelegate,UITableViewDataSource,UIGestureRecognizerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *tableData;
@property (nonatomic, assign) CGPoint trianglePoint;
@property (nonatomic, assign) PopMenuAnimationDirection animationDirection;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, copy) void(^action)(NSInteger index);

@end

@implementation PopMenuView

- (instancetype)initWithItems:(NSArray <NSDictionary *>*)array
                        width:(CGFloat)width
             triangleLocation:(CGPoint)point
           animationDirection:(PopMenuAnimationDirection)direction
                       action:(void(^)(NSInteger index))action
{
    if (array.count == 0) return nil;
    if (self = [super init]) {
        self.frame = [UIScreen mainScreen].bounds;
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        self.alpha = 0;
        _tableData = [array copy];
        _trianglePoint = point;
        self.action = action;
        self.animationDirection = direction;
        self.width = width;
        
        // 添加手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)];
        tap.delegate = self;
        [self addGestureRecognizer:tap];
        
        
        // 创建tableView
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - width - 5, point.y + 10, width, kCellHeight * array.count) style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.layer.masksToBounds = YES;
        _tableView.layer.cornerRadius = 5;
        _tableView.scrollEnabled = NO;
        _tableView.rowHeight = kCellHeight;
        [_tableView registerClass:[PopMenuTableViewCell class] forCellReuseIdentifier:@"PopMenuTableViewCell"];
        [self addSubview:_tableView];
        
    }
    return self;
}

+ (void)showWithItems:(NSArray <NSDictionary *>*)array
                width:(CGFloat)width
     triangleLocation:(CGPoint)point
   animationDirection:(PopMenuAnimationDirection)direction
               action:(void(^)(NSInteger index))action
{
    PopMenuView *view = [[PopMenuView alloc] initWithItems:array width:width triangleLocation:point animationDirection:direction action:action];
    [view show];
}

- (void)tap {
    [self hide];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:NSClassFromString(@"UITableViewCellContentView")]) {
        return NO;
    }
    return YES;
}

#pragma mark - show or hide
- (void)show {
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    // 设置右上角为transform的起点（默认是中心点）
    CGFloat y = (self.animationDirection == PopMenuAnimationDirectionDown) ? _trianglePoint.y + 10 : _trianglePoint.y - 10;
    CGFloat x;
    if (self.animationDirection == PopMenuAnimationDirectionDown) {
        if (self.trianglePoint.x <= self.width * 0.5 + 5) {
            x = 5 + self.width;
        } else if (self.trianglePoint.x + self.width * 0.5 + 5 < SCREEN_WIDTH) {
            x = self.trianglePoint.x - self.width * 0.5 + self.width;
        } else {
            x = SCREEN_WIDTH - 5;
        }
    } else {
        if (self.trianglePoint.x <= self.width * 0.5 + 5) {
            x = 5;
        } else if (self.trianglePoint.x + self.width * 0.5 + 5 < SCREEN_WIDTH) {
            x = self.trianglePoint.x - self.width * 0.5;
        } else {
            x = SCREEN_WIDTH - 5 - self.width;
        }
    }
    
    _tableView.layer.position = CGPointMake(x, y);
    // 向右下transform
    _tableView.layer.anchorPoint = (self.animationDirection == PopMenuAnimationDirectionDown) ? CGPointMake(1, 0) : CGPointMake(0, 1);
    _tableView.transform = CGAffineTransformMakeScale(0.0001, 0.0001);
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 1;
        _tableView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }];
}

- (void)hide {
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0;
        _tableView.transform = CGAffineTransformMakeScale(0.0001, 0.0001);
    } completion:^(BOOL finished) {
        [_tableView removeFromSuperview];
        [self removeFromSuperview];
        if (self.hideHandle) {
            self.hideHandle();
        }
    }];
}

#pragma mark - Draw triangle
- (void)drawRect:(CGRect)rect {
    // 设置背景色
    [[UIColor whiteColor] set];
    //拿到当前视图准备好的画板
    CGContextRef context = UIGraphicsGetCurrentContext();
    //利用path进行绘制三角形
    CGContextBeginPath(context);
    CGPoint point = _trianglePoint;
    // 设置起点
    CGContextMoveToPoint(context, point.x, point.y);
    // 画线
    if (self.animationDirection == PopMenuAnimationDirectionDown) {
        CGContextAddLineToPoint(context, point.x - 10, point.y + 10);
        CGContextAddLineToPoint(context, point.x + 10, point.y + 10);
    } else {
        CGContextAddLineToPoint(context, point.x - 10, point.y - 10);
        CGContextAddLineToPoint(context, point.x + 10, point.y - 10);
    }
    CGContextClosePath(context);
    // 设置填充色
    [[UIColor whiteColor] setFill];
    // 设置边框颜色
    [[UIColor whiteColor] setStroke];
    // 绘制路径
    CGContextDrawPath(context, kCGPathFillStroke);
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PopMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PopMenuTableViewCell" forIndexPath:indexPath];
    NSDictionary *dic = _tableData[indexPath.row];
    cell.leftImageView.image = [[UIImage imageNamed:dic[@"imageName"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.titleLabel.text = dic[@"title"];
    [cell.titleLabel sizeToFit];
//    cell.titleLabel.center = CGPointMake(cell.titleLabel.center.x, cell.center.y);
    cell.titleLabel.frame = CGRectMake(CGRectGetMaxX(cell.leftImageView.frame) + kMargin, (kCellHeight - CGRectGetHeight(cell.titleLabel.frame)) / 2, CGRectGetWidth(cell.titleLabel.frame), CGRectGetHeight(cell.titleLabel.frame));
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.layoutMargins = UIEdgeInsetsZero;
    cell.separatorInset = UIEdgeInsetsZero;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self hide];
    if (_action) {
        _action(indexPath.row);
    }
}

@end

#pragma mark - PopMenuTableViewCell
@implementation PopMenuTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        _leftImageView = [[UIImageView alloc] initWithFrame:CGRectMake(kMargin, (kCellHeight - kIconHeight) / 2, kIconHeight, kIconHeight)];
        _leftImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:_leftImageView];
        
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_leftImageView.frame) + kMargin, _leftImageView.frame.origin.y, 0, 0)];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:16];
        [self.contentView addSubview:_titleLabel];
        
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];
    }else {
        self.backgroundColor = [UIColor whiteColor];
    }
}

@end
