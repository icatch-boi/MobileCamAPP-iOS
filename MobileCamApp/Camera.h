//
//  Camera.h
//  WifiCamMobileApp
//
//  Created by Guo on 5/20/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Camera : NSManagedObject

@property (nonatomic, retain) id thumbnail;
@property (nonatomic, retain) NSString * wifi_ssid;
@property (nonatomic, retain) NSNumber * id;

@end
