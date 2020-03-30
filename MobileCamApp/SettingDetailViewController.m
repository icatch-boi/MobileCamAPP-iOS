//
//  SettingDetailViewController.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-19.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import "SettingDetailViewController.h"

@interface SettingDetailViewController ()
@property(nonatomic) WifiCam *wifiCam;
@property(nonatomic) WifiCamCamera *camera;
@property(nonatomic) WifiCamControlCenter *ctrl;
@property(nonatomic) MBProgressHUD *progressHUD;
@end


@implementation SettingDetailViewController

@synthesize subMenuTable;
@synthesize curSettingDetailType;
@synthesize curSettingDetailItem;

#pragma mark - ViewController lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    NSString *title = nil;
    
    switch (curSettingDetailType) {
        case SettingDetailTypeWhiteBalance:
            title = NSLocalizedString(@"SETTING_AWB", @"");
            break;
            
        case SettingDetailTypePowerFrequency:
            title = NSLocalizedString(@"SETTING_POWER_SUPPLY", @"");
            break;
            
        case SettingDetailTypeBurstNumber:
            title = NSLocalizedString(@"SETTING_BURST", @"");
            break;
            
        case SettingDetailTypeAbout:
            title = NSLocalizedString(@"SETTING_ABOUT", @"");
            break;
            
        case SettingDetailTypeDateStamp:
            title = NSLocalizedString(@"SETTING_DATESTAMP", @"");
            break;
            
        case SettingDetailTypeTimelapseInterval:
            title = NSLocalizedString(@"SETTING_CAP_TIMESCAPE_INTERVAL", @"");
            break;
            
        case SetttngDetailTypeTimelapseDuration:
            title = NSLocalizedString(@"SETTING_CAP_TIMESCAPE_LIMIT", @"");
            break;
            
        case SettingDetailTypeUpsideDown:
            title = NSLocalizedString(@"SETTING_UPSIDE_DOWN", @"");
            break;
            
        case SettingDetailTypeSlowMotion:
            title = NSLocalizedString(@"SETTING_SLOW_MOTION", nil);
            break;
            
        case SettingDetailTypeImageSize:
            title = NSLocalizedString(@"SetPhotoResolution", @"");
            break;
            
        case SettingDetailTypeVideoSize:
            title = NSLocalizedString(@"ALERT_TITLE_SET_VIDEO_RESOLUTION", @"");
            break;
            
        case SettingDetailTypeCaptureDelay:
            title = NSLocalizedString(@"ALERT_TITLE_SET_SELF_TIMER", @"");
            break;
            
        case SettingDetailTypeLiveSize:
            title = NSLocalizedString(@"LIVE_RESOLUTION", @"");
            break;
            
        default:
            break;
    }
    [self.navigationItem setTitle:title];
    
    WifiCamManager *app = [WifiCamManager instance];
    self.wifiCam = [app.wifiCams objectAtIndex:0];
    self.camera = _wifiCam.camera;
    self.ctrl = _wifiCam.controler;
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recoverFromDisconnection)
                                             name    :@"kCameraNetworkConnectedNotification"
                                             object  :nil];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kCameraNetworkConnectedNotification" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)recoverFromDisconnection
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Action Progress

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

#pragma mark - Gesture
- (IBAction)swipeToExit:(UISwipeGestureRecognizer *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}


#pragma mark - Table view data source

- (NSInteger) tableView             :(UITableView *)tableView
              numberOfRowsInSection :(NSInteger)section
{
    return [subMenuTable count];
}

- (UITableViewCell *) tableView             :(UITableView *)tableView
                      cellForRowAtIndexPath :(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"settingDetailCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    
    cell.textLabel.text = [subMenuTable objectAtIndex:indexPath.row];
    // Workaround
    /*
    if (_camera.timelapseType == WifiCamTimelapseTypeStill
        && [cell.textLabel.text isEqualToString:@"1s"]) {
        cell.userInteractionEnabled = NO;
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
     */
    ///
    
    if (curSettingDetailType == SettingDetailTypeAbout) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}

