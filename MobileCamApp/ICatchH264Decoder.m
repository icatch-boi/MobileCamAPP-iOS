//
//  ICatchH264Decoder.m
//  WifiCamMobileApp
//
//  Created by ZJ on 2016/10/26.
//  Copyright © 2016年 iCatchTech. All rights reserved.
//

#import "ICatchH264Decoder.h"
#import "SDK.h"

@implementation ICatchH264Decoder

static void didDecompress(void* decompressionOutputRefCon, void* sourceFrameRefCon,
                          OSStatus status, VTDecodeInfoFlags infoFlags,
                          CVImageBufferRef pixelBuffer, CMTime presentationTimeStamp, CMTime presentationDuration )
{
    
    CVPixelBufferRef *outputPixelBuffer = (CVPixelBufferRef *)sourceFrameRefCon;
    *outputPixelBuffer = CVPixelBufferRetain(pixelBuffer);
}

-(BOOL)initH264Env:(shared_ptr<ICatchVideoFormat>)format {
    
    AppLog(@"w:%d, h: %d", format->getVideoW(), format->getVideoH());

    _spsSize = format->getCsd_0_size()-4;
    _sps = (uint8_t *)malloc(_spsSize);
    memcpy(_sps, format->getCsd_0()+4, _spsSize);
    
    _ppsSize = format->getCsd_1_size()-4;
    _pps = (uint8_t *)malloc(_ppsSize);
    memcpy(_pps, format->getCsd_1()+4, _ppsSize);
    
    AppLog(@"sps:%ld, pps: %ld", (long)_spsSize, (long)_ppsSize);
    
    const uint8_t* const parameterSetPointers[2] = { _sps, _pps };
    const size_t parameterSetSizes[2] = { static_cast<size_t>(_spsSize), static_cast<size_t>(_ppsSize) };
    OSStatus status = CMVideoFormatDescriptionCreateFromH264ParameterSets(kCFAllocatorDefault,
                                                                          2, //param count
                                                                          parameterSetPointers,
                                                                          parameterSetSizes,
                                                                          4, //nal start code size
                                                                          &_decoderFormatDescription);
    if(status != noErr) {
        NSLog(@"IOS8VT: reset decoder session failed status=%d", (int)status);
    } else {
        uint32_t v = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
        const void* keys[] = { kCVPixelBufferPixelFormatTypeKey };
        const void* values[] = { CFNumberCreate(NULL, kCFNumberSInt32Type, &v) };
        CFDictionaryRef attrs = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);
        
        VTDecompressionOutputCallbackRecord callBackRecord;
        callBackRecord.decompressionOutputCallback = didDecompress;
        callBackRecord.decompressionOutputRefCon = NULL;
        
        VTDecompressionSessionCreate(kCFAllocatorDefault,
                                     _decoderFormatDescription,
                                     NULL, attrs,
                                     &callBackRecord,
                                     &_deocderSession);
        
        NSLog(@"__init_decoder__ deocderSession: %p", _deocderSession);
        NSLog(@"__init_decoder__ decoderFormatDescription: %p", _decoderFormatDescription);
        CFRelease(attrs);
    }
    
    return YES;
}

-(void)clearH264Env {
    if(_deocderSession) {
        VTDecompressionSessionInvalidate(_deocderSession);
        CFRelease(_deocderSession);
        _deocderSession = NULL;
    }
    
    if(_decoderFormatDescription) {
        CFRelease(_decoderFormatDescription);
        _decoderFormatDescription = NULL;
    }
    
    free(_sps);
    free(_pps);
    _spsSize = _ppsSize = 0;
}

