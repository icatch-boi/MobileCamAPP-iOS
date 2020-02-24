//
//  HomeVC.m
//  WifiCamMobileApp
//
//  Created by Guo on 5/19/15.
//  Copyright (c) 2015 iCatchTech. All rights reserved.
//

#import "HomeVC.h"
#import "GCDiscreetNotificationView.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "WifiCamControl.h"
#include "PreviewSDKEventListener.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ViewController.h"
#import "Camera.h"
#import <Photos/Photos.h>
#import "SDImageCache.h"
#import "MWCommon.h"
#import "Reachability+Ext.h"
//#import <NetworkExtension/NetworkExtension.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "AddCameraVC.h"
#import "WiFiAPSetupNoticeVC.h"
#import <objc/runtime.h>
#include <ifaddrs.h>
#include <net/if.h>

#import "PanCamSDK.h"
#import "VideoPlaybackViewController.h"

@interface UIButton (UIButtonWiFiCamButton)
@property(nonatomic) id isRecorded;
@end
static char isSlotRecored;
@implementation UIButton (UIButtonWiFiCamButton)
-(id)isRecorded {
    return objc_getAssociatedObject(self, &isSlotRecored);
}

-(void)setIsRecorded:(id)isRecorded {
    objc_setAssociatedObject(self, &isSlotRecored, isRecorded, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

@interface HomeVC ()
<
UIAlertViewDelegate,
NSFetchedResultsControllerDelegate,
MWPhotoBrowserDelegate,
CBCentralManagerDelegate,
CBPeripheralDelegate
>
@property(weak, nonatomic) IBOutlet UIButton *addCamBtn1;
@property(weak, nonatomic) IBOutlet UIButton *addCamBtn2;
@property(weak, nonatomic) IBOutlet UIButton *addCamBtn3;
@property(weak, nonatomic) IBOutlet UIButton *remCamBtn3;
@property(weak, nonatomic) IBOutlet UIButton *remCamBtn2;
@property(weak, nonatomic) IBOutlet UIButton *remCamBtn1;
@property(weak, nonatomic) IBOutlet UIButton *camThumbBtn1;
@property(weak, nonatomic) IBOutlet UIButton *camThumbBtn2;
@property(weak, nonatomic) IBOutlet UIButton *camThumbBtn3;
@property(weak, nonatomic) IBOutlet UIImageView *icon1;
@property(weak, nonatomic) IBOutlet UIImageView *icon2;
@property(weak, nonatomic) IBOutlet UIImageView *icon3;
@property(weak, nonatomic) IBOutlet UIButton *photoBg;
@property(weak, nonatomic) IBOutlet UIButton *videoBg;
@property(weak, nonatomic) IBOutlet UIButton *photoThumb;
@property(weak, nonatomic) IBOutlet UIButton *videoThumb;
@property(weak, nonatomic) IBOutlet UILabel *mediaOnMyIphone;
@property(weak, nonatomic) IBOutlet UINavigationItem *Navbar;
@property(weak, nonatomic) IBOutlet UILabel *photosLabel;
@property(weak, nonatomic) IBOutlet UILabel *videosLabel;
@property(nonatomic, retain) GCDiscreetNotificationView *notificationView;
@property(nonatomic) WifiCam *wifiCam;
@property(nonatomic) WifiCamCamera *camera;
@property(nonatomic) WifiCamControlCenter *ctrl;
@property(nonatomic) Reachability *wifiReachability;
@property(nonatomic) ConnectionListener *connectionChangedListener;
@property(strong, nonatomic) UIAlertView *connErrAlert;
@property(strong, nonatomic) UIAlertView *connErrAlert1;
@property(strong, nonatomic) UIAlertView *reconnAlert;
@property(strong, nonatomic) UIAlertView *customerIDAlert;
@property(nonatomic) NSInteger AppError;
@property(nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property(nonatomic) int cameraTobeRemoved;
@property(nonatomic, strong) NSMutableArray *photos;
@property(nonatomic, strong) NSMutableArray *thumbs;
@property(nonatomic, strong) NSMutableArray *assets;
@property(nonatomic, strong) ALAssetsLibrary *ALAssetsLibrary;
@property(nonatomic) NSMutableArray *selections;
@property(nonatomic) CBCentralManager *myCentralManager;
@property(nonatomic) NSMutableString *receivedCmd;
@property(nonatomic) NSString *cameraSSID;
@property(nonatomic) NSString *cameraPWD;
@property(nonatomic) id current_sender;
@property(nonatomic) NSTimer *timer;
@property(nonatomic) UIButton *selectSender;

@property(nonatomic, strong) NSMutableArray *photosAssets;
@property(nonatomic, strong) NSMutableArray *videosAssets;

@end


@implementation HomeVC

#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >>  8))/255.0 \
blue:((float)((rgbValue & 0x0000FF) >>  0))/255.0 \
alpha:1.0]
/*
- (NSString *)mimeType:(NSURL *)url
{
    //1NSURLRequest
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    //2NSURLConnection
    
    //3 在NSURLResponse里，服务器告诉浏览器用什么方式打开文件。
    
    //使用同步方法后去MIMEType
    NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    return response.MIMEType;
}
*/
- (void)viewDidLoad {
    [super viewDidLoad];

    [self setButtonRadius:self.addCamBtn1 withRadius:5.0];
    [self setButtonRadius:self.addCamBtn2 withRadius:5.0];
    [self setButtonRadius:self.addCamBtn3 withRadius:5.0];
    [self setButtonRadius:self.camThumbBtn1 withRadius:10.0];
    [self setButtonRadius:self.camThumbBtn2 withRadius:10.0];
    [self setButtonRadius:self.camThumbBtn3 withRadius:10.0];
    [self setButtonRadius:self.photoBg withRadius:5.0];
    [self setButtonRadius:self.videoBg withRadius:5.0];
    [self setButtonRadius:self.photoThumb withRadius:10.0];
    [self setButtonRadius:self.videoThumb withRadius:10.0];
    
    _addCamBtn1.tag = 0;
    _addCamBtn2.tag = 1;
    _addCamBtn3.tag = 2;
    _addCamBtn1.isRecorded = @NO;
    _addCamBtn2.isRecorded = @NO;
    _addCamBtn3.isRecorded = @NO;
    _remCamBtn1.tag = 0;
    _remCamBtn2.tag = 1;
    _remCamBtn3.tag = 2;
    
    self.connErrAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectError", nil)
                                                   message:NSLocalizedString(@"NoWifiConnection", nil)
                                                  delegate:self
                                         cancelButtonTitle:NSLocalizedString(@"Sure", nil)
                                         otherButtonTitles:nil, nil];
    _connErrAlert.tag = APP_CONNECT_ERROR_TAG;
    
    self.connErrAlert1 = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectError", nil)
                                                    message:NSLocalizedString(@"Connected to other Wi-Fi", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Sure", nil)
                                          otherButtonTitles:nil, nil];
    
    self.reconnAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectError", nil)
                                                  message:NSLocalizedString(@"TimeoutError", nil)
                                                 delegate:self
                                        cancelButtonTitle:NSLocalizedString(@"STREAM_RECONNECT", nil)
                                        otherButtonTitles:NSLocalizedString(@"Sure", nil), nil];
    _reconnAlert.tag = APP_RECONNECT_ALERT_TAG;
    
    self.customerIDAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectError",nil)
                                                      message:NSLocalizedString(@"ALERT_DOWNLOAD_CORRECT_APP", nil)
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"Exit", nil)
                                            otherButtonTitles:nil, nil];
    _customerIDAlert.tag = APP_CUSTOMER_ALERT_TAG;
    
    self.wifiReachability = [Reachability reachabilityForLocalWiFi];
    [self.wifiReachability startNotifier];
    
    _photosLabel.text = NSLocalizedString(@"PhotosLabel", nil);
    _videosLabel.text = NSLocalizedString(@"Videos", nil);
    _mediaOnMyIphone.text = NSLocalizedString(@"Media on My iPhone", nil);
    [_addCamBtn1 setTitle:NSLocalizedString(@"Add New Camera", nil) forState:UIControlStateNormal];
    [_addCamBtn2 setTitle:NSLocalizedString(@"Add New Camera", nil) forState:UIControlStateNormal];
    [_addCamBtn3 setTitle:NSLocalizedString(@"Add New Camera", nil) forState:UIControlStateNormal];
    
    
    // register timer for check SSID
    //_theTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(checkConnectionStatus) userInfo:nil repeats:YES];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	
	self.myCentralManager = [[CBCentralManager alloc] initWithDelegate:self
                                                                 queue:nil
                                                               options:nil];
    
    
    
    /*
    NSString *test = @"<?xml version='1.0' encoding='UTF-8'?>\
    <!DOCTYPE plist PUBLIC '-//Apple//DTD PLIST 1.0//EN' 'http://www.apple.com/DTDs/PropertyList-1.0.dtd'>\
    <plist version='1.0'>\
    <dict>\
    <key>PayloadContent</key>\
    <array>\
    <dict>\
    <key>AutoJoin</key>\
    <true />\
    <key>EncryptionType</key>\
    <string>WPA</string>\
    <key>HIDDEN_NETWORK</key>\
    <false />\
    <key>PayloadDescription</key>\
    <string>Configura los ajustes de conectividad inalÃ¡mbrica.</string>\
    <key>PayloadDisplayName</key>\
    <string>Wi-Fi SBC_C63284</string>\
    <key>PayloadIdentifier</key>\
    <string>com.icatchtek.ap.SBC_C63284</string>\
    <key>PayloadOrganization</key>\
    <string>XXXXXXXXXX</string>\
    <key>PayloadType</key>\
    <string>com.apple.wifi.managed</string>\
    <key>PayloadUUID</key>\
    <string>XXXXXXXX</string>\
    <key>PayloadVersion</key>\
    <integer>1</integer>\
    <key>ProxyType</key>\
    <string>None</string>\
    <key>SSID_STR</key>\
    <string>%1</string>\
    <key>Password</key>\
    <string>%2</string>\
    </dict>\
    </array>\
    <key>PayloadDescription</key>\
    <string>XXXXXXXXXXXXXXXXX XXXXXXX</string>\
    <key>PayloadDisplayName</key>\
    <string>SBC_C63284</string>\
    <key>PayloadIdentifier</key>\
    <string>com.xxxxxxxx.xxxxxx.xxxxx</string>\
    <key>PayloadOrganization</key>\
    <string>XXXXXXXX</string>\
    <key>PayloadRemovalDisallowed</key>\
    <false />\
    <key>PayloadType</key>\
    <string>Configuration</string>\
    <key>PayloadUUID</key>\
    <string>XXXXXXXXXX</string>\
    <key>PayloadVersion</key>\
    <integer>1</integer>\
    <key>DurationUntilRemoval</key>\
    <integer>2592000</integer>\
    </dict>\
    </plist>\
    ";
    test= [test stringByReplacingOccurrencesOfString:@"%1" withString:@"Mac1058"];
    test= [test stringByReplacingOccurrencesOfString:@"%2" withString:@"sunmedia2016"];
    
    FILE *file;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"test.mobileconfig"];
    file = fopen([filePath cStringUsingEncoding:NSASCIIStringEncoding], "a+");
    fwrite([test UTF8String], sizeof(char), test.length, file);
    fclose(file);
     */
}
// scheduler check
// 1. SSID
// 2. Connection
-(void)checkConnectionStatus
{
    NSDictionary *ifs = [self fetchSSIDInfo];
    current_ssid= [ifs objectForKey:@"SSID"];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.fetchedResultsController.sections.count > 0) {
            id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:0];
