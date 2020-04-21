//
//  JYAudioRecorder.h
//  TestRecord
//
//  Created by donbe on 2020/4/13.
//  Copyright © 2020 donbe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol JYAudioRecorderDelegate <NSObject>

@optional


/// 录制时，麦克风输出回调
/// @param buffer  缓存
/// @param duration  录制的时长
-(void)recorderBuffer:(AVAudioPCMBuffer * _Nonnull)buffer duration:(NSTimeInterval)duration;


/// 状态变更时触发
/// @param isRec  录制状态
/// @param isPlaying  播放状态
-(void)recorderIsRec:(BOOL)isRec isPlaying:(BOOL)isPlaying;


/// 播放时，时间回调
/// @param time 正在播放的时间点
/// @param duration 总时间
-(void)recorderPlayingTime:(NSTimeInterval)time duration:(NSTimeInterval)duration;


@end


@interface JYAudioRecorder : NSObject

@property(nonatomic,strong)NSString *fileBGPath; //背景音地址
@property(nonatomic)float backgroundVolume; //背景音音量，默认0.2

@property(nonatomic)BOOL isRec; //录制状态
@property(nonatomic)BOOL isPlaying; //播放状态

@property(atomic,weak)id<JYAudioRecorderDelegate> delegate;

// 重头开始录音
-(void)startRecord;

// 从某个时间点往后录音
-(void)startRecordAtTime:(NSTimeInterval)time;

// 停止录音
-(void)stopRecord;

#pragma mark -
// 播放录音
-(void)play;

// 从中间开始播放录音
-(void)playAtTime:(NSTimeInterval)time;

// 停止播放录音
-(void)stopPlay;

// 暂停播放录音
-(void)pausePlay;

// 继续播放
-(void)resumePlay;

#pragma mark -
// 给背景音加的延迟秒数
+(NSTimeInterval)bgLatency;

@end

NS_ASSUME_NONNULL_END
