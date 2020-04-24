//
//  JYAudioRecorder.m
//  TestRecord
//
//  Created by donbe on 2020/4/13.
//  Copyright © 2020 donbe. All rights reserved.
//

#import "JYAudioRecorder.h"
#import <UIKit/UIKit.h>

@interface JYAudioRecorder()<AVAudioPlayerDelegate>

@property(nonatomic,strong)AVAudioEngine *audioEngine;
@property(nonatomic,strong)AVAudioPlayerNode *audioPlayerNode;

@property(nonatomic) AVAudioPlayer *audioPlayer;
@property(nonatomic) AVAudioPlayer *audioBGPlayer;

@property(nonatomic) NSTimeInterval pausePoint;

@property(nonatomic,strong)AVAudioFormat *recordFormat; //录音保存格式
@property(nonatomic,strong,readwrite)NSString *recordFilePath; //录制的音频保存地址
@property(nonatomic)AudioFileID recordFileID;

@property(nonatomic,weak)NSTimer *playTimer;

@property(nonatomic,readwrite)NSTimeInterval recordDuration; //录制时长
@property(nonatomic,readwrite)BOOL isRec; //录制状态
@property(nonatomic,readwrite)BOOL isPlaying; //播放状态



@end


@implementation JYAudioRecorder

-(instancetype)init{
    self = [super init];
    if (self) {
        
        self.backgroundVolume = 0.2;
        
        [self.audioEngine attachNode:self.audioPlayerNode];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioSessionInterruptionNotification:) name:AVAudioSessionInterruptionNotification object:nil];
    }
    return self;
}


#pragma mark -
-(void)startRecord{
    [self startRecordAtTime:0];
}


-(void)startRecordAtTime:(NSTimeInterval)time{
    
    if (self.isRec || self.isPlaying) {
        return;
    }
    self.isRec = YES;
    
    // 不能大于录制时间
    time = MIN(time, self.recordDuration);
    
    // 解决精度问题
    time = round(time * 1000)/1000;
    
    // 设置AVAudioSession
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    assert(error == nil);
    [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeSpokenAudio error:&error];
    assert(error == nil);
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    assert(error == nil);
    
    
    // 创建播放文件
    AVAudioFile *audiofile;
    if (self.fileBGPath) {
        audiofile = [[AVAudioFile alloc] initForReading:[NSURL fileURLWithPath:self.fileBGPath] error:&error];
        assert(error == nil);
    }
    
    // 设置录音文件地址
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    self.recordFilePath = [dir stringByAppendingString:@"/recording_file_200422.wav"];
    
    
    // 继续录音的情况，计算从多少byte开始截断
    UInt32 truncateByte = (UInt32)(time * self.recordFormat.sampleRate * self.recordFormat.channelCount * [self bytesOfCommonFormat:self.recordFormat.commonFormat]);
    
    
    // 打开文件，处理截断
    [self openfileWithFormat:self.recordFormat truncateByte:truncateByte];
    
    
    // 重新设置录制时间
    self.recordDuration = time;
    
    
    // 创建格式转换器
    AVAudioConverter *audioConverter = [[AVAudioConverter alloc] initFromFormat:[self.audioEngine.inputNode outputFormatForBus:0] toFormat:self.recordFormat];

    
    // 安装tap
    __block SInt64 inStartingByte = truncateByte;
    __weak JYAudioRecorder *weakSelf = self;
    [self.audioEngine.inputNode installTapOnBus:0 bufferSize:2048 format:nil block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {

        // 文件可能已经被关闭
        if (weakSelf.recordFileID == nil)
            return;
        
        // 进行格式换砖
        float ratio = [[buffer format] sampleRate]/weakSelf.recordFormat.sampleRate;
        UInt32 capacity = buffer.frameCapacity/ratio;
        AVAudioPCMBuffer *convertedBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:weakSelf.recordFormat frameCapacity:capacity];
        AVAudioConverterInputBlock inputBlock = ^(AVAudioPacketCount inNumberOfPackets, AVAudioConverterInputStatus* outStatus){
            *outStatus = AVAudioConverterInputStatus_HaveData;
            return buffer;
        };
        [audioConverter convertToBuffer:convertedBuffer error:nil withInputFromBlock:inputBlock];
        

        // 写文件
        UInt32 length = convertedBuffer.frameLength * weakSelf.recordFormat.channelCount * [weakSelf bytesOfCommonFormat:weakSelf.recordFormat.commonFormat];
        OSStatus status = AudioFileWriteBytes(weakSelf.recordFileID, NO, inStartingByte, &length, convertedBuffer.int16ChannelData[0]);
        assert(status == noErr);
        if (status != noErr)
            return;
        
        
        // 总写入字节数
        inStartingByte += length;
        
        
        // 计算总录制时长，回调
        weakSelf.recordDuration = inStartingByte / weakSelf.recordFormat.sampleRate / weakSelf.recordFormat.channelCount / [weakSelf bytesOfCommonFormat:weakSelf.recordFormat.commonFormat];
        if ([weakSelf.delegate respondsToSelector:@selector(recorderBuffer:duration:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.delegate recorderBuffer:convertedBuffer duration:weakSelf.recordDuration];
            });
        }
 
    }];
    
    
    // 播放设置
    AVAudioFramePosition startFrame = time * audiofile.fileFormat.sampleRate;
    if (audiofile && startFrame < [audiofile length]) {
        // 连接背景音乐node
        [self.audioEngine connect:self.audioPlayerNode to:self.audioEngine.mainMixerNode format:audiofile.processingFormat];
        
        // 设置播放区间
        [self.audioPlayerNode scheduleSegment:audiofile startingFrame:startFrame frameCount:(AVAudioFrameCount)([audiofile length] - startFrame) atTime:nil completionHandler:^{
            NSLog(@"player complete");
        }];
        
        //准备一秒的缓存
        [self.audioPlayerNode prepareWithFrameCount:(AVAudioFrameCount)audiofile.fileFormat.sampleRate];
    }
    

    // 启动引擎
    BOOL result = [self.audioEngine startAndReturnError:&error];
    assert(error == nil);
    assert(result);
    
    
    // 开始播放
    if (audiofile && startFrame < [audiofile length]) {
        self.audioPlayerNode.volume = self.backgroundVolume;
        [self.audioPlayerNode play];
    }
}