//                    AppLog(@"num : %d",[sectionInfo numberOfObjects]);
            if([sectionInfo numberOfObjects] > 0) {
                
                for (int i=0; i<[sectionInfo numberOfObjects]; ++i) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
                    Camera *camera = (Camera *)[self.fetchedResultsController objectAtIndexPath:indexPath];
                    //                AppLog(@"ssid: %@", camera.wifi_ssid);
                    int id0 = [camera.id intValue];
                    //                AppLog(@"id0: %d", id0);
                    
                    NSString *title = camera.wifi_ssid;
                    UIImage *image = (UIImage *)camera.thumbnail;
                    switch (id0) {
                        case 0:
                            if (image) {
                                [_camThumbBtn1 setBackgroundImage:image
                                                         forState:UIControlStateNormal];
                            }
                            [_addCamBtn1 setTitle:title forState:UIControlStateNormal];
                            if( [title isEqualToString:current_ssid]){
                                [_addCamBtn1 setTitleColor:UIColorFromRGB(0x32A3DE) forState:UIControlStateNormal];
                                _icon1.image = [UIImage imageNamed:@"connected_sign"];
                            }else{
                                [_addCamBtn1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                                _icon1.image = [UIImage imageNamed:@"disconnected_sign"];
                            }
                            
                            _addCamBtn1.isRecorded = @YES;
                            [_remCamBtn1 setHidden:NO];
                            break;
                        case 1:
                            if (image) {
                                [_camThumbBtn2 setBackgroundImage:image
                                                         forState:UIControlStateNormal];
                            }
                            [_addCamBtn2 setTitle:title forState:UIControlStateNormal];
                            if( [title isEqualToString:current_ssid]){
                                [_addCamBtn2 setTitleColor:UIColorFromRGB(0x32A3DE) forState:UIControlStateNormal];
                                _icon2.image = [UIImage imageNamed:@"connected_sign"];
                            }else{
                                [_addCamBtn2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                                _icon2.image = [UIImage imageNamed:@"disconnected_sign"];
                            }
                            
                            _addCamBtn2.isRecorded = @YES;
                            [_remCamBtn2 setHidden:NO];
                            break;
                        case 2:
                            if (image) {
                                [_camThumbBtn3 setBackgroundImage:image
                                                         forState:UIControlStateNormal];
                            }
                            [_addCamBtn3 setTitle:title forState:UIControlStateNormal];
                            if( [title isEqualToString:current_ssid]){
                                [_addCamBtn3 setTitleColor:UIColorFromRGB(0x32A3DE) forState:UIControlStateNormal];
                                _icon3.image = [UIImage imageNamed:@"connected_sign"];
                            }else{
                                [_addCamBtn3 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                                _icon3.image = [UIImage imageNamed:@"disconnected_sign"];
                            }
                            
                            _addCamBtn3.isRecorded = @YES;
                            [_remCamBtn3 setHidden:NO];
                            break;
                        default:
                            break;
                    }
                }
            }
        }
    });
    

}
- (id)fetchSSIDInfo {
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    NSLog(@"Supported interfaces: %@", ifs);
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSLog(@"%@ => %@", ifnam, info);
        if (info && [info count]) { break; }
    }
    return info;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadAssets];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.isReconnecting = YES;
    /*
    if (_myCentralManager.state == CBCentralManagerStatePoweredOn) {
        [_myCentralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
        NSLog(@"Scanning started");
    }*/
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    TRACE();
    
    AppLog(@"1: %f", _addCamBtn1.frame.origin.y);
    AppLog(@"2: %f", _addCamBtn2.frame.origin.y);
    AppLog(@"3: %f", _addCamBtn3.frame.origin.y);
    AppLog(@"mediaOnMyIphone: %f", _mediaOnMyIphone.frame.origin.y);
    

    float gap = (_mediaOnMyIphone.frame.origin.y - _addCamBtn1.frame.size.height * 3) / 4;
