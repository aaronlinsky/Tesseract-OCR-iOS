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
#import "BatchProcessorController.h"
#import "BatchProcessor.h"

#define TICK        NSDate *startTime = [NSDate date]
#define ELAPSED     -[startTime timeIntervalSinceNow]
#define TOCK        NSLog(@"Time: %f", ELAPSED)

static NSString * const BATCH_IMAGE_DIR = @"./BATCHED_IMAGES";

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
    UILabel *wineryLabel;
    PreprocessMode preprocessMode;
    SessionPreset sessionPreset;
    UIViewController *vc;
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
    
    [OcrParser instance];//warming-up parser
    self.winery = @"Louis Jadot";//@"Mira";

    [self openVideo:nil];
}

-(void)setWinery:(NSString *)winery{
    _winery = winery;
    wineryLabel.text = winery;
}

-(void)preprocessAndRecognizeImage:(UIImage *)image withMode:(PreprocessMode)mode withBlock:(void(^)(ImageInfo *i))completion
{
    UIImage *bwImage;
    TICK;
//    image = [ImagePreprocessor denoiseImage:image];
//    TOCK;

    switch (mode) {
        case inverseAdaptiveBinarization:
            bwImage = [ImagePreprocessor inverseAdaptiveBinarize:image];
            break;
        case adaptiveBinarization:
            bwImage = [ImagePreprocessor adaptiveBinarize:image];
            break;
        default://no preprocessing at all
            bwImage = image;
            break;
    }
//    TICK;
//    bwImage = [ImagePreprocessor denoiseImage:bwImage];

//    TOCK;

    G8RecognitionOperation *operation = [[G8RecognitionOperation alloc] init];
    
    operation.delegate = self;
    operation.tesseract.image = bwImage;
    operation.recognitionCompleteBlock = ^(G8Tesseract *tesseract) {
//        TOCK;
        NSString *recognizedText = tesseract.recognizedText;
        preprocessPreview.image = bwImage;
        preprocessModeLabel.text = PreprocessModeString(preprocessMode);
        sessionPresetLabel.text = SessionPresetString(sessionPreset);

//        NSLog(@"%@",recognizedText);

        NSString* recognizedTextNoWhitespaces = [[recognizedText stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@"" ];
        ocrResultsLabel.text = [recognizedTextNoWhitespaces stringByAppendingFormat:@"\n%f",ELAPSED];

        if(ELAPSED > 0.8)//should not use constant value here but derive from average ELAPSED time
        {//degradation detected. Force tesserect reinit
            NSLog(@"Reinitializing...");
            ocrResultsLabel.text = [ocrResultsLabel.text stringByAppendingString:@"*"];
            [G8RecognitionOperation reinitTess];
        }

        NSString *year;
        NSString *variety;
        NSString *vineyard;
        NSString *subregion;
        if(recognizedText != nil && ![recognizedText isEqualToString: @""]){
            
            BOOL parsingSuccessful = [OcrParser parseWine:self.winery ocrString:recognizedText toYear:&year variety:&variety vineyard:&vineyard subregion:&subregion];
//            BOOL parsingSuccessful = [OcrParser parseUnknownWine:recognizedText toYear:&year andVariety:&variety];

            if(parsingSuccessful){
                parsingResultsLabel.text = [NSString stringWithFormat:@"%@ / %@ \n%@\n%@",year,variety,vineyard,subregion];
                
            }
            else{
                if (mode == adaptiveBinarization) {
                    //possibly white-on-black. perform additional pass
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [self preprocessAndRecognizeImage: image withMode:inverseAdaptiveBinarization withBlock:completion];
                    });
                    return;
                }
            }
        }
        
        if(completion != nil){
            ImageInfo *imgInfo = [[ImageInfo alloc]init];
            imgInfo.winery = self.winery;
            imgInfo.acceptedSubregions = @[subregion];
            imgInfo.acceptedVarieties = @[variety];
            imgInfo.acceptedVineyards = @[vineyard];
            imgInfo.acceptedYears = @[year];
            completion(imgInfo);
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
    // Session
    _captureSession = [AVCaptureSession new];
    [_captureSession setSessionPreset:  SessionPresetString(sessionPreset)];
    
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
    
    vc = [[UIViewController alloc] init];
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
                                                                   CGRectGetHeight(self.view.frame)-45,
                                                                   CGRectGetWidth(self.view.frame),
                                                                   50)];
    parsingResultsLabel.textAlignment = NSTextAlignmentCenter;
    [vc.view addSubview:parsingResultsLabel];
    parsingResultsLabel.numberOfLines = 0;
    parsingResultsLabel.textColor = [UIColor whiteColor];
    parsingResultsLabel.font = [UIFont systemFontOfSize:12];
    parsingResultsLabel.text = @"Year/Variety\nVineyard\nLocation";
    
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

    wineryLabel = [[UILabel alloc]initWithFrame:CGRectMake(0,-35,CGRectGetWidth(preprocessPreview.frame),20)];
    wineryLabel.textAlignment = NSTextAlignmentCenter;
    wineryLabel.textColor = [UIColor grayColor];
    wineryLabel.text = self.winery;
    wineryLabel.font = [UIFont systemFontOfSize:9];
    [preprocessPreview addSubview:wineryLabel];
    

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
    
    UIButton *wineryButton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetWidth([UIScreen mainScreen].bounds)-40,
                                                                     CGRectGetHeight([UIScreen mainScreen].bounds)-80,
                                                                     40,
                                                                     40)];
    [wineryButton setTitle:@"Winery" forState:UIControlStateNormal];
    [wineryButton addTarget:self action:@selector(pickWinery:) forControlEvents:UIControlEventTouchUpInside];
    [vc.view addSubview:wineryButton];
    [wineryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    wineryButton.titleLabel.font = [UIFont systemFontOfSize:11];
    wineryButton.layer.borderColor = [UIColor whiteColor].CGColor;
    wineryButton.layer.borderWidth = 2;
    wineryButton.layer.cornerRadius = 10;

    
    UIButton *presetButton = [[UIButton alloc]initWithFrame:CGRectMake(0,
                                                                       CGRectGetHeight([UIScreen mainScreen].bounds)-40,
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

    UIButton *batchButton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetWidth([UIScreen mainScreen].bounds)-40,
                                                                      CGRectGetHeight([UIScreen mainScreen].bounds)-120,
                                                                      40,40)];

    [batchButton setTitle:@"Batch" forState:UIControlStateNormal];
    [batchButton addTarget:self action:@selector(presentBatchProcessor:) forControlEvents:UIControlEventTouchUpInside];
    [vc.view addSubview:batchButton];
    [batchButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    batchButton.titleLabel.font = [UIFont systemFontOfSize:11];
    batchButton.layer.borderColor = [UIColor whiteColor].CGColor;
    batchButton.layer.borderWidth = 2;
    batchButton.layer.cornerRadius = 10;
    
    [self presentViewController:vc animated:NO completion:nil];
    
    _dataOutput = [AVCaptureVideoDataOutput new];
    _dataOutput.videoSettings = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                                            forKey:(id)kCVPixelBufferPixelFormatTypeKey];
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
    
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);

    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, rgbColorSpace, (CGBitmapInfo) kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef dstImageFilter = CGBitmapContextCreateImage(context);
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        _customPreviewLayer.contents = (__bridge id)dstImageFilter;
    });

    if(self.readyToOCR){
        UIImage *image = [UIImage imageWithCGImage:dstImageFilter];
        self.readyToOCR = NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self preprocessAndRecognizeImage: image withMode:preprocessMode withBlock:nil];
