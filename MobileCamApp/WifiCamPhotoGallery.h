//
//  WifiCamPhotoGallery.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-16.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WifiCamFileTable.h"

@interface WifiCamPhotoGallery : NSObject

@property (nonatomic) WifiCamFileTable *imageTable;
@property (nonatomic) WifiCamFileTable *videoTable;
@property (nonatomic) WifiCamFileTable *allFileTable;
@property (nonatomic, assign) BOOL needReload;
-(id)initWithFileTables:(WifiCamFileTable *)nImageTable
          andVideoTable:(WifiCamFileTable *)nVideoTable
        andAllFileTable:(WifiCamFileTable *)nAllFileTable;

@end
