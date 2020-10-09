//
//  CollectionViewController.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-5.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWPhotoBrowser.h"
#import "MWPhotoBrowserPrivate.h"
#import "VideoPlaybackViewController.h"
#import "ActivityWrapper.h"

@interface MpbViewController : UICollectionViewController <UIAlertViewDelegate,
  UIPopoverControllerDelegate, MWPhotoBrowserDelegate, UIActionSheetDelegate,
  UICollectionViewDelegateFlowLayout, VideoPlaybackControllerDelegate, ActivityWrapperDelegate>

@property(nonatomic, getter = isEnableHeader) BOOL enableHeader;
@property(nonatomic, getter = isEnableHeader) BOOL enableFooter;
@property int observerNo;

@end