//    float x = _addCamBtn1.frame.origin.x;
//    float w = _addCamBtn1.frame.size.width;
    float h = _addCamBtn1.frame.size.height;
    CGFloat remy1 = _remCamBtn1.frame.origin.y - gap;
    CGFloat remy2 = _remCamBtn2.frame.origin.y - (gap*2+h);
    CGFloat remy3 = _remCamBtn2.frame.origin.y - (gap*3+h*2);

    _remCamBtn1.transform = CGAffineTransformTranslate(_remCamBtn1.transform, 0, -remy1);
    _remCamBtn2.transform = CGAffineTransformTranslate(_remCamBtn2.transform, 0, -remy2);
    _remCamBtn3.transform = CGAffineTransformTranslate(_remCamBtn3.transform, 0, -remy3);
    
    CGFloat ty1 = _addCamBtn1.frame.origin.y - gap;
    _icon1.transform = _camThumbBtn1.transform = _addCamBtn1.transform = CGAffineTransformTranslate(_addCamBtn1.transform, 0, -ty1);
    CGFloat ty2 = _addCamBtn2.frame.origin.y - (gap*2 + h);
    _icon2.transform = _camThumbBtn2.transform = _addCamBtn2.transform = _remCamBtn2.transform = CGAffineTransformTranslate(_addCamBtn2.transform, 0, -ty2);
    CGFloat ty3 = _addCamBtn3.frame.origin.y - (gap*3 + h*2);
    _icon3.transform = _camThumbBtn3.transform = _addCamBtn3.transform = _remCamBtn3.transform = CGAffineTransformTranslate(_addCamBtn3.transform, 0, -ty3);
    
    [self.view needsUpdateConstraints];
    
    NSError *error = nil;
    if (![[self fetchedResultsController] performFetch:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
        abort();
#endif
    }
    [self checkConnectionStatus];
    // regist here, don't execute loadAsset twice
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.delegate = self;
 /*
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"test.mobileconfig"];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    NSLog(@"mime: %@", [self mimeType:url]);
//    NSData *data = [NSData dataWithContentsOfFile:filePath];
    
//    [webView loadData:data //[test dataUsingEncoding:NSUTF8StringEncoding]
//             MIMEType:@"application/x-apple-aspen-config"
//     textEncodingName:@"UTF-8"
//              baseURL:url];
    NSLog(@"url: %@", url);
    [webView loadRequest:[NSURLRequest requestWithURL:url]];
  */
    /*dispatch_async(dispatch_get_main_queue(), ^{
        self.timer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                      target:self
                                                    selector:@selector(checkConnectionStatus)
                                                    userInfo:nil repeats:YES];
    });*/
    [self.wifiReachability startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkConnectionStatus) name:kReachabilityChangedNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_myCentralManager.state == CBManagerStatePoweredOn) {
        [_myCentralManager stopScan];
    }
    //[_timer invalidate];
    [self.wifiReachability stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}

- (void)setButtonRadius:(UIButton *)button withRadius:(CGFloat)radius {
    button.layer.cornerRadius = radius;
    button.layer.masksToBounds = YES;
}

- (void)didReceiveMemoryWarning {
    AppLog(@"ReceiveMemoryWarning");
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(GCDiscreetNotificationView *)notificationView {
    if (!_notificationView) {
        _notificationView = [[GCDiscreetNotificationView alloc] initWithText:nil
                                                                showActivity:NO
                                                          inPresentationMode:GCDiscreetNotificationViewPresentationModeTop
                                                                      inView:self.view];
    }
    return _notificationView;
}

- (void)showGCDNoteWithMessage:(NSString *)message
                  withAnimated:(BOOL)animated
                    withAcvity:(BOOL)activity{
    
    [self enableButtons:NO];
    [self.notificationView setTextLabel:message];
    [self.notificationView setShowActivity:activity];
    [self.notificationView show:animated];
    
}

- (void)showGCDNoteWithMessage:(NSString *)message
                       andTime:(NSTimeInterval) timeInterval
                    withAcvity:(BOOL)activity{
    [self.notificationView setTextLabel:message];
    [self.notificationView setShowActivity:activity];
    [self.notificationView showAndDismissAfter:timeInterval];
    
}

- (void)hideGCDiscreetNoteView:(BOOL)animated {
    [self enableButtons:YES];
    [self.notificationView hide:animated];
    
}

- (void)enableButtons:(BOOL)value {
    self.addCamBtn1.userInteractionEnabled = value;
    self.addCamBtn2.userInteractionEnabled = value;
    self.addCamBtn3.userInteractionEnabled = value;
    self.videoThumb.userInteractionEnabled = value;
    self.photoThumb.userInteractionEnabled = value;
}
struct ifaddrs *interfaces;
/*
- (BOOL) isWiFiEnabled {
    NSCountedSet * cset = [NSCountedSet new];
    struct ifaddrs *interfaces;
    
    if( ! getifaddrs(&interfaces) ) {
        for( struct ifaddrs *interface = interfaces; interface; interface = interface->ifa_next) {
            if ( (interface->ifa_flags & IFF_UP) == IFF_UP ) {
                NSString *obj = [NSString stringWithUTF8String:interface->ifa_name];
                AppLog(@"interface: %@", obj);
                [cset addObject:obj];
            }
        }
    }
    
    return [cset countForObject:@"awdl0"] > 1 ? YES : NO;
}
*/
- (IBAction)addCamera:(id)sender {
    UIButton *btn = (UIButton *)sender;
    NSString *buttonTitle = btn.titleLabel.text;
    
    if (![btn.isRecorded boolValue]) {
        /* Register a new camera */
        // Check redundance
        NSError *error = nil;
        if (![[self fetchedResultsController] performFetch:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
            abort();
#endif
        }
        if (self.fetchedResultsController.sections.count > 0) {
            id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:0];
            if([sectionInfo numberOfObjects] > 0) {
                for (int i=0; i<[sectionInfo numberOfObjects]; ++i) {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
                    Camera *camera = (Camera *)[self.fetchedResultsController objectAtIndexPath:indexPath];
                    if ([camera.wifi_ssid isEqualToString:current_ssid]
                        || [camera.wifi_ssid isEqualToString:_cameraSSID]) {
                        [self showGCDNoteWithMessage:@"You've already registered this camera." andTime:1.5 withAcvity:NO];
                        return;
                    }
                }
            }
        } // --- Check redundance ---
        
        [self performSegueWithIdentifier:@"addCameraSegue" sender:@[@(btn.tag)]];
    } else {
        /* Open a camera */
        if (current_ssid) {
            if ([buttonTitle isEqualToString:current_ssid]) {
                // Goto PV
                [self connect:@[@(btn.tag), current_ssid]];
            } else {
                if (_myCentralManager.state == CBManagerStatePoweredOn) {
                     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        NSLog(@"Scanning started");
                        [_myCentralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
                    });
                } else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Get Connected" message:@"To preview your Wi-Fi Camera, please turn on Bluetooth." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [alert show];
                }
            }
        } else {
            // Wi-Fi is disconnected
            NSString *msg = [NSString stringWithFormat:@"Please turn on Wi-Fi."];
            [self showGCDNoteWithMessage:msg andTime:1.5 withAcvity:NO];
        }
    }
}

