//
//  ImagePreprocessor.h
//  Template Framework Project
//
//  Created by Sergey Yuzepovich on 24.01.15.
//  Copyright (c) 2015 Daniele Galiotto - www.g8production.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImagePreprocessor : NSObject

+(UIImage*)binarize:(UIImage*)image;
+(UIImage*)adaptiveBinarize:(UIImage*)image;
+(UIImage*)inverseAdaptiveBinarize:(UIImage*)image;

@end
