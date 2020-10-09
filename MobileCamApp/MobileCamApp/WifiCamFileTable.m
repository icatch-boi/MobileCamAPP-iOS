//
//  WifiCamFileTable.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-7-3.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamFileTable.h"


@implementation WifiCamFileTable

@synthesize fileList;
@synthesize fileStorage;

-(id)initWithParameters:(vector<shared_ptr<ICatchFile>>)nFileList
         andFileStorage:(unsigned long long)nFileStorage
{
  WifiCamFileTable *table = [[WifiCamFileTable alloc] init];
  table.fileList = nFileList;
  table.fileStorage = nFileStorage;
  return table;
}

@end
