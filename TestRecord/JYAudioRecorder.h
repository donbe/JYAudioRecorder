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

/// 播放时，时间回调
/// @param time 正在播放的时间点
/// @param duration 总时间
-(void)recorderPlayingTime:(NSTimeInterval)time duration:(NSTimeInterval)duration;

/// 播放开始
-(void)recorderPlayingStart;

/// 播放结束
-(void)recorderPlayingFinish;

/// 录制开始
-(void)recorderStart;

/// 录制结束
-(void)recorderFinish;


@end


@interface JYAudioRecorder : NSObject

@property(nonatomic,strong,readonly)NSString *recordFilePath; //录制的音频保存地址
@property(nonatomic,strong)NSString *fileBGPath; //背景音地址
@property(nonatomic)float backgroundVolume; //背景音音量，默认0.2

@property(nonatomic,readonly)BOOL isRec; //录制状态
@property(nonatomic,readonly)BOOL isPlaying; //播放状态

@property(nonatomic,readonly)NSTimeInterval recordDuration; //录制时长
@property(nonatomic,readonly)NSTimeInterval currentPlayTime; //当前播放时间点

@property(atomic,weak)id<JYAudioRecorderDelegate> delegate;

// 从头开始录音
-(void)startRecord;

// 从某个时间点往后继续录音
-(void)startRecordAtTime:(NSTimeInterval)time;

// 停止录音
-(void)stopRecord;

#pragma mark -
// 播放录音
-(void)play;

// 从某个时间点往后继续播放
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
