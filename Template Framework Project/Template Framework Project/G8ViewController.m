//
//  G8ViewController.m
//  Template Framework Project
//
//  Created by Daniele on 14/10/13.
//  Copyright (c) 2013 Daniele Galiotto - www.g8production.com.
//  All rights reserved.
//

#import "G8ViewController.h"
#import "OcrParser.h"
#import "ImagePreprocessor.h"

#define TICK        NSDate *startTime = [NSDate date]
#define ELAPSED     -[startTime timeIntervalSinceNow]
#define TOCK        NSLog(@"Time: %f", ELAPSED)

typedef NS_ENUM(NSUInteger, PreprocessMode) {
    adaptiveBinarization,
    simpleBinarization,
    noPreprocessing
};
#define PreprocessModeString(enum) [@[@"adaptiveBinarization",@"simpleBinarization",@"noPreprocessing"] objectAtIndex:enum]

typedef NS_ENUM(NSUInteger, SessionPreset) {
    preset128x720,
    preset640x480,
    preset352x288
};
#define SessionPresetString(enum) [@[AVCaptureSessionPreset1280x720,AVCaptureSessionPreset640x480,AVCaptureSessionPreset352x288] objectAtIndex:enum]

@interface G8ViewController () 

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property BOOL readyToOCR;
@end


/**
 *  For more information about using `G8Tesseract`, visit the GitHub page at:
 *  https://github.com/gali8/Tesseract-OCR-iOS
 */
@implementation G8ViewController{
    UILabel *ocrResultsLabel;
    UILabel *parsingResultsLabel;
    UIImageView *preprocessPreview;
    UILabel *preprocessModeLabel;
    UILabel *sessionPresetLabel;
    PreprocessMode preprocessMode;
    SessionPreset sessionPreset;
}

@synthesize captureSession = _captureSession;
@synthesize dataOutput = _dataOutput;

@synthesize customPreviewLayer = _customPreviewLayer;

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Create a queue to perform recognition operations
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.readyToOCR = YES;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self openVideo:nil];
}

-(void)recognizeImageWithTesseract:(UIImage *)image
{
    TICK;
    UIImage *bwImage;
    
    switch (preprocessMode) {
        case simpleBinarization:
            bwImage = [ImagePreprocessor binarize:image];
            break;
        case adaptiveBinarization:
            bwImage = [ImagePreprocessor adaptiveBinarize:image];
            break;
        default://no preprocessing at all
            bwImage = image;
            break;
    }
//    TOCK;
    
    G8RecognitionOperation *operation = [[G8RecognitionOperation alloc] init];
    
    operation.delegate = self;
    operation.tesseract.image = bwImage;
    operation.recognitionCompleteBlock = ^(G8Tesseract *tesseract) {
//        TOCK;
        NSString *recognizedText = tesseract.recognizedText;
//        NSLog(@"%@",recognizedText);

        NSString* recognizedTextNoWhitespaces = [[recognizedText stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@"" ];
        ocrResultsLabel.text = [recognizedTextNoWhitespaces stringByAppendingFormat:@"\n%f",ELAPSED];

        if(ELAPSED > 0.7)//should not use constant value here but derive from average ELAPSED time
        {//degradation detected. Force tesserect reinit
            NSLog(@"Reinitializing...");
            ocrResultsLabel.text = [ocrResultsLabel.text stringByAppendingString:@"*"];//reinitialization signalling
            [G8RecognitionOperation reinitTess];
        }
        
        if(recognizedText != nil && ![recognizedText isEqualToString: @""]){
            NSString *year;
            NSString *variety;
            BOOL parsingSuccessful = [OcrParser parseWine:@"mira" ocrString:recognizedText toYear:&year andVariety:&variety];

            if(parsingSuccessful)
                parsingResultsLabel.text = [NSString stringWithFormat:@"%@ / %@",year,variety];
        }
        
        preprocessPreview.image = bwImage;
        preprocessModeLabel.text = PreprocessModeString(preprocessMode);
        sessionPresetLabel.text = SessionPresetString(sessionPreset);
        
        self.readyToOCR = YES;
    };

    [self.operationQueue addOperation:operation];
}

- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    return NO;
}


- (IBAction)openVideo:(id)sender
{
    [self setupCameraSession];
    [_captureSession startRunning];
}


