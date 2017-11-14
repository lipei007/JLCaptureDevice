//
//  ViewController.m
//  JLCaptureDevice
//
//  Created by Jack on 2017/2/28.
//  Copyright © 2017年 Emerys. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVCaptureFileOutputRecordingDelegate>

@property (strong, nonatomic) IBOutlet UIButton *CameraPositionChangeBtn;
@property (strong, nonatomic) IBOutlet UIButton *takeBtn;
@property (strong, nonatomic) IBOutlet UIView *controlView;
@property (strong, nonatomic) IBOutlet UISwitch *switchBtn;

#pragma mark - Capture
@property (nonatomic,strong) AVCaptureSession *captureSession;
@property (nonatomic,strong) AVCaptureDevice *captureDevice;
@property (nonatomic,strong) AVCaptureDeviceInput *captureInput;///<从device获取数据
@property (nonatomic,strong) AVCaptureDeviceInput *audioInput;///<音频输入
@property (nonatomic,strong) AVCaptureMovieFileOutput *fileOutput;///<视频输出
@property (nonatomic,strong) AVCaptureStillImageOutput *imageOutput;///<照片输出

#pragma mark - View
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic,strong) UIView *contentView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self initCamera];
    
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetMinY(self.controlView.frame));
    
    self.previewLayer.frame = frame;
    self.contentView.frame = frame;
    
    [self.view.layer addSublayer:self.previewLayer];

    [self.view addSubview:self.contentView];
    
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetMinY(self.controlView.frame));
    
    self.previewLayer.frame = frame;
    self.contentView.frame = frame;
    
    AVCaptureConnection *captureConnection=[self.previewLayer connection];
    captureConnection.videoOrientation=(AVCaptureVideoOrientation)toInterfaceOrientation;
    
}

#pragma mark - Capture

/**
 获取摄像头

 @param position 摄像头位置
 @return 摄像头
 */
- (AVCaptureDevice *) videoDevicePosition:(AVCaptureDevicePosition)position {
//#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in videoDevices) {
        if ([device position] == position) {
            return device;
        }
    }
//#endif
    
    return nil;
}

#pragma mark Set Property

- (void)setCaptureDeviceProperty:(void(^)(AVCaptureDevice *device))block {
    AVCaptureDevice *device = [self.captureInput device];
    NSError *error;
    [self.captureSession beginConfiguration];
    if ([device lockForConfiguration:&error]) {
        block(device);
        [device unlockForConfiguration];
    } else {
        NSLog(@"change device property error: %@",error.localizedDescription);
    }
    [self.captureSession commitConfiguration];
}

/**
 设置对焦模式

 @param focusMode 对焦模式
 */
- (void)setFocusMode:(AVCaptureFocusMode)focusMode {
    [self setCaptureDeviceProperty:^(AVCaptureDevice *device) {
       
        if ([device isFocusModeSupported:focusMode]) {
            [device setFocusMode:focusMode];
        }
        
    }];
}


/**
 设置焦点

 @param point 焦点
 */
