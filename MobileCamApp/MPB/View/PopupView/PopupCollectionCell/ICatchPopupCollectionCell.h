//
//  ICatchPopupCollectionCell.h
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/2.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ICatchPopupCollectionCell : UICollectionViewCell

@property (nonatomic, copy) NSString *title;
@property (nonatomic, getter=isEnabled) BOOL enabled;

@end

NS_ASSUME_NONNULL_END
