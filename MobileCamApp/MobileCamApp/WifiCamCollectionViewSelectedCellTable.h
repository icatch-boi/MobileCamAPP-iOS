//
//  WifiCamCollectionViewSelectedCellTable.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-7-1.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WifiCamCollectionViewSelectedCellTable : NSObject

@property(nonatomic) NSMutableArray *selectedCells;
@property(nonatomic) NSUInteger count;

-(id)initWithParameters:(NSMutableArray *)nSelectedCells
               andCount:(NSUInteger)nCount;

@end