- (IBAction)removeCameraByBtn:(UIButton*)sender{
        self.cameraTobeRemoved = sender.tag-100.0;
    
        BOOL showAlert = YES;
        switch (_cameraTobeRemoved) {
            case 0:
                if ([_addCamBtn1.titleLabel.text isEqualToString:NSLocalizedString(@"Add New Camera", nil)]) {
                    showAlert = NO;
                }
                break;
            case 1:
                if ([_addCamBtn2.titleLabel.text isEqualToString:NSLocalizedString(@"Add New Camera", nil)]) {
                    showAlert = NO;
                }
                break;
            case 2:
                if ([_addCamBtn3.titleLabel.text isEqualToString:NSLocalizedString(@"Add New Camera", nil)]) {
                    showAlert = NO;
                }
                break;
            default:
                break;
        }
        if (showAlert == YES) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",nil)
                                                            message:NSLocalizedString(@"Are you sure you want to remove this record", nil)
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                                  otherButtonTitles:NSLocalizedString(@"Sure",nil), nil];
            alert.tag = 5;
            [alert show];
        }
}
- (IBAction)removeCamera:(id)sender {
    
    UIButton *testBtn = sender;
    UILongPressGestureRecognizer *testGuesture = sender;
    if ([testBtn isKindOfClass:[UIButton class]]) {
        self.cameraTobeRemoved = (int)testBtn.tag;
    } else if ([testGuesture isKindOfClass:[UILongPressGestureRecognizer class]]) {
        if (testGuesture.state == UIGestureRecognizerStateBegan) {
            self.cameraTobeRemoved = (int)testGuesture.view.tag;
        } else {
            return;
        }
    }
    
    BOOL showAlert = NO;
    switch (_cameraTobeRemoved) {
        case 0:
            if ([_addCamBtn1.isRecorded boolValue]) {
                showAlert = YES;
            }
            break;
        case 1:
            if ([_addCamBtn2.isRecorded boolValue]) {
                showAlert = YES;
            }
            break;
        case 2:
            if ([_addCamBtn3.isRecorded boolValue]) {
                showAlert = YES;
            }
            break;
        default:
            break;
    }
    if (showAlert) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",nil)
                                                        message:NSLocalizedString(@"Are you sure you want to remove this record", nil)
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                              otherButtonTitles:NSLocalizedString(@"Sure",nil), nil];
        alert.tag = 5;
        [alert show];
    }

}

- (void)removeCameraAtIndex:(NSUInteger)index {
    NSString *nullTitle = NSLocalizedString(@"Add New Camera", nil);
    UIImage *nullThumbnail = [UIImage imageNamed:@"empty_thumb"];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Camera"
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id = %@", @(index)];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (!error && fetchedObjects && fetchedObjects.count>0) {
        [self.managedObjectContext deleteObject:fetchedObjects[0]];
        if ([self.managedObjectContext save:&error]) {
            
            if (index == 0) {
                [_addCamBtn1 setTitle:nullTitle forState:UIControlStateNormal];
                [_camThumbBtn1 setBackgroundImage:nullThumbnail
                                         forState:UIControlStateNormal];
                [_addCamBtn1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                _icon1.image = [UIImage imageNamed:@"addIcon"];
                _addCamBtn1.isRecorded = @NO;
                _remCamBtn1.hidden = YES;
            } else if (index == 1) {
                [_addCamBtn2 setTitle:nullTitle forState:UIControlStateNormal];
                [_camThumbBtn2 setBackgroundImage:nullThumbnail
                                         forState:UIControlStateNormal];
                [_addCamBtn2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                _icon2.image = [UIImage imageNamed:@"addIcon"];
                _addCamBtn2.isRecorded = @NO;
                _remCamBtn2.hidden = YES;

            } else {
                [_addCamBtn3 setTitle:nullTitle forState:UIControlStateNormal];
                [_camThumbBtn3 setBackgroundImage:nullThumbnail
                                         forState:UIControlStateNormal];
                [_addCamBtn3 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                _icon3.image = [UIImage imageNamed:@"addIcon"];
                _addCamBtn3.isRecorded = @NO;
                _remCamBtn3.hidden = YES;

            }
        }
    } else {
        AppLog(@"fetch failed.");
    }
}

- (NSString *)checkSSID
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

- (void)connect:(id)sender
{
    self.AppError = 0;
    if (!_connErrAlert.hidden) {
        AppLog(@"dismiss connErrAlert");
        [_connErrAlert dismissWithClickedButtonIndex:0 animated:NO];
    }
    if (!_connErrAlert1.hidden) {
        AppLog(@"dismiss connErrAlert");
        [_connErrAlert1 dismissWithClickedButtonIndex:0 animated:NO];
    }
    if (!_reconnAlert.hidden) {
        AppLog(@"dismiss reconnAlert");
        [_reconnAlert dismissWithClickedButtonIndex:0 animated:NO];
    }
    
    NSString *connectingMessage = [NSString stringWithFormat:@"%@ %@ ...", NSLocalizedString(@"Connect to",nil),[self checkSSID]];
    [self showGCDNoteWithMessage:connectingMessage withAnimated:YES withAcvity:YES];
    
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
                                [self hideGCDiscreetNoteView:YES];
                                AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                                appDelegate.isReconnecting = NO;
                                [self performSegueWithIdentifier:@"newPreviewSegue" sender:sender];
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
                [self hideGCDiscreetNoteView:YES];
//                [_connErrAlert show];
                NSString *ssid = [self checkSSID];
                if (ssid == nil) {
                    [_connErrAlert show];
                } else {
                    if (![ssid isEqualToString:current_ssid]) {
                        [_connErrAlert1 show];
                    } else {
                        [_reconnAlert show];
                        _current_sender = sender;
                    }
               }
            });
        }
    });
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"newPreviewSegue"]) {
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
    } else if ([segue.identifier isEqualToString:@"addCameraSegue"]) {
        UINavigationController *navController = [segue destinationViewController];
        AddCameraVC *vc = (AddCameraVC *)navController.topViewController;
        NSArray *data = (NSArray *)sender;
        vc.idx = [[data objectAtIndex:0] unsignedIntegerValue];
//        vc.cameraSSID = [data objectAtIndex:1];
        vc.cameraSSID = _cameraSSID;
        vc.managedObjectContext = _managedObjectContext;
    } else if ([segue.identifier isEqualToString:@"PortalSegue"]) {
        UINavigationController *navController = [segue destinationViewController];
        WiFiAPSetupNoticeVC *vc = (WiFiAPSetupNoticeVC *)navController.topViewController;
        vc.ssid = _cameraSSID;
        vc.pwd = _cameraPWD;
    } else {
        
    }
}

