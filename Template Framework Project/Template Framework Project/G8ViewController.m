//
//  G8ViewController.m
//  Template Framework Project
//
//  Created by Daniele on 14/10/13.
//  Copyright (c) 2013 Daniele Galiotto - www.g8production.com.
//  All rights reserved.
//

#import "G8ViewController.h"

@interface G8ViewController () 

@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end


/**
 *  For more information about using `G8Tesseract`, visit the GitHub page at:
 *  https://github.com/gali8/Tesseract-OCR-iOS
 */
@implementation G8ViewController{
    double numberOfFrame;
}

@synthesize captureSession = _captureSession;
@synthesize dataOutput = _dataOutput;

@synthesize customPreviewLayer = _customPreviewLayer;

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Create a queue to perform recognition operations
    self.operationQueue = [[NSOperationQueue alloc] init];
}

-(void)recognizeImageWithTesseract:(UIImage *)image
{
    // Preprocess the image so Tesseract's recognition will be more accurate
    UIImage *bwImage = [image g8_blackAndWhite];

    // Animate a progress activity indicator
    [self.activityIndicator startAnimating];

    // Display the preprocessed image to be recognized in the view
    self.imageToRecognize.image = bwImage;

    // Create a new `G8RecognitionOperation` to perform the OCR asynchronously
    G8RecognitionOperation *operation = [[G8RecognitionOperation alloc] init];
    
    // It is assumed that there is a .traineddata file for the language pack
    // you want Tesseract to use in the "tessdata" folder in the root of the
    // project AND that the "tessdata" folder is a referenced folder and NOT
    // a symbolic group in your project
    operation.tesseract.language = @"eng";
    
    // Use the original Tesseract engine mode in performing the recognition
    // (see G8Constants.h) for other engine mode options
    operation.tesseract.engineMode = G8OCREngineModeTesseractOnly;
    
    // Let Tesseract automatically segment the page into blocks of text
    // based on its analysis (see G8Constants.h) for other page segmentation
    // mode options
    operation.tesseract.pageSegmentationMode = G8PageSegmentationModeAutoOnly;
    
    // Optionally limit the time Tesseract should spend performing the
    // recognition
    //operation.tesseract.maximumRecognitionTime = 1.0;
    
    // Set the delegate for the recognition to be this class
    // (see `progressImageRecognitionForTesseract` and
    // `shouldCancelImageRecognitionForTesseract` methods below)
    operation.delegate = self;

    // Optionally limit Tesseract's recognition to the following whitelist
    // and blacklist of characters
    //operation.tesseract.charWhitelist = @"01234";
    //operation.tesseract.charBlacklist = @"56789";
    
    // Set the image on which Tesseract should perform recognition
    operation.tesseract.image = bwImage;

    // Optionally limit the region in the image on which Tesseract should
    // perform recognition to a rectangle
    //operation.tesseract.rect = CGRectMake(20, 20, 100, 100);

    // Specify the function block that should be executed when Tesseract
    // finishes performing recognition on the image
    operation.recognitionCompleteBlock = ^(G8Tesseract *tesseract) {
        // Fetch the recognized text
        NSString *recognizedText = tesseract.recognizedText;
        
        if (![recognizedText isEqualToString:@""]){
            NSLog(@"%@", recognizedText);
            
            // Remove the animated progress activity indicator
            [self.activityIndicator stopAnimating];
            
            // Spawn an alert with the recognized text
            //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"OCR Result"
//                                                            message:recognizedText
//                                                           delegate:nil
//                                                  cancelButtonTitle:@"OK"
//                                                  otherButtonTitles:nil];
            //[alert show];
        }
    };

    // Finally, add the recognition operation to the queue
    [self.operationQueue addOperation:operation];
}

/**
 *  This function is part of Tesseract's delegate. It will be called
 *  periodically as the recognition happens so you can observe the progress.
 *
 *  @param tesseract The `G8Tesseract` object performing the recognition.
 */
- (void)progressImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    NSLog(@"progress: %lu", (unsigned long)tesseract.progress);
}

/**
 *  This function is part of Tesseract's delegate. It will be called
 *  periodically as the recognition happens so you can cancel the recogntion
 *  prematurely if necessary.
 *
 *  @param tesseract The `G8Tesseract` object performing the recognition.
 *
 *  @return Whether or not to cancel the recognition.
 */
- (BOOL)shouldCancelImageRecognitionForTesseract:(G8Tesseract *)tesseract {
    return NO;  // return YES, if you need to cancel recognition prematurely
}

- (IBAction)openCamera:(id)sender
{
    UIImagePickerController *imgPicker = [UIImagePickerController new];
    imgPicker.delegate = self;

    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:imgPicker animated:YES completion:nil];
    }
}

- (IBAction)openVideo:(id)sender
{
    numberOfFrame = 0;
    [self setupCameraSession];
    [_captureSession startRunning];
    
    
}

- (IBAction)recognizeSampleImage:(id)sender {
    [self recognizeImageWithTesseract:[UIImage imageNamed:@"2010.png"]];
}

- (IBAction)clearCache:(id)sender
{
    [G8Tesseract clearCache];
}

#pragma mark - UIImagePickerController Delegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self recognizeImageWithTesseract:image];
}


- (void)setupCameraSession
{
    //ICLog;
    
    // Session
    _captureSession = [AVCaptureSession new];
    [_captureSession setSessionPreset:AVCaptureSessionPresetLow];
    
    // Capture device
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    
    // Device input
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
    if ( [_captureSession canAddInput:deviceInput] )
        [_captureSession addInput:deviceInput];
    
    // Preview
    _customPreviewLayer = [CALayer layer];
    _customPreviewLayer.bounds = CGRectMake(0, 0, self.view.frame.size.height, self.view.frame.size.width);
    _customPreviewLayer.position = CGPointMake(self.view.frame.size.width/2., self.view.frame.size.height/2.);
    _customPreviewLayer.affineTransform = CGAffineTransformMakeRotation(M_PI/2);

    //[self.view.layer insertSublayer:_customPreviewLayer atIndex:0];
    
    UIViewController *vc = [[UIViewController alloc] init];
    [vc.view.layer addSublayer:_customPreviewLayer ];
    
    [self presentViewController:vc animated:true completion:nil];
    
    _dataOutput = [AVCaptureVideoDataOutput new];
    _dataOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
                                                            forKey:(NSString *)kCVPixelBufferPixelFormatTypeKey];
    
    [_dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    if ( [_captureSession canAddOutput:_dataOutput] )
        [_captureSession addOutput:_dataOutput];
    
    [_captureSession commitConfiguration];
    
    dispatch_queue_t queue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL);
    [_dataOutput setSampleBufferDelegate:self queue:queue];
}

- (void)maxFromImage:(const vImage_Buffer)src toImage:(const vImage_Buffer)dst
{
    int kernelSize = 7;
    vImageMin_Planar8(&src, &dst, NULL, 0, 0, kernelSize, kernelSize, kvImageDoNotTile);
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    numberOfFrame++;
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
    
    UIImage *image = [UIImage imageWithCGImage:dstImageFilter scale:1.0 orientation:UIImageOrientationRight];
    double frameSampleRate = 20.0;
    //NSLog(@"%f", numberOfFrame);
    
    if(fmodf(numberOfFrame,frameSampleRate)==0){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
              [self recognizeImageWithTesseract:image];
        });
    }
    
    CGImageRelease(dstImageFilter);
    CGContextRelease(context);
    CGColorSpaceRelease(grayColorSpace);
}


@end