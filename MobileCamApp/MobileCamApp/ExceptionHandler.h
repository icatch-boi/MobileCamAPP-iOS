//
//  ExceptionHandler.h
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-4-2.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ExceptionHandler : NSObject {
  BOOL dismissed;
}
void InstallUncaughtExceptionHandler();
@end
