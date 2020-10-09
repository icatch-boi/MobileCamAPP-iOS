//
//  ZJInternalMacros.h
//  ZJDataCache
//
//  Created by ZJ on 2019/8/9.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#ifndef ZJInternalMacros_h
#define ZJInternalMacros_h

#ifndef ZJ_LOCK
#define ZJ_LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#endif

#ifndef ZJ_UNLOCK
#define ZJ_UNLOCK(lock) dispatch_semaphore_signal(lock);
#endif

#endif /* ZJInternalMacros_h */
