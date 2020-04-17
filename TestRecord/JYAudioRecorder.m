//
//  JYAudioRecorder.m
//  TestRecord
//
//  Created by donbe on 2020/4/13.
//  Copyright © 2020 donbe. All rights reserved.
//

#import "JYAudioRecorder.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>


static float backgroundVolume = 0.2;

@interface JYAudioRecorder()<AVAudioPlayerDelegate>

@property(nonatomic,strong)AVAudioEngine *audioEngine;
@property(nonatomic,strong)AVAudioMixerNode *audioMixerNode;
@property(nonatomic,strong)AVAudioPlayerNode *audioPlayerNode;

@property(nonatomic) AVAudioPlayer *audioPlayer;
@property(nonatomic) AVAudioPlayer *audioBGPlayer;

@property(nonatomic,strong)NSString *filePath;
@property(nonatomic,strong)NSString *fileBGPath;

@property(atomic)BOOL isRec;
@property(atomic)BOOL isPlaying;

@end

@implementation JYAudioRecorder

-(instancetype)init{
    self = [super init];
    if (self) {
        
        self.audioEngine = [AVAudioEngine new];
        self.audioPlayerNode = [AVAudioPlayerNode new];
        self.audioMixerNode = [AVAudioMixerNode new];
        
        [self.audioEngine attachNode:self.audioPlayerNode];
        [self.audioEngine attachNode:self.audioMixerNode];
        
    }
    return self;
}


#pragma mark -
-(void)startRecord{
    [self startRecordFromSection:0];
}

-(void)startRecordFromSection:(float)second{
    
    if (self.isRec || self.isPlaying) {
        return;
    }
    self.isRec = YES;
    NSLog(@"begin record");
    
    
    // 设置AVAudioSession
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord mode:AVAudioSessionModeSpokenAudio options:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    assert(error == nil);
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    assert(error == nil);
    
    
    // 创建播放文件
    AVAudioFile *audiofile = [[AVAudioFile alloc] initForReading:[NSURL URLWithString:self.fileBGPath] error:&error];
    assert(error == nil);
    
    
    // 连接node
    [self.audioEngine connect:self.audioPlayerNode to:self.audioEngine.mainMixerNode format:audiofile.processingFormat];
    
    
    // 存储文件路径
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    self.filePath =  [dir stringByAppendingString:@"/temp2.wav"];

    
    // 存储的文件格式
    AVAudioFormat *formatOut = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16 sampleRate:16000 channels:1 interleaved:true];
    
    // 计算从多少byte开始截断
    UInt32 truncateByte = 0;
    switch (formatOut.commonFormat) {
        case AVAudioPCMFormatInt16:
            truncateByte = (UInt32)(second * formatOut.sampleRate * formatOut.channelCount * 2);
            break;
        case AVAudioPCMFormatInt32:
            truncateByte = (UInt32)(second * formatOut.sampleRate * formatOut.channelCount * 4);
            break;
        case AVAudioPCMFormatFloat32:
            truncateByte = (UInt32)(second * formatOut.sampleRate * formatOut.channelCount * 5);
            break;
        case AVAudioPCMFormatFloat64:
            truncateByte = (UInt32)(second * formatOut.sampleRate * formatOut.channelCount * 8);
            break;
        default:
            assert(0);
            break;
    }
    
    
    // 打开文件，处理截断
    AudioFileID fileID;
    {
        char buf[truncateByte];
        UInt32 pos = truncateByte;
        if (truncateByte>0) {
            OSStatus stats = AudioFileOpenURL((__bridge CFURLRef)[NSURL URLWithString:self.filePath], kAudioFileReadPermission, kAudioFileWAVEType, &fileID);
            assert(stats==0);
            AudioFileReadBytes(fileID, NO, 0, &pos, buf);
            AudioFileClose(fileID);
        }
        
        // 重新创建文件
        OSStatus stats = AudioFileCreateWithURL((__bridge CFURLRef)[NSURL URLWithString:self.filePath], kAudioFileWAVEType, formatOut.streamDescription, kAudioFileFlags_EraseFile, &fileID);
        assert(stats==0);
        
        // 重新写入需要保留的部分
        if (truncateByte > 0) {
            AudioFileWriteBytes(fileID, NO, 0, &pos, buf);
        }
    }
    
    
    // 创建格式转换器
    AVAudioConverter *audioConverter = [[AVAudioConverter alloc] initFromFormat:[self.audioEngine.inputNode outputFormatForBus:0] toFormat:formatOut];

    
    // 安装tap
    __block SInt64 inStartingByte = truncateByte;
    [self.audioEngine.inputNode installTapOnBus:0 bufferSize:2048 format:nil block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {

        
        // 进行格式换砖
        float ratio = [[buffer format] sampleRate]/formatOut.sampleRate;
        UInt32 capacity = buffer.frameCapacity/ratio;
        AVAudioPCMBuffer *convertedBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:formatOut frameCapacity:capacity];
        AVAudioConverterInputBlock inputBlock = ^(AVAudioPacketCount inNumberOfPackets, AVAudioConverterInputStatus* outStatus){
            *outStatus = AVAudioConverterInputStatus_HaveData;
            return buffer;
        };
        [audioConverter convertToBuffer:convertedBuffer error:nil withInputFromBlock:inputBlock];
        

        // 写文件
        UInt32 length = convertedBuffer.frameLength * 2;
        OSStatus status = AudioFileWriteBytes(fileID, NO, inStartingByte, &length, convertedBuffer.int16ChannelData[0]);
        assert(status == noErr);
        inStartingByte += length;
        
        
        NSLog(@"%lld", inStartingByte / 2);
        
    }];
    
    
    // 播放设置
    [self.audioPlayerNode scheduleSegment:audiofile startingFrame:0 frameCount:(AVAudioFrameCount)[audiofile length] atTime:nil completionHandler:^{
        AudioFileClose(fileID);
        NSLog(@"player complete");
        
    }];
    
  
    // 启动引擎
    BOOL result = [self.audioEngine startAndReturnError:&error];
    assert(error == nil);
    assert(result);
    
    
    // 开始播放
    self.audioPlayerNode.volume = backgroundVolume;
    [self.audioPlayerNode play];
    
}

