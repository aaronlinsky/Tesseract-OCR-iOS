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

#define TICK        NSDate *startTime = [NSDate date]
#define ELAPSED     -[startTime timeIntervalSinceNow]
#define TOCK        NSLog(@"Time: %f", ELAPSED)


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
    UIImage *bwImage = image;//[image g8_blackAndWhite];

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
    [_captureSession setSessionPreset:  //AVCaptureSessionPreset352x288
                                        //AVCaptureSessionPreset640x480
                                        AVCaptureSessionPreset1280x720
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
    parsingResultsLabel.layer.position = CGPointMake(CGRectGetWidth(parsingResultsLabel.frame)/2,CGRectGetHeight(self.view.frame)-50);
    parsingResultsLabel.textAlignment = NSTextAlignmentCenter;
    [vc.view addSubview:parsingResultsLabel];
    parsingResultsLabel.numberOfLines = 0;
    parsingResultsLabel.textColor = [UIColor whiteColor];
    parsingResultsLabel.text = @"Year/Variety";
    
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
        UIImage *image = [UIImage imageWithCGImage:dstImageFilter];//[UIImage imageWithCGImage:dstImageFilter scale:1.0 orientation:UIImageOrientationUp];
        self.readyToOCR = NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self recognizeImageWithTesseract:image];
//            [self recognizeImageWithTesseract:[[UIImage imageNamed:@"2009.jpg"] g8_blackAndWhite] ];
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

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchPoint = [touch locationInView:touch.view];
    [self focus:touchPoint];
}

- (void) focus:(CGPoint) aPoint;
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