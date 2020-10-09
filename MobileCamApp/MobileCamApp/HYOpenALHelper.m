//
//  HYOpenALHelper.m
//  BTDemo
//
//  Created by crte on 13-8-16.
//  Copyright (c) 2013年 Shadow. All rights reserved.
//

#import "HYOpenALHelper.h"

@interface HYOpenALHelper ()
@property (nonatomic) NSData *audioData;
@property (nonatomic) double timestamp;
@property (nonatomic) ALfloat removedBufferLength;
@property (nonatomic) BOOL deleting;
@property (nonatomic) NSTimeInterval allPlayedBufferLength;

@property (nonatomic) ALsizei freq;
@property (nonatomic) ALenum format;

@property (nonatomic) NSTimer *testTimer;
@end

@implementation HYOpenALHelper

@synthesize outSourceID;
@synthesize timestamp;

- (BOOL)initOpenAL:(ALsizei)freq channel:(int)channel sampleBit:(int)bit
{
    if (!self.mDevice) {
        self.mDevice = alcOpenDevice(NULL);
    }
    if (!self.mDevice) {
        return NO;
    }
    if (!self.mContext) {
        self.mContext = alcCreateContext(self.mDevice, NULL);
        alcMakeContextCurrent(self.mContext);
    }
    
    alGenSources(1, &outSourceID);
    alSourcei(outSourceID, AL_LOOPING, AL_FALSE);
    alSourcef(outSourceID, AL_SOURCE_TYPE, AL_STREAMING);
    alSourcef(outSourceID, AL_GAIN, 1.0);
    alSourcef(outSourceID, AL_PITCH, 1.0);
    alSpeedOfSound(1.0);
    alDopplerVelocity(1.0);
    alDopplerFactor(1.0);
    
    alGetError();
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(cleanBuffers)
                                                    userInfo:nil repeats:YES];
//        self.testTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
//                                                          target:self
//                                                        selector:@selector(getInfo2)
//                                                        userInfo:nil repeats:YES];
    });
    
    if (!self.mContext) {
        return NO;
    }
    
    self.freq = freq;
    AppLog(@"Audio Frequency: %d", freq);
    if (channel == 1 && bit == 8) {
        AppLog(@"mono08");
        self.format = AL_FORMAT_MONO8;
    } else if (channel == 1 && bit == 16) {
        AppLog(@"mono16");
        self.format = AL_FORMAT_MONO16;
    } else if (channel == 2 && bit == 8) {
        AppLog(@"stereo08");
        self.format = AL_FORMAT_STEREO8;
    } else if (channel == 2 && bit == 16) {
        AppLog(@"stereo16");
        self.format = AL_FORMAT_STEREO16;
    } else {
        AppLog(@"Unknow channel: %d", channel);
    }
    return YES;
}

- (BOOL)insertPCMDataToQueue:(const ALvoid *)data size:(NSUInteger)size
{
    @synchronized(self) {
        ALenum error = alGetError();
        if (error != AL_NO_ERROR) {
            AppLog(@"** Insert PCM data failed with error code %d.", error);
            return NO;
        }

        if (data == NULL) {
            AppLog(@"** PCM data is null.");
            return NO;
        }
        
        ALuint bufferID = 0;
        alGenBuffers(1, &bufferID);
        error = alGetError();
        if (error != AL_NO_ERROR) {
            AppLog(@"** Failed to create buffer with error code %d.", error);
            return NO;
        }
        
        //NSData *nData = [NSData dataWithBytes:data length:size];
        //NSData *nData = [NSData dataWithBytesNoCopy:data length:size freeWhenDone:NO];
        //alBufferData(bufferID, AL_FORMAT_STEREO16, (char *)[nData bytes], (ALsizei)[nData length], 44100);
        //alBufferData(bufferID, AL_FORMAT_STEREO16, (const ALvoid *)data, (ALsizei)size, 44100);
        alBufferData(bufferID, self.format, data, (ALsizei)size, self.freq);
        error = alGetError();
        if (error != AL_NO_ERROR) {
            AppLog(@"** Copy failed with error code %d.", error);
            return NO;
        }
        
        ALint state;
        alGetSourcei(outSourceID, AL_SOURCE_STATE, &state);
        if (state == AL_STOPPED) {
            AppLog(@"openAL 播放中断......");
            [self getInfo2];
            [self cleanBuffers];
            alSourceRewind(outSourceID);
        }
        
        //        alSourcei(outSourceID, AL_BUFFER, bufferID);
        alSourceQueueBuffers(outSourceID, 1, &bufferID);
        
        error = alGetError();
        if (error != AL_NO_ERROR) {
            AppLog(@"** Insert failed with error code %d.", error);
            return NO;
        }
        
        //        [self play];
//        AppLog(@"Insert OK!");
        return YES;
    }
}

- (void)play
{
    ALint state;
    alGetSourcei(outSourceID, AL_SOURCE_STATE, &state);
    RunLog(@"state: %x", state);
    if (state != AL_PLAYING) {
        alSourcePlay(outSourceID);
    }
}

- (void)stop
{
    ALint state;
    alGetSourcei(outSourceID, AL_SOURCE_STATE, &state);
    
    if (state != AL_STOPPED) {
        alSourceStop(outSourceID);
    }
}

- (void)clean {
    if ([_timer isValid]) {
        [_timer invalidate];
        _timer = nil;
    }
    
    if ([_testTimer isValid]) {
        [_testTimer invalidate];
        _testTimer = nil;
    }
    alDeleteSources(1, &outSourceID);
    alcDestroyContext(self.mContext);
    alcCloseDevice(self.mDevice);
}

