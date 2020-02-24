//
//  WifiCamPhotoGallery.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-16.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "WifiCamPhotoGallery.h"


@implementation WifiCamPhotoGallery

@synthesize imageTable;
@synthesize videoTable;
@synthesize allFileTable;

-(id)initWithFileTables:(WifiCamFileTable *)nImageTable
          andVideoTable:(WifiCamFileTable *)nVideoTable
        andAllFileTable:(WifiCamFileTable *)nAllFileTable {
    
  WifiCamPhotoGallery *gallery = [[WifiCamPhotoGallery alloc] init];
  gallery.imageTable = nImageTable;
  gallery.videoTable = nVideoTable;
  gallery.allFileTable = nAllFileTable;
  return gallery;
}


@end