- (IBAction)showLocalMediaBrowser:(UIButton *)sender {
    _selectSender = sender;
    // Browser
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    NSMutableArray *thumbs = [[NSMutableArray alloc] init];
    //MWPhoto *photo, *thumb;
    BOOL displayActionButton = YES;
    BOOL displaySelectionButtons = NO;
    BOOL displayNavArrows = YES;
    BOOL enableGrid = YES;
    BOOL startOnGrid = YES;
    BOOL autoPlayOnAppear = NO;
    /*@synchronized(_assets) {
        NSMutableArray *copy = [_assets copy];
        if (NSClassFromString(@"PHAsset")) {
            // Photos library
            UIScreen *screen = [UIScreen mainScreen];
            CGFloat scale = screen.scale;
            // Sizing is very rough... more thought required in a real implementation
            CGFloat imageSize = MAX(screen.bounds.size.width, screen.bounds.size.height) * 1.5;
            CGSize imageTargetSize = CGSizeMake(imageSize * scale, imageSize * scale);
            CGSize thumbTargetSize = CGSizeMake(imageSize / 3.0 * scale, imageSize / 3.0 * scale);
            for (PHAsset *asset in copy) {
                if (sender.tag == 11 && asset.mediaType == PHAssetMediaTypeImage) {
                    [photos addObject:[MWPhoto photoWithAsset:asset targetSize:imageTargetSize]];
                    [thumbs addObject:[MWPhoto photoWithAsset:asset targetSize:thumbTargetSize]];
                } else if (sender.tag == 12 && asset.mediaType == PHAssetMediaTypeVideo) {
                    [photos addObject:[MWPhoto photoWithAsset:asset targetSize:imageTargetSize]];
                    [thumbs addObject:[MWPhoto photoWithAsset:asset targetSize:thumbTargetSize]];
                }
            }
        } else {
            // Assets library
            for (ALAsset *asset in copy) {
                if (sender.tag == 11 && [asset valueForProperty:ALAssetPropertyType] == ALAssetTypePhoto) {
                    photo = [MWPhoto photoWithURL:asset.defaultRepresentation.url];
                    [photos addObject:photo];
                    thumb = [MWPhoto photoWithImage:[UIImage imageWithCGImage:asset.thumbnail]];
                    [thumbs addObject:thumb];
                } else if (sender.tag == 12 && [asset valueForProperty:ALAssetPropertyType] == ALAssetTypeVideo) {
                    photo = [MWPhoto photoWithURL:asset.defaultRepresentation.url];
                    [photos addObject:photo];
                    thumb = [MWPhoto photoWithImage:[UIImage imageWithCGImage:asset.thumbnail]];
                    [thumbs addObject:thumb];
                    photo.videoURL = asset.defaultRepresentation.url;
                    thumb.isVideo = YES;
                }

            }
        }
    }*/
    if (sender.tag == 11) {
        @synchronized (_photosAssets) {
            NSMutableArray *copy = [_photosAssets copy];
            for (NSURL *photoURL in copy) {
                @autoreleasepool {
                    [photos addObject:[MWPhoto photoWithURL:photoURL]];
                    [thumbs addObject:[MWPhoto photoWithURL:photoURL]];
                }
            }
        }
    } else {
        @synchronized (_videosAssets) {
            NSMutableArray *copy = [_videosAssets copy];
            for (NSURL *photoURL in copy) {
                @autoreleasepool {
                    [photos addObject:[MWPhoto videoWithURL:photoURL]];
                    [thumbs addObject:[MWPhoto videoWithURL:photoURL]];
                }
            }
        }
    }
    
    self.photos = photos;
    self.thumbs = thumbs;
    
    // Create browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = displayActionButton;
    browser.displayNavArrows = displayNavArrows;
    browser.displaySelectionButtons = displaySelectionButtons;
    browser.alwaysShowControls = displaySelectionButtons;
    browser.zoomPhotosToFill = YES;
    browser.enableGrid = enableGrid;
    browser.startOnGrid = startOnGrid;
    browser.enableSwipeToDismiss = NO;
    browser.autoPlayOnAppear = autoPlayOnAppear;
    //[browser setCurrentPhotoIndex:0];
//    if ([[SDK instance] disablePTPIP]) {
//        [[SDK instance] initializeSDK];
//    }
    // Test custom selection images
    //    browser.customImageSelectedIconName = @"ImageSelected.png";
    //    browser.customImageSelectedSmallIconName = @"ImageSelectedSmall.png";
    
    // Reset selections
    if (displaySelectionButtons) {
        _selections = [NSMutableArray new];
        for (int i = 0; i < photos.count; i++) {
            [_selections addObject:[NSNumber numberWithBool:NO]];
        }
    }
    
    
    // Modal
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
    nc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nc animated:YES completion:nil];

    
    // Test reloading of data after delay
    double delayInSeconds = 3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        

        
    });
}
/*
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    AppLog(@"get the media info: %@", info);
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}
*/

-(void)globalReconnect
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:NSLocalizedString(@"Connecting", nil)
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:nil, nil];
        [alert show];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kCameraNetworkDisconnectedNotification"
                                                                object:nil];
            [NSThread sleepForTimeInterval:1.0];
            
            int totalCheckCount = 60; // 60times : 30s
            while (totalCheckCount-- > 0) {
                @autoreleasepool {
                    if ([Reachability didConnectedToCameraHotspot]) {
                        [[SDK instance] destroySDK];
                        [[PanCamSDK instance] destroypanCamSDK];
                        if ([[SDK instance] initializeSDK]) {
                            
                            // modify by allen.chuang - 20140703
                            /*
                             if( [[SDK instance] isValidCustomerID:0x0100] == false){
                             dispatch_async(dispatch_get_main_queue(), ^{
                             AppLog(@"CustomerID mismatch");
                             [_customerIDAlert show];
                             _AppError=1;
                             });
                             break;
                             }
                             */
                            
                            [WifiCamControl scan];
                            
                            WifiCamManager *app = [WifiCamManager instance];
                            self.wifiCam = [app.wifiCams objectAtIndex:0];
                            _wifiCam.camera = [WifiCamControl createOneCamera];
                            self.camera = _wifiCam.camera;
                            self.ctrl = _wifiCam.controler;
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                AppDelegate *appDetegale = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                                appDetegale.isReconnecting = NO;
                                [alert dismissWithClickedButtonIndex:0 animated:NO];
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"kCameraNetworkConnectedNotification"
                                                                                    object:nil];
                                [self performSegueWithIdentifier:@"newPreviewSegue" sender:_current_sender];
                            });
                            break;
                        }
                    }
                    
                    AppLog(@"[%d]NotReachable -- Sleep 500ms", totalCheckCount);
                    [NSThread sleepForTimeInterval:0.5];
                }
            }
            
            if (totalCheckCount <= 0 && _AppError == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [alert dismissWithClickedButtonIndex:0 animated:NO];
//                    [_reconnAlert show];
                    NSString *ssid = [self checkSSID];
                    if (ssid == nil) {
                        [_connErrAlert show];
                    } else if (![ssid isEqualToString:current_ssid]) {
                        [_connErrAlert1 show];
                    } else {
                        [_reconnAlert show];
                    }
                });
            }
            
        });
        
        
    });
}

- (void)showReconnectAlert
{
    if (!_reconnAlert.visible) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_reconnAlert show];
        });
    }
}


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case APP_RECONNECT_ALERT_TAG:
            //[self dismissViewControllerAnimated:YES completion:nil];
            //[self.navigationController popToRootViewControllerAnimated:YES];
            if (buttonIndex == 0) {
                [self globalReconnect];
            }
            break;
            
        case APP_CUSTOMER_ALERT_TAG:
            AppLog(@"dismissViewControllerAnimated - start");
            [self dismissViewControllerAnimated:YES completion:^{
                AppLog(@"dismissViewControllerAnimated - complete");
            }];
            [[SDK instance] destroySDK];
            exit(0);
            break;
            
        case 5:
            if (buttonIndex == 1) {
                [self removeCameraAtIndex:_cameraTobeRemoved];
            }
            break;
            
        default:
            break;
    }
}


