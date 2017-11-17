//
//  ViewController.m
//  JLCaptureDevice
//
//  Created by Jack on 2017/2/28.
//  Copyright © 2017年 Emerys. All rights reserved.
//

#import "JLCaptureViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>



typedef enum {
    JLStatusStop,
    JLStatusRecording
}JLStatus;

@interface JLCaptureViewController ()<AVCaptureFileOutputRecordingDelegate>
{
    UIView *_previewContainer;
}

#pragma mark - Capture
@property (nonatomic,strong) AVCaptureSession *captureSession;
@property (nonatomic,strong) AVCaptureDevice *captureDevice;
@property (nonatomic,strong) AVCaptureDeviceInput *captureInput;///<从device获取数据
@property (nonatomic,strong) AVCaptureDeviceInput *audioInput;///<音频输入
@property (nonatomic,strong) AVCaptureMovieFileOutput *fileOutput;///<视频输出
@property (nonatomic,strong) AVCaptureStillImageOutput *imageOutput;///<照片输出

@property (nonatomic,assign) JLStatus recordStatus;

#pragma mark - View
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation JLCaptureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 1 初始化相机
    [self initCamera];
    // 2 初始化UI
    [self setupUI];
    // 3 设置默认模式
    self.mode = JLCaptureModeTakePicture;

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.captureSession.isRunning) {
        [self.captureSession startRunning];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self stopRecordMovie];
    
    if (self.captureSession.isRunning) {
        
        [self.captureSession stopRunning];
    }
    
}