//            [self recognizeImageWithTesseract:[UIImage imageNamed:@"2009.jpg"] ];
        });
    }
    
    CGImageRelease(dstImageFilter);
    CGContextRelease(context);
    CGColorSpaceRelease(rgbColorSpace);
}

-(void)quitPreview:(id)sender
{
    [_captureSession stopRunning];
    [_captureSession removeOutput:_dataOutput];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)pauseCapture{
    [_captureSession stopRunning];
}

-(void)unpauseCapture{
    [_captureSession startRunning];
}

-(void)togglePreprocessMode:(id)sender
{
    preprocessMode = (preprocessMode + 1) % (noPreprocessing);
}

-(void)toggleSessionPreset:(id)sender
{
    sessionPreset = (sessionPreset + 1) % (preset352x288+1);
    [self quitPreview:nil];//reinitializing capture
}

-(void)presentBatchProcessor:(id)sender
{
    [self pauseCapture];
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: [NSBundle mainBundle]];
    BatchProcessorController *batchProc = [mainStoryboard instantiateViewControllerWithIdentifier:@"BatchProcessorController"];

    NSMutableArray *imagesNames = [[NSMutableArray alloc]init];
    batchProc.images = [self loadImages:imagesNames];
    batchProc.imageInfos = [self imagesInfos:imagesNames];
    
    [vc presentViewController:batchProc animated:YES completion:nil];
}

-(NSArray*)loadImages:(NSMutableArray*)outImagesNames{

    NSArray *paths = [[NSBundle mainBundle] pathsForResourcesOfType:@"jpg" inDirectory:BATCH_IMAGE_DIR];
    paths = [paths arrayByAddingObjectsFromArray:
             [[NSBundle mainBundle]pathsForResourcesOfType:@"JPG" inDirectory:BATCH_IMAGE_DIR]];
    paths = [paths arrayByAddingObjectsFromArray:
     [[NSBundle mainBundle]pathsForResourcesOfType:@"png" inDirectory:BATCH_IMAGE_DIR]];

    NSMutableArray *images = [[NSMutableArray alloc]initWithCapacity:paths.count];
    for (NSString* p in paths) {
        [images addObject:[UIImage imageWithContentsOfFile:p]];
        [outImagesNames addObject:p.lastPathComponent];
    }
    
    return images;
}

-(NSArray*)imagesInfos:(NSArray*)imagesNames{
    NSString *path = [[NSBundle mainBundle]pathForResource:@"images" ofType:@"json"inDirectory:BATCH_IMAGE_DIR];

    NSData *jsonData = [NSData dataWithContentsOfFile:path];
    NSArray *jsonResults = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];

    NSMutableArray *infos = [[NSMutableArray alloc]initWithCapacity:imagesNames.count];
    for (NSString *path in imagesNames) {
        ImageInfo *i = nil;

        for (NSDictionary *wine in jsonResults) {
            if ([path isEqualToString:wine[@"file"]]) {
                i = [[ImageInfo alloc]init];
                i.winery = wine[@"winery"];
                i.acceptedVarieties = wine[@"varietals"];
                i.acceptedVineyards = wine[@"vineyards"];
                i.acceptedSubregions = wine[@"subregions"];
                i.acceptedYears = wine[@"vintages"];
                [infos addObject:i];

                break;
            }
        }
        
        if(i == nil){
            @throw [[NSException alloc]initWithName:@"Internal Inconsistency" reason:@"Images and their descriptions are out of sync" userInfo:nil];
        }
    }
    
    return infos;
}

-(void)pickWinery:(id)sender
{
    [self pauseCapture];
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main" bundle: [NSBundle mainBundle]];
    UIViewController *wineryPciker = [mainStoryboard instantiateViewControllerWithIdentifier:@"WineryPickerController"];
    
    [vc presentViewController:wineryPciker animated:YES completion:nil];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
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