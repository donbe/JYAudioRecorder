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
/// @param when  时间
-(void)recorderBuffer:(AVAudioPCMBuffer * _Nonnull) buffer when:(AVAudioTime * _Nonnull) when;


/// 播放时，时间回调
/// @param time 正在播放的时间点
-(void)recorderPlayingTime:(NSTimeInterval * _Nonnull) time;


/// 状态变更时触发
/// @param isRec  录制状态
/// @param isPlaying  播放状态
-(void)recorderIsRec:(BOOL)isRec isPlaying:(BOOL)isPlaying;


@end

@interface JYAudioRecorder : NSObject

@property(nonatomic,strong)NSString *fileBGPath; //背景音地址
@property(atomic)BOOL isRec; //录制状态
@property(atomic)BOOL isPlaying; //播放状态

@property(atomic,strong)id<JYAudioRecorderDelegate> delegate;

// 重头开始录音
-(void)startRecord;

// 从某个时间点往后录音
-(void)startRecordFromTime:(NSTimeInterval)second;

// 停止录音
-(void)stopRecord;

#pragma mark -
// 播放录音
-(void)play;

// 停止播放录音
-(void)stopPlay;

// 暂停播放录音
-(void)pausePlay;

// 继续播放
-(void)resumePlay;

@end

NS_ASSUME_NONNULL_END