- (void)setupCameraSession
{
    //ICLog;
    
    // Session
    _captureSession = [AVCaptureSession new];
    [_captureSession setSessionPreset:  SessionPresetString(sessionPreset)
                                        //AVCaptureSessionPreset352x288
                                        //AVCaptureSessionPreset640x480
                                        //AVCaptureSessionPreset1280x720
     ];
    
    // Capture device
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    
    // Device input
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
    if ( [_captureSession canAddInput:deviceInput] )
        [_captureSession addInput:deviceInput];
    
    // Preview
    _customPreviewLayer = [CALayer layer];
    _customPreviewLayer.bounds = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    _customPreviewLayer.position = CGPointMake(self.view.frame.size.width/2., self.view.frame.size.height/2.);
    
    UIViewController *vc = [[UIViewController alloc] init];
    [vc.view.layer addSublayer:_customPreviewLayer ];
    
    ocrResultsLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,
                                                               0,
                                                               CGRectGetWidth(self.view.frame),
                                                               CGRectGetHeight(self.view.frame))];
    ocrResultsLabel.layer.position = CGPointMake(CGRectGetWidth(ocrResultsLabel.frame)/2,50);
    ocrResultsLabel.textAlignment = NSTextAlignmentCenter;
    [vc.view addSubview:ocrResultsLabel];
    ocrResultsLabel.numberOfLines = 0;
    ocrResultsLabel.textColor = [UIColor whiteColor];

    parsingResultsLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,
                                                                   0,
                                                                   CGRectGetWidth(self.view.frame),
                                                                   CGRectGetHeight(self.view.frame))];
    parsingResultsLabel.layer.position = CGPointMake(CGRectGetWidth(parsingResultsLabel.frame)/2,CGRectGetHeight(self.view.frame)-20);
    parsingResultsLabel.textAlignment = NSTextAlignmentCenter;
    [vc.view addSubview:parsingResultsLabel];
    parsingResultsLabel.numberOfLines = 0;
    parsingResultsLabel.textColor = [UIColor whiteColor];
    parsingResultsLabel.text = @"Year/Variety";
    
    preprocessPreview = [[UIImageView alloc] initWithFrame:CGRectMake(CGRectGetWidth([UIScreen mainScreen].bounds)/4,
                                                                      CGRectGetHeight([UIScreen mainScreen].bounds) - CGRectGetWidth([UIScreen mainScreen].bounds)/2 - 40,
                                                                      CGRectGetWidth([UIScreen mainScreen].bounds)/2,
                                                                      CGRectGetWidth([UIScreen mainScreen].bounds)/2)];
    preprocessPreview.alpha = 0.75;
    [vc.view addSubview:preprocessPreview];

    preprocessModeLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,-15,CGRectGetWidth(preprocessPreview.frame),20)];
    preprocessModeLabel.textAlignment = NSTextAlignmentCenter;
    preprocessModeLabel.textColor = [UIColor whiteColor];
    preprocessModeLabel.text = @"preprocess mode";
    preprocessModeLabel.font = [UIFont systemFontOfSize:10];
    [preprocessPreview addSubview:preprocessModeLabel];

    sessionPresetLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,-25,CGRectGetWidth(preprocessPreview.frame),20)];
    sessionPresetLabel.textAlignment = NSTextAlignmentCenter;
    sessionPresetLabel.textColor = [UIColor whiteColor];
    sessionPresetLabel.text = @"preset";
    sessionPresetLabel.font = [UIFont systemFontOfSize:9];
    [preprocessPreview addSubview:sessionPresetLabel];

    
    UIButton *quitButton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetWidth([UIScreen mainScreen].bounds)-40,
                                                                     CGRectGetHeight([UIScreen mainScreen].bounds)-40,
                                                                     40,
                                                                     40)];
    [quitButton setTitle:@"Quit" forState:UIControlStateNormal];
    [quitButton addTarget:self action:@selector(quitPreview:) forControlEvents:UIControlEventTouchUpInside];
    [vc.view addSubview:quitButton];
    [quitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal]  ;
    quitButton.layer.borderColor = [UIColor whiteColor].CGColor;
    quitButton.layer.borderWidth = 2;
    quitButton.layer.cornerRadius = 10;
    
    UIButton *preprocButton = [[UIButton alloc]initWithFrame:CGRectMake(0,
                                                                         CGRectGetHeight([UIScreen mainScreen].bounds)-40,
                                                                         50,
                                                                         40)];
    [preprocButton setTitle:@"Preproc" forState:UIControlStateNormal];
    [preprocButton addTarget:self action:@selector(togglePreprocessMode:) forControlEvents:UIControlEventTouchUpInside];
    [vc.view addSubview:preprocButton];
    [preprocButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    preprocButton.titleLabel.font = [UIFont systemFontOfSize:11];
    preprocButton.layer.borderColor = [UIColor whiteColor].CGColor;
    preprocButton.layer.borderWidth = 2;
    preprocButton.layer.cornerRadius = 10;
    
    UIButton *presetButton  = [[UIButton alloc]initWithFrame:CGRectMake(0,
                                                                        CGRectGetHeight([UIScreen mainScreen].bounds)-40 - CGRectGetHeight(preprocButton.frame),
                                                                        50,
                                                                        40)];
    [presetButton setTitle:@"Preset" forState:UIControlStateNormal];
    [presetButton addTarget:self action:@selector(toggleSessionPreset:) forControlEvents:UIControlEventTouchUpInside];
    [vc.view addSubview:presetButton];
    [presetButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    presetButton.titleLabel.font = [UIFont systemFontOfSize:11];
    presetButton.layer.borderColor = [UIColor whiteColor].CGColor;
    presetButton.layer.borderWidth = 2;
    presetButton.layer.cornerRadius = 10;
    
    [self presentViewController:vc animated:NO completion:nil];
    
    _dataOutput = [AVCaptureVideoDataOutput new];
    _dataOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    
    [_dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    if ( [_captureSession canAddOutput:_dataOutput] )
        [_captureSession addOutput:_dataOutput];
    
    [_captureSession commitConfiguration];
    
    dispatch_queue_t queue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL);
    [_dataOutput setSampleBufferDelegate:self queue:queue];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    if([connection isVideoOrientationSupported])
        connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // For the iOS the luma is contained in full plane (8-bit)
    size_t width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
    size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
    
    Pixel_8 *lumaBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
    
    const vImage_Buffer inImage = { lumaBuffer, height, width, bytesPerRow };
    
    CGColorSpaceRef grayColorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(inImage.data, width, height, 8, bytesPerRow, grayColorSpace, kCGImageAlphaNone);
    CGImageRef dstImageFilter = CGBitmapContextCreateImage(context);
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        _customPreviewLayer.contents = (__bridge id)dstImageFilter;
    });

    if(self.readyToOCR){
//        NSLog(@"1");
        UIImage *image = [UIImage imageWithCGImage:dstImageFilter];
        self.readyToOCR = NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self recognizeImageWithTesseract:image];