#pragma mark - Fetched results controller
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

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    
}
/*
 -(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
 {
 
 }
 
-(void)controller:(NSFetchedResultsController *)controller
  didChangeObject:(id)anObject
      atIndexPath:(NSIndexPath *)indexPath
    forChangeType:(NSFetchedResultsChangeType)type
     newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            break;
            
        case NSFetchedResultsChangeDelete:
            break;
            
        case NSFetchedResultsChangeUpdate:
            break;
            
        case NSFetchedResultsChangeMove:
            break;
            
        default:
            break;
    }
}

-(void)controller:(NSFetchedResultsController *)controller
 didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
          atIndex:(NSUInteger)sectionIndex
    forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            break;
            
        case NSFetchedResultsChangeDelete:
            break;
            
        default:
            break;
    }
}
*/
#pragma mark - Load Assets
- (void)loadAssets {
    // get current SSID
    NSDictionary *ifs = [self fetchSSIDInfo];
    current_ssid= [ifs objectForKey:@"SSID"] ;
    
    if (NSClassFromString(@"PHAsset")) {
        // Check library permissions
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusNotDetermined) {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
//                    [self performLoadAssets];
                    [self performLoadLocalAssets];
                }
            }];
        } else if (status == PHAuthorizationStatusAuthorized) {
//            [self performLoadAssets];
            [self performLoadLocalAssets];
        }
    } else {
        // Assets library
//        [self performLoadAssets];
        [self performLoadLocalAssets];
    }
}

- (void)performLoadLocalAssets {
    
    // Initialise
    if (!_photosAssets) {
        _photosAssets = [NSMutableArray new];
    } else {
        [_photosAssets removeAllObjects];
    }
    
    if (!_videosAssets) {
        _videosAssets = [NSMutableArray new];
    } else {
        [_videosAssets removeAllObjects];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _photoThumb.tag = 11;
        _videoThumb.tag = 12;
    });
    
    // Load
    /*
     Create MobileCamApp-Medias Directory path: /var/mobile/Containers/Data/Application/7E35890F-F156-4556-AF70-19A5ADAE24DE/Documents/MobileCamApp-Medias
     Create MobileCamApp-Medias/Photos Directory path: /var/mobile/Containers/Data/Application/7E35890F-F156-4556-AF70-19A5ADAE24DE/Documents/MobileCamApp-Medias/Photos
     Create MobileCamApp-Medias/Videos Directory path: /var/mobile/Containers/Data/Application/7E35890F-F156-4556-AF70-19A5ADAE24DE/Documents/MobileCamApp-Medias/Videos
     */
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *photosPath = [[SDK instance] createMediaDirectory][1];
        NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:photosPath error:nil];
        for (NSString *photoPath in documentsDirectoryContents) {
            [_photosAssets addObject:[NSURL fileURLWithPath:[photosPath stringByAppendingPathComponent:photoPath]]];
        }
        
        if (_photosAssets.count > 0) {
            AppLog(@"_photosAssets.count: %lu", (unsigned long)_photosAssets.count);
            
//            if (_photoThumb.tag == 0) {
//                _photoThumb.tag = 11;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [_photoThumb setBackgroundImage:[UIImage imageWithContentsOfFile:((NSURL*)_photosAssets[0]).path] forState:UIControlStateNormal];
                });
//            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImage *noImage = [UIImage imageNamed:@"empty_thumb"];
                [_photoThumb setBackgroundImage:noImage forState:UIControlStateNormal];
            });
        }
        
        NSString *videosPath = [[SDK instance] createMediaDirectory][2];
        NSArray *videoDocuments = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:videosPath error:nil];
        for (NSString *videoPath in videoDocuments) {
            [_videosAssets addObject:[NSURL fileURLWithPath:[videosPath stringByAppendingPathComponent:videoPath]]];
        }
        
        if (_videosAssets.count > 0) {
            AppLog(@"_videosAssets.count: %lu", (unsigned long)_videosAssets.count);
            
//            if (_videoThumb.tag == 0) {
//                _videoThumb.tag = 12;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [_videoThumb setBackgroundImage:[self getImage:_videosAssets[0]] forState:UIControlStateNormal];
                });
//            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImage *noImage = [UIImage imageNamed:@"empty_thumb"];
                [_videoThumb setBackgroundImage:noImage forState:UIControlStateNormal];
            });
        }
    });
}

- (UIImage *)getImage:(NSURL *)videoURL

{
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    gen.appliesPreferredTrackTransform = YES;
    
    CMTime time = CMTimeMakeWithSeconds(0.0, 300);
    
    NSError *error = nil;
    
    CMTime actualTime;
    
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    
    CGImageRelease(image);
    
    return thumb;
}

- (void)performLoadAssets {
    
    // Initialise
    if (!_assets) {
        _assets = [NSMutableArray new];
    } else {
        [_assets removeAllObjects];
    }
    
    _photoThumb.tag = 0;
    _videoThumb.tag = 0;
    
    // Load
    if (NSClassFromString(@"PHAsset")) {
        
        // Photos library iOS >= 8
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            PHFetchResult *assetsFetchResult = nil;
            PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
            for (int i=0; i<topLevelUserCollections.count; ++i) {
                PHCollection *collection = [topLevelUserCollections objectAtIndex:i];
                if ([collection.localizedTitle isEqualToString:@"MobileCamApp"/*@"SBCapp"*//*@"WiFiCam"*/]) {
                    if (![collection isKindOfClass:[PHAssetCollection class]]) {
                        continue;
                    }
                    // Configure the AAPLAssetGridViewController with the asset collection.
                    PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
                    PHFetchOptions *options = [PHFetchOptions new];
                    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
                    assetsFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:options];
                    break;
                }
            }
            if (!assetsFetchResult) {
                AppLog(@"assetsFetchResult was nil.");
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImage *noImage = [UIImage imageNamed:@"empty_thumb"];
                    [_videoThumb setBackgroundImage:noImage forState:UIControlStateNormal];
                    [_photoThumb setBackgroundImage:noImage forState:UIControlStateNormal];
                });
                return;
            }
            
            [assetsFetchResult enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                //Add
                [_assets addObject:obj];
                
                PHAsset *asset = obj;
                if (_photoThumb.tag == 0 && asset.mediaType == PHAssetMediaTypeImage) {
                    _photoThumb.tag = 11;
                    PHImageManager *manager = [PHImageManager defaultManager];
                    PHImageRequestOptions * options = [[PHImageRequestOptions alloc] init];
                    options.resizeMode = PHImageRequestOptionsResizeModeExact;
                    [manager requestImageForAsset:asset
                                       targetSize:_photoThumb.frame.size
                                      contentMode:PHImageContentModeAspectFit
                                          options:options
                                    resultHandler:^(UIImage *result, NSDictionary *info) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [_photoThumb setBackgroundImage:result forState:UIControlStateNormal];
                                        });
                                        
                                    }];
                    
                } else if (_videoThumb.tag == 0 && asset.mediaType == PHAssetMediaTypeVideo) {
                    _videoThumb.tag = 12;
                    PHCachingImageManager *manager = [[PHCachingImageManager alloc] init];
                    PHImageRequestOptions * options = [[PHImageRequestOptions alloc] init];
                    options.resizeMode = PHImageRequestOptionsResizeModeExact;
                    [manager requestImageForAsset:asset
                                       targetSize:_videoThumb.frame.size
                                      contentMode:PHImageContentModeAspectFit
                                          options:options
                                    resultHandler:^(UIImage *result, NSDictionary *info) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [_videoThumb setBackgroundImage:result forState:UIControlStateNormal];
                                        });
                                        
                                    }];
                }
                
            }];
            
            if (assetsFetchResult.count > 0) {
                AppLog(@"_assets.count: %lu", (unsigned long)_assets.count);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIImage *noImage = [UIImage imageNamed:@"empty_thumb"];
                    [_videoThumb setBackgroundImage:noImage forState:UIControlStateNormal];
                    [_photoThumb setBackgroundImage:noImage forState:UIControlStateNormal];
                });
            }
        });
        
    } else {
        
        /*
         ALAssetsLibrary：代表整个PhotoLibrary，我们可以生成一个它的实例对象，这个实例对象就相当于是照片库的句柄。
         ALAssetsGroup：照片库的分组，我们可以通过ALAssetsLibrary的实例获取所有的分组的句柄。
         ALAsset：一个ALAsset的实例代表一个资产，也就是一个photo或者video，我们可以通过他的实例获取对应的缩略图或者原图等等。
         */
        
        // Assets Library iOS < 8
        _ALAssetsLibrary = [[ALAssetsLibrary alloc] init];
        // Run in the background as it takes a while to get all assets from the library
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSMutableArray *assetGroups = [[NSMutableArray alloc] init];
            NSMutableArray *assetURLDictionaries = [[NSMutableArray alloc] init];
            
            // Process assets
            void (^assetEnumerator)(ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if (result) {
                    NSString *assetType = [result valueForProperty:ALAssetPropertyType];
                    
                    if (_photoThumb.tag == 0 && [assetType isEqualToString:ALAssetTypePhoto]) {
                        [self loadFirstPhotoThumbnail:result];
                    } else if (_videoThumb.tag == 0 && [assetType isEqualToString:ALAssetTypeVideo]) {
                        [self loadFirstVideoThumbnail:result];
                    }
                    
                    if ([assetType isEqualToString:ALAssetTypePhoto] || [assetType isEqualToString:ALAssetTypeVideo]) {
                        [assetURLDictionaries addObject:[result valueForProperty:ALAssetPropertyURLs]];
                        NSURL *url = result.defaultRepresentation.url;
                        [_ALAssetsLibrary assetForURL:url
                                          resultBlock:^(ALAsset *asset) {
                                              if (asset) {
                                                  @synchronized(_assets) {
                                                      [_assets addObject:asset];
                                                  }
                                              }
                                          }
                                         failureBlock:^(NSError *error){
                                             NSLog(@"operation was not successfull!");
                                         }];
                    }
                }
            };
            
            // Process groups
            void (^ assetGroupEnumerator) (ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
                if (group) {
                    [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:assetEnumerator];
                    [assetGroups addObject:group];
                }
            };
            
            // Process!
            [_ALAssetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos
                                            usingBlock:assetGroupEnumerator
                                          failureBlock:^(NSError *error) {
                                              NSLog(@"There is an error");
                                          }];
            
        });
        
    }
    
}

