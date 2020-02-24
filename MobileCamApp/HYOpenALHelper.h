//
//  HYOpenALHelper.h
//  BTDemo
//
//  Created by rainbownight on 13-8-16.
//  Copyright (c) 2013年 Shadow. All rights reserved.
//

//  功能说明:
//  简单的实现了播放流式PCM数据的功能

//  使用方法:
//  1. 导入OpenAL.framework
//  1. alloc/init方法创建对象
//  2. 调用initOpenAL方法初始化OpenAL
//  3. 使用insertPCMDataToQueue:size:方法将PCM数据加载到缓冲队列里, 会自动播放
//  4. 不用的时候, 先调用clean方法关闭OpenAL然后再销毁对象. (不clean的话, 下次初始化会有问题)


#import <Foundation/Foundation.h>
#import <OpenAL/al.h>
#import <OpenAL/alc.h>

@interface HYOpenALHelper : NSObject
{
    ALuint outSourceID;
}

//声音环境
@property ALCcontext *mContext;
//声音设备
@property ALCdevice *mDevice;
//声源
@property ALuint outSourceID;
//用来定时清除已播放buffer的定时器
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, readonly) double timestamp;



//初始化openAL
- (BOOL)initOpenAL:(ALsizei)freq channel:(int)channel sampleBit:(int)bit;
//添加音频数据到队列内
- (BOOL)insertPCMDataToQueue:(const ALvoid*)data size:(NSUInteger)size;

//播放声音
- (void)play;
//停止播放
- (void)stop;
//不用时先调用清除, 再销毁对象
- (void)clean;
// pause
- (void)pause;

//debug, 打印队列内缓存区数量和已播放的缓存区数量
- (ALint)getInfo;
@end
