//
//  WifiCamObserver.m
//  WifiCamMobileApp
//
//  Created by Guo on 6/26/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#import "WifiCamObserver.h"

@implementation WifiCamObserver
@synthesize listener;
@synthesize eventType;
@synthesize isCustomized;
@synthesize isGlobal;

-(id)initWithListener:(shared_ptr<ICatchICameraListener>)listener1
            eventType:(ICatchCamEventID)eventType1
         isCustomized:(BOOL)isCustomized1
             isGlobal:(BOOL)isGlobal1 {
    WifiCamObserver *observer = [[WifiCamObserver alloc] init];
    observer.listener = listener1;
    observer.eventType = eventType1;
    observer.isCustomized = isCustomized1;
    observer.isGlobal = isGlobal1;
    return observer;
}
@end
