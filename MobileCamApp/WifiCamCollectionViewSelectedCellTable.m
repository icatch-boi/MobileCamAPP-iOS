//
//  WifiCamCollectionViewSelectedCellTable.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-7-1.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamCollectionViewSelectedCellTable.h"

@implementation WifiCamCollectionViewSelectedCellTable


-(id)initWithParameters:(NSMutableArray *)nSelectedCells
               andCount:(NSUInteger)nCount
{
  WifiCamCollectionViewSelectedCellTable *table = [[WifiCamCollectionViewSelectedCellTable alloc] init];
  table.selectedCells = nSelectedCells;
  table.count = nCount;
  return table;
}
@end
