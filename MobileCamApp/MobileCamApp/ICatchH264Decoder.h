//
//  ICatchH264Decoder.h
//  WifiCamMobileApp
//
//  Created by ZJ on 2016/10/26.
//  Copyright © 2016年 iCatchTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

@interface ICatchH264Decoder : NSObject {
    uint8_t *_sps;
    NSInteger _spsSize;
    uint8_t *_pps;
    NSInteger _ppsSize;
    CMVideoFormatDescriptionRef _decoderFormatDescription;
    VTDecompressionSessionRef _deocderSession;
}

-(BOOL)initH264Env:(shared_ptr<ICatchVideoFormat>)format;
-(void)clearH264Env;
- (void)decode:(NSData*)data;
- (void)decodeAndDisplayH264Frame:(NSData *)frame withDisplayLayer:(AVSampleBufferDisplayLayer *)avslayer;

@end
