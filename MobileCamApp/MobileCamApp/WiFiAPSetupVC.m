//
//  WiFiAPSetupVC.m
//  WifiCamMobileApp
//
//  Created by Guo on 11/5/15.
//  Copyright © 2015 iCatchTech. All rights reserved.
//

#import "WiFiAPSetupVC.h"
#import "WiFiAPSetupNoticeVC.h"

@interface WiFiAPSetupVC ()
<
CBPeripheralDelegate,
UITextFieldDelegate
>
@property(nonatomic) MBProgressHUD *progressHUD;
@property (weak, nonatomic) IBOutlet UILabel *noticeLabel;
@property (weak, nonatomic) IBOutlet UITextField *ssidSlot;
@property (weak, nonatomic) IBOutlet UITextField *pwdSlot;
@property (weak, nonatomic) IBOutlet UIButton *setupButton;
@property (nonatomic) NSMutableString *receivedCmd;
@end

@implementation WiFiAPSetupVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _ssidSlot.text = _ssid;
    _pwdSlot.text = _pwd;
    
    _ssidSlot.clearsOnBeginEditing = NO;
    _pwdSlot.clearsOnBeginEditing = NO;
//    _ssidSlot.returnKeyType = UIReturnKeyNext;
//    _pwdSlot.returnKeyType = UIReturnKeyDone;
    
    _ssidSlot.delegate = self;
    _pwdSlot.delegate = self;
    
    _noticeLabel.text =  NSLocalizedString(@"Pair camera succeed, you can setup camera Wi-Fi or just click Setup button to keep default setting.", nil);
    _noticeLabel.numberOfLines = 4;
    _setupButton.titleLabel.text = NSLocalizedString(@"Setup", nil);
    
    _discoveredPeripheral.delegate = self;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (IBAction)skipSetup:(id)sender {
    [self showProgressHUDWithMessage:@"Turn on Wi-Fi..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!_discoveredPeripheral || !_discoveredCharacteristic) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Get Connected"
                                                                message:@"Connect failed."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
                [alert show];
            });
        } else {
            [_discoveredPeripheral setNotifyValue:YES forCharacteristic:_discoveredCharacteristic];
            
            NSRange ssidRange = [_ssidSlot.text rangeOfString:@"[^\u4e00-\u9fa5]{1,32}" options:NSRegularExpressionSearch];
            NSRange pwdRange = [_pwdSlot.text rangeOfString:@"[A-Za-z0-9_(?![，。？：；’‘！”“、]]{8,63}" options:NSRegularExpressionSearch];
            
            if (ssidRange.location == NSNotFound || pwdRange.location == NSNotFound) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideProgressHUD:YES];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                                    message:@"Invalid information."
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil, nil];
                    [alert show];
                });
                
            } else {
                NSString *cmd = @"{\"mode\":\"wifi\",\"action\":\"enable\",\"type\":\"ap\"}";
                NSData *data = [[NSData alloc] initWithBytes:[cmd UTF8String] length:cmd.length];
                [_discoveredPeripheral writeValue:data forCharacteristic:_discoveredCharacteristic type:CBCharacteristicWriteWithResponse];
            }
        }
    });
}

- (IBAction)setup:(id)sender {
    [self showProgressHUDWithMessage:@"Turn on Wi-Fi..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!_discoveredPeripheral || !_discoveredCharacteristic) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Get Connected"
                                                                message:@"Connect failed."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil, nil];
                [alert show];
            });
        } else {
            [_discoveredPeripheral setNotifyValue:YES forCharacteristic:_discoveredCharacteristic];
            //TODO: Check valid value. - KVO

            NSRange ssidRange = [_ssidSlot.text rangeOfString:@"[^\u4e00-\u9fa5]{1,32}" options:NSRegularExpressionSearch];
            NSRange pwdRange = [_pwdSlot.text rangeOfString:@"[A-Za-z0-9_(?![，。？：；’‘！”“、]]{8,63}" options:NSRegularExpressionSearch];

            if (ssidRange.location == NSNotFound || pwdRange.location == NSNotFound) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideProgressHUD:YES];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                                    message:@"Invalid information."
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil, nil];
                    [alert show];
                });
                
            } else {
                NSString *cmd;
                if (![_pwdSlot.text isEqualToString:_pwd] || ![_ssidSlot.text isEqualToString:_ssid]) {
//                    cmd = [NSString stringWithFormat:@"bt wifi set essid=%@,pwd=%@\0", _ssidSlot.text, _pwdSlot.text];
                    cmd = [NSString stringWithFormat:@"{\"mode\":\"wifi\",\"action\":\"set\",\"essid\":\"%@\",\"pwd\":\"%@\"}", _ssidSlot.text, _pwdSlot.text];
                } else {
//                    cmd = [NSString stringWithFormat:@"bt wifi enable ap\0"];
                    cmd = @"{\"mode\":\"wifi\",\"action\":\"enable\",\"type\":\"ap\"}";
                }
                NSData *data = [[NSData alloc] initWithBytes:[cmd UTF8String] length:cmd.length];
                [_discoveredPeripheral writeValue:data forCharacteristic:_discoveredCharacteristic type:CBCharacteristicWriteWithResponse];
            }
        }
    });
    
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        AppLog(@"Error update characteristic value %@", [error localizedDescription]);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showProgressHUDNotice:@"Failed" showTime:1.0];
        });
        return;
    }
    
    NSData *data = characteristic.value;
    NSString *info = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
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
    NSString *mode;
    NSString *action;
    NSArray *subs;
    uint err = YES;
    
    if ([info containsString:@"}"]) {
        AppLog(@"%@", _receivedCmd);
        NSArray *items = [_receivedCmd componentsSeparatedByString:@","];
        
        for (int i = 0; i < items.count; i++) {
            subs = [items[i] componentsSeparatedByString:@":"];
            if ([subs[0] isEqualToString:@" \"mode\""] || [subs[0] isEqualToString:@"{\"mode\""]) {
                mode = subs[1];
                NSLog(@"mode: %@", mode);
            } else if ([subs[0] isEqualToString:@" \"action\""] || [subs[0] isEqualToString:@"{\"action\""]) {
                action = subs[1];
                NSLog(@"action: %@", action);
            } else if ([subs[0] isEqualToString:@" \"err\""] || [subs[0] isEqualToString:@"{\"err\""]) {
                if (i == items.count - 1) {
                    err = [[subs[1] substringWithRange:NSMakeRange(1, (((NSString *)subs[1]).length) - 2)] intValue];
                } else {
                    err = [subs[1] unsignedIntValue];
                }
            }
        }
        if (([mode isEqualToString:@" \"wifi\""] || [mode isEqualToString:@" \"wifi\"}"])
            && ([action isEqualToString:@" \"enable\""] || [action isEqualToString:@" \"enable\"}"])) {
            if (err == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideProgressHUD:NO];
                    [self performSegueWithIdentifier:@"wifiAPSetupNoticeSegue" sender:nil];
                });
            } else {
                AppLog(@"Error: %u", err);
            }
        } else if (([mode isEqualToString:@" \"wifi\""] || [mode isEqualToString:@" \"wifi\"}"])
                   && ([action isEqualToString:@" \"set\""] || [action isEqualToString:@" \"set\"}"])) {
            if (err == 0) {
                NSString *cmd = @"{\"mode\":\"wifi\",\"action\":\"enable\",\"type\":\"ap\"}";
                NSData *data = [[NSData alloc] initWithBytes:[cmd UTF8String] length:cmd.length];
                [_discoveredPeripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            } else {
                AppLog(@"Error: %u", err);
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showProgressHUDNotice:@"Failed" showTime:1.0];
            });
        }
        _receivedCmd = nil;
    }
}

