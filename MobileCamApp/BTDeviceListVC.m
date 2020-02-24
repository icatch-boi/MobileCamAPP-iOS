//
//  BTDeviceListVC.m
//  WifiCamMobileApp
//
//  Created by Guo on 3/7/16.
//  Copyright © 2016 iCatchTech. All rights reserved.
//

#import "BTDeviceListVC.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "WiFiAPSetupVC.h"

typedef NS_OPTIONS(NSUInteger, PairingSectionType) {
    PairingSectionTypeTitle = 0,
    PairingSectionTypeDeviceList = 1,
};

@interface BTDeviceListVC ()
<
CBCentralManagerDelegate,
CBPeripheralDelegate
>
@property(nonatomic) MBProgressHUD *progressHUD;
@property(nonatomic) CBCentralManager *myCentralManager;
@property(nonatomic) NSMutableDictionary *devices;
@property(nonatomic) NSMutableString *receivedCmd;
@property(nonatomic) NSString *cameraSSID;
@property(nonatomic) NSString *cameraPWD;
@property(nonatomic) CBPeripheral *selectedPeripheral;
@property(nonatomic) CBCharacteristic *selectedCharacteristic;
@end

@implementation BTDeviceListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.myCentralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                 queue:nil
                                                               options:nil];
    self.devices = [[NSMutableDictionary alloc] init];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"wifiAPSetupSegue"]) {
//        UINavigationController *navController = [segue destinationViewController];
//        WiFiAPSetupVC *vc = (WiFiAPSetupVC *)navController.topViewController;
        WiFiAPSetupVC *vc = [segue destinationViewController];
        vc.ssid = _cameraSSID;
        vc.pwd = _cameraPWD;
        vc.discoveredPeripheral = _selectedPeripheral;
        vc.discoveredCharacteristic = _selectedCharacteristic;
    }
}

- (IBAction)refresh:(id)sender {
    [_devices removeAllObjects];
    if (_myCentralManager.state == CBManagerStatePoweredOn) {
        [_myCentralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
        NSLog(@"Starting to scan.");
    }
    [self.tableView reloadData];
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        [_myCentralManager stopScan];
    }];
}

#pragma mark - CBCentralManagerDelegate
-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOn) {
//        CBUUID *myServiceUUID = [CBUUID UUIDWithString: @"E44B82FB-F3A6-4C72-AB3F-BF94ABFD9930"];
        [central scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
        AppLog(@"Starting to scan.");
    }
}

-(void)centralManager:(CBCentralManager *)central
didDiscoverPeripheral:(CBPeripheral *)peripheral
    advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                 RSSI:(NSNumber *)RSSI {
    NSLog(@"Discoverd %@ at %@", peripheral.name, RSSI);
    if (peripheral.name) {
        //    [_devices setValue:peripheral forKey:peripheral.name];
        [_devices setObject:RSSI?RSSI:[NSNull null] forKey:peripheral];
        [self.tableView reloadData];
    }
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Peripheral connected.");
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self showProgressHUDWithMessage:@"Connectted."];
//        [NSThread sleepForTimeInterval:0.5];
//        [self showProgressHUDWithMessage:@"Discovering services..."];
//    });
    
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideProgressHUD:NO];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Get Connected"
                                                        message:@"Connect failed."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
    });
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Peripheral disconnected.");
    AppLog(@"peripheral.name : %@ ", peripheral.name);
    AppLog(@"------> %@", error);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self hideProgressHUD:NO];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Get Connected"
                                                        message:@"Connect failed."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
    });
}

#pragma mark - CBPeripheralDelegate
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        [self showProgressHUDNotice:@"There isn't any services on peripheral." showTime:1.5];
        return;
    }
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self showProgressHUDWithMessage:@"Discovering characteristics..."];
//    });
    
    NSLog(@"Service count: %lu", (long)peripheral.services.count);
    for (CBService *service in peripheral.services) {
        //TODO:
        AppLog(@"Service UUID: %@", service.UUID);
        
        [peripheral discoverCharacteristics:nil forService:service];
        return;// testing
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showProgressHUDNotice:@"Failed" showTime:1.0];
    });
}