- (void)setFocusPoint:(CGPoint)point {
    __weak typeof(self) weakself = self;
    [self setCaptureDeviceProperty:^(AVCaptureDevice *device) {
        
        [weakself setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        
        if ([device isFocusPointOfInterestSupported]) {
            [device setFocusPointOfInterest:point];
        }
        
        [weakself setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        [weakself setExposurePoint:point];
        
    }];
}


/**
 设置曝光模式

 @param exposureMode 曝光模式
 */
- (void)setExposureMode:(AVCaptureExposureMode)exposureMode {
    
    [self setCaptureDeviceProperty:^(AVCaptureDevice *device) {
        if ([device isExposureModeSupported:exposureMode]) {
            [device setExposureMode:exposureMode];
        }
    }];
    
}


/**
 设置曝光点

 @param point 曝光点
 */
- (void)setExposurePoint:(CGPoint)point {
    [self setCaptureDeviceProperty:^(AVCaptureDevice *device) {
        if ([device isExposurePointOfInterestSupported]) {
            [device setExposurePointOfInterest:point];
        }
    }];
}

/**
 设置焦点光标位置
 
 @param curPosition 焦点光标位置
 */
- (void)setFocusCurPosition:(CGPoint)curPosition {
    
}

/**
 设置闪光模式

 @param flashMode 闪光模式
 */
- (void)setFlashMode:(AVCaptureFlashMode)flashMode {
    [self setCaptureDeviceProperty:^(AVCaptureDevice *device) {
        if ([device isFlashModeSupported:flashMode]) {
            [device setFlashMode:flashMode];
        }
    }];
}

- (BOOL)hasFlash {
    return self.captureDevice.hasFlash;
}


/**
 设置白平衡

 @param whiteBalanceMode 白平衡模式
 */
- (void)setWhiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode {
    [self setCaptureDeviceProperty:^(AVCaptureDevice *device) {
        if ([device isWhiteBalanceModeSupported:whiteBalanceMode]) {
            [device setWhiteBalanceMode:whiteBalanceMode];
        }
    }];
}


/**
 设置手电筒模式

 @param torchMode 手电筒模式
 */
- (void)setTorchMode:(AVCaptureTorchMode)torchMode {
    [self setCaptureDeviceProperty:^(AVCaptureDevice *device) {
        if ([device isTorchModeSupported:torchMode]) {
            [device setTorchMode:torchMode];
        }
    }];
}

- (BOOL)hasTorch {
    return self.captureDevice.hasTorch;
}

- (BOOL)torchAvailableNow {
    return self.captureDevice.torchAvailable;
}

- (BOOL)torchActiveNow {
    return self.captureDevice.torchActive;
}

#pragma mark Authorization

- (BOOL)authorizeMediaType:(NSString *)mediaType {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    switch (status) {
        case AVAuthorizationStatusNotDetermined: { // 还没确定
            return NO;
        }
            break;
        case AVAuthorizationStatusDenied: { // 被拒绝
            return NO;
        }
            break;
        case AVAuthorizationStatusRestricted: { // 受限制，如家长控制
            return NO;
        }
            break;
        case AVAuthorizationStatusAuthorized: { // 已经被授权
            return YES;
        }
            break;
            
        default:
            break;
    }
    return NO;
}

- (BOOL)cameraAuthorization {
    return [self authorizeMediaType:AVMediaTypeVideo];
}

- (BOOL)audioAuthorization {
    return [self authorizeMediaType:AVMediaTypeAudio];
}

#pragma mark - Init

- (void)initCamera {
    
    // session
    _captureSession = [[AVCaptureSession alloc] init];
    
    // device
    _captureDevice = [self videoDevicePosition:AVCaptureDevicePositionBack];

    if (!_captureDevice) {
        NSLog(@"no back camera");
        return;
    }
    
    NSError *error;
    //添加一个音频输入设备
    AVCaptureDevice * audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    _audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"audio device error：%@",error.localizedDescription);
        return;
    }
    
    // 根据输入设备初始化设备输入对象，用于获得输入数据
    _captureInput = [[AVCaptureDeviceInput alloc]initWithDevice:_captureDevice error:&error];
    if (error) {
        NSLog(@"input error：%@",error.localizedDescription);
        return;
    }
    
    _fileOutput = [[AVCaptureMovieFileOutput alloc] init];
    
    // 初始化设备输出对象，用于获得输出数据
    _imageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary * outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    // 输出设置
    [_imageOutput setOutputSettings:outputSettings];
    
    // 将设备输入添加到会话中
    if ([_captureSession canAddInput:_captureInput]) {
        
        [_captureSession addInput:_captureInput];
        [_captureSession addInput:_audioInput];
        
        AVCaptureConnection * captureConnection = [_fileOutput connectionWithMediaType:AVMediaTypeVideo];

        if ([captureConnection isVideoStabilizationSupported]) {
            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
    }
    
    // 将设输出添加到会话中
    if ([_captureSession canAddOutput:_imageOutput]) {
        [_captureSession addOutput:_imageOutput];
    }
    
    if ([_captureSession canAddOutput:_fileOutput]) {
        [_captureSession addOutput:_fileOutput];
    }
    
    // Init PreviewLayer
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_captureSession startRunning];
}

#pragma mark - File Output Recording Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    NSLog(@"start recording");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    NSLog(@"finish recording");
    if (!error) {
        [self performSelector:@selector(saveVideoAtURL:) withObject:outputFileURL afterDelay:5];
    }
}

- (void)saveVideoAtURL:(NSURL *)url {
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.absoluteString)) {
        UISaveVideoAtPathToSavedPhotosAlbum(url.absoluteString,self,@selector(video:didFinishSavingWithError:contextInfo:),nil);
    }
}

// save video complete selector
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"save video error: %@",error);
    }
}

