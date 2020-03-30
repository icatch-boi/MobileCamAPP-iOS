//
//  ICatchFileInfo.m
//  MobileCamApp
//
//  Created by zj on 2020/2/11.
//  Copyright © 2020 iCatchTech. All rights reserved.
//

#import "ICatchFileInfo.h"

@implementation ICatchFileInfo

- (instancetype)initWithFile:(shared_ptr<ICatchFile>)file
{
    self = [super init];
    if (self) {
        self.file = file;
    }
    return self;
}

+ (instancetype)fileInfoWithFile:(shared_ptr<ICatchFile>)file {
    return [[self alloc] initWithFile:file];
}

@end