//-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
//    if (error) {
//        AppLog(@"Error update characteristic value %@", [error localizedDescription]);
//        return;
//    }
//    NSData *data = characteristic.value;
//    NSString *info = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    /*
//     AppLog(@"info: %@", info);
//     
//     char *d = (char *)[data bytes];
//     NSMutableString *hex = [[NSMutableString alloc] init];
//     for(int i=0; i<data.length; ++i) {
//     [hex appendFormat:@"0x%02x ", *d++ & 0xFF];
//     }
//     AppLog(@"hex: %@", hex);
//     */
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
//    [_receivedCmd appendString:info];
//    if ([info containsString:@"}"]) {
//        AppLog(@"%@", _receivedCmd);
//        NSArray *items = [_receivedCmd componentsSeparatedByString:@" "];
//        //        for (NSString *s in items) {
//        //            AppLog(@"%@", s);
//        //        }
//        if ([items[1] isEqualToString:@"wifi"]
//            && [items[2] isEqualToString:@"enable"]) {
//            NSArray *subs = [items[4] componentsSeparatedByString:@"="];
//            uint err = [subs[1] unsignedIntValue];
//            if (err == 0) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self hideProgressHUD:NO];
//                    [self performSegueWithIdentifier:@"wifiAPSetupNoticeSegue" sender:nil];
//                });
//            } else {
//                AppLog(@"Error: %u", err);
//            }
//        } else if ([items[1] isEqualToString:@"wifi"]
//                   && [items[2] isEqualToString:@"set"]) {
//            
//            NSArray *subs = [items[4] componentsSeparatedByString:@"="];
//            uint err = [subs[1] unsignedIntValue];
//            if (err == 0) {
////                NSString *cmd = @"bt wifi enable ap\0";
//                NSString *cmd = @"{\"mode\":\"wifi\",\"action\":\"enable\",\"type\":\"ap\"}";
//                NSData *data = [[NSData alloc] initWithBytes:[cmd UTF8String] length:cmd.length];
//                [_discoveredPeripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
//            } else {
//                AppLog(@"Error: %u", err);
//            }
//        } else {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self showProgressHUDNotice:@"Failed" showTime:1.0];
//            });
//        }
//        _receivedCmd = nil;
//    }
//}


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"wifiAPSetupNoticeSegue"]) {
//        UINavigationController *navController = [segue destinationViewController];
//        WiFiAPSetupNoticeVC *vc = (WiFiAPSetupNoticeVC *)navController.topViewController;
        WiFiAPSetupNoticeVC *vc = [segue destinationViewController];
//        vc.ssid = _ssid;
//        vc.pwd = _pwd;
        vc.ssid = _ssidSlot.text;
        vc.pwd = _pwdSlot.text;
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSRange ssidRange = [_ssidSlot.text rangeOfString:@"[^\u4e00-\u9fa5]{1,32}" options:NSRegularExpressionSearch];
    NSRange pwdRange = [_pwdSlot.text rangeOfString:@"[A-Za-z0-9_(?![，。？：；’‘！”“、]]{8,63}" options:NSRegularExpressionSearch];
    
    if (ssidRange.location == NSNotFound || pwdRange.location == NSNotFound) {
        _setupButton.enabled = NO;
    } else {
        _setupButton.enabled = YES;
    }
    [textField resignFirstResponder];
    return YES;
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
