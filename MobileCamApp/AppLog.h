//
//  AppLog.h
//  WifiCamMobileApp
//
//  Created by ZJ on 2017/1/3.
//  Copyright © 2017年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AppLogLevel) {
    AppLogLevelError   = 0,
    AppLogLevelWarn    = 1,
    AppLogLevelInfo    = 2,
    AppLogLevelDebug   = 3,
};

typedef NS_ENUM(NSUInteger, AppLogTag) {
    AppLogTagSDK   = 0,
    AppLogTagAPP   = 1,
};

#define DEBUG 1
#define AppLogENABLE 0

#pragma mark - AppLogMacro

#if (AppLogENABLE == 1)

#define APP_LOG_MACRO(_level, Tag, fmt, ...) [AppLog level:_level tag:Tag info:[NSString stringWithFormat:@"%s(%d)", __func__, __LINE__] log:fmt, ##__VA_ARGS__]

#define AppLogError(tag, fmt, ...)   APP_LOG_MACRO(AppLogLevelError, tag, fmt, ##__VA_ARGS__)
#define AppLogWarn(tag, fmt, ...)    APP_LOG_MACRO(AppLogLevelWarn,  tag, fmt, ##__VA_ARGS__)
#define AppLogInfo(tag, fmt, ...)    APP_LOG_MACRO(AppLogLevelInfo, tag, fmt, ##__VA_ARGS__)
#define AppLogDebug(tag, fmt, ...)   APP_LOG_MACRO(AppLogLevelDebug, tag, fmt, ##__VA_ARGS__)
#define AppLogTRACE() AppLogInfo(AppLogTagAPP, nil)

#else

#define APP_LOG_MACRO(_level, Tag, fmt, ...) do { \
    NSString *info = [NSString stringWithFormat:@"%s(%d)", __func__, __LINE__]; \
    if (Tag == AppLogTagAPP) { \
    NSLog((@"app %@: [ %@ ---> " fmt @" ]"), _level, info, ##__VA_ARGS__); \
    } else { \
        NSLog((@"sdk %@: [ %@ ---> " fmt @" ]"), _level, info, ##__VA_ARGS__); \
    } \
} while(0)

#define AppLogError(tag, fmt, ...)   APP_LOG_MACRO(@"error", tag, fmt, ##__VA_ARGS__)
#define AppLogWarn(tag, fmt, ...)    APP_LOG_MACRO(@"warn ",  tag, fmt, ##__VA_ARGS__)
#define AppLogInfo(tag, fmt, ...)    APP_LOG_MACRO(@"info ", tag, fmt, ##__VA_ARGS__)
#define AppLogTRACE() AppLogInfo(AppLogTagAPP, @"app run trace.")

#if DEBUG
#define AppLogDebug(tag, fmt, ...)   APP_LOG_MACRO(@"debug", tag, fmt, ##__VA_ARGS__)
#else
#define AppLogDebug(tag, fmt, ...)
#endif

#endif


#pragma mark - Interface
@interface AppLog : NSObject

/**
 *    @brief 打印AppLogLevelInfo日志
 *
 *    @param format   日志内容
 */
+ (void)log:(NSString *)format, ...;

/**
 *    @brief  打印日志
 *
 *    @param level 日志级别
 *    @param message   日志内容
 */
+ (void)level:(AppLogLevel) level logs:(NSString *)message;

/**
 *    @brief  打印日志
 *
 *    @param level 日志级别
 *    @param format   日志内容
 */
+ (void)level:(AppLogLevel) level log:(NSString *)format, ...;

/**
 *    @brief  打印日志
 *
 *    @param level  日志级别
 *    @param tag    日志模块分类
 *    @param format   日志内容
 */
+ (void)level:(AppLogLevel) level tag:(AppLogTag) tag info:(NSString *)info log:(NSString *)format, ...;

@end