-(void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering characteristic: %@", [error localizedDescription]);
        [self showProgressHUDNotice:@"Failed" showTime:1.0];
        return;
    }
    
    NSLog(@"Characteristic count: %lu", (long)service.characteristics.count);
    for (CBCharacteristic *characteristic in service.characteristics) {
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        
        AppLog(@"Service UUID: %@, Characteristic UUID: %@", service.UUID, characteristic.UUID);
        if ((characteristic.properties & CBCharacteristicPropertyWrite) == CBCharacteristicPropertyWrite) {
            NSLog(@"It can be writed.");
            
            AppLog(@"characteristic: %@", characteristic);
            self.selectedCharacteristic = characteristic;
//            NSString *cmd = @"bt wifi info essid,pwd\0";
//            NSString *cmd = @"{\"mode\":\"wifi\",\"action\":\"info\",\"essid\":\"\",\"pwd\":\"\",\"ipaddr\":\"\"}";
            NSString *cmd = @"{\"mode\":\"wifi\",\"action\":\"info\"}";

            NSData *data = [[NSData alloc] initWithBytes:[cmd UTF8String] length:cmd.length];
            [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            AppLog(@"characteristic: %@", characteristic);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgressHUDWithMessage:@"Getting ESSID and password..."];
            });
            
            return;
        } else {
            NSLog(@"It cannot be writed.");
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showProgressHUDNotice:@"Failed" showTime:1.0];
    });
}

-(void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
            error:(NSError *)error {
    if (error) {
        NSLog(@"Error update characteristic value %@", [error localizedDescription]);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showProgressHUDNotice:@"Failed" showTime:1.0];
        });
        return;
    }
    
    NSData *data = characteristic.value;
    printf("%s", [data bytes]);
    printf("\n");
    NSString *info = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"info: %@", info);
    char *d = (char *)[data bytes];
    NSMutableString *hex = [[NSMutableString alloc] init];
    for(int i=0; i<data.length; ++i) {
        [hex appendFormat:@"0x%02x ", *d++ & 0xFF];
    }
    printf("\n");
    NSLog(@"hex: %@", hex);
    
    
    if (!_receivedCmd) {
        self.receivedCmd = [[NSMutableString alloc] init];
    }
    
    if (!info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showProgressHUDNotice:@"Failed" showTime:1.0];
        });
        return;
    }
    
    [_receivedCmd appendString:info];
    NSString *ssid;
    NSString *pwd;
    NSArray *subs;
    NSString *mode;
    NSString *action;
    uint err = YES;
    if ([_receivedCmd containsString:@"}"]) {
        NSLog(@"%@", _receivedCmd);
        NSArray *items = [_receivedCmd componentsSeparatedByString:@","];
        for (int i = 0; i < items.count; i++) {
            subs = [items[i] componentsSeparatedByString:@":"];
            if ([subs[0] isEqualToString:@" \"mode\""] || [subs[0] isEqualToString:@"{\"mode\""]) {
                mode = subs[1];
                NSLog(@"mode: %@", mode);
            } else if ([subs[0] isEqualToString:@" \"action\""] || [subs[0] isEqualToString:@"{\"action\""]) {
                action = subs[1];
                NSLog(@"action: %@", action);
            } else if ([subs[0] isEqualToString:@" \"essid\""] || [subs[0] isEqualToString:@"{\"essid\""]) {
                if (i == items.count - 1) {
                    ssid = [subs[1] substringWithRange:NSMakeRange(2, (((NSString *)subs[1]).length) - 4)];
                } else {
                    ssid = [subs[1] substringWithRange:NSMakeRange(2, (((NSString *)subs[1]).length) - 3)];
                }
                NSLog(@"SSID: %@", ssid);
            } else if ([subs[0] isEqualToString:@" \"pwd\""] || [subs[0] isEqualToString:@"{\"pwd\""]) {
                if (i == items.count - 1) {
                    pwd = [subs[1] substringWithRange:NSMakeRange(2, (((NSString *)subs[1]).length) - 4)];
                } else {
                    pwd = [subs[1] substringWithRange:NSMakeRange(2, (((NSString *)subs[1]).length) - 3)];
                }
                NSLog(@"Password: %@", pwd);
            } else if ([subs[0] isEqualToString:@" \"err\""] || [subs[0] isEqualToString:@"{\"err\""]) {
                if (i == items.count - 1) {
                    err = [[subs[1] substringWithRange:NSMakeRange(1, (((NSString *)subs[1]).length) - 2)] intValue];
                } else {
                    err = [subs[1] unsignedIntValue];
                }
            }
        }
        if (([mode isEqualToString:@" \"wifi\""] || [mode isEqualToString:@" \"wifi\"}"])
            && ([action isEqualToString:@" \"info\""] || [action isEqualToString:@" \"info\"}"])) {
            if (err == 0) {
                self.cameraSSID = ssid;
                self.cameraPWD = pwd;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideProgressHUD:NO];
                    [self performSegueWithIdentifier:@"wifiAPSetupSegue" sender:nil];
                });
                [_myCentralManager stopScan];
            } else {
                NSLog(@"Error: %u", err);
            }
        } else if (([mode isEqualToString:@" \"wifi\""] || [mode isEqualToString:@" \"wifi\"}"])
                   && ([action isEqualToString:@" \"enable\""] || [action isEqualToString:@" \"enable\"}"])) {
            if (err == 0) {
                NSString *cmd = @"{\"mode\":\"wifi\",\"action\":\"info\"}";
                NSData *data = [[NSData alloc] initWithBytes:[cmd UTF8String]
                                                      length:cmd.length];
                [peripheral writeValue:data
                     forCharacteristic:characteristic
                                  type:CBCharacteristicWriteWithResponse];
            } else {
                NSLog(@"Error: %u", err);
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgressHUDNotice:@"Failed" showTime:1.0];
            });
        }
        _receivedCmd = nil;
    }
}

