//
//  AppDelegate.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-5.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import "AppDelegate.h"
#import "ExceptionHandler.h"
#ifdef DEBUG
//#include "ICatchWificamConfig.h"
#endif
#import "ViewController.h"
#import "HomeVC.h"
#include "WifiCamSDKEventListener.h"
#import "WifiCamControl.h"
#import "Reachability+Ext.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "GCDiscreetNotificationView.h"

#import "PanCamSDK.h"
#if 0
#import <BuglyHotfix/Bugly.h>
#endif
//#import <GoogleSignIn/GoogleSignIn.h>
//#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <CoreLocation/CoreLocation.h>
#import "Tool.h"

@interface AppDelegate () <CLLocationManagerDelegate>
@property(nonatomic) BOOL enableLog;
@property(nonatomic) FILE *appLogFile;
//@property (nonatomic) FILE *sdkLogFile;
@property(nonatomic) WifiCamObserver *globalObserver;
@property(strong, nonatomic) UIAlertView *reconnectionAlertView;
@property(strong, nonatomic) UIAlertView *connectionErrorAlertView;
@property(strong, nonatomic) UIAlertView *connectionErrorAlertView1;
@property(strong, nonatomic) UIAlertView *connectingAlertView;
@property(nonatomic) NSString *current_ssid;
@property(nonatomic, retain) GCDiscreetNotificationView *notificationView;
@property(nonatomic) NSTimer *timer;
@property(nonatomic) WifiCamObserver *sdcardRemoveObserver;
@property(nonatomic) BOOL isTimeout;
@property(nonatomic) NSTimer *timeOutTimer;

@property(nonatomic) WifiCamObserver *sdcardInObserver;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, weak) UIAlertController *locationAuthorizationAlertView;

@end

#define UmengAppkey @"55765a2467e58ed0a60031d8"
static NSString * const kClientID = @"759186550079-nj654ak1umgakji7qmhl290hfcp955ep.apps.googleusercontent.com";

@implementation AppDelegate

#if 0
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
#if 0
    if ([[url scheme] isEqualToString:@"fb295583287549917"]){
        return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                              openURL:url
                                                    sourceApplication:sourceApplication
                                                           annotation:annotation];
    } else {
        return [[GIDSignIn sharedInstance] handleURL:url
                                   sourceApplication:sourceApplication
                                          annotation:annotation];
    }
#else
    return [[GIDSignIn sharedInstance] handleURL:url
    sourceApplication:sourceApplication
           annotation:annotation];
#endif
}
#endif

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if 0
    [Bugly startWithAppId:nil]; //add bugly SDK 2016.12.28
#endif
    // Exception handler
    [self registerDefaultsFromSettingsBundle];
#if 0
    // Set app's client ID for |GIDSignIn|.
    [GIDSignIn sharedInstance].clientID = kClientID;
#endif
    
#if 0
    // Facebook delegate
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
#endif
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults stringForKey:@"RTMPURL"]) {
        [defaults setObject:@"rtmp://a.rtmp.youtube.com/live2/7m5m-wuhz-ryaq-89ss" forKey:@"RTMPURL"];
    }
    
    // Enalbe log
    NSUserDefaults *defaultSettings = [NSUserDefaults standardUserDefaults];
    self.enableLog = [defaultSettings boolForKey:@"PreferenceSpecifier:Log"];
    if (_enableLog) {
        [self startLogToFile];
    } else {
        [self cleanLogs];
    }
    
    [self showAppVersionInfoAndRunDate];

    //
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    //
    UINavigationController *rootNavController = (UINavigationController *)self.window.rootViewController;
    HomeVC *homeVC = (HomeVC *)rootNavController.topViewController;
    homeVC.managedObjectContext = self.managedObjectContext;
    
    self.connectionErrorAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectError", nil)
          message                                         :NSLocalizedString(@"NoWifiConnection", nil)
          delegate                                        :self
          cancelButtonTitle                               :NSLocalizedString(@"Exit", nil)
          otherButtonTitles                               :nil, nil];
    _connectionErrorAlertView.tag = APP_CONNECT_ERROR_TAG;
    
    self.connectionErrorAlertView1 = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectError", nil)
                                                    message:NSLocalizedString(@"Connected to other Wi-Fi", nil)
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Exit", nil)
                                          otherButtonTitles:nil, nil];
    _connectionErrorAlertView1.tag = APP_CONNECT_ERROR_TAG;
    
    self.reconnectionAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ConnectError", nil)
                                       message           :NSLocalizedString(@"TimeoutError", nil)
                                       delegate          :self
                                       cancelButtonTitle :NSLocalizedString(@"STREAM_RECONNECT", nil)
                                       otherButtonTitles :NSLocalizedString(@"Exit", nil), nil];
    _reconnectionAlertView.tag = APP_RECONNECT_ALERT_TAG;
    
    [self addGlobalObserver];
    self.isReconnecting = YES;
    if (![self.timer isValid]) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCurrentNetworkStatus) userInfo:nil repeats:YES];
    }
    
    return YES;
}

