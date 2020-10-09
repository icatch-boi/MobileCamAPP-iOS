//
//  ExceptionHandler.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-4-2.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "ExceptionHandler.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>


NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";
volatile int32_t UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;
const NSInteger UncaughtExceptionHandlerSkipAddressCount = 0;
const NSInteger UncaughtExceptionHandlerReportAddressCount = 20;
int signum;

@implementation ExceptionHandler

+ (NSArray *)backtrace
{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (i = UncaughtExceptionHandlerSkipAddressCount;
         i < UncaughtExceptionHandlerSkipAddressCount +
         UncaughtExceptionHandlerReportAddressCount;
         ++i)
    {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    return backtrace;
}

- (void)alertView:(UIAlertView *)anAlertView
clickedButtonAtIndex:(NSInteger)anIndex
{
    if (anIndex == 0)
    {
        dismissed = YES;
    }
}

- (void)handleException:(NSException *)exception
{
    NSString *exceptionMessage = [NSString stringWithFormat:NSLocalizedString(@"[CRASH].\n" @"Reason:%@\n UserInfo:\n%@", nil),
                                  [exception reason],
                                  [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey]];
    AppLog(@"Exception: %@", exceptionMessage);
    
    WifiCamManager *app = [WifiCamManager instance];
    WifiCam *wifiCam = [app.wifiCams objectAtIndex:0];
    WifiCamCamera *camera = wifiCam.camera;
    camera.exceptionOccured = YES;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Oops...", nil)
                                                    message:[NSString stringWithFormat:NSLocalizedString(@"Sorry, something wrong[%d] with the app. Please send log to us, thank you so much.", nil), signum]
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"Quit", nil)
                                          otherButtonTitles:nil/*NSLocalizedString(@"Continue", nil)*/, nil];
    [alert show];
    
    
    // Still run
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
    while (!dismissed)
    {
        for (NSString *mode in (__bridge NSArray *)allModes)
        {
            CFRunLoopRunInMode((__bridge CFStringRef)mode, 0.001, false);
        }
    }
    CFRelease(allModes);
    
    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    if ([[exception name] isEqual:UncaughtExceptionHandlerSignalExceptionName])
    {
        kill(getpid(), [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
    }
    else
    {
        [exception raise];
    }
}

@end

NSString* getAppInfo()
{
    NSString *appInfo = [NSString stringWithFormat:@"App : %@ %@(%@)\nDevice : %@\nOS Version : %@ %@\n",
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
                         [UIDevice currentDevice].model,
                         [UIDevice currentDevice].systemName,
                         [UIDevice currentDevice].systemVersion];
    return appInfo;
}

void MySignalHandler(int signal)
{
    signum = signal;
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaximum)
    {
        return;
    }
    
    NSMutableDictionary *userInfo = [[NSMutableDictionary alloc] init];
    NSArray *callStack = [ExceptionHandler backtrace];
    
    [userInfo setObject:[NSNumber numberWithInt:signal] forKey:UncaughtExceptionHandlerSignalKey];
    [userInfo setObject:callStack forKey:UncaughtExceptionHandlerAddressesKey];
    
    NSException *exception = [NSException exceptionWithName:UncaughtExceptionHandlerSignalExceptionName
                                                     reason:[NSString stringWithFormat:NSLocalizedString(@"Signal %d was raised.\n" @"%@", nil), signal, getAppInfo()]
                                                   userInfo:userInfo];

    [[[ExceptionHandler alloc] init] performSelectorOnMainThread:@selector(handleException:)
                                                      withObject:exception
                                                   waitUntilDone:YES];
}

void InstallUncaughtExceptionHandler()
{
    signal(SIGABRT, MySignalHandler); /* 6 - abort() */
    signal(SIGSEGV, MySignalHandler); /* 11 - segmentation violation */
    signal(SIGBUS, MySignalHandler);  /* 10 - bus error */
    signal(SIGPIPE, MySignalHandler); /* 13 - write on a pipe with no one to read it */
    signal(SIGFPE, MySignalHandler);  /* 8 - floating point exception */
    signal(SIGILL, MySignalHandler);  /* 4 - illegal instruction (not reset when caught) */
}