-(void)stopRecord{
    if (self.isRec) {
        
        [self.audioPlayerNode stop];
        [self.audioEngine stop];
        
        [self.audioEngine.inputNode removeTapOnBus:0];
        
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        
        self.isRec = NO;
        NSLog(@"stoped record");
    }
}


#pragma mark -
-(NSString *)fileBGPath{
    if (_fileBGPath == nil) {
        _fileBGPath = [[[NSBundle mainBundle] URLForResource:@"1" withExtension:@"mp3"] relativePath];
    }
    return _fileBGPath;
}
#pragma  mark -
-(void)stopPlay{
    if (self.isPlaying) {
        
        [[AVAudioSession sharedInstance] setActive:NO error:nil];
        [self.audioPlayer stop];
        [self.audioBGPlayer stop];
        
        self.isPlaying = NO;
        NSLog(@"stoped play");
    }
}

-(void)play{
    
//    [self print_wav_head_info];
//    return;
     
    if (self.isPlaying || self.isRec) {
        return;
    }

    if (self.filePath == nil) {
        return;
    }
    
    self.isPlaying = YES;
    NSLog(@"begin play");

    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    assert(error == nil);

    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    assert(error == nil);
    
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:self.filePath] error:&error];
    assert(error == nil);
    
    self.audioBGPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:self.fileBGPath] error:&error];
    assert(error == nil);
    
    
    self.audioPlayer.delegate = self;
    self.audioBGPlayer.delegate = self;
    
    self.audioBGPlayer.volume = backgroundVolume;
    
    [self.audioPlayer play];
    [self.audioBGPlayer play];
    
}

#pragma mark - AVAudioPlayerDelegate
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    NSLog(@"audioPlayerDidFinishPlaying");
    if (player == self.audioPlayer) {
        [self.audioBGPlayer stop];
        self.isPlaying = NO;
    }
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error{
    NSLog(@"audioPlayerDecodeErrorDidOccur");
    if (player == self.audioPlayer) {
        [self.audioBGPlayer stop];
        self.isPlaying = NO;
    }
}


#pragma mark - help
-(void)print_wav_head_info{
    
    NSData *d = [[NSFileManager defaultManager] contentsAtPath:self.filePath];
    
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

@end
