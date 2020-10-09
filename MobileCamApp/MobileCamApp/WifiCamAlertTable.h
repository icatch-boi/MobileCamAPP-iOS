//
//  TableAlertArray.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-17.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WifiCamAlertTable : NSObject

@property (nonatomic) NSMutableArray *array;
@property (nonatomic) NSUInteger lastIndex;


-(id)initWithParameters:(NSMutableArray *)nArray
           andLastIndex:(NSUInteger)nLastIndex;

@end
