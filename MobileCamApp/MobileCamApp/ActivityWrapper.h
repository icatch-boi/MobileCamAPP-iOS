//
//  ActivityWrapper.h
//  WifiCamMobileApp
//
//  Created by Sunmedia on 14-10-16.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

/*
 
 UIActivityTypePostToFacebook,
 UIActivityTypePostToTwitter,
 UIActivityTypePostToWeibo,
 UIActivityTypeMessage,
 UIActivityTypeMail,
 UIActivityTypePrint,
 UIActivityTypeCopyToPasteboard,
 UIActivityTypeAssignToContact,
 UIActivityTypeSaveToCameraRoll,
 UIActivityTypeAddToReadingList,
 UIActivityTypePostToFlickr,
 UIActivityTypePostToVimeo,
 UIActivityTypePostToTencentWeibo,
 
 */

#import <Foundation/Foundation.h>
#import <Social/Social.h>

@protocol ActivityWrapperDelegate <NSObject>
@optional
-(void)showSLComposeViewController:(NSString *)serviceType;
-(void)showDownloadConfirm;
- (void)showShareConfirm;

@end

@interface ActivityWrapper : NSObject
@property(nonatomic, weak) id<ActivityWrapperDelegate> delegate;
@end
