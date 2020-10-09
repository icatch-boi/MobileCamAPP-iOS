//
//  StreamObserver.h
//  WifiCamMobileApp
//
//  Created by ZJ on 2017/6/23.
//  Copyright © 2017年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "ICatchtekControl.h"

@interface StreamObserver : NSObject

@property(nonatomic) ICatchGLEventID eventType;
@property(nonatomic) shared_ptr<ICatchIPancamListener> listener;
@property(nonatomic) BOOL isCustomized;
@property(nonatomic) BOOL isGlobal;
-(id)initWithListener:(shared_ptr<ICatchIPancamListener>)listener1
            eventType:(ICatchGLEventID)eventType1
         isCustomized:(BOOL)isCustomized1
             isGlobal:(BOOL)isGlobal1;

@end