- (void)setupUI {
    
    _previewContainer = [self containerViewForPreviewLayer];
    if (_previewContainer == nil) {
        _previewContainer = self.view;
    } else {
        // 自己返回的就是self.view
        if (self.view != _previewContainer) {
            [self.view addSubview:_previewContainer];
            [self.view sendSubviewToBack:_previewContainer];
        }
    }
    self.previewLayer.frame = _previewContainer.bounds;
    [_previewContainer.layer addSublayer:self.previewLayer];
    // 避免从Nib加载ViewController PreviewLayer在最顶层遮挡住下面控件
    if (_previewContainer == self.view) {
        [_previewContainer.layer insertSublayer:self.previewLayer atIndex:0];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
    self.previewLayer.frame = _previewContainer.bounds;
    // 调整方向
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

- (void)initRecordMovie {
    
    // 移除图像输出
    if (_imageOutput && [_captureSession.outputs containsObject:_imageOutput]) {
        [_captureSession removeOutput:_imageOutput];
    }
    
    NSError *error;
    // 初始化音频
    if (!_audioInput) {
        AVCaptureDevice * audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
        _audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:&error];
        if (error) {
            NSLog(@"audio device error：%@",error.localizedDescription);
            return;
        }
    }
    // 初始化视频输出
    if (!_fileOutput) {
        _fileOutput = [[AVCaptureMovieFileOutput alloc] init];
    }
    
    // 添加音频输入
    if ([_captureSession canAddInput:_audioInput]) {
        [_captureSession addInput:_audioInput];
    } else {
        NSLog(@"init audio failed");
    }
    // 添加MovieFile输出
    if ([_captureSession canAddOutput:_fileOutput]) {
        [_captureSession addOutput:_fileOutput];
    } else {
        NSLog(@"init to record movie false");
        return;
    }
    
    // 默认值就是10秒。解决超出10s时长的视频无声音
    _fileOutput.movieFragmentInterval = kCMTimeInvalid;
    
    //根据设备输出获得连接
    AVCaptureConnection *captureConnection=[self.fileOutput connectionWithMediaType:AVMediaTypeVideo];
    
    //预览图层和视频方向保持一致
    if (captureConnection.isVideoOrientationSupported) {
        captureConnection.videoOrientation=[self.previewLayer connection].videoOrientation;
    }
    if ([captureConnection isVideoStabilizationSupported]) { // 防抖
        captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }

    [self configureMovieVar:self.fileOutput];
    [self addMetaDataForMovieOutputFile:self.fileOutput];
}

- (void)initTakePicture {
    // 移除视频输出
    if (_fileOutput && [_captureSession.outputs containsObject:_fileOutput]) {
        [_captureSession removeOutput:_fileOutput];
    }
    // 移除音频输入
    if (_audioInput && [_captureSession.inputs containsObject:_audioInput]) {
        [_captureSession removeInput:_audioInput];
    }
    
    // 初始化设备输出对象，用于获得输出数据
    if (!_imageOutput) {
        _imageOutput = [[AVCaptureStillImageOutput alloc] init];
    }
    
    AVCaptureConnection *connection = [_imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (connection.supportsVideoOrientation) {
        connection.videoOrientation = [self.previewLayer connection].videoOrientation;
    }
    
    // 设置图形输出格式
    NSDictionary * outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    // 输出设置
    [_imageOutput setOutputSettings:outputSettings];
    
    // 将设输出添加到会话中
    if ([_captureSession canAddOutput:_imageOutput]) {
        [_captureSession addOutput:_imageOutput];
    } else {
        NSLog(@"can't add image output");
    }
}

- (void)initCamera {

    // session
    _captureSession = [[AVCaptureSession alloc] init];

//    // device
//    if (!_captureDevice) {
//        _captureDevice = [self videoDevicePosition:AVCaptureDevicePositionBack];
//        if (!_captureDevice) {
//            NSLog(@"no back camera");
//            return;
//        }
//    }
//    // 初始化图像输入
//    NSError *error;
//    // 根据输入设备初始化设备输入对象，用于获得输入数据
//    _captureInput = [[AVCaptureDeviceInput alloc] initWithDevice:_captureDevice error:&error];
//    if (error) {
//        NSLog(@"input error：%@",error.localizedDescription);
//        return;
//    }
//    // 将设备输入添加到会话中
//    if ([_captureSession canAddInput:_captureInput]) {
//
//        [_captureSession addInput:_captureInput];
//
//        // 设置图形采集质量，在设置Input之后。切换Input之前重置采集质量
//        if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
//            _captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
//        } else {
//            if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
//                _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
//            }
//        }
//
//    } else {
//        NSLog(@"can't add capture input");
//    }

    [self changeCaptureDevice];

    // Init PreviewLayer
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_captureSession startRunning];
}

#pragma mark - Change Device Or Mode

- (void)changeCaptureDevice {
    if (self.mode == JLCaptureModeRecordMovie && self.recordStatus == JLStatusRecording) {
        [self stopRecordMovie];
    }

    AVCaptureDevice *currentDevice = nil;
    AVCaptureDevicePosition currentPosition = AVCaptureDevicePositionUnspecified;
    if (self.captureInput != nil) {
        currentDevice = [self.captureInput device];
        currentPosition = [currentDevice position];
    } else {
        currentPosition = AVCaptureDevicePositionUnspecified;
    }

    AVCaptureDevice * toChangeDevice;
    AVCaptureDevicePosition  toChangePosition = AVCaptureDevicePositionFront;
    if (currentPosition==AVCaptureDevicePositionUnspecified||currentPosition==AVCaptureDevicePositionFront) {
        toChangePosition = AVCaptureDevicePositionBack;
    } else {
        toChangePosition = AVCaptureDevicePositionFront;
    }
    toChangeDevice = [self videoDevicePosition:toChangePosition];
    if (toChangeDevice == nil) {
        NSLog(@"change device failed with no device");
        return;
    }

    //获得要调整到设备输入对象
    NSError *error;
    AVCaptureDeviceInput * toChangeDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:toChangeDevice error:&error];
    if (error) {
        NSLog(@"change camera error: %@",error);
        return;
    }

    //改变会话到配置前一定要先开启配置，配置完成后提交配置改变
    [self.captureSession beginConfiguration];

    // 设置图形采集质量，在设置Input之后。切换Input之前重置采集质量
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    }
    //移除原有输入对象
    if (self.captureInput) {
        [self.captureSession removeInput:self.captureInput];
    }
    //添加新的输入对象
    if ([self.captureSession canAddInput:toChangeDeviceInput]) {
        

        [self.captureSession addInput:toChangeDeviceInput];
        self.captureInput=toChangeDeviceInput;

        //
        _captureDevice = toChangeDevice;
        
        // 设置图形采集质量，在设置Input之后。切换Input之前重置采集质量
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
            _captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
        } else {
            if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
                _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
            }
        }
        
    } else {
        NSLog(@"can't add capture input");
        if (self.captureInput) {
            // 恢复原来输入
            if ([self.captureSession canAddInput:self.captureInput]) {
                [self.captureSession addInput:self.captureInput];
            }
        }
        // 设置图形采集质量，在设置Input之后。切换Input之前重置采集质量
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
            _captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
        } else {
            if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
                _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
            }
        }
    }

    //提交新的输入对象
    [self.captureSession commitConfiguration];
    
}

