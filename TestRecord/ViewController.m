//
//  ViewController.m
//  TestRecord
//
//  Created by donbe on 2020/4/14.
//  Copyright © 2020 donbe. All rights reserved.
//

#import "ViewController.h"
#import "JYAudioRecorder.h"
#import <AVFoundation/AVFoundation.h>


//参数为数据，采样个数
static int simpleCalculate_DB(short* pcmData, long long sample)
{
    signed short ret = 0;
    if (sample > 0){
        int sum = 0;
        signed short* pos = (signed short *)pcmData;
        for (int i = 0; i < sample; i++){
            
            sum += abs(*pos);
            pos++;
        }
        ret = ((float)sum/(sample * 32767)) * 200.0;
        if (ret >= 50){
            ret = 50;
        }
        if (ret < 1) {
            ret = 1;
        }
    }
    return ret;
}


@interface ViewController ()<JYAudioRecorderDelegate>

@property(nonatomic,strong)JYAudioRecorder *recorder;
@property(nonatomic,strong)UIScrollView *scrollView;
@property(nonatomic)int waveformindex;

@property(nonatomic,strong)NSData *buff;

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 请求授权
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio] != AVAuthorizationStatusAuthorized) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            
        }];
    }
    
    
   
    
    [self addButtonWith:@"开始录音" frame:CGRectMake(80, 120, 100, 50) action:@selector(recordBtnAction)];
    [self addButtonWith:@"继续录音" frame:CGRectMake(200, 120, 100, 50) action:@selector(resumeBtnAction)];
    [self addButtonWith:@"停止录音" frame:CGRectMake(80, 190, 100, 50) action:@selector(stopBtnAction)];
    [self addButtonWith:@"从1秒开始" frame:CGRectMake(200, 190, 100, 50) action:@selector(recordFromTimeBtnAction)];
    [self addButtonWith:@"2秒截断" frame:CGRectMake(80, 260, 100, 50) action:@selector(truncateBtnAction)];
    
    [self addButtonWith:@"播放录音" frame:CGRectMake(80, 330, 100, 50) action:@selector(playBtnAction)];
    [self addButtonWith:@"停止播放" frame:CGRectMake(200, 330, 100, 50) action:@selector(stopPlayBtnAction)];
    [self addButtonWith:@"暂停播放" frame:CGRectMake(80, 400, 100, 50) action:@selector(pausePlayBtnAction)];
    [self addButtonWith:@"继续播放" frame:CGRectMake(200, 400, 100, 50) action:@selector(resumePlayBtnAction)];
    [self addButtonWith:@"2秒开播" frame:CGRectMake(80, 470, 100, 50) action:@selector(playattime)];
    
    [self addButtonWith:@"释放录音器" frame:CGRectMake(80, 540, 100, 50) action:@selector(releaseRecorder)];

    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 650, [[UIApplication sharedApplication].windows firstObject].frame.size.width, 50)];
    [self.view addSubview:self.scrollView];
    self.scrollView.backgroundColor = [UIColor cyanColor];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

-(void)resumeBtnAction{
    [self.recorder startRecordAtTime:self.recorder.recordDuration];
}

-(void)recordBtnAction{
//    self.recorder.maxRecordTime = 3;
//    self.recorder.bgmPath = [[[NSBundle mainBundle] URLForResource:@"output" withExtension:@"mp3"] relativePath];
//    self.recorder.bgmPlayOffset = 2.0;
//    self.recorder.bgmPlayLength = 2.0;
    [self.recorder startRecord];
}

-(void)stopBtnAction{
    [self.recorder stopRecord];
}

-(void)recordFromTimeBtnAction{
    [self.recorder startRecordAtTime:1];
}
-(void)truncateBtnAction{
    [self.recorder truncateFile:2];
}

-(void)playBtnAction{
    [self.recorder play];
}

-(void)stopPlayBtnAction{
    [self.recorder stopPlay];
}

-(void)pausePlayBtnAction{
    [self.recorder pausePlay];
}

-(void)resumePlayBtnAction{
    [self.recorder resumePlay];
}
-(void)releaseRecorder{
    self.recorder = nil;
}

-(void)playattime{
    [self.recorder playAtTime:2];
}

#pragma mark -
-(JYAudioRecorder *)recorder{
    if (_recorder == nil) {
        _recorder = [JYAudioRecorder new];
        _recorder.delegate = self;
    }
    return _recorder;
}

#pragma mark - private
- (void)addButtonWith:(NSString *)title frame:(CGRect)frame action:(SEL)action {
    UIButton *record = [[UIButton alloc] initWithFrame:frame];
    record.layer.borderColor = [UIColor blackColor].CGColor;
    record.layer.borderWidth = 0.5;
    [record setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [record setTitle:title forState:UIControlStateNormal];
    [record addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [record setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [self.view addSubview:record];
}

#pragma mark -
-(void)recorderStart{

    NSLog(@"开始录制");
}

-(void)recorderFinish{
    NSLog(@"结束录制");
}

-(void)recorderPlayingStart{
    NSLog(@"开始播放");
}

-(void)recorderPlayingFinish{
    NSLog(@"结束播放");
}

-(void)recorderBuffer:(AVAudioPCMBuffer *)buffer duration:(NSTimeInterval)duration{
    NSLog(@"recorderBuffer %f", duration);
    
    NSData *data  = [NSData dataWithBytes:buffer.int16ChannelData[0] length:buffer.frameLength];
    NSArray *dd = [ViewController pcmToAverageAmplitude:data];
    
    for (int i=0; i<[dd count]; i++) {
        
        UIView *waveunit = [[UIView alloc] initWithFrame:CGRectMake(_waveformindex, 50 - [dd[i] doubleValue], 0.5, [dd[i] doubleValue])];
        waveunit.tag = 100+_waveformindex;
        waveunit.backgroundColor = [UIColor blackColor];
        [self.scrollView addSubview:waveunit];
        
        _waveformindex ++;
    }
}


+ (NSArray*)pcmToAverageAmplitude:(NSData*)volumeData{
    
    NSMutableArray* array = [NSMutableArray array];
    Byte *dataByte = (Byte *)[volumeData bytes];
    NSInteger atime = 320; //320个byge计算一次？
    NSUInteger countSize = (volumeData.length)/atime;
    
    for (int i = 0; i < countSize; i++) {
        
        short bufferBytes[atime/2];
        memcpy(bufferBytes, &dataByte[i*atime], atime);//byte数据接收者，dataByte数据源，1000要copy的数据长度。
        double v = simpleCalculate_DB(bufferBytes,atime/2);
        [array addObject:[NSNumber numberWithDouble:v]];
    }
    return [array copy];
}

-(void)recorderPlayingTime:(NSTimeInterval)time duration:(NSTimeInterval)duration{
    NSLog(@"play time: %f / %f",time,duration);
}


-(void)recorderStateChange:(JYAudioRecorderState)state{
    NSLog(@"recorderStateChange:%ld",(long)state);
}
@end
