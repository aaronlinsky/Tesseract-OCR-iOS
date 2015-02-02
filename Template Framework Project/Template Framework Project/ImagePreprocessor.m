//
//  ImagePreprocessor.m
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 24.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "ImagePreprocessor.h"
#import "GPUImage.h"
#import "InverseAdaptiveThresholdFilter.h"
#import "Median5x5Filter.h"

@implementation ImagePreprocessor

+(UIImage*)binarize:(UIImage*)image
{
    GPUImageLuminanceThresholdFilter *fixedThresholdFilter = [[GPUImageLuminanceThresholdFilter alloc] init];
    fixedThresholdFilter.threshold = 0.55;

    return [ImagePreprocessor processImage:image withFilter:fixedThresholdFilter];
}

+(UIImage*)adaptiveBinarize:(UIImage*)image
{
    GPUImageAdaptiveThresholdFilter *adaptiveThresholdFilter = [[GPUImageAdaptiveThresholdFilter alloc] init];
    
    return [ImagePreprocessor processImage:image withFilter:adaptiveThresholdFilter];
}

+(UIImage*)inverseAdaptiveBinarize:(UIImage*)image
{
    InverseAdaptiveThresholdFilter *adaptiveThresholdFilter = [[InverseAdaptiveThresholdFilter alloc] init];
    
    return [ImagePreprocessor processImage:image withFilter:adaptiveThresholdFilter];
}

+(UIImage*)processImage:(UIImage*)image withFilter:(GPUImageOutput<GPUImageInput>*)filter
{
    GPUImagePicture *stillImageSource = [[GPUImagePicture alloc] initWithImage:image];

    [stillImageSource addTarget:filter];
    [filter useNextFrameForImageCapture];
    [stillImageSource processImage];

    UIImage *filteredImage = [filter imageFromCurrentFramebuffer];

    return filteredImage;
}

+(UIImage*)denoiseImage:(UIImage*)image
{
    GPUImageMedianFilter *filter = [[GPUImageMedianFilter alloc] init];
    return [ImagePreprocessor processImage:image withFilter:filter];
//    Median5x5Filter *filter = [[Median5x5Filter alloc]initWithImage:image];
//    return [ImagePreprocessor processImage:image withFilter:filter];
}

@end