- (void)changeMode {
    if (self.mode == JLCaptureModeRecordMovie) {
        [self stopRecordMovie];
        self.mode = JLCaptureModeTakePicture;
    } else if (self.mode == JLCaptureModeTakePicture) {
        self.mode = JLCaptureModeRecordMovie;
    }
}

- (void)setMode:(JLCaptureMode)mode {
    _mode = mode;
    if (mode == JLCaptureModeTakePicture) {
        [self initTakePicture];
    } else {
        [self initRecordMovie];
    }
}

#pragma mark - Take Picture Or Record

- (void)startRecordMovie {
    if (self.mode == JLCaptureModeTakePicture) {
        return;
    }
    
//    [self initRecordMovie];
    
    NSURL *fileUrl=[NSURL fileURLWithPath:[self movieOutputPath]];
    [self.fileOutput startRecordingToOutputFileURL:fileUrl recordingDelegate:self];
}

- (void)stopRecordMovie {
    if (self.mode == JLCaptureModeTakePicture) {
        return;
    }
    if ([self.fileOutput isRecording]) {
        [self.fileOutput stopRecording];
    }
}

- (void)takePicture {
    if (self.mode == JLCaptureModeRecordMovie) {
        return;
    }
    
    /**
     * 提前初始化Output，若此时初始化Output，会导致刚启动时（后置摄像头）拍照错误。
     * 切换镜头后正常
    */
//    [self initTakePicture];
    
    // 拍照
    //根据设备输出获得连接
    AVCaptureConnection *captureConnection=[self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    //根据连接取得设备输出的数据
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:captureConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        if (imageDataSampleBuffer) {
            NSData *imageData=[AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image=[UIImage imageWithData:imageData];
            [self capturedImage:image];
        } else {
            NSLog(@"take picture failed: %@",error);
        }
        
    }];
}