//            [self recognizeImageWithTesseract:[UIImage imageNamed:@"2009.jpg"] ];
        });
    }
    
    CGImageRelease(dstImageFilter);
    CGContextRelease(context);
    CGColorSpaceRelease(grayColorSpace);
}

-(void)quitPreview:(id)sender
{
    [_captureSession removeOutput:_dataOutput];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)togglePreprocessMode:(id)sender
{
    preprocessMode = (preprocessMode + 1) % (noPreprocessing+1);
}

-(void)toggleSessionPreset:(id)sender
{
    sessionPreset = (sessionPreset + 1) % (preset352x288+1);
    [self quitPreview:nil];//reinitializing capture
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchPoint = [touch locationInView:touch.view];
    [self focus:touchPoint];
}

- (void) focus:(CGPoint) aPoint
{
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    
    if (captureDeviceClass != nil) {
        NSLog(@"Focusing...");
        AVCaptureDevice *device = [captureDeviceClass defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            CGRect screenRect = [[UIScreen mainScreen] bounds];
            double screenWidth = screenRect.size.width;
            double screenHeight = screenRect.size.height;
            double focus_x = aPoint.x/screenWidth;
            double focus_y = aPoint.y/screenHeight;
            
            if([device lockForConfiguration:nil]) {
                [device setFocusPointOfInterest:CGPointMake(focus_x,focus_y)];
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
                
                if ([device isExposureModeSupported:AVCaptureExposureModeAutoExpose]){
                    [device setExposureMode:AVCaptureExposureModeAutoExpose];
                }
                [device unlockForConfiguration];
            }
        }
    }
}

@end