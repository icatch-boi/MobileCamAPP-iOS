//
//  ICatchDateSelectReusableView.h
//  MobileCamApp-MPB
//
//  Created by ZJ on 2020/1/3.
//  Copyright © 2020 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ICatchTextField.h"

NS_ASSUME_NONNULL_BEGIN

@interface ICatchDateSelectReusableView : UICollectionReusableView

@property (weak, nonatomic) IBOutlet ICatchTextField *startTextField;
@property (weak, nonatomic) IBOutlet ICatchTextField *endTextField;

@end

NS_ASSUME_NONNULL_END
