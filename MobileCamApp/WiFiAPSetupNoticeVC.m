//
//  WiFiAPSetupNoticeVC.m
//  WifiCamMobileApp
//
//  Created by Guo on 11/5/15.
//  Copyright © 2015 iCatchTech. All rights reserved.
//

#import "WiFiAPSetupNoticeVC.h"

@interface WiFiAPSetupNoticeVC ()
@property (weak, nonatomic) IBOutlet UILabel *noticeTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *noticeContentLabel;
@property (strong, nonatomic) IBOutlet UIButton *okButton;
@end

@implementation WiFiAPSetupNoticeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _noticeTitleLabel.text = NSLocalizedString(@"Connect to your camera", nil);
    _noticeContentLabel.text = [[NSString alloc] initWithFormat:@"1. Press Home key on the iPhone.\n2. Go to Setting > Wi-Fi.\n3. Select \"%@\" and enter the password \"%@\".\n4. Return to the app.", _ssid, _pwd];
    _noticeContentLabel.numberOfLines = 6;
    self.okButton.hidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)goBackToHome:(id)sender {
    [self.view.window.rootViewController dismissViewControllerAnimated:YES completion: nil];
}

@end
