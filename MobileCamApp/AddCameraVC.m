//
//  AddCameraVC.m
//  WifiCamMobileApp
//
//  Created by Guo on 11/2/15.
//  Copyright © 2015 iCatchTech. All rights reserved.
//

#import "AddCameraVC.h"
#import "GCDiscreetNotificationView.h"
#import "Camera.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "Reachability+Ext.h"
#import "WifiCamControl.h"
#import "ViewController.h"
#import "WiFiAPSetupVC.h"

@interface AddCameraVC ()
<
NSFetchedResultsControllerDelegate
>
@property(nonatomic) MBProgressHUD *progressHUD;
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic) NSInteger AppError;
@property(strong, nonatomic) UIAlertView *connErrAlert;
@property(strong, nonatomic) UIAlertView *reconnAlert;
@property(strong, nonatomic) UIAlertView *customerIDAlert;
@property(nonatomic) WifiCam *wifiCam;
@property(nonatomic) WifiCamCamera *camera;
@property(nonatomic) WifiCamControlCenter *ctrl;
@property(nonatomic) CBCentralManager *myCentralManager;
@property(nonatomic) NSMutableString *receivedCmd;
@property(nonatomic) NSString *cameraPWD;
@property (weak, nonatomic) IBOutlet UILabel *wifiConnectLable;
@property (weak, nonatomic) IBOutlet UIButton *wifiConnectButton;
@property (weak, nonatomic) IBOutlet UILabel *blePairLable;
@property (weak, nonatomic) IBOutlet UIButton *blePairButton;
@end

@implementation AddCameraVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _wifiConnectLable.text = NSLocalizedString(@"When you already connect to camera by Wi-Fi", nil);
    _wifiConnectButton.titleLabel.text = NSLocalizedString(@"Wi-Fi Connect", nil);
    _blePairLable.text = NSLocalizedString(@"For new camera, and the camera supports bluetooth low energy.", nil);
    _blePairButton.titleLabel.text = NSLocalizedString(@"Bluetooth Pair", nil);
    
    self.connErrAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectError", nil)
                                                   message:NSLocalizedString(@"NoWifiConnection", nil)
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Sure", nil)
                                         otherButtonTitles:nil, nil];
    _connErrAlert.tag = APP_CONNECT_ERROR_TAG;
    
    self.reconnAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectError", nil)
                                                  message:NSLocalizedString(@"TimeoutError", nil)
                                                 delegate:self
                                        cancelButtonTitle:NSLocalizedString(@"STREAM_RECONNECT", nil)
                                        otherButtonTitles:nil, nil];
    _reconnAlert.tag = APP_RECONNECT_ALERT_TAG;
    
    self.customerIDAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectError",nil)
                                                      message:NSLocalizedString(@"ALERT_DOWNLOAD_CORRECT_APP", nil)
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"Exit", nil)
                                            otherButtonTitles:nil, nil];
    _customerIDAlert.tag = APP_CUSTOMER_ALERT_TAG;
    self.myCentralManager = [[CBCentralManager alloc] initWithDelegate:nil
                                                                 queue:nil
                                                               options:nil];
    
    NSString *ssid = [self _checkSSID];
    if (ssid && _cameraSSID && [ssid isEqualToString:_cameraSSID]) {
        [_wifiConnectButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    } else {
        
    }
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
}

- (IBAction)wifiConnect:(id)sender {
    NSString *ssid = [self _checkSSID];
    if (![self _checkSSID]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Get Connected"
                                                        message:@"Please turn on Wi-Fi."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
    } else {
        [self _connect:@[@(_idx), ssid]];
    }
}