- (void)showAppVersionInfoAndRunDate {
    NSDate *date = [NSDate date];

    NSLog(@"====================== MobileCamApp run starting ======================");
    NSLog(@"###### App Version: %@", APP_VERSION);
    NSLog(@"###### Build: %@", APP_BUILDNUMBER);
    
    NSLog(@"-----------------------------------------------------------------------");
    
    string sdkVString = ICatchPancamInfo::getSDKVersion();
    NSLog(@"###### SDK Version: %s", sdkVString.c_str());

    NSLog(@"-----------------------------------------------------------------------");

    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSLog(@"###### Run Date: %@", [dateformatter stringFromDate:date]);
    NSLog(@"###### Device info: %@", [WifiCamStaticData deviceInfo]);
    NSLog(@"###### Locale Language Code: %@（%@）", [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode], [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"][0]);
    NSLog(@"=======================================================================");
}

- (void)checkCurrentNetworkStatus
{
    if (![Reachability didConnectedToCameraHotspot]) {
        if (!_isReconnecting) {
            [self notifyDisconnectionEvent];
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, doneand throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    TRACE();
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    TRACE();
    
    [self removeGlobalObserver];
    [self.timer invalidate];
    _isReconnecting = NO;
    [self.timeOutTimer invalidate];
    _isTimeout = NO;
    
    if (![[SDK instance] isBusy]) {
        if ([self.delegate respondsToSelector:@selector(applicationDidEnterBackground:)]) {
            AppLog(@"Execute delegate method.");
            [self.delegate applicationDidEnterBackground:nil];
        } else {
            AppLog(@"Execute default method.");
            dispatch_sync([[SDK instance] sdkQueue], ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"kCameraDestroySDKNotification"
                                                                    object:nil];
                [[SDK instance] destroySDK];
//                [[SDK instance] enablePTPIP];
                [[PanCamSDK instance] destroypanCamSDK];
            });
        }
        
        [self.window.rootViewController dismissViewControllerAnimated:NO completion: nil];
    } else {
        NSTimeInterval ti = 0;
        ti = [[UIApplication sharedApplication] backgroundTimeRemaining];
        NSLog(@"backgroundTimeRemaining: %f", ti);
    }
    
    if (!_connectingAlertView.hidden) {
        [_connectingAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }
    if (!_connectionErrorAlertView.hidden) {
        [_connectionErrorAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }
    if (!_connectionErrorAlertView1.hidden) {
        [_connectionErrorAlertView1 dismissWithClickedButtonIndex:0 animated:NO];
    }
    if (!_reconnectionAlertView.hidden) {
        [_reconnectionAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    TRACE();
    
    [self addGlobalObserver];
    //[[Reachability reachabilityForLocalWiFi] startNotifier];
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyDisconnectionEvent) name:kReachabilityChangedNotification object:nil];
    if (![self.timer isValid]) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(checkCurrentNetworkStatus)
                                                    userInfo:nil repeats:YES];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    TRACE();
#ifdef DEBUG
    //  NSUserDefaults *defaultSettings = [NSUserDefaults standardUserDefaults];
    //  if (![defaultSettings integerForKey:@"PreviewCacheTime"]) {
    //    AppLog(@"loading default value...");
    //    [self performSelector:@selector(registerDefaultsFromSettingsBundle)];
    //  }
    
    /*
     NSInteger pct = [[NSUserDefaults standardUserDefaults] integerForKey:@"PreviewCacheTime"];
     AppLog(@"pct: %d", pct);
     ICatchWificamConfig *config = new ICatchWificamConfig();
     config->setPreviewCacheParam(pct);
     delete config; config = NULL;
     */
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"PreferenceSpecifier:DumpMediaStream"]) {
#if 0
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *streamType = [defaults stringForKey:@"PreferenceSpecifier:DumpMediaStreamType"];
        bool videoStream = [streamType isEqualToString:@"Video"] ? true : false;
        ICatchCameraConfig::getInstance()->enableDumpMediaStream(videoStream, documentsDirectory.UTF8String);
#endif
    }
#endif
    /*
     if (![[SDK instance] isSDKInitialized]) {
     //
     UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Disconnected from camera." delegate:self cancelButtonTitle:@"Back" otherButtonTitles:@"Reconnect", nil];
     alert.tag = 1000;
     [alert show];
     
     return;
     }
     */
//    [FBSDKAppEvents activateApp];
    
    if ([self.delegate respondsToSelector:@selector(applicationDidBecomeActive:)]) {
        [self.delegate applicationDidBecomeActive:nil];
    }
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 13.0) {
        [self requestLocationPermission];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    AppLog(@"%s", __func__);
    //[[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    if (_enableLog) {
        [self stopLog];
    }
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    TRACE();
}

