//
//  Cell.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 13-12-5.
//  Copyright (c) 2013年 iCatchTech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MpbCollectionViewCell : UICollectionViewCell
@property(strong, nonatomic) IBOutlet UIImageView *imageView;
-(void)setVideoStaticIconHidden:(BOOL)value;

-(void)setSelectedConfirmIconHidden:(BOOL)value;
//-(void)setSelectedConfirmIconRect:(CGRect)rect;
@end
