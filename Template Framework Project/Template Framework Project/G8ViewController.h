//
//  G8ViewController.h
//  Template Framework Project
//
//  Created by Daniele on 14/10/13.
//  Copyright (c) 2013 Daniele Galiotto - www.g8production.com.
//  All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TesseractOCR/TesseractOCR.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>
#import <Accelerate/Accelerate.h>
#import "TesseractRecognizer.h"

@class ImageInfo;

@interface G8ViewController : UIViewController <G8TesseractDelegate,
                                                UIImagePickerControllerDelegate,
                                                UINavigationControllerDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureVideoDataOutput *dataOutput;
@property (nonatomic, strong) CALayer *customPreviewLayer;
@property (nonatomic, copy) NSString *winery;

- (IBAction)openVideo:(id)sender;
- (void)setupCameraSession;

//-(void)preprocessAndRecognizeImage:(UIImage *)image withMode:(PreprocessMode)mode withBlock:(void(^)(ImageInfo *i))completion;

-(void)pauseCapture;
-(void)unpauseCapture;

@end