- (void)pause {
    ALint state;
    alGetSourcei(outSourceID, AL_SOURCE_STATE, &state);
    
    if (state != AL_PAUSED) {
        AppLog(@"call pause");
        alSourcePause(outSourceID);
    }
    [self cleanBuffers];
}

- (ALint)getInfo
{
    ALint queued;
    ALint processed;
    //    ALint bytes;
    //    ALfloat sec;
    //    ALint sample;
    alGetSourcei(outSourceID, AL_BUFFERS_PROCESSED, &processed);
    alGetSourcei(outSourceID, AL_BUFFERS_QUEUED, &queued);
    //    alGetSourcei(outSourceID, AL_BYTE_OFFSET, &bytes);
    //    alGetSourcef(outSourceID, AL_SEC_OFFSET, &sec);
    //    alGetSourcei(outSourceID, AL_SAMPLE_OFFSET, &sample);
    //    AppLog(@"Current：processed = %d, queued = %d, bytes = %d, sec = %f, sample = %d", processed, queued, bytes, sec, sample);
    
    return queued - processed;
}

- (ALfloat)getInfo2
{
    ALint queued;
    ALint processed;
    ALint bytes;
    ALfloat sec;
    ALint state;
    alGetSourcei(outSourceID, AL_BUFFERS_PROCESSED, &processed);
    alGetSourcei(outSourceID, AL_BUFFERS_QUEUED, &queued);
    alGetSourcei(outSourceID, AL_BYTE_OFFSET, &bytes);
    alGetSourcef(outSourceID, AL_SEC_OFFSET, &sec);
    alGetSourcei(outSourceID, AL_SOURCE_STATE, &state);
//    AppLog(@"=====>  processed = %d, queued = %d, bytes = %d, sec = %f", processed, queued, bytes, sec);
    
    //    if (state == AL_PLAYING && queued - processed < 2) {
    //        [self pause];
    //    }
    
    return sec;
}

- (void)cleanBuffers
{
    //self.deleting = YES;
    
    //ALfloat sec = 0;
    ALint processed = 0;
    //alGetSourcef(outSourceID, AL_SEC_OFFSET, &sec);
    
    alGetSourcei(outSourceID, AL_BUFFERS_PROCESSED, &processed);
    //    ALfloat temp = 0;
//    if (processed > 0) {
//        AppLog(@"----------------------------------> 销毁【%d】个Buffer", processed);
//    }
    
    while (processed--) {
        //ALint bID;
        ALuint bufferID;
        
        //alGetSourcef(outSourceID, AL_SEC_OFFSET, &sec);
        //AppLog(@"[%d]sec: %f", processed, sec);
        /*
         if (processed == 0) {
         ALfloat ssec = 0;
         alGetSourcef(outSourceID, AL_SEC_OFFSET, &ssec);
         //AppLog(@"processed: %d, ssec: %f", processed, ssec);
         sec = sec - ssec;
         
         }
         
         ALfloat bufferSize = 0;
         alGetSourcei(outSourceID, AL_BUFFER, &bID);
         alGetBufferf(bID, AL_SIZE, &bufferSize);
         AppLog(@"--> [%d]bufferSize: %f", bID, bufferSize);
         */
        alSourceUnqueueBuffers(outSourceID, 1, &bufferID);
        
        //        ALint bufferSize = 0, frequency, bitsPerSample, channels;
        //        alGetBufferi(bufferID, AL_SIZE, &bufferSize);
        //        alGetBufferi(bufferID, AL_FREQUENCY, &frequency);
        //        alGetBufferi(bufferID, AL_CHANNELS, &channels);
        //        alGetBufferi(bufferID, AL_BITS, &bitsPerSample);
        
        //AppLog(@"--> [%d]bufferSize: %d, frequency: %d, channels: %d, bitsPerSample: %d", bufferID, bufferSize, frequency, channels, bitsPerSample);
        //        temp += ((ALfloat)bufferSize/(frequency * channels * (bitsPerSample/8)));
        
        alDeleteBuffers(1, &bufferID);
        
    }
    
    //self.removedBufferLength += sec;
    //AppLog(@"sec: %f, removed: %f, remained: %f", sec, temp, sec - temp);
    //    self.removedBufferLength += temp;
    //AppLog(@"removedBufferLength: %f", _removedBufferLength);
    
    //self.deleting = NO;
}

-(double)timestamp
{
    ALfloat sec = -1;
    ALenum error;
    
    alGetSourcef(outSourceID, AL_SEC_OFFSET, &sec);
    
    if((error = alGetError()) != AL_NO_ERROR) {
        if (error == AL_INVALID_VALUE) {
            AppLog(@"error OFFSET source: AL_INVALID_VALUE:%f",sec);
        }else if (error == AL_INVALID_ENUM) {
            AppLog(@"error OFFSET source: AL_INVALID_ENUM");
        }else if (error == AL_INVALID_NAME) {
            AppLog(@"error OFFSET source: AL_INVALID_NAME");
        }else if (error == AL_INVALID_OPERATION) {
            AppLog(@"error OFFSET source: AL_INVALID_OPERATION");
        }else {
            AppLog(@"error OFFSET source: %x", error);
        }
        
    } else {
        AppLog(@"OFFSET source: %f, removed: %f", sec, _removedBufferLength);
        self.allPlayedBufferLength = _removedBufferLength + sec;
    }
    
    return _allPlayedBufferLength;
}

@end