- (void)forcusAtPoint:(CGPoint)point {
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

- (void)pinchAtPoint:(CGPoint)point withScaleFactor:(float)scale {
    
    CGPoint capturePoint = [self.previewLayer captureDevicePointOfInterestForPoint:point];
    
    AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    
    CGFloat cropFactor = connection.videoScaleAndCropFactor * scale;
    
    if (cropFactor < 1.0) {
        cropFactor = 1.0;
    }
    
    if (cropFactor > connection.videoMaxScaleAndCropFactor) {
        cropFactor = connection.videoMaxScaleAndCropFactor;
    }
    
    connection.videoScaleAndCropFactor = cropFactor;
    
    self.previewLayer.affineTransform = CGAffineTransformScale(self.previewLayer.affineTransform, scale, scale);
    
    // 先设置点再设置模式
    [self setFocusPoint:capturePoint];
    [self setFocusMode:AVCaptureFocusModeAutoFocus];
    
    // 曝光要根据对焦点的光线状况而决定,所以和对焦一块写
    [self setExposurePoint:capturePoint];
    [self setExposureMode:AVCaptureExposureModeAutoExpose];
    
    // 白平衡
    [self setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
}

#pragma mark - File Output Recording Delegate

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    NSLog(@"start recording");
    self.recordStatus = JLStatusRecording;
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    
    NSLog(@"finish recording");
    self.recordStatus = JLStatusStop;
    if (!error) {
        [self recordedMovieAtURL:outputFileURL];
    }
}

#pragma mark - Movie

- (void)addMetaDataForMovieOutputFile:(AVCaptureMovieFileOutput *)aMovieFileOutput {
    
    NSArray *existingMetadataArray = aMovieFileOutput.metadata;
    NSMutableArray *newMetadataArray = nil;
    if (existingMetadataArray) {
        newMetadataArray = [existingMetadataArray mutableCopy];
    }
    else {
        newMetadataArray = [[NSMutableArray alloc] init];
    }
    
    AVMutableMetadataItem *item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceCommon;
//    item.key = AVMetadataCommonKeyLocation;
//
//    CLLocation *location - <#The location to set#>;
//    item.value = [NSString stringWithFormat:@"%+08.4lf%+09.4lf/"
//                  location.coordinate.latitude, location.coordinate.longitude];
//
//    [newMetadataArray addObject:item];
//
    
    item.key = AVMetadataCommonKeyModel;
    item.value = [UIDevice currentDevice].model;
    aMovieFileOutput.metadata = newMetadataArray;
}

- (void)configureMovieVar:(AVCaptureMovieFileOutput *)aMovieFileOutput {

//    CMTime maxDuration = <#Create a CMTime to represent the maximum duration#>;
//    aMovieFileOutput.maxRecordedDuration = maxDuration;
//    aMovieFileOutput.minFreeDiskSpaceLimit = <#An appropriate minimum given the quality of the movie format and the duration#>;
//    The resolution and bit rate for the output depend on the capture session’s sessionPreset. The video encoding is typically H.264 and audio encoding is typically AAC. The actual values vary by device.

    
}

#pragma mark - Save

- (void)saveImage:(UIImage *)img {
    [self capturedImage:img];
}

- (void)saveVideoAtURL:(NSURL *)url {
    /**
     * url.absoluteString != url.path
     * url.absoluteString : file://.....
     * url.path           : .......
     */
    //    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.absoluteString)) {
    //        UISaveVideoAtPathToSavedPhotosAlbum(url.absoluteString,self,@selector(video:didFinishSavingWithError:contextInfo:),nil);
    //    }
    [self save:url.path];
}

- (void)save:(NSString*)urlString{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:urlString]
                                completionBlock:^(NSURL *assetURL, NSError *error) {
                                    if (error) {
                                        NSLog(@"save movie error: %@",error);
                                    } else {
                                        NSLog(@"save movie to photo library success");
                                    }
                                }];
}

// save video complete selector
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"save movie error: %@",error);
    } else {
        NSLog(@"save movie to photo library success");
    }
}

// save image complete selector
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error) {
        NSLog(@"save image error: %@",error);
    } else {
        NSLog(@"save image to photo library success");
    }
}

#pragma mark - Save Path

- (NSString *)movieOutputPath {
    // 根据时间设置视频名称
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"YYYYMMDDHHmmss";
    NSString *MovieName = [formatter stringFromDate:date];
    NSString *ouputeDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *outputPath =[ouputeDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mov",MovieName]];
    return outputPath;
}

#pragma mark - SubClass Implements

- (UIView *)containerViewForPreviewLayer {
    return self.view;
}

- (void)recordedMovieAtURL:(NSURL *)url {
    [self saveVideoAtURL:url];
}

- (void)capturedImage:(UIImage *)image {
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

#pragma mark - Getter

- (BOOL)isRecordingMovie {
    return self.recordStatus == JLStatusRecording;
}

@end