-(void)stopRecord{
    if (self.isRec) {
        
        [self.audioPlayerNode stop];
        [self.audioEngine stop];
        
        [self.audioEngine.inputNode removeTapOnBus:0];
        
        AudioFileClose(self.recordFileID);
        self.recordFileID = nil;
        
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        
        self.isRec = NO;
    }
}


#pragma  mark -
-(void)play{
    [self playAtTime:0];
}

-(void)playAtTime:(NSTimeInterval)time{
        
    if (time > self.recordDuration) {
        return;
    }
    
    if (self.isRec) {
        return;
    }

    if (self.recordFilePath == nil) {
        return;
    }
    
    if (!self.isPlaying) {
        NSError *error;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
        assert(error == nil);

        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        assert(error == nil);
        
        
        self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:self.recordFilePath] error:&error];
        assert(error == nil);
        
        self.audioBGPlayer = nil;
        if (self.fileBGPath) {
            self.audioBGPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:self.fileBGPath] error:&error];
            assert(error == nil);
        }
        
        self.audioPlayer.delegate = self;
        self.audioBGPlayer.delegate = self;
        
        self.audioBGPlayer.volume = self.backgroundVolume;
    }
    

    self.audioPlayer.currentTime = time;
    self.audioBGPlayer.currentTime = time;
    
    if (!self.audioPlayer.isPlaying) {
        // 同步两个播放器
        NSTimeInterval shortStartDelay = 0.01;
        NSTimeInterval shortBGStartDelay = [JYAudioRecorder bgLatency];
        NSTimeInterval now = self.audioPlayer.deviceCurrentTime;
        
        [self.audioPlayer playAtTime: now + shortStartDelay];
        [self.audioBGPlayer playAtTime: now + shortStartDelay + shortBGStartDelay];
        
    }
    
    self.isPlaying = YES;
    [self startTimer];
}

-(void)pausePlay{
    if (self.isPlaying) {
        [self.audioPlayer stop];
        [self.audioBGPlayer stop];
        [self stopTimer];
    }
}

-(void)resumePlay{
    if (self.isPlaying) {
        [self.audioPlayer prepareToPlay];
        [self.audioBGPlayer prepareToPlay];
        
        [self.audioPlayer play];
        [self.audioBGPlayer play];
        [self startTimer];
    }
}

