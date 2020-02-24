//
//  Reachability+Ext.m
//  WifiCamMobileApp
//
//  Created by Guo on 7/14/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#import "Reachability+Ext.h"

@implementation Reachability (Ext)
+ (BOOL)didConnectedToCameraHotspot
{
    BOOL retVal = NO;
    NetworkStatus netStatus = [[Reachability reachabilityForLocalWiFi] currentReachabilityStatus];
    
    switch (netStatus) {
        case NotReachable:
            //AppLog(@"NotReachable");
            break;
            
        case ReachableViaWWAN:
            AppLog(@"ReachableViaWWAN");
            break;
            
        case ReachableViaWiFi:
            //AppLog(@"ReachableViaWiFi");
            retVal = YES;
            break;
    }
    
    return retVal;
}

@end
