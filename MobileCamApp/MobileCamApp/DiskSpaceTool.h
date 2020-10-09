//
//  DiskSpaceTool.h
//  WifiCamMobileApp
//
//  Created by zj.feng on 16/7/12.
//  Copyright © 2016年 Tobias Tiemerding. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <sys/param.h>
#include <sys/mount.h>

@interface DiskSpaceTool : NSObject

+ (NSString *) freeDiskSpaceInBytes;//设备剩余空间
+ (NSString *) totalDiskSpaceInBytes;//设备总空间
+ (NSString *) folderSizeAtPath:(NSString*) folderPath;//某个文件夹占用空间的大小
+ (long long) fileSizeAtPath:(NSString*) filePath;//单个文件的大小
+ (long long) num_folderSizeAtPath:(NSString*) folderPath;
+ (NSString *)humanReadableStringFromBytes:(unsigned long long)byteCount;//计算文件大小

@end