#pragma mark - Log

- (void)startLogToFile
{
    // Get the document directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    // Name the log folder & file
    NSDate *date = [NSDate date];
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"yyyyMMdd-HHmmss"];
    NSString *name = [dateformatter stringFromDate:date];
    NSString *appLogFileName = [NSString stringWithFormat:@"APP-%@.log", name];
    // Create the log folder
    NSString *logDirectory = [documentsDirectory stringByAppendingPathComponent:name];
    [[NSFileManager defaultManager] createDirectoryAtPath:logDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    // Create(Open) the log file
    NSString *appLogFilePath = [logDirectory stringByAppendingPathComponent:appLogFileName];
    self.appLogFile = freopen([appLogFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stderr);
    
    //NSString *sdkLogFileName = [NSString stringWithFormat:@"SDK-%@.log", [NSDate date]];
    //NSString *sdkLogFilePath = [documentsDirectory stringByAppendingPathComponent:sdkLogFileName];
    //self.sdkLogFile = freopen([sdkLogFilePath cStringUsingEncoding:NSASCIIStringEncoding], "a+", stdout);
    
    // Log4SDK
    [[SDK instance] enableLogSdkAtDiretctory:logDirectory enable:YES];
    [[PanCamSDK instance] enableLogSdkAtDiretctory:logDirectory enable:YES];
    
    TRACE();
}

- (void)stopLog
{
    TRACE();
    fclose(_appLogFile);
    //fclose(_sdkLogFile);
}

- (void)cleanLogs
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSString *logFilePath = nil;
    for (NSString *fileName in  documentsDirectoryContents) {
        if (![fileName isEqualToString:@"Camera.sqlite"] && ![fileName isEqualToString:@"Camera.sqlite-shm"] && ![fileName isEqualToString:@"Camera.sqlite-wal"] && ![fileName isEqualToString:@"MobileCamApp-Medias"]) {
            
            logFilePath = [documentsDirectory stringByAppendingPathComponent:fileName];
            [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:nil];
        }
        
    }
}

// retrieve the default setting values
- (void)registerDefaultsFromSettingsBundle {
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if(!settingsBundle) {
        NSLog(@"Could not find Settings.bundle");
        return;
    }
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    for(NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if(key) {
            [defaultsToRegister setObject:[prefSpecification objectForKey:@"DefaultValue"] forKey:key];
        }
    }
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsToRegister];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext {
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return _managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
    
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    //NSURL* modelURL=[[NSBundle mainBundle] URLForResource:@"Camera" withExtension:@"momd"];
    //_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    return _managedObjectModel;
}

