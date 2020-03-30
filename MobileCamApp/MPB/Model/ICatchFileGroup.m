//
//  ICatchFileGroup.m
//  MobileCamApp
//
//  Created by zj on 2020/2/14.
//  Copyright © 2020 iCatchTech. All rights reserved.
//

#import "ICatchFileGroup.h"

@interface ICatchFileGroup ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSArray<ICatchFileInfo *> *fileInfos;

@end

@implementation ICatchFileGroup

+ (instancetype)fileGroupWithTitle:(NSString *)title fileInfos:(nonnull NSArray<ICatchFileInfo *> *)fileInfos {
    return [[self alloc] initWithTitle:title fileInfos:fileInfos];
}

- (instancetype)initWithTitle:(NSString *)title fileInfos:(nonnull NSArray<ICatchFileInfo *> *)fileInfos
{
    self = [super init];
    if (self) {
        self.title = title;
        self.fileInfos = [NSArray arrayWithArray:fileInfos];
        self.visible = true;
    }
    return self;
}

- (void)updateFileInfos:(NSArray<ICatchFileInfo *> *)fileInfos {
    if (fileInfos.count != 0) {
        self.fileInfos = [NSArray arrayWithArray:fileInfos];
    }
}

@end
