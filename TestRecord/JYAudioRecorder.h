//
//  JYAudioRecorder.h
//  TestRecord
//
//  Created by donbe on 2020/4/13.
//  Copyright © 2020 donbe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JYAudioRecorder : NSObject

@property(atomic)BOOL isRec; //录制状态

@property(atomic)BOOL isPlaying; //播放状态

// 重头开始录音
-(void)startRecord;

// 从某个时间点往后录音
-(void)startRecordFromSection:(float)second;

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