#pragma mark - Table view data delegate
- (void)tableView               :(UITableView *)tableView
        didSelectRowAtIndexPath :(NSIndexPath *)indexPath
{
    uint value = 0;
    BOOL errorHappen = NO;
    
    switch (curSettingDetailType) {
        case SettingDetailTypeWhiteBalance:
            value = [_ctrl.propCtrl parseWhiteBalanceInArray:indexPath.row];
            if ([_ctrl.propCtrl changeWhiteBalance:value] == WCRetSuccess) {
                _camera.curWhiteBalance = value;
            } else {
                errorHappen = YES;
            }
            break;
            
        case SettingDetailTypePowerFrequency:
            value = [_ctrl.propCtrl parsePowerFrequencyInArray:indexPath.row];
            if ([_ctrl.propCtrl changeLightFrequency:value] == WCRetSuccess) {
                _camera.curLightFrequency = value;
            } else {
                errorHappen = YES;
            }
            break;
            
        case SettingDetailTypeBurstNumber:
            value = [_ctrl.propCtrl parseBurstNumberInArray:indexPath.row];
            /*-
             if (value != BURST_NUMBER_OFF) {
             _camera.curCaptureDelay = CAP_DELAY_NO;
             [_ctrl.propCtrl changeDelayedCaptureTime:CAP_DELAY_NO];
             }
             */
            
            AppLog(@"_camera.curBurstNumber: %d", _camera.curBurstNumber);
            if ([_ctrl.propCtrl changeBurstNumber:value] == WCRetSuccess) {
                _camera.curBurstNumber = value;
                //        _camera.curCaptureDelay = CAP_DELAY_NO;
                
                // Re-Get
                //_camera.curCaptureDelay = [_ctrl.propCtrl retrieveDelayedCaptureTime];
                //_camera.curTimelapseInterval = [_ctrl.propCtrl retrieveCurrentTimelapseInterval];
                AppLog(@"_camera.curBurstNumber: %d", _camera.curBurstNumber);
            } else {
                errorHappen = YES;
            }
            
            break;
            
        case SettingDetailTypeDateStamp:
            value = [_ctrl.propCtrl parseDateStampInArray:indexPath.row];
            if ([_ctrl.propCtrl changeDateStamp:value] == WCRetSuccess) {
                AppLog(@"set date stamp to value: %d", value);
                _camera.curDateStamp = value;
            } else {
                errorHappen = YES;
            }
            break;
            
        case SettingDetailTypeTimelapseInterval:
            value = [_ctrl.propCtrl parseTimelapseIntervalInArray:indexPath.row];
            AppLog(@"set timelapse interval to : %d", value);
            if ([_ctrl.propCtrl changeTimelapseInterval:value] == WCRetSuccess) {
                _camera.curTimelapseInterval = value;
                
                // Re-Get
                //_camera.curCaptureDelay = [_ctrl.propCtrl retrieveDelayedCaptureTime];
                //_camera.curBurstNumber = [_ctrl.propCtrl retrieveBurstNumber];
            } else {
                errorHappen = YES;
            }
            break;
            
        case SetttngDetailTypeTimelapseDuration:
            value = [_ctrl.propCtrl parseTimelapseDurationInArray:indexPath.row];
            AppLog(@"set timelapse duration to : %d", value);
            if ([_ctrl.propCtrl changeTimelapseDuration:value] == WCRetSuccess) {
                _camera.curTimelapseDuration = value;
            } else {
                errorHappen = YES;
            }
            break;
            
        case SettingDetailTypeTimelapseType: {
            ICatchCamPreviewMode mode = ICH_CAM_TIMELAPSE_STILL_PREVIEW_MODE;
            if (indexPath.row == 0) {
                value = WifiCamTimelapseTypeStill;
                mode = ICH_CAM_TIMELAPSE_STILL_PREVIEW_MODE;
            } else if (indexPath.row == 1) {
                value = WifiCamTimelapseTypeVideo;
                mode = ICH_CAM_TIMELAPSE_VIDEO_PREVIEW_MODE;
            }
            
            AppLog(@"set timelapse type to: %d, mode: %d", value, mode);
            if ([_ctrl.propCtrl changeTimelapseType:mode] == WCRetSuccess) {
                _camera.timelapseType = value;
            } else {
                errorHappen = YES;
            }
        }
            break;
            
        case SettingDetailTypeUpsideDown:
            if ([_ctrl.propCtrl changeUpsideDown:(uint)indexPath.row] != WCRetSuccess) {
                errorHappen = YES;
            } else {
                _camera.curInvertMode = (uint)indexPath.row;
            }
            break;
            
        case SettingDetailTypeSlowMotion:
            if ([_ctrl.propCtrl changeSlowMotion:(uint)indexPath.row] != WCRetSuccess) {
                errorHappen = YES;
            } else {
                _camera.curSlowMotion = (uint)indexPath.row;
            }
            break;
            
        case SettingDetailTypeImageSize:
        {
            string value = [_ctrl.propCtrl parseImageSizeInArray:indexPath.row];
            if ([_ctrl.propCtrl changeImageSize:value] != WCRetSuccess) {
                errorHappen = YES;
            } else {
                _camera.curImageSize = value;
            }
            break;
        }
            
        case SettingDetailTypeVideoSize:
        {
            string value = [_ctrl.propCtrl parseVideoSizeInArray:indexPath.row];
            if ([_ctrl.propCtrl changeVideoSize:value] != WCRetSuccess) {
                errorHappen = YES;
            } else {
                _camera.curVideoSize = value;
            }
            break;
        }
            
        case SettingDetailTypeCaptureDelay: {
            unsigned int curCaptureDelay = [_ctrl.propCtrl parseDelayCaptureInArray:indexPath.row];
            if ([_ctrl.propCtrl changeDelayedCaptureTime:curCaptureDelay] != WCRetSuccess) {
                errorHappen = YES;
            } else {
                _camera.curCaptureDelay = curCaptureDelay;
            }
        }
            break;
    
        case SettingDetailTypeLiveSize:
        {
            NSString *liveSize = [subMenuTable objectAtIndex:indexPath.row];
            AppLog(@"%@", liveSize);
            NSArray *sizeAr = [liveSize componentsSeparatedByString:@" "];
            if (!liveSize) {
                errorHappen = YES;
            } else {
                [[NSUserDefaults standardUserDefaults] setObject:sizeAr[1] forKey:@"LiveSize"];
            }
            break;
        }
            
        case SettingDetailTypeAbout:
        default:
            break;
    }
    
    [_ctrl.propCtrl updateAllProperty:_camera];
    if (errorHappen) {
        [self showProgressHUDNotice:NSLocalizedString(@"STREAM_SET_ERROR", @"") showTime:2.0];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)tableView         :(UITableView *)tableView
        willDisplayCell   :(UITableViewCell *)cell
        forRowAtIndexPath :(NSIndexPath *)indexPath
{
    cell.accessoryType = UITableViewCellAccessoryNone;
    if ((curSettingDetailItem == indexPath.row) && (curSettingDetailType != SettingDetailTypeAbout)) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}
#pragma mark -

#pragma mark AppDelegateProtocol
- (void)sdcardRemoveCallback
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showProgressHUDNotice:NSLocalizedString(@"CARD_REMOVED", nil) showTime:2.0];
    });
}

- (void)sdcardInCallback {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self showProgressHUDNotice:NSLocalizedString(@"CARD_INSERTED", nil) showTime:2.0];
    });
}

@end
