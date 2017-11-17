//
//  ViewController.h
//  JLCaptureDevice
//
//  Created by Jack on 2017/2/28.
//  Copyright © 2017年 Emerys. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


typedef enum {
    JLCaptureModeTakePicture,
    JLCaptureModeRecordMovie
}JLCaptureMode;


@interface JLCaptureViewController : UIViewController

@property (nonatomic,assign) JLCaptureMode mode;
@property (nonatomic,assign,readonly) BOOL isRecordingMovie;

#pragma mark - Action

- (void)pinchAtPoint:(CGPoint)point withScaleFactor:(float)scale;
- (void)forcusAtPoint:(CGPoint)point;
- (void)takePicture;
- (void)startRecordMovie;
- (void)stopRecordMovie;
- (void)changeMode;
- (void)changeCaptureDevice;

#pragma mark - Device Setting

//- (void)setTorchMode:(AVCaptureTorchMode)torchMode;
- (void)setFlashMode:(AVCaptureFlashMode)flashMode;
- (void)setWhiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode;
- (void)setFocusCurPosition:(CGPoint)curPosition;
- (void)setExposurePoint:(CGPoint)point;
- (void)setExposureMode:(AVCaptureExposureMode)exposureMode;
- (void)setFocusPoint:(CGPoint)point;
- (void)setFocusMode:(AVCaptureFocusMode)focusMode;

#pragma mark - SubClass Implements

- (UIView *)containerViewForPreviewLayer;
- (void)recordedMovieAtURL:(NSURL *)url;
- (void)capturedImage:(UIImage *)image;

@end

