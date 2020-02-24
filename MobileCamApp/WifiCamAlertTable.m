//
//  TableAlertArray.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-17.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import "WifiCamAlertTable.h"

@implementation WifiCamAlertTable

@synthesize array;
@synthesize lastIndex;

-(id)initWithParameters:(NSMutableArray *)nArray
           andLastIndex:(NSUInteger)nLastIndex
{
  WifiCamAlertTable *table = [[WifiCamAlertTable alloc] init];
  table.array = nArray;
  table.lastIndex = nLastIndex;
  return table;
}

@end