- (IBAction)blePair:(id)sender {
    if (_myCentralManager.state == CBManagerStatePoweredOn) {
        [self performSegueWithIdentifier:@"bleDeviceListSegue" sender:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Get Connected"
                                                        message:@"Please turn on Bluetooth."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (IBAction)done:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)_checkSSID
{
    //    NSArray * networkInterfaces = [NEHotspotHelper supportedNetworkInterfaces];
    //    NSLog(@"Networks: %@",networkInterfaces);
    
    NSString *ssid = nil;
    //NSString *bssid = @"";
    CFArrayRef myArray = CNCopySupportedInterfaces();
    if (myArray) {
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo((CFStringRef)CFArrayGetValueAtIndex(myArray, 0));
        /*
         Core Foundation functions have names that indicate when you own a returned object:
         
         Object-creation functions that have “Create” embedded in the name;
         Object-duplication functions that have “Copy” embedded in the name.
         If you own an object, it is your responsibility to relinquish ownership (using CFRelease) when you have finished with it.
         
         */
        CFRelease(myArray);
        if (myDict) {
            NSDictionary *dict = (NSDictionary *)CFBridgingRelease(myDict);
            ssid = [dict valueForKey:@"SSID"];
            //bssid = [dict valueForKey:@"BSSID"];
        }
    }
    NSLog(@"ssid : %@", ssid);
    //NSLog(@"bssid: %@", bssid);
    
    return ssid;
}


- (void)_connect:(id)sender
{
    self.AppError = 0;
    if (!_connErrAlert.hidden) {
        AppLog(@"dismiss connErrAlert");
        [_connErrAlert dismissWithClickedButtonIndex:0 animated:NO];
    }
    if (!_reconnAlert.hidden) {
        AppLog(@"dismiss reconnAlert");
        [_reconnAlert dismissWithClickedButtonIndex:0 animated:NO];
    }
    
    NSString *connectingMessage = [NSString stringWithFormat:@"Connect to %@ ...", [self _checkSSID]];
    [self showProgressHUDWithMessage:connectingMessage];
    
    dispatch_async([[SDK instance] sdkQueue], ^{
        
        int totalCheckCount = 4;
        while (totalCheckCount-- > 0) {
            @autoreleasepool {
                if ([Reachability didConnectedToCameraHotspot]) {
                    if ([[SDK instance] initializeSDK]) {
                        
                        // modify by allen.chuang - 20140703
                        /*
                         if( [[SDK instance] isValidCustomerID:0x0100] == false){
                         dispatch_async(dispatch_get_main_queue(), ^{
                         AppLog(@"CustomerID mismatch");
                         [_customerIDAlert show];
                         self.AppError=1;
                         });
                         break;
                         }
                         */
                        
                        [WifiCamControl scan];
                        
                        WifiCamManager *app = [WifiCamManager instance];
                        self.wifiCam = [app.wifiCams objectAtIndex:0];
                        _wifiCam.camera = [WifiCamControl createOneCamera];
                        self.camera = _wifiCam.camera;
                        self.ctrl = _wifiCam.controler;
                        
                        if ([[SDK instance] isSDKInitialized]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self hideProgressHUD:YES];
                                if ([self capableOf:WifiCamAbilityDefaultToPlayback] && [[SDK instance] checkCameraCapabilities:ICH_CAM_APP_DEFAULT_TO_PLAYBACK]) {
                                    [self enterMPBActionWithSender:sender];
                                } else {
                                    [self performSegueWithIdentifier:@"newPreviewSegue01" sender:sender];
                                }
                            });
                        } else {
                            totalCheckCount = 4;
                            continue;
                        }
                        
                        return;
                    }
                }
                
                AppLog(@"[%d]NotReachable -- Sleep 500ms", totalCheckCount);
                [NSThread sleepForTimeInterval:0.5];
            }
        }
        
        if (totalCheckCount <= 0 && _AppError == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideProgressHUD:YES];
                [_connErrAlert show];
            });
        }
    });
}

- (BOOL)capableOf:(WifiCamAbility)ability
{
//    return (_camera.ability & ability) == ability ? YES : NO;
    return [_camera.ability containsObject:@(ability)];
}

- (void)enterMPBActionWithSender:(id)sender {
    [self saveCameraDataWithSender:sender];

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MPBHome" bundle:nil];
    UINavigationController *nav = sb.instantiateInitialViewController;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)saveCameraDataWithSender:(id)sender {
    NSArray *data = (NSArray *)sender;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Camera" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate
                              predicateWithFormat:@"id = %@",[data firstObject]];
    [fetchRequest setPredicate:predicate];
    
    Camera *camera = nil;
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (!error && fetchedObjects && fetchedObjects.count>0) {
        AppLog(@"Already have one camera: %d", [[data firstObject] intValue]);
        
        camera = (Camera *)fetchedObjects[0];
    } else {
        AppLog(@"Create a camera");
        
        camera = (Camera *)[NSEntityDescription insertNewObjectForEntityForName:@"Camera"
        inManagedObjectContext:self.managedObjectContext];
    }
    
    camera.id = [data firstObject];
    camera.wifi_ssid = [data lastObject];
    
    if (![camera.managedObjectContext save:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        AppLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
        abort();
#endif
    } else {
        AppLog(@"Saved to sqlite.");
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"newPreviewSegue01"]) {
        NSArray *data = (NSArray *)sender;
        UINavigationController *navController = [segue destinationViewController];
        ViewController *vc = (ViewController *)navController.topViewController;
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Camera" inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate
                                  predicateWithFormat:@"id = %@",[data firstObject]];
        [fetchRequest setPredicate:predicate];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (!error && fetchedObjects && fetchedObjects.count>0) {
            
            vc.savedCamera = (Camera *)fetchedObjects[0];
            AppLog(@"Already have one camera: %d", [[data firstObject] intValue]);
        } else {
            vc.savedCamera = (Camera *)[NSEntityDescription insertNewObjectForEntityForName:@"Camera"
                                                                     inManagedObjectContext:self.managedObjectContext];
            AppLog(@"Create a camera");
        }
        vc.savedCamera.id = [data firstObject];
        vc.savedCamera.wifi_ssid = [data lastObject];
    }
}

#pragma mark - progressHUD
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view.window];
        _progressHUD.minSize = CGSizeMake(60, 60);
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

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
}

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hide:animated];
}

#pragma mark - NSFetchedResultsController
- (NSFetchedResultsController *)fetchedResultsController {
    
    // Set up the fetched results controller if needed.
    if (_fetchedResultsController == nil) {
        TRACE();
        // Create the fetch request for the entity.
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        // Edit the entity name as appropriate.
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Camera"
                                                  inManagedObjectContext:self.managedObjectContext];
        [fetchRequest setEntity:entity];
        
        // Edit the sort key as appropriate.
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"id" ascending:YES];
        NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
        [fetchRequest setSortDescriptors:sortDescriptors];
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Root"];
        
        aFetchedResultsController.delegate = self;
        self.fetchedResultsController = aFetchedResultsController;
    }
    
    return _fetchedResultsController;
}

@end
