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

@interface ViewController ()
@property(nonatomic,strong)JYAudioRecorder *recorder;
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
    [self addButtonWith:@"停止录音" frame:CGRectMake(200, 120, 100, 50) action:@selector(stopBtnAction)];
    [self addButtonWith:@"从1秒开始" frame:CGRectMake(80, 190, 100, 50) action:@selector(recordFromTimeBtnAction)];
    [self addButtonWith:@"播放录音" frame:CGRectMake(200, 190, 100, 50) action:@selector(playBtnAction)];
    [self addButtonWith:@"停止播放" frame:CGRectMake(80, 260, 100, 50) action:@selector(stopPlayBtnAction)];
    [self addButtonWith:@"暂停播放" frame:CGRectMake(200, 260, 100, 50) action:@selector(pausePlayBtnAction)];
    [self addButtonWith:@"继续播放" frame:CGRectMake(200, 330, 100, 50) action:@selector(resumePlayBtnAction)];

}

-(void)recordBtnAction{
    self.recorder.fileBGPath = [[[NSBundle mainBundle] URLForResource:@"output" withExtension:@"mp3"] relativePath];
    [self.recorder startRecord];
}

-(void)stopBtnAction{
    [self.recorder stopRecord];
}

-(void)recordFromTimeBtnAction{
    [self.recorder startRecordFromTime:1];
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

#pragma mark -
-(JYAudioRecorder *)recorder{
    if (_recorder == nil) {
        _recorder = [JYAudioRecorder new];
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

@end
