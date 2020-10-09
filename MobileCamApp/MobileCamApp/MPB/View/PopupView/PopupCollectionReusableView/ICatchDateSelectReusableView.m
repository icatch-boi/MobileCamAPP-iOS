//
//  ICatchDateSelectReusableView.m
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/3.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import "ICatchDateSelectReusableView.h"
#import "ICatchDatePickerView.h"

@interface ICatchDateSelectReusableView ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *describeLabel;

@end

@implementation ICatchDateSelectReusableView

- (void)awakeFromNib {
    [super awakeFromNib];
    
//    _startTextField.inputView = self.datePicker;
    _startTextField.placeholder = NSLocalizedString(@"kStartTime", nil);
    __weak typeof(self) weakSelf = self;
    _startTextField.tapActionBlock = ^{
        [ICatchDatePickerView showDatePickerWithTitle:NSLocalizedString(@"kStartTime", nil) defaultSelValue:_startTextField.text isAutoSelect:NO resultBlock:^(NSString * _Nonnull selectValue) {
            weakSelf.startTextField.text = selectValue;
        }];
    };
    
    _endTextField.placeholder = NSLocalizedString(@"kEndTime", nil);
    _endTextField.tapActionBlock = ^{
        [ICatchDatePickerView showDatePickerWithTitle:NSLocalizedString(@"kEndTime", nil) defaultSelValue:_endTextField.text isAutoSelect:NO resultBlock:^(NSString * _Nonnull selectValue) {
            weakSelf.endTextField.text = selectValue;
        }];
    };
    
    [self setupLocalizedString];
}

- (void)setupLocalizedString {
    _titleLabel.text = NSLocalizedString(@"kPeriodOfTime", nil);
    _describeLabel.text = NSLocalizedString(@"kTo", nil);
}

@end
