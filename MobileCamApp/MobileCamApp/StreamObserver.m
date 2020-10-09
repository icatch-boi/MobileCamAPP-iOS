//
//  StreamObserver.m
//  WifiCamMobileApp
//
//  Created by ZJ on 2017/6/23.
//  Copyright © 2017年 iCatchTech. All rights reserved.
//

#import "StreamObserver.h"

@implementation StreamObserver

@synthesize listener;
@synthesize eventType;
@synthesize isCustomized;
@synthesize isGlobal;

-(id)initWithListener:(shared_ptr<ICatchIPancamListener>)listener1
            eventType:(ICatchGLEventID)eventType1
         isCustomized:(BOOL)isCustomized1
             isGlobal:(BOOL)isGlobal1 {
    StreamObserver *observer = [[StreamObserver alloc] init];
    observer.listener = listener1;
    observer.eventType = eventType1;
    observer.isCustomized = isCustomized1;
    observer.isGlobal = isGlobal1;
    return observer;
}

@end