/**
 Returns the URL to the application's documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // copy the default store (with a pre-populated data) into our Documents folder
    //
    NSString *documentsStorePath =
    [[[self applicationDocumentsDirectory] path] stringByAppendingPathComponent:@"Camera.sqlite"];
    AppLog(@"sqlite's path: %@", documentsStorePath);
    
    // if the expected store doesn't exist, copy the default store
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsStorePath]) {
        NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"Camera" ofType:@"sqlite"];
        if (defaultStorePath) {
            [[NSFileManager defaultManager] copyItemAtPath:defaultStorePath toPath:documentsStorePath error:NULL];
        }
    }
    
    _persistentStoreCoordinator =
    [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    // add the default store to our coordinator
    NSError *error;
    NSURL *defaultStoreURL = [NSURL fileURLWithPath:documentsStorePath];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:defaultStoreURL
                                                         options:nil
                                                           error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible
         * The schema for the persistent store is incompatible with current managed object model
         Check the error message to determine what the actual problem was.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
        abort();
#endif
    }
    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Core Data Saving support
- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
            abort();
#endif
        }
    }
}
#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case APP_RECONNECT_ALERT_TAG:
            if (buttonIndex == 0) {
               [self globalReconnect];
            } else if (buttonIndex == 1) {
                [self.window.rootViewController dismissViewControllerAnimated:YES completion: nil];
                //exit(0);
            }
            
            break;
            
        case APP_CONNECT_ERROR_TAG:
            if (buttonIndex == 0) {
                [self.window.rootViewController dismissViewControllerAnimated:YES completion: nil];
                //exit(0);
            }
            break;
            
        case APP_CUSTOMER_ALERT_TAG:
            [[SDK instance] destroySDK];
            exit(0);
            break;
            
        case APP_TIMEOUT_ALERT_TAG:
            if (buttonIndex == 0) {
                [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
            }
            break;
            
        default:
            break;
    }
}

#pragma mark - Observer
-(void)addGlobalObserver {
#if USE_SDK_EVENT_DISCONNECTED
    auto listener = make_shared<WifiCamSDKEventListener>(self, @selector(notifyDisconnectionEvent));
    self.globalObserver = [[WifiCamObserver alloc] initWithListener:listener eventType:ICATCH_EVENT_CONNECTION_DISCONNECTED isCustomized:NO isGlobal:YES];
    [[SDK instance] addObserver:_globalObserver];
#else
#endif
    
    auto sdcardRemovelistener = make_shared<WifiCamSDKEventListener>(self, @selector(notifySdCardRemoveEvent));
    self.sdcardRemoveObserver = [[WifiCamObserver alloc] initWithListener:sdcardRemovelistener eventType:ICH_CAM_EVENT_SDCARD_REMOVED isCustomized:NO isGlobal:YES];
    [[SDK instance] addObserver:self.sdcardRemoveObserver];
    
    // sdcard in
    auto sdkcardInlister = make_shared<WifiCamSDKEventListener>(self, @selector(notifySDCardInEvent));
    self.sdcardInObserver = [[WifiCamObserver alloc] initWithListener:sdkcardInlister eventType:ICH_CAM_EVENT_SDCARD_IN isCustomized:NO isGlobal:YES];
    [[SDK instance] addObserver:self.sdcardInObserver];
}

-(void)removeGlobalObserver {
#if USE_SDK_EVENT_DISCONNECTED
    [[SDK instance] removeObserver:_globalObserver];
    delete _globalObserver.listener;
    _globalObserver.listener = NULL;
    self.globalObserver = nil;
#else
#endif
    
    [[SDK instance] removeObserver:self.sdcardRemoveObserver];
//    delete self.sdcardRemoveObserver.listener;
    self.sdcardRemoveObserver.listener = NULL;
    self.sdcardRemoveObserver = nil;
    
    [[SDK instance] removeObserver:self.sdcardInObserver];
//    delete self.sdcardInObserver.listener;
    self.sdcardInObserver.listener = NULL;
    self.sdcardInObserver = nil;
}

- (void)notifySdCardRemoveEvent
{
    AppLog(@"SDCardRemoved event was received.");
    if ([self.delegate respondsToSelector:@selector(sdcardRemoveCallback)]) {
        [self.delegate sdcardRemoveCallback];
    }
}

- (void)notifySDCardInEvent {
    AppLog(@"SDCardIn event was received.");
    if ([self.delegate respondsToSelector:@selector(sdcardInCallback)]) {
        [self.delegate sdcardInCallback];
    }
}

-(void)notifyDisconnectionEvent {
#if USE_SDK_EVENT_DISCONNECTED
#else
    if (_current_ssid && [[Tool sysSSID] isEqualToString:_current_ssid] && [Reachability didConnectedToCameraHotspot]) {
        return;
    }
#endif
    
    AppLog(@"Disconnectino event was received.");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kCameraNetworkDisconnectedNotification"
                                                        object:nil];
    
    _current_ssid = nil;
    if ([self.delegate respondsToSelector:@selector(notifyConnectionBroken)]) {
        _current_ssid = [self.delegate notifyConnectionBroken];
    } else {
        [[SDK instance] destroySDK];
        [[PanCamSDK instance] destroypanCamSDK];
    }
    
    if (_current_ssid) {
        [NSThread sleepForTimeInterval:0.03];
        [self globalReconnect];
    } else {
        if (!_reconnectionAlertView.visible) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_reconnectionAlertView show];
                _isReconnecting = YES;
            });
        }
    }
//    //[self removeGlobalObserver];
//    if (!_reconnectionAlertView.visible) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [_reconnectionAlertView show];
//        });
//    }
}

-(void)globalReconnect
{
    // [self addGlobalObserver];
#if USE_SDK_EVENT_DISCONNECTED
    if ([[SDK instance] isConnected]) {
        return;
    }
#else
    if ([Reachability didConnectedToCameraHotspot] && [[SDK instance] isConnected]) {
        return;
    }
#endif

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_current_ssid) {
            if (!_connectingAlertView) {
                self.connectingAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                                      message:NSLocalizedString(@"Connecting", nil)
                                                                     delegate:nil
                                                            cancelButtonTitle:nil
                                                            otherButtonTitles:nil, nil];
            }
            
            [_connectingAlertView show];
        } else {
            NSString *connectingMessage = [NSString stringWithFormat:@"%@ %@ ...", NSLocalizedString(@"Reconnect to",nil),_current_ssid];
            [self showGCDNoteWithMessage:connectingMessage withAnimated:YES withAcvity:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kCameraReconnectNotification"
                                                                object:self.notificationView];
        }
        
        if (![self.timeOutTimer isValid]) {
            self.timeOutTimer = [NSTimer scheduledTimerWithTimeInterval:45.0 target:self selector:@selector(timeOutHandle) userInfo:nil repeats:NO];
        }
        
        _isReconnecting = YES;
        dispatch_async([[SDK instance] sdkQueue], ^{
            /*[[NSNotificationCenter defaultCenter] postNotificationName:@"kCameraNetworkDisconnectedNotification"
                                                                object:nil];
            [NSThread sleepForTimeInterval:1.0];*/
            
            int totalCheckCount = 2; // 60times : 30s
            while (totalCheckCount-- > 0 && !_isTimeout) {
                @autoreleasepool {
                    if ([Reachability didConnectedToCameraHotspot]) {
                        if ([[SDK instance] initializeSDK]) {
                            [WifiCamControl scan];
                            
                            WifiCamManager *app = [WifiCamManager instance];
                            WifiCam *wifiCam = [app.wifiCams objectAtIndex:0];
                            wifiCam.camera = [WifiCamControl createOneCamera];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                _isReconnecting = NO;
                                
                                if (!_current_ssid) {
                                    [_connectingAlertView dismissWithClickedButtonIndex:0 animated:NO];
                                } else {
                                    [self hideGCDiscreetNoteView:YES];
                                }
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"kCameraNetworkConnectedNotification"
                                                                                    object:nil];
                            });
                            break;
                        }
                    }
                    
                    AppLog(@"[%d]NotReachable -- Sleep 500ms", totalCheckCount);
                    [NSThread sleepForTimeInterval:0.5];
                }
            }
            
            if (totalCheckCount <= 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!_current_ssid) {
                        [_connectingAlertView dismissWithClickedButtonIndex:0 animated:NO];
                    } else {
                        [self hideGCDiscreetNoteView:YES];
                    }
