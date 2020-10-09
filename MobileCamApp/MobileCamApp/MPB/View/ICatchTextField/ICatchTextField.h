//
//  ICatchTextField.h
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/8.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ICatchTapActionBlock)(void);
@interface ICatchTextField : UITextField

@property (nonatomic, copy) ICatchTapActionBlock tapActionBlock;

@end

NS_ASSUME_NONNULL_END
