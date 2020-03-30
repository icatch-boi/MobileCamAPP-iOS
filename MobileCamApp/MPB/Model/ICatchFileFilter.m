//
//  ICatchFileFilter.m
//  MobileCamApp
//
//  Created by ZJ on 2020/3/2.
//  Copyright © 2020 iCatchTech. All rights reserved.
//

#import "ICatchFileFilter.h"

@implementation ICatchFileFilter

- (void)setStartDateString:(NSString *)startDateString {
    _startDateString = startDateString;
    
    if (startDateString.length != 0) {
        _endDateString = [self stringFromDate:[NSDate date]];
    }
}

- (void)setEndDateString:(NSString *)endDateString {
    if (endDateString.length == 0 && _startDateString.length != 0) {
        endDateString = [self stringFromDate:[NSDate date]];
    }
    
    _endDateString = endDateString;
}

- (void)setTimeBucket:(NSString *)timeBucket {
    if (timeBucket.length == 0) {
        AppLog(@"timeBucket is empty.");
        return;
    }
    
    _timeBucket = timeBucket;
    
    if (timeBucket != nil) {
        NSInteger days = 0;
        if ([timeBucket isEqualToString:NSLocalizedString(@"kToday", nil)]) {
            days = 0;
        } else if ([timeBucket isEqualToString:NSLocalizedString(@"kNearlyThreeDays", nil)]) {
            days = 3;
        } else if ([timeBucket isEqualToString:NSLocalizedString(@"kNearlyAWeekk", nil)]) {
            days = 7;
        } else if ([timeBucket isEqualToString:NSLocalizedString(@"kNearlyAMonth", nil)]) {
            days = 30;
        } else if ([timeBucket isEqualToString:NSLocalizedString(@"kNearlyHalfAYear", nil)]) {
            days = 180;
        }
        
        if ([timeBucket isEqualToString:NSLocalizedString(@"kToday", nil)]) {
            NSString *currentDate = [self stringFromDate:[NSDate date]];
            _startDateString = [NSString stringWithFormat:@"%@ 00", [currentDate componentsSeparatedByString:@" "].firstObject];
        } else {
            _startDateString = [self stringFromDate:[NSDate dateWithTimeIntervalSinceNow:-60 * 60 * 24 * days]];
        }
        
        _endDateString = [self stringFromDate:[NSDate date]];
    }
}

- (NSString *)stringFromDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH";
    
    return [formatter stringFromDate:date];
}

@end
