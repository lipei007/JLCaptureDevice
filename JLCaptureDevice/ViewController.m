//
//  ViewController.m
//  JLCaptureDevice
//
//  Created by jack lee on 2017/11/17.
//  Copyright © 2017年 mini1. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIButton *CameraPositionChangeBtn;
@property (strong, nonatomic) IBOutlet UIButton *takeBtn;
@property (strong, nonatomic) IBOutlet UIView *controlView;
@property (strong, nonatomic) IBOutlet UISwitch *switchBtn;

@property (nonatomic,strong) UIView *contentView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view addSubview:self.contentView];
    
    self.mode = JLCaptureModeRecordMovie;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [UIColor clearColor];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        [_contentView addGestureRecognizer:tap];
        
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
        [_contentView addGestureRecognizer:pinch];
    }
    return _contentView;
}

#pragma mark - Btn Action

- (IBAction)changeCameraClick:(UIButton *)sender {
    
    [self changeCaptureDevice];
    
}

- (IBAction)takePressed:(UIButton *)sender {
    
    if (self.mode == JLCaptureModeTakePicture) {
        [self takePicture];
    } else if (self.mode == JLCaptureModeRecordMovie) {
        if (self.isRecordingMovie) {
            [self stopRecordMovie];
        } else if (!self.isRecordingMovie) {
            [self startRecordMovie];
        }
    }
}

- (IBAction)flashAuto:(UIButton *)sender {
    [self setFlashMode:AVCaptureFlashModeAuto];
}
- (IBAction)flashOn:(UIButton *)sender {
    [self setFlashMode:AVCaptureFlashModeOn];
}
- (IBAction)flashOff:(UIButton *)sender {
    [self setFlashMode:AVCaptureFlashModeOff];
}

- (void)tap:(UITapGestureRecognizer *)tap {
    
    CGPoint point = [tap locationInView:self.contentView];
    [self forcusAtPoint:point];
    
}

- (void)pinch:(UIPinchGestureRecognizer *)pinch {
    
    CGPoint point = [pinch locationInView:self.contentView];
    
    [self pinchAtPoint:point withScaleFactor:pinch.scale];
    
    pinch.scale = 1;
    
}
@end
