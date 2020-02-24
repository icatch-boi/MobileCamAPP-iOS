//
//  PCMDataPlayer.m
//  PCMDataPlayerDemo
//
//  Created by Android88 on 15-2-10.
//  Copyright (c) 2015年 Android88. All rights reserved.
//

#import "PCMDataPlayer.h"

@interface PCMDataPlayer()

@property(nonatomic) Float64 freq;
@property(nonatomic) UInt32 channel;
@property(nonatomic) UInt32 bit;

@end

@implementation PCMDataPlayer

- (id)initWithFreq:(Float64)freq channel:(UInt32)channel sampleBit:(UInt32)bit
{
    self = [super init];
    if (self) {
        self.freq = freq;
        self.channel = channel;
        self.bit = bit;
        [self reset];
    }
    return self;
}

- (void)dealloc
{
    if (audioQueue != nil) {
        AudioQueueStop(audioQueue, true);
    }
    audioQueue = nil;

    sysnLock = nil;

    NSLog(@"PCMDataPlayer dealloc...");
}

static void AudioPlayerAQInputCallback(void* inUserData, AudioQueueRef outQ, AudioQueueBufferRef outQB)
{
    PCMDataPlayer* player = (__bridge PCMDataPlayer*)inUserData;
    [player playerCallback:outQB];
}

- (void)reset
{
    [self stop];

    sysnLock = [[NSLock alloc] init];

    ///设置音频参数
    audioDescription.mSampleRate = self.freq; //采样率
    audioDescription.mFormatID = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioDescription.mChannelsPerFrame = self.channel; ///单声道
    audioDescription.mFramesPerPacket = 1; //每一个packet一侦数据
    audioDescription.mBitsPerChannel = self.bit; //每个采样点16bit量化
    audioDescription.mBytesPerFrame = (audioDescription.mBitsPerChannel / 8) * audioDescription.mChannelsPerFrame;
    audioDescription.mBytesPerPacket = audioDescription.mBytesPerFrame;

    AudioQueueNewOutput(&audioDescription, AudioPlayerAQInputCallback, (__bridge void*)self, nil, nil, 0, &audioQueue); //使用player的内部线程播放

    //初始化音频缓冲区
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        int result = AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]); ///创建buffer区，MIN_SIZE_PER_FRAME为每一侦所需要的最小的大小，该大小应该比每次往buffer里写的最大的一次还大
        NSLog(@"AudioQueueAllocateBuffer i = %d,result = %d", i, result);
    }

    NSLog(@"PCMDataPlayer reset");
}

- (void)stop
{
    if (audioQueue != nil) {
        AudioQueueStop(audioQueue, true);
        AudioQueueReset(audioQueue);
    }

    audioQueue = nil;
}

- (void)play:(void*)pcmData length:(NSUInteger)length
{
    if (audioQueue == nil || ![self checkBufferHasUsed]) {
        [self reset];
        AudioQueueStart(audioQueue, NULL);
    }

    [sysnLock lock];

    AudioQueueBufferRef audioQueueBuffer = NULL;

    while (true) {
        @autoreleasepool {
            audioQueueBuffer = [self getNotUsedBuffer];
            if (audioQueueBuffer != NULL) {
                break;
            }
        }
    }

    audioQueueBuffer->mAudioDataByteSize = (uint)length;
    Byte* audiodata = (Byte*)audioQueueBuffer->mAudioData;
    for (int i = 0; i < length; i++) {
        audiodata[i] = ((Byte*)pcmData)[i];
    }

    AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffer, 0, NULL);

    RunLog(@"PCMDataPlayer play dataSize:%d", length);

    [sysnLock unlock];
}

- (BOOL)checkBufferHasUsed
{
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        if (YES == audioQueueUsed[i]) {
            return YES;
        }
    }
    NSLog(@"PCMDataPlayer 播放中断............");
    return NO;
}

- (AudioQueueBufferRef)getNotUsedBuffer
{
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        if (NO == audioQueueUsed[i]) {
            audioQueueUsed[i] = YES;
            RunLog(@"PCMDataPlayer play buffer index:%d", i);
            return audioQueueBuffers[i];
        }
    }
    return NULL;
}

- (void)playerCallback:(AudioQueueBufferRef)outQB
{
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        if (outQB == audioQueueBuffers[i]) {
            audioQueueUsed[i] = NO;
        }
    }
}

@end
