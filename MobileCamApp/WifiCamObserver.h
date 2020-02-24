//
//  WifiCamObserver.h
//  WifiCamMobileApp
//
//  Created by Guo on 6/26/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "ICatchtekControl.h"

@interface WifiCamObserver : NSObject
@property(nonatomic) ICatchCamEventID eventType;
@property(nonatomic) shared_ptr<ICatchICameraListener>listener;
@property(nonatomic) BOOL isCustomized;
@property(nonatomic) BOOL isGlobal;
-(id)initWithListener:(shared_ptr<ICatchICameraListener>)listener1
            eventType:(ICatchCamEventID)eventType1
         isCustomized:(BOOL)isCustomized1
             isGlobal:(BOOL)isGlobal1;
@end