-(void)stopPlay{
    if (self.isPlaying) {
        
        [self.audioPlayer stop];
        [self.audioBGPlayer stop];
        
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        
        self.isPlaying = NO;
        [self stopTimer];
    }
}

#pragma mark - get/set
-(void)setIsRec:(BOOL)isRec{
    if (isRec != _isRec) {
        _isRec = isRec;
        
        if (isRec) {
            if ([self.delegate respondsToSelector:@selector(recorderStart)]) {
                [self.delegate recorderStart];
            }
        }else{
            if ([self.delegate respondsToSelector:@selector(recorderFinish)]) {
                [self.delegate recorderFinish];
            }
        }
    }
}

-(void)setIsPlaying:(BOOL)isPlaying{
    if (_isPlaying != isPlaying) {
        _isPlaying = isPlaying;
        
        if (isPlaying) {
            if ([self.delegate respondsToSelector:@selector(recorderPlayingStart)]) {
                [self.delegate recorderPlayingStart];
            }
        }else{
            if ([self.delegate respondsToSelector:@selector(recorderPlayingFinish)]) {
                [self.delegate recorderPlayingFinish];
            }
        }
        
    }
}


-(NSTimeInterval)currentPlayTime{
    return self.audioPlayer.currentTime;
}


-(AVAudioEngine *)audioEngine{
    if (_audioEngine == nil) {
        _audioEngine = [AVAudioEngine new];
    }
    return _audioEngine;
}

-(AVAudioPlayerNode *)audioPlayerNode{
    if (_audioPlayerNode == nil) {
        _audioPlayerNode = [AVAudioPlayerNode new];
    }
    return _audioPlayerNode;
}

-(AVAudioFormat *)recordFormat{
    return [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16 sampleRate:16000 channels:1 interleaved:true];;
}

#pragma mark - AVAudioPlayerDelegate
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"audioPlayerDidFinishPlaying");
    if (player == self.audioPlayer) {
        [self stopPlay];
    }
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
    NSLog(@"audioPlayerDecodeErrorDidOccur");
    if (player == self.audioPlayer) {
        [self stopPlay];
    }
}

#pragma mark - AVAudioSessionInterruptionNotification
-(void)audioSessionInterruptionNotification:(NSNotification *)notification{
    AVAudioSessionInterruptionType type = [notification.userInfo[AVAudioSessionInterruptionTypeKey] intValue];
    if (type == AVAudioSessionInterruptionTypeBegan) {
        NSLog(@"Interruption Began");
        [self stopRecord];
        [self stopPlay];
    }else{
        NSLog(@"Interruption end");
    }
}

#pragma mark - NStimer
- (NSTimer * _Nonnull)startTimer{
    return self.playTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(playTimerCB) userInfo:nil repeats:YES];
}

- (void)stopTimer {
    [self.playTimer invalidate];
    self.playTimer = nil;
}

-(void)playTimerCB{
    if ([self.delegate respondsToSelector:@selector(recorderPlayingTime:duration:)]) {
        [self.delegate recorderPlayingTime:self.audioPlayer.currentTime duration:self.audioPlayer.duration];
    }
}

#pragma mark - public
- (void)truncateFile:(NSTimeInterval)time {
    
    // 不能大于录制时间
    time = MIN(time, self.recordDuration);
    
    // 解决精度问题
    time = round(time * 1000)/1000;
    
    // 继续录音的情况，计算从多少byte开始截断
    UInt32 truncateByte = (UInt32)(time * self.recordFormat.sampleRate * self.recordFormat.channelCount * [self bytesOfCommonFormat:self.recordFormat.commonFormat]);
    
    // 截断
    [self truncateFileForFormat:self.recordFormat truncateByte:truncateByte];
    
    // 重新设置录制时间
    self.recordDuration = time;
}

#pragma mark - help

