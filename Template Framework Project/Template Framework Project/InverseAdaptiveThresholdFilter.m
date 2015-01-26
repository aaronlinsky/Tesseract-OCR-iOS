//
//  AdaptiveThresholdFilter.m
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 24.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import "InverseAdaptiveThresholdFilter.h"
#import "GPUImageFilterGroup.h"
#import "GPUImageAdaptiveThresholdFilter.h"
#import "GPUImageFilter.h"
#import "GPUImageTwoInputFilter.h"
#import "GPUImageGrayscaleFilter.h"
#import "GPUImageBoxBlurFilter.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
NSString *const kGPUImageAdaptiveThresholdFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 varying highp vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     highp float blurredInput = texture2D(inputImageTexture, textureCoordinate).r;
     highp float localLuminance = texture2D(inputImageTexture2, textureCoordinate2).r;
     highp float thresholdResult = step(blurredInput - 0.05, localLuminance);
     
     gl_FragColor = vec4(vec3(thresholdResult), 1.0);
 }
 );
#else
NSString *const kGPUImageAdaptiveThresholdFragmentShaderString = SHADER_STRING
(
 varying vec2 textureCoordinate;
 varying vec2 textureCoordinate2;
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 
 void main()
 {
     float blurredInput = texture2D(inputImageTexture, textureCoordinate).r;
     float localLuminance = texture2D(inputImageTexture2, textureCoordinate2).r;
     float thresholdResult = step(blurredInput - 0.05, localLuminance);
     
     gl_FragColor = vec4(vec3(thresholdResult), 1.0);
 }
 );
#endif



@interface InverseAdaptiveThresholdFilter()
{
    GPUImageBoxBlurFilter *boxBlurFilter;
}
@end

@implementation InverseAdaptiveThresholdFilter

- (id)init
{
    if (!(self = [super init]))
    {
        return nil;
    }
    
    GPUImageGrayscaleFilter *luminanceFilter = [[GPUImageGrayscaleFilter alloc] init];
    [self addFilter:luminanceFilter];
    
    boxBlurFilter = [[GPUImageBoxBlurFilter alloc] init];
    [self addFilter:boxBlurFilter];
    [luminanceFilter addTarget:boxBlurFilter];

    GPUImageFilter *adaptiveThresholdFilter = [[GPUImageTwoInputFilter alloc] initWithFragmentShaderFromString:kGPUImageAdaptiveThresholdFragmentShaderString];
    [self addFilter:adaptiveThresholdFilter];
    
    [boxBlurFilter addTarget:adaptiveThresholdFilter];
    [luminanceFilter addTarget:adaptiveThresholdFilter];
    
    GPUImageColorInvertFilter *invertFilter = [[GPUImageColorInvertFilter alloc]init];
    [self addFilter:invertFilter];
    [invertFilter addTarget:luminanceFilter];
    
    self.initialFilters = [NSArray arrayWithObject:invertFilter];
    self.terminalFilter = adaptiveThresholdFilter;
    
    return self;
}


@end
