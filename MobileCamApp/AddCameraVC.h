//
//  AddCameraVC.h
//  WifiCamMobileApp
//
//  Created by Guo on 11/2/15.
//  Copyright © 2015 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AddCameraVC : UIViewController
@property(nonatomic) NSUInteger idx;
@property(nonatomic) NSString *cameraSSID;
@property(nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end