- (void)loadFirstPhotoThumbnail:(ALAsset*)asset {
//    NSString *photoURL=[NSString stringWithFormat:@"%@",asset.defaultRepresentation.url];
//    NSLog(@"photoURL:%@", photoURL);
    
    //UIImage* photo = [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
    //NSLog(@"PHOTO:%@", photo);
    //NSLog(@"photoSize:%@", NSStringFromCGSize(photo.size));
    
    UIImage* photoThumbnail = [UIImage imageWithCGImage:asset.thumbnail];
//    NSLog(@"PHOTO2:%@", photoThumbnail);
//    NSLog(@"photoSize2:%@", NSStringFromCGSize(photoThumbnail.size));
    if (_photoThumb.tag == 0 && photoThumbnail) {
        _photoThumb.tag = 11;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_photoThumb setBackgroundImage:photoThumbnail forState:UIControlStateNormal];
        });
    }
}

- (void)loadFirstVideoThumbnail:(ALAsset*)asset {
//    NSString *photoURL=[NSString stringWithFormat:@"%@",asset.defaultRepresentation.url];
//    NSLog(@"videoURL:%@", photoURL);
    
    UIImage* videoThumbnail = [UIImage imageWithCGImage:asset.thumbnail];
//    NSLog(@"VIDEO2:%@", videoThumbnail);
//    NSLog(@"videoSize2:%@", NSStringFromCGSize(videoThumbnail.size));
    if (_videoThumb.tag == 0) {
        _videoThumb.tag = 12;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_videoThumb setBackgroundImage:videoThumbnail forState:UIControlStateNormal];
            
        });
    }
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return _photos.count;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (index < _thumbs.count)
        return [_thumbs objectAtIndex:index];
    return nil;
}

//- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index {
//    MWPhoto *photo = [self.photos objectAtIndex:index];
//    MWCaptionView *captionView = [[MWCaptionView alloc] initWithPhoto:photo];
//    return [captionView autorelease];
//}

//- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
//    NSLog(@"ACTION!");
//}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"Did start viewing photo at index %lu", (unsigned long)index);
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    return [[_selections objectAtIndex:index] boolValue];
}

//- (NSString *)photoBrowser:(MWPhotoBrowser *)photoBrowser titleForPhotoAtIndex:(NSUInteger)index {
//    return [NSString stringWithFormat:@"Photo %lu", (unsigned long)index+1];
//}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
    [_selections replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:selected]];
    NSLog(@"Photo at index %lu selected %@", (unsigned long)index, selected ? @"YES" : @"NO");
}

- (void)photoBrowserDidFinishModalPresentation:(MWPhotoBrowser *)photoBrowser {
    // If we subscribe to this method we must dismiss the view controller ourselves
    NSLog(@"Did finish modal presentation");
    [self dismissViewControllerAnimated:YES completion:^{
//        [[SDK instance] destroySDK];
//        [[SDK instance] enablePTPIP];
        //[[PanCamSDK instance] destroypanCamSDK];
        
        /*if ([EAGLContext currentContext] == photoBrowser.context) {
            [EAGLContext setCurrentContext:nil];
        }*/
    }];
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser deletePhotoAtIndex:(NSUInteger)index
{
    NSString *filePath;
    NSArray *documentsDirectoryContents;
    
    if (_selectSender.tag == 11) {
        filePath = [[SDK instance] createMediaDirectory][1];
    } else {
        filePath = [[SDK instance] createMediaDirectory][2];
    }
    documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:filePath error:nil];
    
    BOOL ret = [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", filePath, documentsDirectoryContents[index]] error:nil];
    
    if (ret) {
        [self performLoadLocalAssets];
        if (_photos.count) {
            [_photos removeAllObjects];
        }
        if (_thumbs.count) {
            [_thumbs removeAllObjects];
        }
        [NSThread sleepForTimeInterval:1.0];
        
        if (_selectSender.tag == 11) {
            for (NSURL *photoURL in _photosAssets) {
                [_photos addObject:[MWPhoto photoWithURL:photoURL]];
                [_thumbs addObject:[MWPhoto photoWithURL:photoURL]];
            }
        } else {
            for (NSURL *videoURL in _videosAssets) {
                [_photos addObject:[MWPhoto videoWithURL:videoURL]];
                [_thumbs addObject:[MWPhoto videoWithURL:videoURL]];
            }
        }
    }
    
    return ret;
}

- (void)panCamSDKinit {
    [[PanCamSDK instance] initImage];
}

- (BOOL)changePanoramaType:(int)panoramaType {
    return [[PanCamSDK instance] changePanoramaType:panoramaType isStream:NO];
}

- (void)createICatchImage:(UIImage *)image {
    [[PanCamSDK instance] panCamcreateICatchImage:image];
}

- (void)configureGLKView:(int)width andHeight:(int)height {
    //[[PanCamSDK instance] panCamSetViewPort:width andHeight:height];
    [[PanCamSDK instance] panCamSetViewPort:0 andY:44 andWidth:width andHeight:height - 88];
    [[PanCamSDK instance] panCamRender];
}

- (void)rotate:(CGPoint) pointC andPointPre:(CGPoint)pointP {
    [[PanCamSDK instance] panCamRotate:pointC andPointPre:pointP andType:PCFileTypeImage];
}

- (void)rotate:(int)orientation andX:(float)x andY:(float)y andZ:(float)z andTimestamp:(long)timestamp {
    [[PanCamSDK instance] panCamRotate:orientation andSpeedX:x andSpeedY:y andSpeedZ:z andTamp:timestamp andType:PCFileTypeImage];
}

- (void)locate:(float)distance {
    [[PanCamSDK instance] panCamLocate: distance andType:PCFileTypeImage];
}

- (void)panCamSDKDestroy {
//    [[PanCamSDK instance] destroyImage];
    [[PanCamSDK instance] destroypanCamSDK];
}

- (void)destroyDataForEnterBackground {
    dispatch_sync([[SDK instance] sdkQueue], ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kCameraDestroySDKNotification"
                                                            object:nil];
//        [[SDK instance] destroySDK];
//        [[SDK instance] enablePTPIP];
        [[PanCamSDK instance] destroypanCamSDK];
    });
}