//                    [_reconnectionAlertView show];
                    NSString *ssid = [Tool sysSSID];
                    if (ssid == nil) {
                        [_connectionErrorAlertView show];
                    } else {
                        if (_current_ssid && ![ssid isEqualToString:_current_ssid]) {
                            [_connectionErrorAlertView1 show];
                        } else {
                            [_reconnectionAlertView show];
                        }
                    }
                });
            }
            self.isTimeout = NO;
            [self.timeOutTimer invalidate];
        });
    });
}

- (void)timeOutHandle
{
    if (![[SDK instance] isConnected]) {
        TRACE();
        self.isTimeout = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            /*if (!_current_ssid) {
             [_connectingAlertView dismissWithClickedButtonIndex:0 animated:NO];
             } else {
             [self hideGCDiscreetNoteView:YES];
             }
             NSString *ssid = [Tool sysSSID];
             if (ssid == nil) {
             [_connectionErrorAlertView show];
             } else {
             if (_current_ssid && ![ssid isEqualToString:_current_ssid]) {
             [_connectionErrorAlertView1 show];
             } else {
             [_reconnectionAlertView show];
             }
             }*/
            UIAlertView *timeOutAlert = [[UIAlertView alloc] initWithTitle:nil
                                                        message           :NSLocalizedString(@"ActionTimeOut.", nil)
                                                        delegate          :self
                                                        cancelButtonTitle :NSLocalizedString(@"Exit", nil)
                                                        otherButtonTitles :nil, nil];
            timeOutAlert.tag = APP_TIMEOUT_ALERT_TAG;
            [timeOutAlert show];
        });
    }
}

