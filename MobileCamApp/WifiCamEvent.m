//
//  WifiCamEvent.m
//  WifiCamMobileApp
//
//  Created by ZJ on 2017/7/26.
//  Copyright © 2017年 iCatchTech. All rights reserved.
//

#import "WifiCamEvent.h"

@implementation WifiCamEvent

+ (instancetype)wifiCamEvent:(shared_ptr<com::icatchtek::pancam::ICatchGLEvent>)icatchEvt {
    WifiCamEvent *instance = [WifiCamEvent new];
    
    instance.longValue1 = icatchEvt->getLongValue1();
    instance.longValue2 = icatchEvt->getLongValue2();
    instance.longValue3 = icatchEvt->getLongValue3();
    instance.doubleValue1 = icatchEvt->getDoubleValue1();
    instance.doubleValue2 = icatchEvt->getDoubleValue2();
    instance.doubleValue3 = icatchEvt->getDoubleValue3();
    
    return instance;
}

@end