- (void)truncateFileForFormat:(AVAudioFormat *)format truncateByte:(UInt32)truncateByte {
    OSStatus stats = AudioFileOpenURL((__bridge CFURLRef)[NSURL fileURLWithPath:self.recordFilePath], kAudioFileReadPermission, kAudioFileWAVEType, &_recordFileID);
    assert(stats==0);
    
    
    // 临时创建一个文件
    AudioFileID tmpfileid;
    // 设置录音文件地址
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *tmpFilePath = [dir stringByAppendingString:@"/recording_tempfile.wav"];
    stats = AudioFileCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:tmpFilePath], kAudioFileWAVEType, format.streamDescription, kAudioFileFlags_EraseFile, &tmpfileid);
    assert(stats==0);
    
    
    // 如果一次性缓存太多，会闪退
    const int bytesPreLoop = 32000*5; // 每次拷贝字节数
    int loopCount = ceil(truncateByte / 1.0 / bytesPreLoop); //总拷贝次数
    char buf[bytesPreLoop]; //缓存
    UInt32 startpos = 0; //开始拷贝的位置
    UInt32 numofbytes = 0; //结束拷贝的位置
    
    for (int i=0; i<loopCount; i++) {
        
        startpos = i*bytesPreLoop;
        numofbytes = MIN(bytesPreLoop, truncateByte-startpos);
        
        AudioFileReadBytes(_recordFileID, NO, startpos, &numofbytes, buf);
        AudioFileWriteBytes(tmpfileid, NO, startpos, &numofbytes, buf);
    }
    
    AudioFileClose(_recordFileID);
    AudioFileClose(tmpfileid);
    
    //删除源文件
    NSError *err;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:self.recordFilePath error:&err];
    assert(err==nil);
    
    //移动文件
    [fileManager moveItemAtPath:tmpFilePath toPath:self.recordFilePath error:&err];
    assert(err==nil);
    
}

/// 打开音频文件，可能会进行截断操作
/// @param format 音频文件格式
/// @param truncateByte 从第几个字节开始截断
- (void)openfileWithFormat:(AVAudioFormat *)format truncateByte:(UInt32)truncateByte {
    if (truncateByte>0) {
        
        [self truncateFileForFormat:format truncateByte:truncateByte];
        
        OSStatus stats = AudioFileOpenURL((__bridge CFURLRef)[NSURL fileURLWithPath:self.recordFilePath], kAudioFileReadWritePermission, kAudioFileWAVEType, &_recordFileID);
        assert(stats==0);
        
    }else{
        
        // 创建文件
        OSStatus stats = AudioFileCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:self.recordFilePath], kAudioFileWAVEType, format.streamDescription, kAudioFileFlags_EraseFile, &_recordFileID);
        assert(stats==0);
        
    }
}

-(void)print_wav_head_info{
    
    NSData *d = [[NSFileManager defaultManager] contentsAtPath:self.recordFilePath];
    
    // RIFF
    const char *bs = (char *)d.bytes;
    for (int i=0; i<4; i++) {
        printf("%c",bs[0]);
        bs++;
    }
    printf("\r");
    
    int *bsi = (int *)bs;
    printf("chunk size: %d",bsi[0]);
    
    bs+=8;
    
    // fmt
    printf("\r");
    printf("\r");
    for (int i=0; i<4; i++) {
        printf("%c",bs[0]);
        bs++;
    }
    
    bsi = (int *)bs;
    printf("\r");
    printf("sub chunk size: %d",bsi[0]);
    bs+=20;
    
    // FLLR
    printf("\r");
    printf("\r");
    for (int i=0; i<4; i++) {
        printf("%c",bs[0]);
        bs++;
    }
    
    bsi = (int *)bs;
    printf("\r");
    printf("FLLR chunk size: %d",bsi[0]);
    bs+=4;
    bs+=4044;
    
    
    // data
    printf("\r");
    printf("\r");
    for (int i=0; i<4; i++) {
        printf("%c",bs[0]);
        bs++;
    }
    
    bsi = (int *)bs;
    printf("\r");
    printf("data chunk size: %d",bsi[0]);
}

+(BOOL)isIphoneX{
    BOOL isPhoneX = NO;
         if (@available(iOS 11.0, *)) {
             isPhoneX = [[UIApplication sharedApplication].windows firstObject].safeAreaInsets.bottom > 0.0;
        }
    return isPhoneX;
}

-(unsigned int)bytesOfCommonFormat:(AVAudioCommonFormat)format{
    switch (format) {
        case AVAudioPCMFormatInt16:
            return 2;
        case AVAudioPCMFormatInt32:
            return 4;
        case AVAudioPCMFormatFloat32:
            return 4;
        case AVAudioPCMFormatFloat64:
            return 8;
        default:
            assert(0);
            return 2;
    }
}

#pragma mark -
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"recorder dealloc");
}

#pragma mark -
+(NSTimeInterval)bgLatency{
    return [self isIphoneX] ? 0.17 : 0.20;
}
@end