//-(void)peripheral:(CBPeripheral *)peripheral
//didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
//            error:(NSError *)error {
//    if (error) {
//        NSLog(@"Error update characteristic value %@", [error localizedDescription]);
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self showProgressHUDNotice:@"Failed" showTime:1.0];
//        });
//        return;
//    }
//    
//    NSData *data = characteristic.value;
//    printf("%s", [data bytes]);
//    printf("\n");
//    NSString *info = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    
//    NSLog(@"info: %@", info);
//    char *d = (char *)[data bytes];
//    NSMutableString *hex = [[NSMutableString alloc] init];
//    for(int i=0; i<data.length; ++i) {
//        [hex appendFormat:@"0x%02x ", *d++ & 0xFF];
//    }
//    printf("\n");
//    NSLog(@"hex: %@", hex);
//    
//    
//    if (!_receivedCmd) {
//        self.receivedCmd = [[NSMutableString alloc] init];
//    }
//    
//    if (!info) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self showProgressHUDNotice:@"Failed" showTime:1.0];
//        });
//        return;
//    }
//    
//    [_receivedCmd appendString:info];
//    if ([info containsString:@"\0"]) {
//        NSLog(@"%@", _receivedCmd);
//        NSArray *items = [_receivedCmd componentsSeparatedByString:@" "];
//        if ([items[1] isEqualToString:@"wifi"]
//            && [items[2] isEqualToString:@"info"]) {
//            NSArray *subs = [items[4] componentsSeparatedByString:@"="];
//            uint err = [subs[1] unsignedIntValue];
//            if (err == 0) {
//                NSArray *s1 = [items[3] componentsSeparatedByString:@","];
//                NSArray *ss1 = [s1[0] componentsSeparatedByString:@"="];
//                self.cameraSSID = ss1[1];
//                NSLog(@"SSID: %@", ss1[1]);
//                NSArray *ss2 = [s1[1] componentsSeparatedByString:@"="];
//                self.cameraPWD = ss2[1];
//                NSLog(@"Password: %@", ss2[1]);
//                
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self hideProgressHUD:NO];
//                    [self performSegueWithIdentifier:@"wifiAPSetupSegue" sender:nil];
//                });
//                [_myCentralManager stopScan];
//            } else {
//                NSLog(@"Error: %u", err);
//            }
//            
//        } else if ([items[1] isEqualToString:@"wifi"]
//                   && [items[2] isEqualToString:@"enable"]) {
//            
//            NSArray *subs = [items[4] componentsSeparatedByString:@"="];
//            uint err = [subs[1] unsignedIntValue];
//            if (err == 0) {
//                NSString *cmd = @"bt wifi info essid,pwd\0";
//                NSData *data = [[NSData alloc] initWithBytes:[cmd UTF8String]
//                                                      length:cmd.length];
//                [peripheral writeValue:data
//                     forCharacteristic:characteristic
//                                  type:CBCharacteristicWriteWithResponse];
//            } else {
//                NSLog(@"Error: %u", err);
//            }
//        } else {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self showProgressHUDNotice:@"Failed" showTime:1.0];
//            });
//        }
//        _receivedCmd = nil;
//    }
//}

