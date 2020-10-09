//
//  WifiCamFileTable.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-7-3.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WifiCamFileTable : NSObject

@property (nonatomic) vector<shared_ptr<ICatchFile>> fileList;
@property (nonatomic) unsigned long long fileStorage;

-(id)initWithParameters:(vector<shared_ptr<ICatchFile>>)nFileList
         andFileStorage:(unsigned long long)nFileStorage;

@end
