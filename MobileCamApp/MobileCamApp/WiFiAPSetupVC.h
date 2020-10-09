//
//  WiFiAPSetupVC.h
//  WifiCamMobileApp
//
//  Created by Guo on 11/5/15.
//  Copyright © 2015 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface WiFiAPSetupVC : UIViewController
@property (nonatomic) NSString *ssid;
@property (nonatomic) NSString *pwd;
@property(nonatomic) CBPeripheral *discoveredPeripheral;
@property(nonatomic) CBCharacteristic *discoveredCharacteristic;
@end
