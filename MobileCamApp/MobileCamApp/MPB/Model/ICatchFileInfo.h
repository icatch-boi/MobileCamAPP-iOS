//
//  ICatchFileInfo.h
//  MobileCamApp
//
//  Created by zj on 2020/2/11.
//  Copyright © 2020 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ICatchFileInfo : NSObject

@property (nonatomic) shared_ptr<ICatchFile> file;
@property (nonatomic, assign, getter=isSelected) BOOL selected;

- (instancetype)initWithFile:(shared_ptr<ICatchFile>)file;
+ (instancetype)fileInfoWithFile:(shared_ptr<ICatchFile>)file;

@end

NS_ASSUME_NONNULL_END