//- (NSString *)checkSSID
//{
//    //    NSArray * networkInterfaces = [NEHotspotHelper supportedNetworkInterfaces];
//    //    NSLog(@"Networks: %@",networkInterfaces);
//
//    NSString *ssid = nil;
//    //NSString *bssid = @"";
//    CFArrayRef myArray = CNCopySupportedInterfaces();
//    if (myArray) {
//        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo((CFStringRef)CFArrayGetValueAtIndex(myArray, 0));
//        /*
//         Core Foundation functions have names that indicate when you own a returned object:
//
//         Object-creation functions that have “Create” embedded in the name;
//         Object-duplication functions that have “Copy” embedded in the name.
//         If you own an object, it is your responsibility to relinquish ownership (using CFRelease) when you have finished with it.
//
//         */
//        CFRelease(myArray);
//        if (myDict) {
//            NSDictionary *dict = (NSDictionary *)CFBridgingRelease(myDict);
//            ssid = [dict valueForKey:@"SSID"];
//            //bssid = [dict valueForKey:@"BSSID"];
//        }
//    }
//    NSLog(@"ssid : %@", ssid);
//    //NSLog(@"bssid: %@", bssid);
//
//    return ssid;
//}

-(GCDiscreetNotificationView *)notificationView {
    if (!_notificationView) {
        _notificationView = [[GCDiscreetNotificationView alloc] initWithText:nil
                                                                showActivity:NO
                                                          inPresentationMode:GCDiscreetNotificationViewPresentationModeTop
                                                                      inView:((ViewController *)(self.delegate)).view];
    }
    return _notificationView;
}

- (void)showGCDNoteWithMessage:(NSString *)message
                  withAnimated:(BOOL)animated
                    withAcvity:(BOOL)activity{
    if ([self.delegate respondsToSelector:@selector(setButtonEnable:)]) {
        [self.delegate setButtonEnable:NO];
    }
    [self.notificationView setView:((ViewController *)(self.delegate)).view];
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
    if ([self.delegate respondsToSelector:@selector(setButtonEnable:)]) {
        [self.delegate setButtonEnable:YES];
    }
    [self.notificationView hide:animated];
    
}

#pragma mark - CLLocationManager
- (void)requestLocationPermission {
    if ([CLLocationManager locationServicesEnabled]){

        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        
        if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [_locationManager requestWhenInUseAuthorization];
        }
    }
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    switch (status) {
        case  kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            [self showLocationAuthorizationAlertView];
            break;
            
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            break;
            
        default:
            break;
    }
}

- (void)showLocationAuthorizationAlertView {
    if (self.locationAuthorizationAlertView != nil) {
        return;
    }
    
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"Warning" message:@"You need to open the mobile phone location permission to get the information that the mobile phone is connected to Wi-Fi." preferredStyle:UIAlertControllerStyleAlert];
    
    [alertC addAction:[UIAlertAction actionWithTitle:@"go to-settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setupLocationAuthorization];
    }]];
    
    [self.window.rootViewController presentViewController:alertC animated:YES completion:nil];
    
    self.locationAuthorizationAlertView = alertC;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    AppLog(@"Location happened error: %@", error.description);
}

- (void)setupLocationAuthorization {
    NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        if ([[UIDevice currentDevice].systemVersion doubleValue] >= 10.0) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}

@end