- (void)popGLKViewByphotoBrowser:(MWPhotoBrowser *)photoBrowser andVideoURL:(NSURL *)videoURL {
    /*PanCamGLKView *glkView = [[PanCamGLKView alloc] init];
    //glkView.image = img;
    glkView.videoURL = videoURL;
    glkView.photoBrowser = photoBrowser;
    glkView.photoNum = [photoBrowser numberOfPhotos];
    glkView.currentIndex = photoBrowser.currentPhotoIndex;*/
    
    VideoPlaybackViewController *playView = [[VideoPlaybackViewController alloc] init];
    playView.videoURL = videoURL;
    
    // Modal
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:playView];
    nc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nc.navigationBar.barTintColor = [UIColor blackColor];
    //glkView.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    nc.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [photoBrowser presentViewController:nc animated:YES completion:nil];
}

#pragma mark - AppDelegateProtocol
-(void)applicationDidBecomeActive:(UIApplication *)application {
    [self loadAssets];
    [self checkConnectionStatus];
    /*
	if (_myCentralManager.state == CBCentralManagerStatePoweredOn
        && !_discoveredPeripheral) {
        [_myCentralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
        NSLog(@"Scanning started");
    }
     */
}

#pragma mark - CBCentralManagerDelegate
-(void)centralManagerDidUpdateState:(CBCentralManager *)central {
    /*
    if (central.state == CBCentralManagerStatePoweredOn) {
        [central scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
        NSLog(@"Starting to scan.");
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self checkConnectionStatus];
        });
        self.discoveredPeripheral = nil;
    }*/
}

-(void)centralManager:(CBCentralManager *)central
didDiscoverPeripheral:(CBPeripheral *)peripheral
    advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                 RSSI:(NSNumber *)RSSI {
    NSLog(@"Discoverd %@ at %@", peripheral.name, RSSI);
    
    if ([peripheral.name isEqualToString:current_ssid]) {
        [_myCentralManager stopScan];
        NSLog(@"Connecting to peripheral %@", peripheral);
        [_myCentralManager connectPeripheral:peripheral options:nil];
    }
}

-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"Peripheral connected.");
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Failed to connect to %@. (%@)", peripheral, [error localizedDescription]);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showGCDNoteWithMessage:@"Failed to pair!" andTime:2.0 withAcvity:NO];
    });
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSLog(@"Peripheral disconnected.");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self checkConnectionStatus];
    });
    self.cameraSSID = nil;
    self.cameraPWD = nil;
    /*
    if (central.state == CBCentralManagerStatePoweredOn) {
        [central scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
        NSLog(@"Scanning started");
    }
     */
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Get Connected" message:@"Connect failed." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    });
}

#pragma mark - CBPeripheralDelegate
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering services: %@", [error localizedDescription]);
        return;
    }
    
    NSLog(@"Service count: %lu", (long)peripheral.services.count);
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
        // test
        break;
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSLog(@"Error discovering characteristic: %@", [error localizedDescription]);
        return;
    }
    
    NSLog(@"Characteristic count: %lu", (long)service.characteristics.count);
    for (CBCharacteristic *characteristic in service.characteristics) {
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        
        if ((characteristic.properties & CBCharacteristicPropertyWrite) == CBCharacteristicPropertyWrite) {
            NSLog(@"It can be writed.");
            
//            NSString *cmd = @"bt wifi info essid,pwd\0";
//            NSString *cmd = @"{\"mode\":\"wifi\",\"action\":\"info\",\"essid\":\"\",\"pwd\":\"\",\"ipaddr\":\"\"}";
            NSString *cmd = @"{\"mode\":\"wifi\",\"action\":\"info\"}";
            NSData *data = [[NSData alloc] initWithBytes:[cmd UTF8String] length:cmd.length];
            [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
            break;
            
        } else {
            NSLog(@"It cannot be writed.");
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
            error:(NSError *)error {
    if (error) {
        NSLog(@"Error update characteristic value %@", [error localizedDescription]);
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showGCDNoteWithMessage:@"Failed" andTime:1.0 withAcvity:NO];
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
            [self showGCDNoteWithMessage:@"Failed" andTime:1.0 withAcvity:NO];
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
                    [self hideGCDiscreetNoteView:NO];
                    [self performSegueWithIdentifier:@"PortalSegue" sender:nil];
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
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self checkConnectionStatus];
                });
            } else {
                NSLog(@"Error: %u", err);
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showGCDNoteWithMessage:@"Failed" andTime:1.0 withAcvity:NO];
            });
        }
        _receivedCmd = nil;
    }
}

//-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
//    if (error) {
//        NSLog(@"Error update characteristic value %@", [error localizedDescription]);
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self showGCDNoteWithMessage:@"Failed" andTime:1.0 withAcvity:NO];
//        });
//        return;
//    }
//    
//    NSData *data = characteristic.value;
//    NSString *info = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    if (!_receivedCmd) {
//        self.receivedCmd = [[NSMutableString alloc] init];
//    }
//    
//    [_receivedCmd appendString:info];
//    if ([info containsString:@"\0"]) {
//        NSLog(@"%@", _receivedCmd);
//        NSArray *items = [_receivedCmd componentsSeparatedByString:@" "];
//        if ([items[1] isEqualToString:@"wifi"]
//                   && [items[2] isEqualToString:@"info"]) {
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
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self hideGCDiscreetNoteView:NO];
//                    [self performSegueWithIdentifier:@"PortalSegue" sender:nil];
//                });
//            } else {
//                NSLog(@"Error: %u", err);
//            }
//        } else if ([items[1] isEqualToString:@"wifi"]
//                   && [items[2] isEqualToString:@"enable"]) {
//            NSArray *subs = [items[4] componentsSeparatedByString:@"="];
//            uint err = [subs[1] unsignedIntValue];
//            if (err == 0) {
//                NSString *cmd = @"bt wifi enable ap\0";
//                NSData *data = [[NSData alloc] initWithBytes:[cmd UTF8String]
//                                                      length:cmd.length];
//                [peripheral writeValue:data
//                     forCharacteristic:characteristic
//                                  type:CBCharacteristicWriteWithResponse];
//                
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self checkConnectionStatus];
//                });
//            } else {
//                NSLog(@"Error: %u", err);
//            }
//        }
//        _receivedCmd = nil;
//    }
//}
@end
