//
//  StreamSDKEventListener.hpp
//  WifiCamMobileApp
//
//  Created by ZJ on 2017/6/23.
//  Copyright © 2017年 iCatchTech. All rights reserved.
//

#ifndef StreamSDKEventListener_hpp
#define StreamSDKEventListener_hpp

#include <stdio.h>

class StreamSDKEventListener: public ICatchIPancamListener {
private:
    id object;
    SEL callback;
    void eventNotify(shared_ptr<ICatchGLEvent> icatchEvt);
public:
    StreamSDKEventListener(id object, SEL callback);
};

#endif /* StreamSDKEventListener_hpp */
