//
//  AppLog.m
//  WifiCamMobileApp
//
//  Created by ZJ on 2017/1/3.
//  Copyright © 2017年 iCatchTech. All rights reserved.
//

#import "AppLog.h"

@implementation AppLog

+ (instancetype)instance
{
    static AppLog *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AppLog alloc] init];
    });
    
    return instance;
}

- (void)prefix:(NSString *)prefix tag:(AppLogTag)tag info:(NSString*)info log:(NSString *)format, ...
{
    if (format) {
        va_list vp;
        va_start(vp, format);
        
        NSString *message = [NSString stringWithFormat:format , va_arg(vp, id)];
        if (tag == AppLogTagAPP) {
            NSLog((@"app %@ : [ %@ ---> %@ ]"), prefix, info, message);
        } else {
            NSLog((@"sdk %@ : [ %@ ---> %@ ]"), prefix, info, message);
        }
        
        va_end(vp);
    } else {
        NSLog((@"app %@ : [ %@ ]"), prefix, info);
    }
}

- (void)printAppLogWithLevel:(AppLogLevel)level tag:(AppLogTag)tag info:(NSString*)info log:(NSString *)format, ...
{
    va_list vp;
    va_start(vp, format);
    
    switch (level) {
        case AppLogLevelInfo:
            [self prefix:@"info" tag:tag info:info log:format, va_arg(vp, id)];
            break;
            
        case AppLogLevelError:
            [self prefix:@"error" tag:tag info:info log:format, va_arg(vp, id)];
            break;
            
        case AppLogLevelWarn:
            [self prefix:@"Warn" tag:tag info:info log:format, va_arg(vp, id)];
            break;
            
        case AppLogLevelDebug:
#if DEBUG
            [self prefix:@"debug" tag:tag info:info log:format, va_arg(vp, id)];
#endif
            break;
            
        default:
            break;
    }
    
    va_end(vp);
}

+ (void)log:(NSString *)format, ...
{
    va_list vp;
    va_start(vp, format);
    
    [[AppLog instance] printAppLogWithLevel:AppLogLevelInfo tag:AppLogTagAPP info:nil log:format, va_arg(vp, id)];
    
    va_end(vp);
}

+ (void)level:(AppLogLevel)level log:(NSString *)format, ...
{
    va_list vp;
    va_start(vp, format);
    
    [[AppLog instance] printAppLogWithLevel:level tag:AppLogTagAPP info:nil log:format, va_arg(vp, id)];
    
    va_end(vp);
}

+ (void)level:(AppLogLevel)level logs:(NSString *)message
{
    [[AppLog instance] printAppLogWithLevel:level tag:AppLogTagAPP info:nil log:message];
}

+ (void)level:(AppLogLevel)level tag:(AppLogTag)tag info:(NSString *)info log:(NSString *)format, ...
{
    va_list vp;
    va_start(vp, format);
    
    [[AppLog instance] printAppLogWithLevel:level tag:tag info:info log:format, va_arg(vp, id)];
    
    va_end(vp);
}

@end
