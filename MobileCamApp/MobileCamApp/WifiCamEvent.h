//
//  WifiCamEvent.h
//  WifiCamMobileApp
//
//  Created by ZJ on 2017/7/26.
//  Copyright © 2017年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WifiCamEvent : NSObject

@property (nonatomic, assign) int64_t longValue1;
@property (nonatomic, assign) int64_t longValue2;
@property (nonatomic, assign) int64_t longValue3;

@property (nonatomic, assign) double doubleValue1;
@property (nonatomic, assign) double doubleValue2;
@property (nonatomic, assign) double doubleValue3;

+ (instancetype)wifiCamEvent:(shared_ptr<ICatchGLEvent>)icatchEvt;

@end
