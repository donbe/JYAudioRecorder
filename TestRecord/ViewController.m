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
    
    // 请求授权
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio] != AVAuthorizationStatusAuthorized) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            
        }];
    }
    
    [super viewDidLoad];
    UIButton *record = [[UIButton alloc] initWithFrame:CGRectMake(80, 120, 100, 50)];
    record.layer.borderColor = [UIColor blackColor].CGColor;
    record.layer.borderWidth = 0.5;
    [record setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [record setTitle:@"开始录音" forState:UIControlStateNormal];
    [record addTarget:self action:@selector(recordBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [record setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [self.view addSubview:record];
    
    UIButton *stop = [[UIButton alloc] initWithFrame:CGRectMake(200, 120, 100, 50)];
    stop.layer.borderColor = [UIColor blackColor].CGColor;
    stop.layer.borderWidth = 0.5;
    [stop setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [stop setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [stop setTitle:@"停止录音" forState:UIControlStateNormal];
    [stop addTarget:self action:@selector(stopBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stop];
    
    UIButton *pause = [[UIButton alloc] initWithFrame:CGRectMake(80, 190, 100, 50)];
    pause.layer.borderColor = [UIColor blackColor].CGColor;
    pause.layer.borderWidth = 0.5;
    [pause setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [pause setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [pause setTitle:@"从1秒开始" forState:UIControlStateNormal];
    [pause addTarget:self action:@selector(pauseBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pause];
    
    UIButton *play = [[UIButton alloc] initWithFrame:CGRectMake(200, 190, 100, 50)];
    play.layer.borderColor = [UIColor blackColor].CGColor;
    play.layer.borderWidth = 0.5;
    [play setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [play setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [play setTitle:@"播放录音" forState:UIControlStateNormal];
    [play addTarget:self action:@selector(playBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:play];
    
    UIButton *stopplay = [[UIButton alloc] initWithFrame:CGRectMake(80, 260, 100, 50)];
    stopplay.layer.borderColor = [UIColor blackColor].CGColor;
    stopplay.layer.borderWidth = 0.5;
    [stopplay setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [stopplay setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [stopplay setTitle:@"停止播放" forState:UIControlStateNormal];
    [stopplay addTarget:self action:@selector(stopplayBtnAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopplay];
}

-(void)recordBtnAction{
    [self.recorder startRecord];
}

-(void)stopBtnAction{
    [self.recorder stopRecord];
}

-(void)pauseBtnAction{
    [self.recorder startRecordFromSection:1];
}

-(void)playBtnAction{
    [self.recorder play];
}

-(void)stopplayBtnAction{
    [self.recorder stopPlay];
}


#pragma mark -
-(JYAudioRecorder *)recorder{
    if (_recorder == nil) {
        _recorder = [JYAudioRecorder new];
    }
    return _recorder;
}


@end
