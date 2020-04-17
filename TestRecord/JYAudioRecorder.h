//
//  JYAudioRecorder.h
//  QKRight
//
//  Created by donbe on 2020/4/13.
//  Copyright © 2020 卢仕彤. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JYAudioRecorder : NSObject

// 重头开始录音
-(void)startRecord;

// 从某个时间点往后录音
-(void)startRecordWithSection:(float)second;

// 停止录音
-(void)stopRecord;

// 播放录音
-(void)play;

// 停止播放录音
-(void)stopPlay;

@end

NS_ASSUME_NONNULL_END