#pragma mark - UITableView
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == PairingSectionTypeTitle) {
        return 1;
    } else {
        return _devices.count;
    }
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellDentifier = @"titleCell";
    static NSString *cellDentifier1 = @"deviceListCell";
    
    UITableViewCell *cell = nil;
    if (indexPath.section == PairingSectionTypeTitle) {
        cell = [tableView dequeueReusableCellWithIdentifier:cellDentifier forIndexPath:indexPath];
        cell.textLabel.text = @"Select your camera BT";
        cell.textLabel.font = [UIFont systemFontOfSize:20.0];
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    } else if (indexPath.section == PairingSectionTypeDeviceList) {
        cell = [tableView dequeueReusableCellWithIdentifier:cellDentifier1 forIndexPath:indexPath];
        CBPeripheral *peripheral = [_devices allKeys][indexPath.row];
        cell.textLabel.text = peripheral.name;
        cell.textLabel.font = [UIFont systemFontOfSize:22.0];
        cell.detailTextLabel.text = [[_devices allValues][indexPath.row] stringValue];
    }
    
    if (cell) {
        return cell;
    } else {
        AppLog(@"Some exception message for unexpected tableView");
        abort();
    }
}

- (NSString *)tableView               :(UITableView *)tableView
              titleForHeaderInSection :(NSInteger)section
{
    NSString *retVal = nil;
    
    if (section == PairingSectionTypeDeviceList) {
        retVal = @"BT devices";
    }
    
    return retVal;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == PairingSectionTypeDeviceList) {
        CBPeripheral *peripheral = [_devices allKeys][indexPath.row];
        self.selectedPeripheral = peripheral;
        [self showProgressHUDWithMessage:@"Connecting..."];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_myCentralManager connectPeripheral:self.selectedPeripheral options:nil];
        });
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == PairingSectionTypeTitle) {
        return 65.0;
    } else {
        return 55.0;
    }
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view.window];
        _progressHUD.minSize = CGSizeMake(120, 120);
        _progressHUD.minShowTime = 1;
        _progressHUD.dimBackground = YES;
        // The sample image is based on the
        // work by: http://www.pixelpressicons.com
        // licence: http://creativecommons.org/licenses/by/2.5/ca/
        self.progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]];
        [self.view.window addSubview:_progressHUD];
    }
    return _progressHUD;
}

- (void)showProgressHUDNotice:(NSString *)message
                     showTime:(NSTimeInterval)time {
    if (message) {
        [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.mode = MBProgressHUDModeText;
        [self.progressHUD hide:YES afterDelay:time];
    } else {
        [self.progressHUD hide:YES];
    }
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    if (message) {
        [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.detailsLabelText = nil;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hide:YES afterDelay:1.0];
    } else {
        [self.progressHUD hide:YES];
    }
}

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hide:animated];
}
@end
