//
//  ICatchFileFilter.h
//  MobileCamApp
//
//  Created by ZJ on 2020/3/2.
//  Copyright © 2020 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ICatchFileFilter : NSObject

@property (nonatomic, copy) NSString *startDateString;
@property (nonatomic, copy) NSString *endDateString;
@property (nonatomic, copy) NSString *timeBucket;
@property (nonatomic, copy) NSString *cameraType;

@end

NS_ASSUME_NONNULL_END
