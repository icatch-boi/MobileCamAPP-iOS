//
//  MpbPopoverViewController.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-24.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import "MpbPopoverViewController.h"

@interface MpbPopoverViewController ()
@property(weak, nonatomic) IBOutlet UILabel* message;
@end

@implementation MpbPopoverViewController

@synthesize msg;
@synthesize msgColor;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  //self.contentSizeForViewInPopover = CGSizeMake(250.0, 150.0);
  self.message.text = msg;
  self.message.textColor = msgColor;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