#pragma mark - Btn Action

- (IBAction)changeCameraClick:(UIButton *)sender {
    
    AVCaptureDevice * currentDevice = [self.captureInput device];
    AVCaptureDevicePosition currentPosition = [currentDevice position];

    AVCaptureDevice * toChangeDevice;
    AVCaptureDevicePosition  toChangePosition = AVCaptureDevicePositionFront;
    if (currentPosition==AVCaptureDevicePositionUnspecified||currentPosition==AVCaptureDevicePositionFront) {
        toChangePosition = AVCaptureDevicePositionBack;
    } else {
        toChangePosition = AVCaptureDevicePositionFront;
    }
    toChangeDevice = [self videoDevicePosition:toChangePosition];

    
    //获得要调整到设备输入对象
    AVCaptureDeviceInput * toChangeDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
    
    //改变会话到配置前一定要先开启配置，配置完成后提交配置改变
    [self.captureSession beginConfiguration];
    //移除原有输入对象
    [self.captureSession removeInput:self.captureInput];
    //添加新的输入对象
    if ([self.captureSession canAddInput:toChangeDeviceInput]) {
        [self.captureSession addInput:toChangeDeviceInput];
        self.captureInput=toChangeDeviceInput;
    }
    
    //提交新的输入对象
    [self.captureSession commitConfiguration];

}

- (IBAction)takePressed:(UIButton *)sender {
    
    if (self.switchBtn.on) {
        if ([self.fileOutput isRecording]) {
            
            [self.fileOutput stopRecording];
            
        } else {
            //根据设备输出获得连接
            AVCaptureConnection *captureConnection=[self.fileOutput connectionWithMediaType:AVMediaTypeVideo];
            
            //预览图层和视频方向保持一致
            captureConnection.videoOrientation=[self.previewLayer connection].videoOrientation;
            
            // 根据时间设置视频名称
            NSDate *date = [NSDate date];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"YYYYMMDDHHmmss";
            NSString *name = [formatter stringFromDate:date];
            NSString *dir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
            NSString *outputFielPath=[dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",name]];
            
            NSURL *fileUrl=[NSURL fileURLWithPath:outputFielPath];
            [self.fileOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
        }
    } else {
        // 拍照
        //根据设备输出获得连接
        AVCaptureConnection *captureConnection=[self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
        //根据连接取得设备输出的数据
        [self.imageOutput captureStillImageAsynchronouslyFromConnection:captureConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            if (imageDataSampleBuffer) {
                NSData *imageData=[AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                UIImage *image=[UIImage imageWithData:imageData];
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
                
            }
            
        }];
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
    
    CGPoint capturePoint = [self.previewLayer captureDevicePointOfInterestForPoint:point];
    
    // 先设置点再设置模式
    [self setFocusPoint:capturePoint];
    [self setFocusMode:AVCaptureFocusModeAutoFocus];
    
    // 曝光要根据对焦点的光线状况而决定,所以和对焦一块写
    [self setExposurePoint:capturePoint];
    [self setExposureMode:AVCaptureExposureModeAutoExpose];
    
    // 白平衡
    [self setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
}

- (void)pinch:(UIPinchGestureRecognizer *)pinch {
    
    CGPoint point = [pinch locationInView:self.contentView];
    
    CGPoint capturePoint = [self.previewLayer captureDevicePointOfInterestForPoint:point];
    
    
    

    
    AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    CGFloat cropFactor = connection.videoScaleAndCropFactor * pinch.scale;

    if (cropFactor < 1.0) {
        cropFactor = 1.0;
    }
    
    if (cropFactor > connection.videoMaxScaleAndCropFactor) {
        cropFactor = connection.videoMaxScaleAndCropFactor;
    }
    
    connection.videoScaleAndCropFactor = cropFactor;
    
    self.previewLayer.affineTransform = CGAffineTransformScale(self.previewLayer.affineTransform, pinch.scale, pinch.scale);

    
    
    // 先设置点再设置模式
    [self setFocusPoint:capturePoint];
    [self setFocusMode:AVCaptureFocusModeAutoFocus];
    
    // 曝光要根据对焦点的光线状况而决定,所以和对焦一块写
    [self setExposurePoint:capturePoint];
    [self setExposureMode:AVCaptureExposureModeAutoExpose];
    
    // 白平衡
    [self setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
    
    
    pinch.scale = 1;
    
}



@end
