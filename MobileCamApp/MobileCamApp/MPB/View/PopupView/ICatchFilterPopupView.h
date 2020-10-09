//
//  ICatchFilterPopupView.h
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/2.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import "PopupBaseView.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    PopupViewStateSelect,
    PopupViewStateCancel,
    PopupViewStateConfirm,
} PopupViewState;

typedef void(^ICatchFilterResultBlock)(id selectValue, NSString * _Nullable startDate, NSString * _Nullable endDate, PopupViewState state);

@interface ICatchFilterPopupView : PopupBaseView

+ (void)showFilterPopupViewWithDataSource:(NSArray *)dataSource
                          defaultSelValue:(_Nullable id)defaultSelValue
                                startDate:(NSString * _Nullable)startDate
                                  endDate:(NSString * _Nullable)endDate
                             isAutoSelect:(BOOL)isAutoSelect
                              resultBlock:(ICatchFilterResultBlock)resultBlock;

@end

NS_ASSUME_NONNULL_END