- (void)decode:(NSData*)data
{
    NSDate *begin = [NSDate date];
    /* create block buffer */
    CMBlockBufferRef blockBuffer = NULL;
    CVPixelBufferRef pixelBuffer = NULL;
    
    OSStatus status  = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                          (void*)data.bytes, data.length,
                                                          kCFAllocatorNull,
                                                          NULL, 0, data.length,
                                                          0, &blockBuffer);
    if (status == kCMBlockBufferNoErr) {
        /* create sample buffer */
        CMSampleBufferRef sampleBuffer = NULL;
        const size_t sampleSizeArray[] = {static_cast<size_t>(data.length)};
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription ,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        if (status == kCMBlockBufferNoErr || sampleBuffer) {
            /* decode frame */
            VTDecodeFrameFlags  flags = 0;
            VTDecodeInfoFlags   flagOut = 0;
            OSStatus decodeStatus = VTDecompressionSessionDecodeFrame(_deocderSession,
                                                                      sampleBuffer,
                                                                      flags,
                                                                      &pixelBuffer,
                                                                      &flagOut);
            
            if(decodeStatus == kVTInvalidSessionErr) {
                NSLog(@"IOS8VT: Invalid session, reset decoder session");
            } else if(decodeStatus == kVTVideoDecoderBadDataErr) {
                NSLog(@"IOS8VT: decode failed status=%d(Bad data)", (int)decodeStatus);
            } else if(decodeStatus != noErr) {
                NSLog(@"IOS8VT: decode failed status=%d", (int)decodeStatus);
            }
            
            CFRelease(sampleBuffer);
            
        } else  NSLog(@"IOS8VT: create sample buffer failed.");
        
        CFRelease(blockBuffer);
        
    } else  NSLog(@"IOS8VT: create block failed.");
    
    if (pixelBuffer != NULL) {
        if (!CVPixelBufferIsPlanar(pixelBuffer)) {
            NSLog(@"...., not a planar buffer.");
        }
        
        size_t planCount = CVPixelBufferGetPlaneCount(pixelBuffer);
        if (planCount != 2) {
            NSLog(@"...., not a NV12 color.");
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        uint8_t* dataNV12_YY = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
        uint8_t* dataNV12_UV = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
        int32_t  dataNV12_YY_size = (int32_t)(CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0) * CVPixelBufferGetHeightOfPlane(pixelBuffer, 0));
        int32_t  dataNV12_UV_size = (int32_t)(CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1) * CVPixelBufferGetHeightOfPlane(pixelBuffer, 1));
        NSDate *end1 = [NSDate date];
        [[PanCamSDK instance] panCamUpdateFrame:dataNV12_YY andImageYsize:dataNV12_YY_size andImageU:dataNV12_UV andImageUsize:dataNV12_UV_size andImageV:dataNV12_UV andImageVsize:dataNV12_UV_size];
        NSDate *end2 = [NSDate date];
        AppLog(@"=========> time1: %f, time2: %f, time3: %f, videSize: %lu", [end1 timeIntervalSinceDate:begin] * 1000, [end2 timeIntervalSinceDate:begin] * 1000, [end2 timeIntervalSinceDate:end1] * 1000, (unsigned long)data.length);
        //NSLog(@"dataNV12, dataNV12_YY, %p %d", dataNV12_YY, dataNV12_YY_size);
        //NSLog(@"dataNV12, dataNV12_UV, %p %d", dataNV12_YY, dataNV12_UV_size);
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        CVPixelBufferRelease(pixelBuffer);
    }
}

- (void)decodeAndDisplayH264Frame:(NSData *)frame withDisplayLayer:(AVSampleBufferDisplayLayer *)avslayer {
    CMBlockBufferRef blockBuffer = NULL;
    CMSampleBufferRef sampleBuffer = NULL;
    
    OSStatus status = CMBlockBufferCreateWithMemoryBlock(kCFAllocatorDefault,
                                                         (void*)frame.bytes, frame.length,
                                                         kCFAllocatorNull,
                                                         NULL, 0, frame.length,
                                                         0, &blockBuffer);
    if(status == kCMBlockBufferNoErr) {
        const size_t sampleSizeArray[] = {frame.length};
        
        status = CMSampleBufferCreateReady(kCFAllocatorDefault,
                                           blockBuffer,
                                           _decoderFormatDescription,
                                           1, 0, NULL, 1, sampleSizeArray,
                                           &sampleBuffer);
        CFRelease(blockBuffer);
        CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
        CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
        CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
        if (status == kCMBlockBufferNoErr) {
            if ([avslayer isReadyForMoreMediaData]) {
                dispatch_sync(dispatch_get_main_queue(),^{
                    [avslayer enqueueSampleBuffer:sampleBuffer];
                });
            }
            CFRelease(sampleBuffer);
        }
    }
}

@end
