//
//  WifiCamManager.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-18.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamManager.h"


@implementation WifiCamManager

@synthesize wifiCams;

+(id)instance
{
  static WifiCamManager *app = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    app = [[self alloc] initSingleton];
  });
  return app;
}

-(id)init
{
  return [self initSingleton];
}

- (id)initSingleton
{
  if (self = [super init]) {
    wifiCams = [[NSMutableArray alloc] init];
  }
  return self;
}


@end
